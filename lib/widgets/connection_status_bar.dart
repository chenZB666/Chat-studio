import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/server_provider.dart';

class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color color;
    String text;

    switch (serverState.connectionState) {
      case ServerConnectionState.connected:
        icon = Icons.check_circle;
        color = Colors.green;
        text = 'llama connected  •  ${serverState.latency?.inMilliseconds ?? "?"}ms';
        break;
      case ServerConnectionState.connecting:
        icon = Icons.sync;
        color = Colors.orange;
        text = 'Connecting...';
        break;
      case ServerConnectionState.error:
        icon = Icons.error;
        color = Colors.red;
        text = 'Connection error: ${serverState.errorMessage ?? "unknown"}';
        break;
      case ServerConnectionState.disconnected:
        icon = Icons.link_off;
        color = colorScheme.onSurfaceVariant;
        text = 'No server configured';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (serverState.currentUrl != null)
            Text(
              serverState.currentUrl!,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}