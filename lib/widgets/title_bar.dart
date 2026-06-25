import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;
  final bool isMaximized;

  const TitleBar({
    super.key,
    this.leading,
    this.actions,
    this.isMaximized = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerLow
            : Colors.white,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          // Window drag area + app icon + title
          if (Platform.isWindows)
            Expanded(
              child: DragToMoveArea(
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.auto_awesome, size: 18, color: const Color(0xFF7C4DFF)),
                      const SizedBox(width: 8),
                      Text(
                        'Chat Studio',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (leading != null) ...[
                        const SizedBox(width: 8),
                        leading!,
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.auto_awesome, size: 18, color: const Color(0xFF7C4DFF)),
                  const SizedBox(width: 8),
                  Text(
                    'Chat Studio',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (leading != null) ...[
                    const SizedBox(width: 8),
                    leading!,
                  ],
                ],
              ),
            ),

          // Action buttons (search, settings)
          if (actions != null) ...actions!,

          const SizedBox(width: 4),

          // Window control buttons
          if (Platform.isWindows) ...[
            _WindowButton(
              icon: Icons.horizontal_rule_rounded,
              onTap: () => windowManager.minimize(),
            ),
            _WindowButton(
              icon: isMaximized ? Icons.filter_none : Icons.check_box_outline_blank_rounded,
              onTap: () async {
                if (isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
            ),
            _WindowButton(
              icon: Icons.close_rounded,
              isClose: true,
              onTap: () => windowManager.hide(),
            ),
          ],
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 40,
          color: widget.isClose && _hovered
              ? Colors.red
              : _hovered
                  ? colorScheme.surfaceContainerHighest
                  : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: widget.isClose && _hovered
                ? Colors.white
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}