import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Conversations, ChatMessages, ServerConfigs, PromptTemplates])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Conversations ──

  Future<List<Conversation>> getAllConversations() =>
      select(conversations).get();

  Stream<List<Conversation>> watchAllConversations() =>
      select(conversations).watch();

  Future<Conversation?> getConversation(String id) =>
      (select(conversations)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertConversation(ConversationsCompanion entry) =>
      into(conversations).insert(entry);

  Future<bool> updateConversation(ConversationsCompanion entry) =>
      update(conversations).replace(entry);

  Future<int> deleteConversation(String id) =>
      (delete(conversations)..where((t) => t.id.equals(id))).go();

  Future<List<Conversation>> searchConversations(String query) {
    return (select(conversations)
      ..where((t) => t.title.like('%$query%'))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .get();
  }

  // ── Chat Messages ──

  Future<List<ChatMessage>> getMessagesForConversation(String convId) =>
      (select(chatMessages)
        ..where((t) => t.conversationId.equals(convId))
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  Stream<List<ChatMessage>> watchMessagesForConversation(String convId) =>
      (select(chatMessages)
        ..where((t) => t.conversationId.equals(convId))
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .watch();

  Future<int> insertMessage(ChatMessagesCompanion entry) =>
      into(chatMessages).insert(entry);

  Future<int> deleteMessagesForConversation(String convId) =>
      (delete(chatMessages)..where((t) => t.conversationId.equals(convId))).go();

  // ── Server Configs ──

  Future<List<ServerConfig>> getAllServerConfigs() =>
      select(serverConfigs).get();

  Future<ServerConfig?> getServerConfig(String id) =>
      (select(serverConfigs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertServerConfig(ServerConfigsCompanion entry) =>
      into(serverConfigs).insert(entry);

  Future<bool> updateServerConfig(ServerConfigsCompanion entry) =>
      update(serverConfigs).replace(entry);

  Future<int> deleteServerConfig(String id) =>
      (delete(serverConfigs)..where((t) => t.id.equals(id))).go();

  // ── Prompt Templates ──

  Future<List<PromptTemplate>> getAllTemplates() =>
      (select(promptTemplates)..orderBy([(t) => OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc)])).get();

  Future<int> insertTemplate(PromptTemplatesCompanion entry) =>
      into(promptTemplates).insert(entry);

  Future<bool> updateTemplate(PromptTemplatesCompanion entry) =>
      update(promptTemplates).replace(entry);

  Future<int> deleteTemplate(String id) =>
      (delete(promptTemplates)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'llamachat.sqlite'));
    return NativeDatabase(file);
  });
}
