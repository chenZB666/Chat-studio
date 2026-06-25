import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../core/theme/design_tokens.dart';

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
  Size get preferredSize => const Size.fromHeight(LayoutTokens.titleBarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: LayoutTokens.titleBarHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          if (Platform.isWindows)
            Expanded(
              child: DragToMoveArea(
                child: SizedBox(
                  height: LayoutTokens.titleBarHeight,
                  child: Row(
                    children: [
                      const SizedBox(width: Spacing.md),
                      _AppLogo(colorScheme: colorScheme),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Chat Studio',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (leading != null) ...[
                        const SizedBox(width: Spacing.sm),
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
                  const SizedBox(width: Spacing.md),
                  _AppLogo(colorScheme: colorScheme),
                  const SizedBox(width: Spacing.sm),
                  Text('Chat Studio',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (leading != null) ...[
                    const SizedBox(width: Spacing.sm),
                    leading!,
                  ],
                ],
              ),
            ),

          if (actions != null) ...actions!,
          const SizedBox(width: Spacing.xxs),

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

class _AppLogo extends StatelessWidget {
  final ColorScheme colorScheme;
  const _AppLogo({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadiusTokens.xxs),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(child: Icon(Icons.auto_awesome, size: 14, color: Colors.white)),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46,
          height: LayoutTokens.titleBarHeight,
          color: widget.isClose && _hovered
              ? colorScheme.error.withValues(alpha: 0.8)
              : _hovered
                  ? colorScheme.surfaceContainerHighest
                  : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: widget.isClose && _hovered
                ? Colors.white
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}