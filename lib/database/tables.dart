import 'package:drift/drift.dart';

class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get modelId => text().nullable()();
  RealColumn get temperature => real().withDefault(const Constant(0.7))();
  RealColumn get topP => real().withDefault(const Constant(0.9))();
  IntColumn get topK => integer().withDefault(const Constant(40))();
  IntColumn get maxTokens => integer().withDefault(const Constant(4096))();
  RealColumn get repeatPenalty => real().withDefault(const Constant(1.1))();
  TextColumn get systemPrompt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  IntColumn get createdAt => integer()();
  IntColumn get tokenCount => integer().nullable()();
  TextColumn get attachmentsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ServerConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get apiKey => text().nullable()();
  TextColumn get label => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastUsedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PromptTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get systemPrompt => text()();
  TextColumn get userMessageTemplate => text().nullable()();
  TextColumn get category => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get lastUsedAt => integer().nullable()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
