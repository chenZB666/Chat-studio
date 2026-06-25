import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/server_provider.dart';
import '../core/theme/design_tokens.dart';

class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);
    final colorScheme = Theme.of(context).colorScheme;

    Widget statusWidget;
    switch (serverState.connectionState) {
      case ServerConnectionState.connected:
        statusWidget = _StatusRow(
          dotColor: Colors.green.shade400,
          text: '${serverState.latency?.inMilliseconds ?? "?"}ms',
          subtext: serverState.currentUrl,
          colorScheme: colorScheme,
        );
        break;
      case ServerConnectionState.connecting:
        statusWidget = _StatusRow(
          dotColor: Colors.orange.shade400,
          text: 'Connecting...',
          colorScheme: colorScheme,
          isAnimated: true,
        );
        break;
      case ServerConnectionState.error:
        statusWidget = _StatusRow(
          dotColor: colorScheme.error,
          text: serverState.errorMessage ?? 'Connection error',
          colorScheme: colorScheme,
        );
        break;
      case ServerConnectionState.disconnected:
        statusWidget = _StatusRow(
          dotColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          text: 'No server configured',
          colorScheme: colorScheme,
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: statusWidget,
    );
  }
}

class _StatusRow extends StatelessWidget {
  final Color dotColor;
  final String text;
  final String? subtext;
  final ColorScheme colorScheme;
  final bool isAnimated;

  const _StatusRow({
    required this.dotColor,
    required this.text,
    this.subtext,
    required this.colorScheme,
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (subtext != null)
          Text(
            subtext!,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}