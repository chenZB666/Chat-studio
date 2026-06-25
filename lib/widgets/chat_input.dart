import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/chat_provider.dart';
import '../providers/document_provider.dart';
import '../providers/server_provider.dart';
import '../core/theme/design_tokens.dart';
import 'parameter_panel.dart';

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final docState = ref.read(documentProvider);
    final attachments = docState.attachments.isNotEmpty ? docState.attachments : null;

    ref.read(chatProvider.notifier).sendMessage(text, attachments: attachments);
    _controller.clear();
    ref.read(documentProvider.notifier).clearAttachments();
    setState(() => _hasText = false);
  }

  void _showModelSelector(BuildContext context, ServerState serverState, ColorScheme colorScheme) {
    final searchController = TextEditingController();
    String filter = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final models = serverState.availableModels;
            final filtered = filter.isEmpty
                ? models
                : models.where((m) =>
                    m.id.toLowerCase().contains(filter.toLowerCase()) ||
                    m.name.toLowerCase().contains(filter.toLowerCase())).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: Spacing.sm),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.sm),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search models...',
                        prefixIcon: Icon(Icons.search, size: LayoutTokens.iconSize),
                        isDense: true,
                      ),
                      onChanged: (v) => setSheetState(() => filter = v),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(Spacing.lg),
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 32, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                                const SizedBox(height: Spacing.sm),
                                Text('No models match your search', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final model = filtered[i];
                              final isSelected = model.id == serverState.selectedModelId;
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: colorScheme.primary.withValues(alpha: 0.08),
                                leading: Icon(
                                  Icons.smart_toy_outlined,
                                  size: LayoutTokens.iconSize,
                                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                ),
                                title: Text(model.name, style: const TextStyle(fontSize: 14)),
                                subtitle: model.contextLength != null
                                    ? Text('Context: ${model.contextLength} tokens', style: const TextStyle(fontSize: 11))
                                    : null,
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: colorScheme.primary, size: 18)
                                    : null,
                                onTap: () {
                                  ref.read(serverProvider.notifier).selectModel(model.id);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: Spacing.sm),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final docState = ref.watch(documentProvider);
    final serverState = ref.watch(serverProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isStreaming = chatState.streamState == ChatStreamState.streaming;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment chips
          if (docState.attachments.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
                itemCount: docState.attachments.length,
                itemBuilder: (context, index) {
                  final att = docState.attachments[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      label: Text(att.fileName, style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => ref.read(documentProvider.notifier).removeAttachment(index),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                },
              ),
            ),

          // Input row
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.sm, Spacing.xxs, Spacing.sm, Spacing.sm),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attach file button
                  PopupMenuButton<String>(
                    icon: Icon(Icons.attach_file_rounded, size: LayoutTokens.iconSize, color: colorScheme.onSurfaceVariant),
                    onSelected: (value) async {
                      if (value == 'file') {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['txt', 'md', 'pdf'],
                        );
                        if (result != null && result.files.single.path != null) {
                          ref.read(documentProvider.notifier).addFile(result.files.single.path!);
                        }
                      } else if (value == 'image') {
                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (result != null && result.files.single.path != null) {
                          ref.read(documentProvider.notifier).addFile(result.files.single.path!);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'file', child: ListTile(leading: Icon(Icons.description_outlined), title: Text('File'), dense: true)),
                      const PopupMenuItem(value: 'image', child: ListTile(leading: Icon(Icons.image_outlined), title: Text('Image'), dense: true)),
                    ],
                  ),

                  // Model selector
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(RadiusTokens.full),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(RadiusTokens.full),
                      onTap: () => _showModelSelector(context, serverState, colorScheme),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smart_toy_outlined, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            serverState.selectedModelId?.split('/').last ?? 'Model',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                          ),
                          Icon(Icons.arrow_drop_down, size: 16, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      onChanged: (v) => setState(() => _hasText = v.isNotEmpty),
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),

                  // Send/Stop button
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: isStreaming
                        ? Material(
                            color: colorScheme.error.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(RadiusTokens.md),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(RadiusTokens.md),
                              onTap: () => ref.read(chatProvider.notifier).stopStream(),
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                child: const Icon(Icons.stop, size: 18, color: Colors.white),
                              ),
                            ),
                          )
                        : Material(
                            color: _hasText ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(RadiusTokens.md),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(RadiusTokens.md),
                              onTap: _hasText ? _sendMessage : null,
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 20,
                                  color: _hasText ? colorScheme.onPrimary : colorScheme.onSurface.withValues(alpha: 0.38),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Parameter panel
          const ParameterPanel(),
        ],
      ),
    );
  }
}