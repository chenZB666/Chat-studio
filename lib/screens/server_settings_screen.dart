import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/server_provider.dart';

class ServerSettingsScreen extends ConsumerStatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  ConsumerState<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends ConsumerState<ServerSettingsScreen> {
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _labelController = TextEditingController();
  bool _testing = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final state = ref.read(serverProvider);
    if (state.currentUrl != null) {
      _urlController.text = state.currentUrl!;
    }
    if (state.apiKey != null) {
      _apiKeyController.text = state.apiKey!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Server Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'http://192.168.1.100:8080',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'API Key (optional)',
              prefixIcon: const Icon(Icons.key),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureApiKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
              ),
            ),
            obscureText: _obscureApiKey,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label (optional)',
              hintText: 'My Server',
              prefixIcon: Icon(Icons.label),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    serverState.connectionState == ServerConnectionState.connected
                        ? Icons.check_circle
                        : Icons.error,
                    color: serverState.connectionState == ServerConnectionState.connected
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serverState.connectionState == ServerConnectionState.connected
                              ? 'Connected'
                              : serverState.connectionState == ServerConnectionState.error
                                  ? 'Error'
                                  : 'Not connected',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (serverState.latency != null)
                          Text('Latency: ${serverState.latency!.inMilliseconds}ms',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        if (serverState.errorMessage != null)
                          Text(serverState.errorMessage!,
                              style: TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testing ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_find),
              label: Text(_testing ? 'Testing...' : 'Test Connection'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveServer,
              icon: const Icon(Icons.save),
              label: const Text('Save & Connect'),
            ),
          ),
          const SizedBox(height: 24),
          if (serverState.availableModels.isNotEmpty) ...[
            Text('Available Models', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...serverState.availableModels.map((model) => Card(
              child: ListTile(
                leading: const Icon(Icons.smart_toy),
                title: Text(model.name),
                subtitle: model.contextLength != null
                    ? Text('Context: ${model.contextLength} tokens')
                    : null,
                trailing: model.id == serverState.selectedModelId
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => ref.read(serverProvider.notifier).selectModel(model.id),
              ),
            )),
          ],
          const SizedBox(height: 24),
          if (serverState.savedServers.isNotEmpty) ...[
            Text('Saved Servers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...serverState.savedServers.map((server) => Card(
              child: ListTile(
                leading: const Icon(Icons.dns),
                title: Text(server.label),
                subtitle: Text(server.url, style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: () async {
                    await ref.read(storageServiceProvider).deleteServerConfig(server.id);
                    await ref.read(serverProvider.notifier).refreshSavedServers();
                  },
                ),
                onTap: () async {
                  _urlController.text = server.url;
                  final apiKey = await ref.read(storageServiceProvider).getServerApiKey(server);
                  _apiKeyController.text = apiKey ?? '';
                  _labelController.text = server.label;
                },
              ),
            )),
          ],
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    await ref.read(serverProvider.notifier).connect(
      _urlController.text.trim(),
      apiKey: _apiKeyController.text.trim().isNotEmpty ? _apiKeyController.text.trim() : null,
    );
    setState(() => _testing = false);
  }

  Future<void> _saveServer() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    await _testConnection();
    if (ref.read(serverProvider).connectionState == ServerConnectionState.connected) {
      await ref.read(storageServiceProvider).saveServerConfig(
        url: url,
        apiKey: _apiKeyController.text.trim().isNotEmpty ? _apiKeyController.text.trim() : null,
        label: _labelController.text.trim().isNotEmpty ? _labelController.text.trim() : null,
      );
      if (mounted) Navigator.pop(context);
    }
  }
}