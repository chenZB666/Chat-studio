import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import 'api_key_store.dart';

class StorageService {
  final AppDatabase _db;
  final _uuid = const Uuid();
  final _apiKeyStore = ApiKeyStore();

  StorageService(this._db);

  // ── Conversations ──

  Stream<List<Conversation>> watchConversations() =>
      _db.watchAllConversations();

  Future<List<Conversation>> getAllConversations() =>
      _db.getAllConversations();

  Future<Conversation?> getConversation(String id) =>
      _db.getConversation(id);

  Future<Conversation> createConversation({
    String? title,
    String? modelId,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
    int maxTokens = 4096,
    double repeatPenalty = 1.1,
    String? systemPrompt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final entry = ConversationsCompanion(
      id: Value(id),
      title: Value(title ?? 'New Conversation'),
      createdAt: Value(now),
      updatedAt: Value(now),
      modelId: Value(modelId),
      temperature: Value(temperature),
      topP: Value(topP),
      topK: Value(topK),
      maxTokens: Value(maxTokens),
      repeatPenalty: Value(repeatPenalty),
      systemPrompt: Value(systemPrompt),
    );
    await _db.insertConversation(entry);
    return (await _db.getConversation(id))!;
  }

  Future<void> updateConversationTitle(String id, String title) async {
    await _db.updateConversation(
      ConversationsCompanion(
        id: Value(id),
        title: Value(title),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateConversationModel(String id, String modelId) async {
    await _db.updateConversation(
      ConversationsCompanion(
        id: Value(id),
        modelId: Value(modelId),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateConversationParameters(String id, {
    double? temperature,
    double? topP,
    int? topK,
    int? maxTokens,
    double? repeatPenalty,
    String? systemPrompt,
  }) async {
    await _db.updateConversation(
      ConversationsCompanion(
        id: Value(id),
        temperature: temperature != null ? Value(temperature) : Value.absent(),
        topP: topP != null ? Value(topP) : Value.absent(),
        topK: topK != null ? Value(topK) : Value.absent(),
        maxTokens: maxTokens != null ? Value(maxTokens) : Value.absent(),
        repeatPenalty: repeatPenalty != null ? Value(repeatPenalty) : Value.absent(),
        systemPrompt: systemPrompt != null ? Value(systemPrompt) : Value.absent(),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deleteConversation(String id) async {
    await _db.deleteMessagesForConversation(id);
    await _db.deleteConversation(id);
  }

  Future<List<Conversation>> searchConversations(String query) =>
      _db.searchConversations(query);

  // ── Messages ──

  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      _db.watchMessagesForConversation(conversationId);

  Future<List<ChatMessage>> getMessages(String conversationId) =>
      _db.getMessagesForConversation(conversationId);

  Future<ChatMessage> addMessage({
    required String conversationId,
    required String role,
    required String content,
    int? tokenCount,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final entry = ChatMessagesCompanion(
      id: Value(_uuid.v4()),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      createdAt: Value(now),
      tokenCount: Value(tokenCount),
      attachmentsJson: Value(
        attachments != null ? jsonEncode(attachments) : null,
      ),
    );
    await _db.insertMessage(entry);
    final messages = await _db.getMessagesForConversation(conversationId);
    return messages.last;
  }

  // ── Server Configs ──

  Future<List<ServerConfig>> getAllServerConfigs() =>
      _db.getAllServerConfigs();

  Future<ServerConfig> saveServerConfig({
    required String url,
    String? apiKey,
    String? label,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    await _db.insertServerConfig(ServerConfigsCompanion(
      id: Value(id),
      url: Value(url),
      apiKey: const Value(null), // API keys stored in secure storage
      label: Value(label ?? url),
      createdAt: Value(now),
      lastUsedAt: Value(now),
    ));
    // Store API key in platform keychain (Windows DPAPI / macOS Keychain)
    if (apiKey != null && apiKey.isNotEmpty) {
      await _apiKeyStore.save(id, apiKey);
    }
    return (await _db.getServerConfig(id))!;
  }

  Future<void> updateServerLastUsed(String id) async {
    await _db.updateServerConfig(ServerConfigsCompanion(
      id: Value(id),
      lastUsedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> deleteServerConfig(String id) async {
    await _apiKeyStore.delete(id);
    await _db.deleteServerConfig(id);
  }

  /// Retrieve the API key for a server config from secure storage.
  /// Migrates existing keys from the DB column on first access.
  Future<String?> getServerApiKey(ServerConfig config) async {
    // Try secure storage first
    final stored = await _apiKeyStore.get(config.id);
    if (stored != null) return stored;

    // Fall back to DB column and migrate
    if (config.apiKey != null && config.apiKey!.isNotEmpty) {
      try {
        await _apiKeyStore.save(config.id, config.apiKey!);
        await _db.updateServerConfig(ServerConfigsCompanion(
          id: Value(config.id),
          apiKey: const Value(null),
        ));
      } catch (_) {
        // Non-fatal: migration failed, key stays in DB
      }
      return config.apiKey;
    }

    return null;
  }

  // ── Templates ──

  Future<List<PromptTemplate>> getAllTemplates() =>
      _db.getAllTemplates();

  Future<PromptTemplate> saveTemplate({
    required String title,
    required String systemPrompt,
    String? userMessageTemplate,
    String? category,
    bool isBuiltIn = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    await _db.insertTemplate(PromptTemplatesCompanion(
      id: Value(id),
      title: Value(title),
      systemPrompt: Value(systemPrompt),
      userMessageTemplate: Value(userMessageTemplate),
      category: Value(category),
      createdAt: Value(now),
      lastUsedAt: Value(null),
      isBuiltIn: Value(isBuiltIn),
    ));
    final templates = await _db.getAllTemplates();
    return templates.firstWhere((t) => t.id == id);
  }

  Future<void> updateTemplateLastUsed(String id) async {
    await _db.updateTemplate(PromptTemplatesCompanion(
      id: Value(id),
      lastUsedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> deleteTemplate(String id) =>
      _db.deleteTemplate(id);

  /// Seed built-in templates
  Future<void> seedBuiltInTemplates() async {
    final existing = await _db.getAllTemplates();
    if (existing.any((t) => t.isBuiltIn)) return;

    await saveTemplate(
      title: 'Code Review',
      systemPrompt: 'You are an expert code reviewer. Analyze the provided code for bugs, performance issues, and best practices.',
      userMessageTemplate: 'Review this code:\n\n```\n{{code}}\n```',
      category: 'Development',
      isBuiltIn: true,
    );
    await saveTemplate(
      title: 'Translation Assistant',
      systemPrompt: 'You are a professional translator. Translate the text accurately while preserving tone and style.',
      userMessageTemplate: 'Translate the following to {{language}}:\n\n{{text}}',
      category: 'Writing',
      isBuiltIn: true,
    );
    await saveTemplate(
      title: 'Paper Summary',
      systemPrompt: 'You are a research assistant. Summarize academic papers clearly and concisely.',
      userMessageTemplate: 'Summarize this paper:\n\n{{text}}',
      category: 'Research',
      isBuiltIn: true,
    );
    await saveTemplate(
      title: 'Brainstorming',
      systemPrompt: 'You are a creative brainstorming partner. Generate diverse ideas and explore possibilities.',
      userMessageTemplate: 'Let\'s brainstorm ideas about:\n\n{{topic}}',
      category: 'Creative',
      isBuiltIn: true,
    );
  }
}
