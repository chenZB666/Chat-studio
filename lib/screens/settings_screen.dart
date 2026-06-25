import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  subtitle: Text(_themeModeName(settings.themeMode)),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.auto_mode)),
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (v) {
                      ref.read(settingsProvider.notifier).setThemeMode(v.first);
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme Color'),
                  subtitle: Text(settings.colorSeed),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.presetColorSeeds.map((seed) {
                      final isSelected = settings.colorSeed == seed;
                      return ChoiceChip(
                        label: Text(seed, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: AppTheme.colorFromSeed(seed).withOpacity(0.3),
                        onSelected: (_) {
                          ref.read(settingsProvider.notifier).setColorSeed(seed);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Defaults', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.thermostat),
                  title: const Text('Temperature'),
                  subtitle: Text(settings.defaultTemperature.toStringAsFixed(2)),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: settings.defaultTemperature,
                      min: 0, max: 2,
                      divisions: 40,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultTemperature(v),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Max Tokens'),
                  subtitle: Text(settings.defaultMaxTokens.toString()),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: settings.defaultMaxTokens.toDouble(),
                      min: 256, max: 32768,
                      divisions: 20,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultMaxTokens(v.toInt()),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Default System Prompt',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    controller: TextEditingController(text: settings.defaultSystemPrompt),
                    onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultSystemPrompt(v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export All Conversations'),
                  subtitle: const Text('Save as JSON file'),
                  onTap: () async {
                    final storage = ref.read(storageServiceProvider);
                    final convs = await storage.getAllConversations();
                    final exportData = <Map<String, dynamic>>[];
                    for (final conv in convs) {
                      final msgs = await storage.getMessages(conv.id);
                      exportData.add({
                        'title': conv.title,
                        'createdAt': conv.createdAt,
                        'modelId': conv.modelId,
                        'messages': msgs.map((m) => {
                          'role': m.role,
                          'content': m.content,
                          'createdAt': m.createdAt,
                        }).toList(),
                      });
                    }
                    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
                    final dir = await getApplicationDocumentsDirectory();
                    final file = File('${dir.path}/llamachat_export_${DateTime.now().millisecondsSinceEpoch}.json');
                    await file.writeAsString(jsonStr);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exported ${exportData.length} conversations to ${file.path}')),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Import Conversations'),
                  subtitle: const Text('Load from JSON file'),
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );
                    if (result != null && result.files.single.path != null) {
                      final file = File(result.files.single.path!);
                      final jsonStr = await file.readAsString();
                      final data = jsonDecode(jsonStr) as List<dynamic>;
                      final storage = ref.read(storageServiceProvider);
                      for (final item in data) {
                        final conv = item as Map<String, dynamic>;
                        final newConv = await storage.createConversation(
                          title: conv['title'] as String?,
                          modelId: conv['modelId'] as String?,
                        );
                        final messages = conv['messages'] as List<dynamic>? ?? [];
                        for (final msg in messages) {
                          final m = msg as Map<String, dynamic>;
                          await storage.addMessage(
                            conversationId: newConv.id,
                            role: m['role'] as String,
                            content: m['content'] as String,
                            tokenCount: m['tokenCount'] as int?,
                          );
                        }
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Imported ${data.length} conversations')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: colorScheme.error),
                  title: Text('Clear All Conversations', style: TextStyle(color: colorScheme.error)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear all conversations?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              final storage = ref.read(storageServiceProvider);
                              final convs = await storage.getAllConversations();
                              for (final conv in convs) {
                                await storage.deleteConversation(conv.id);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('All conversations cleared')),
                                );
                              }
                            },
                            child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('About', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('LlamaChat'),
              subtitle: Text('Version ${AppConstants.appVersion}'),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System';
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
    }
  }
}