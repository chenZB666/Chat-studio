import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../services/storage_service.dart';
import 'providers.dart';

class TemplateNotifier extends StateNotifier<List<PromptTemplate>> {
  final StorageService _storage;

  TemplateNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.getAllTemplates();
  }

  Future<void> addTemplate({
    required String title,
    required String systemPrompt,
    String? userMessageTemplate,
    String? category,
  }) async {
    await _storage.saveTemplate(
      title: title,
      systemPrompt: systemPrompt,
      userMessageTemplate: userMessageTemplate,
      category: category,
    );
    state = await _storage.getAllTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    await _storage.deleteTemplate(id);
    state = await _storage.getAllTemplates();
  }

  Future<void> markUsed(String id) async {
    await _storage.updateTemplateLastUsed(id);
    state = await _storage.getAllTemplates();
  }
}

final templateProvider = StateNotifierProvider<TemplateNotifier, List<PromptTemplate>>((ref) {
  return TemplateNotifier(ref.read(storageServiceProvider));
});