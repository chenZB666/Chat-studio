import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/template_provider.dart';

class PromptLibraryScreen extends ConsumerStatefulWidget {
  const PromptLibraryScreen({super.key});

  @override
  ConsumerState<PromptLibraryScreen> createState() => _PromptLibraryScreenState();
}

class _PromptLibraryScreenState extends ConsumerState<PromptLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTemplateEditor({PromptTemplate? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final systemPromptController = TextEditingController(text: existing?.systemPrompt ?? '');
    final userMsgController = TextEditingController(text: existing?.userMessageTemplate ?? '');
    final categoryController = TextEditingController(text: existing?.category ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Edit Template' : 'New Template'),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: systemPromptController, decoration: const InputDecoration(labelText: 'System Prompt', border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 8),
              TextField(controller: userMsgController, decoration: const InputDecoration(labelText: 'User Message Template', helperText: 'Use {{variable}} for placeholders', border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 8),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              ref.read(templateProvider.notifier).addTemplate(
                title: titleController.text.trim(),
                systemPrompt: systemPromptController.text.trim(),
                userMessageTemplate: userMsgController.text.trim().isNotEmpty ? userMsgController.text.trim() : null,
                category: categoryController.text.trim().isNotEmpty ? categoryController.text.trim() : null,
              );
              Navigator.pop(ctx);
            },
            child: Text(existing != null ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final query = _searchController.text.toLowerCase();
    final filtered = query.isEmpty
        ? templates
        : templates.where((t) =>
            t.title.toLowerCase().contains(query) ||
            (t.category?.toLowerCase().contains(query) ?? false))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTemplateEditor(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search templates...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 48, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text('No templates yet', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: () => _showTemplateEditor(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Template'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final template = filtered[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            template.isBuiltIn ? Icons.auto_awesome : Icons.description,
                            color: template.isBuiltIn ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                          title: Text(template.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (template.category != null)
                                Text(template.category!, style: TextStyle(fontSize: 11, color: colorScheme.primary)),
                              Text(template.systemPrompt, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: template.isBuiltIn
                              ? null
                              : IconButton(
                                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                  onPressed: () => ref.read(templateProvider.notifier).deleteTemplate(template.id),
                                ),
                          onTap: () {
                            ref.read(templateProvider.notifier).markUsed(template.id);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}