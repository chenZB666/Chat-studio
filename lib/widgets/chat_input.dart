import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/chat_provider.dart';
import '../providers/document_provider.dart';
import '../providers/server_provider.dart';
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
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (docState.attachments.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: docState.attachments.length,
                itemBuilder: (context, index) {
                  final att = docState.attachments[index];
                  return Chip(
                    label: Text(att.fileName, style: const TextStyle(fontSize: 11)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => ref.read(documentProvider.notifier).removeAttachment(index),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.attach_file, color: colorScheme.onSurfaceVariant),
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
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                      );
                      if (result != null && result.files.single.path != null) {
                        ref.read(documentProvider.notifier).addFile(result.files.single.path!);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'file', child: ListTile(leading: Icon(Icons.description), title: Text('File'), dense: true)),
                    const PopupMenuItem(value: 'image', child: ListTile(leading: Icon(Icons.image), title: Text('Image'), dense: true)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: serverState.selectedModelId,
                      isDense: true,
                      hint: const Text('Model', style: TextStyle(fontSize: 12)),
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                      items: serverState.availableModels.map((m) {
                        return DropdownMenuItem(value: m.id, child: Text(m.name, style: const TextStyle(fontSize: 12)));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) ref.read(serverProvider.notifier).selectModel(v);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    onChanged: (v) => setState(() => _hasText = v.isNotEmpty),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                isStreaming
                    ? IconButton.filled(
                        onPressed: () => ref.read(chatProvider.notifier).stopStream(),
                        icon: const Icon(Icons.stop),
                        style: IconButton.styleFrom(backgroundColor: Colors.red),
                      )
                    : IconButton.filled(
                        onPressed: _hasText ? _sendMessage : null,
                        icon: const Icon(Icons.send),
                      ),
              ],
            ),
          ),
          const ParameterPanel(),
        ],
      ),
    );
  }
}