import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:markdown/markdown.dart' as md;
import '../database/database.dart';
import '../core/theme/design_tokens.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;
  final bool isDark;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateTime.fromMillisecondsSinceEpoch(message.createdAt);
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: Spacing.sm, top: 6),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary.withValues(alpha: 0.10)
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(RadiusTokens.md).copyWith(
                      bottomRight: isUser ? Radius.zero : null,
                      bottomLeft: !isUser ? Radius.zero : null,
                    ),
                  ),
                  child: isUser
                      ? SelectableText(
                          message.content,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: colorScheme.onSurface,
                          ),
                        )
                      : _buildMarkdownContent(message.content, colorScheme, isDark),
                ),
                const SizedBox(height: Spacing.xxs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isStreaming)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (!isUser && !isStreaming)
                      IconButton(
                        icon: Icon(Icons.content_copy, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: message.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                          );
                        },
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                        splashRadius: 14,
                        tooltip: 'Copy',
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: Spacing.sm, top: 6),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.secondary.withValues(alpha: 0.12),
                child: Icon(Icons.person_outline, size: 16, color: colorScheme.secondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(String content, ColorScheme colorScheme, bool isDark) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 14, height: 1.6, color: colorScheme.onSurface),
        a: TextStyle(color: colorScheme.primary),
        strong: TextStyle(fontWeight: FontWeight.w600),
        code: TextStyle(
          backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          fontSize: 13,
          fontFamily: 'monospace',
          color: isDark ? Colors.amber.shade300 : Colors.indigo.shade700,
        ),
        codeblockDecoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(RadiusTokens.sm),
        ),
        codeblockPadding: const EdgeInsets.all(Spacing.xs),
        h1: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
        h2: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
        h3: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3), width: 3)),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      ),
      builders: {
        'code': _CodeBlockBuilder(isDark: isDark),
      },
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  final bool isDark;
  _CodeBlockBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(md.Element elem, TextStyle? preferredStyle) {
    final code = elem.textContent;
    final lang = elem.attributes['class']?.replaceAll('language-', '') ?? '';
    final theme = isDark ? draculaTheme : githubTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 6),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.sm)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.isNotEmpty ? lang : 'code',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                  },
                  child: Icon(Icons.content_copy, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ],
            ),
          ),
          ClipRect(
            child: HighlightView(
              code,
              language: lang.isNotEmpty ? lang : 'plaintext',
              theme: theme,
              padding: const EdgeInsets.all(Spacing.md),
              textStyle: const TextStyle(fontSize: 13, fontFamily: 'monospace', height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}