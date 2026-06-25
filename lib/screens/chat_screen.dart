import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../providers/conversation_list_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../core/theme/design_tokens.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final convState = ref.watch(conversationListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (chatState.streamState == ChatStreamState.streaming) {
      _scrollToBottom();
    }

    return Column(
      children: [
        // Conversation header
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: LayoutTokens.iconSize),
                onPressed: () => ref.read(conversationListProvider.notifier).selectConversation(''),
                tooltip: 'Back',
              ),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(
                  _getConversationTitle(convState),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, size: LayoutTokens.iconSize, color: colorScheme.onSurfaceVariant),
                onSelected: (value) {
                  if (value == 'delete' && convState.activeConversationId != null) {
                    ref.read(conversationListProvider.notifier).deleteConversation(convState.activeConversationId!);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'delete', child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    title: Text('Delete conversation'),
                    dense: true,
                  )),
                ],
              ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: Spacing.xs, bottom: Spacing.xs),
            itemCount: chatState.messages.length + (chatState.streamState == ChatStreamState.streaming ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < chatState.messages.length) {
                return MessageBubble(
                  message: chatState.messages[index],
                  isDark: isDark,
                );
              }
              // Streaming placeholder
              if (chatState.currentStreamContent.isNotEmpty) {
                return MessageBubble(
                  message: chatState.messages.last.copyWith(
                    content: chatState.currentStreamContent,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  ),
                  isDark: isDark,
                  isStreaming: true,
                );
              }
              return const SizedBox(
                height: 40,
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              );
            },
          ),
        ),

        // Error banner
        if (chatState.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            color: colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: colorScheme.onErrorContainer, size: 16),
                const SizedBox(width: Spacing.sm),
                Expanded(child: Text(chatState.errorMessage!, style: TextStyle(fontSize: 12, color: colorScheme.onErrorContainer))),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 16, color: colorScheme.onErrorContainer),
                  onPressed: () => ref.read(chatProvider.notifier).clearError(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

        // Chat input
        const ChatInput(),
      ],
    );
  }

  String _getConversationTitle(convState) {
    final convs = convState.conversations.where((c) => c.id == convState.activeConversationId);
    return convs.isNotEmpty ? convs.first.title : 'Chat';
  }
}