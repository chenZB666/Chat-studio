import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/template_provider.dart';

class TemplateSelector extends ConsumerWidget {
  final void Function(PromptTemplate template) onSelected;

  const TemplateSelector({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (templates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No templates yet')),
      );
    }

    return SizedBox(
      width: 320,
      height: 400,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Choose Template', style: Theme.of(context).textTheme.titleSmall),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: templates.map((template) {
                return ListTile(
                  leading: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
                  title: Text(template.title, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(template.systemPrompt, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11)),
                  dense: true,
                  onTap: () {
                    ref.read(templateProvider.notifier).markUsed(template.id);
                    onSelected(template);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}