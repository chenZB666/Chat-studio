import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:markdown/markdown.dart' as md;
import '../database/database.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.primaryContainer,
                child: Text('AI', style: TextStyle(fontSize: 10, color: colorScheme.onPrimaryContainer)),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12).copyWith(
                      bottomRight: isUser ? Radius.zero : null,
                      bottomLeft: !isUser ? Radius.zero : null,
                    ),
                  ),
                  child: isUser
                      ? SelectableText(
                          message.content,
                          style: TextStyle(color: colorScheme.onPrimaryContainer),
                        )
                      : _buildMarkdownContent(message.content),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(timeStr, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                    if (isStreaming)
                      Text(' ● streaming', style: TextStyle(fontSize: 10, color: Colors.green)),
                    if (!isUser && !isStreaming)
                      IconButton(
                        icon: Icon(Icons.copy, size: 14, color: colorScheme.onSurfaceVariant),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: message.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Copied'), duration: const Duration(seconds: 1)),
                          );
                        },
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(Icons.person, size: 16, color: colorScheme.onSecondaryContainer),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(String content) {
    if (isStreaming && content.isEmpty) {
      return const SizedBox(
        height: 20,
        width: 40,
        child: LinearProgressIndicator(),
      );
    }

    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14),
        code: TextStyle(
          backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang.isNotEmpty ? lang : 'code',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              const Icon(Icons.copy, size: 14),
            ],
          ),
        ),
        ClipRect(
          child: HighlightView(
            code,
            language: lang.isNotEmpty ? lang : 'plaintext',
            theme: theme,
            padding: const EdgeInsets.all(12),
            textStyle: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}