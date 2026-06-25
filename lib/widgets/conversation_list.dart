import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../providers/conversation_list_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/providers.dart';
import '../core/theme/design_tokens.dart';

class ConversationList extends ConsumerWidget {
  const ConversationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final grouped = _groupConversations(state.conversations);

    return Column(
      children: [
        // Header + New button
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.sm),
          child: Row(
            children: [
              Text(
                'Conversations',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: Icon(Icons.add_rounded, size: LayoutTokens.iconSize),
                  onPressed: () async {
                    final id = await ref.read(conversationListProvider.notifier).createConversation();
                    ref.read(chatProvider.notifier).loadConversation(id);
                  },
                  tooltip: 'New Conversation',
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: LayoutTokens.dividerThickness, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),

        // Conversation list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xxs),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.xxs),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ...entry.value.map((conv) => _ConversationTile(
                    conversation: conv,
                    isSelected: conv.id == state.activeConversationId,
                    onTap: () {
                      ref.read(conversationListProvider.notifier).selectConversation(conv.id);
                      ref.read(chatProvider.notifier).loadConversation(conv.id);
                    },
                    onDelete: () => ref.read(conversationListProvider.notifier).deleteConversation(conv.id),
                    onRename: (title) => ref.read(storageServiceProvider).updateConversationTitle(conv.id, title),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Map<String, List<Conversation>> _groupConversations(List<Conversation> conversations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<Conversation>>{
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Earlier': [],
    };

    for (final conv in conversations) {
      final date = DateTime.fromMillisecondsSinceEpoch(conv.updatedAt);
      final day = DateTime(date.year, date.month, date.day);
      if (day == today) {
        groups['Today']!.add(conv);
      } else if (day == yesterday) {
        groups['Yesterday']!.add(conv);
      } else if (day.isAfter(weekAgo)) {
        groups['This Week']!.add(conv);
      } else {
        groups['Earlier']!.add(conv);
      }
    }

    groups.removeWhere((_, list) => list.isEmpty);
    return groups;
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<String>? onRename;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    this.onRename,
  });

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: conversation.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              onRename?.call(v.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onRename?.call(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateTime.fromMillisecondsSinceEpoch(conversation.updatedAt);
    final timeStr = DateFormat('HH:mm').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
        onTap: onTap,
        onLongPress: () => _showRenameDialog(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? colorScheme.onSurface : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.xs),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 16, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  splashRadius: 12,
                  tooltip: 'Delete',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}