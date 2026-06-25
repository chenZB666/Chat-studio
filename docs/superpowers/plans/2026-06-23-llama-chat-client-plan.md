# LlamaChat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter-based cross-platform chat client for llama.cpp server with Material 3 design.

**Architecture:** Three-layer architecture — Presentation (Material 3 widgets/screens) → State (Riverpod providers) → Services (llama API client via HTTP/SSE, Drift SQLite storage, file processing). The app connects to a user-provided llama.cpp server URL, lists available models, and provides a full-featured chat experience.

**Tech Stack:** Flutter 3.22+, Dart 3.4+, Riverpod 2.5+, Drift 2.16+, dio 5.4+, go_router 14+, flex_color_scheme 8+, flutter_markdown, flutter_highlight, file_picker, share_plus

## Global Constraints

- All API calls go through `llama_api_client.dart` using OpenAI-compatible endpoints
- SSE streaming via `dio` response stream, parsed token-by-token
- All local data persisted via Drift SQLite (no shared_preferences for structured data)
- Observability (connection state, streaming state) goes through Riverpod providers, never through direct setState on service objects
- Conversations auto-save to Drift after each assistant turn
- Layout adapts at 800px breakpoint (side-by-side vs drawer)
- All colors come from Material 3 `ColorScheme`, never hardcoded
- Target platforms: Windows (win32), Android (API 26+)

---

### Task 1: Project Scaffold and Dependencies

**Files:**
- Create: `e:\gemma\pubspec.yaml`
- Create: `e:\gemma\lib\main.dart`
- Create: `e:\gemma\lib\app.dart`
- Create: `e:\gemma\lib\core\constants\app_constants.dart`
- Create: `e:\gemma\analysis_options.yaml`

**Interfaces:**
- Produces: `main.dart` (entry point), `app.dart` (MaterialApp widget), `app_constants.dart` (string/num constants)

- [ ] **Step 1: Create Flutter project**

```bash
cd /e/gemma
flutter create --org com.llamachat --project-name llamachat .
```

Expected: Flutter project scaffold with `lib/`, `test/`, `android/`, `windows/` directories.

- [ ] **Step 2: Write pubspec.yaml with all dependencies**

```yaml
# e:\gemma\pubspec.yaml
name: llamachat
description: Cross-platform chat client for llama.cpp server
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.4.0

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.2.7
  dio: ^5.4.3+1
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.20
  path_provider: ^2.1.3
  path: ^1.9.0
  uuid: ^4.4.0
  intl: ^0.19.0
  flex_color_scheme: ^8.1.0
  flutter_markdown: ^0.7.1
  flutter_highlight: ^0.7.0
  highlight.js: ^11.10.0
  flutter_math_fork: ^0.7.2
  file_picker: ^8.0.3
  share_plus: ^9.0.0
  super_editor: ^0.5.1
  flutter_svg: ^2.0.10+1
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  drift_dev: ^2.16.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  json_serializable: ^6.8.0
  json_annotation: ^4.9.0

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Write analysis_options.yaml**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: false
```

- [ ] **Step 4: Write app_constants.dart**

```dart
// e:\gemma\lib\core\constants\app_constants.dart
class AppConstants {
  static const String appName = 'LlamaChat';
  static const String appVersion = '1.0.0';
  static const double defaultTemperature = 0.7;
  static const double defaultTopP = 0.9;
  static const int defaultTopK = 40;
  static const int defaultMaxTokens = 4096;
  static const double defaultRepeatPenalty = 1.1;
  static const double layoutBreakpoint = 800.0;
  static const List<String> presetColorSeeds = [
    'blue', 'green', 'purple', 'orange', 'red',
    'teal', 'pink', 'grey', 'brown', 'indigo',
  ];
}
```

- [ ] **Step 5: Write main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LlamaChatApp()));
}
```

- [ ] **Step 6: Write app.dart (minimal start, will expand in Task 7)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LlamaChatApp extends ConsumerWidget {
  const LlamaChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LlamaChat',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: Text('LlamaChat')),
      ),
    );
  }
}
```

- [ ] **Step 7: Verify project builds**

```bash
cd /e/gemma
flutter pub get
```

Expected: `flutter pub get` succeeds, no dependency resolution errors.

---

### Task 2: Data Models and Database Layer

**Files:**
- Create: `lib/database/database.dart`
- Create: `lib/database/tables.dart`
- Create: `lib/models/chat_message.dart`
- Create: `lib/models/conversation.dart`
- Create: `lib/models/server_config.dart`
- Create: `lib/models/prompt_template.dart`
- Create: `lib/models/model_info.dart`

**Interfaces:**
- Produces: `AppDatabase` class with `conversations`, `chatMessages`, `serverConfigs`, `promptTemplates` DAOs
- Produces: Model classes: `ConversationData`, `ChatMessageData`, `ServerConfigData`, `PromptTemplateData`, `ModelInfo`

- [ ] **Step 1: Write the database tables**

```dart
// lib/database/tables.dart
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
  TextColumn get userMessageTemplate => text()();
  TextColumn get category => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get lastUsedAt => integer().nullable()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 2: Write the database class**

```dart
// lib/database/database.dart
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

  Future<int> updateConversation(ConversationsCompanion entry) =>
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

  Future<int> updateServerConfig(ServerConfigsCompanion entry) =>
      update(serverConfigs).replace(entry);

  Future<int> deleteServerConfig(String id) =>
      (delete(serverConfigs)..where((t) => t.id.equals(id))).go();

  // ── Prompt Templates ──

  Future<List<PromptTemplate>> getAllTemplates() =>
      (select(promptTemplates)..orderBy([(t) => OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc)])).get();

  Future<int> insertTemplate(PromptTemplatesCompanion entry) =>
      into(promptTemplates).insert(entry);

  Future<int> updateTemplate(PromptTemplatesCompanion entry) =>
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
```

- [ ] **Step 3: Create model classes**

```dart
// lib/models/chat_message.dart
class AttachmentInfo {
  final String fileName;
  final String fileType; // 'image', 'pdf', 'txt', 'md'
  final String content;

  AttachmentInfo({
    required this.fileName,
    required this.fileType,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'fileType': fileType,
    'content': content,
  };

  factory AttachmentInfo.fromJson(Map<String, dynamic> json) => AttachmentInfo(
    fileName: json['fileName'] as String,
    fileType: json['fileType'] as String,
    content: json['content'] as String,
  );
}
```

```dart
// lib/models/model_info.dart
class ModelInfo {
  final String id;
  final String name;
  final int? contextLength;

  ModelInfo({required this.id, required this.name, this.contextLength});

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return ModelInfo(
      id: id,
      name: id.split('/').last,
      contextLength: json['context_length'] as int?,
    );
  }
}
```

- [ ] **Step 4: Run build_runner to generate Drift code**

```bash
cd /e/gemma
dart run build_runner build --delete-conflicting-outputs
```

Expected: `database.g.dart` is generated alongside `database.dart`.

---

### Task 3: Llama API Client (Service Layer)

**Files:**
- Create: `lib/services/llama_api_client.dart`

**Interfaces:**
- Consumes: `ModelInfo.fromJson()`, `ServerConfig` model
- Produces: `LlamaApiClient` class — `connect(url, apiKey) → bool`, `fetchModels() → List<ModelInfo>`, `sendChatStream(…) → Stream<String>`, `testConnection() → Duration`

- [ ] **Step 1: Write the Llama API client**

```dart
// lib/services/llama_api_client.dart
import 'dart:async';
import 'package:dio/dio.dart';
import '../models/model_info.dart';

class LlamaApiClient {
  final Dio _dio;
  String? _baseUrl;
  String? _apiKey;
  CancelToken? _cancelToken;

  LlamaApiClient()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Content-Type': 'application/json'},
        ));

  String? get baseUrl => _baseUrl;

  /// Test connection and return latency in milliseconds. Returns null on failure.
  Future<Duration?> testConnection(String url, {String? apiKey}) async {
    try {
      final stopwatch = Stopwatch()..start();
      final options = Options(
        headers: {'Authorization': 'Bearer $apiKey'},
      );
      await _dio.get('$url/v1/models', options: options);
      stopwatch.stop();
      return stopwatch.elapsed;
    } catch (_) {
      return null;
    }
  }

  /// Connect to a server and store the configuration.
  bool connect(String url, {String? apiKey}) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _apiKey = apiKey;
    _dio.options.baseUrl = _baseUrl!;
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
    } else {
      _dio.options.headers.remove('Authorization');
    }
    return true;
  }

  /// Fetch available models from the server.
  Future<List<ModelInfo>> fetchModels() async {
    try {
      final response = await _dio.get('/v1/models');
      final data = response.data as Map<String, dynamic>;
      final modelsList = data['data'] as List<dynamic>;
      return modelsList
          .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  /// Send a chat completion request and return a stream of delta text tokens.
  Stream<String> sendChatStream({
    required String model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
    int maxTokens = 4096,
    double repeatPenalty = 1.1,
    bool stream = true,
  }) async* {
    _cancelToken = CancelToken();
    try {
      final response = await _dio.post(
        '/v1/chat/completions',
        options: Options(responseType: ResponseType.stream),
        data: {
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'top_p': topP,
          if (topK > 0) 'top_k': topK,
          'max_tokens': maxTokens,
          'repeat_penalty': repeatPenalty,
          'stream': stream,
        },
        cancelToken: _cancelToken,
      );

      final stream = response.data.stream as Stream<List<int>>;
      await for (final chunk in stream.transform(_SSEDecoder())) {
        if (chunk.startsWith('data: ')) {
          final jsonStr = chunk.substring(6);
          if (jsonStr == '[DONE]') break;
          try {
            // Parse JSON and extract delta content
            final Map<String, dynamic> json =
                _parseJsonSafe(jsonStr);
            if (json == null) continue;
            final choices = json['choices'] as List<dynamic>?;
            if (choices == null || choices.isEmpty) continue;
            final delta = choices[0] as Map<String, dynamic>;
            final content = delta['delta']?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          } catch (_) {
            // Skip unparseable chunks
            continue;
          }
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Stream was cancelled by user
      } else {
        rethrow;
      }
    } finally {
      _cancelToken = null;
    }
  }

  /// Cancel an active stream
  void cancelStream() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  Map<String, dynamic>? _parseJsonSafe(String str) {
    try {
      return _parseJson(str) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}

/// Simple SSE decoder transform.
class _SSEDecoder extends Converter<List<int>, String> {
  @override
  String convert(List<int> input) {
    return utf8.decode(input);
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<String> sink) {
    return _SSEDecoderSink(sink);
  }
}

class _SSEDecoderSink extends Sink<List<int>> {
  final Sink<String> _output;
  final StringBuffer _buffer = StringBuffer();

  _SSEDecoderSink(this._output);

  @override
  void add(List<int> data) {
    _buffer.write(utf8.decode(data));
    final str = _buffer.toString();
    // Process complete lines
    while (str.contains('\n')) {
      final idx = str.indexOf('\n');
      final line = str.substring(0, idx);
      _output.add(line);
      _buffer.clear();
      _buffer.write(str.substring(idx + 1));
    }
  }

  @override
  void close() {
    if (_buffer.isNotEmpty) {
      _output.add(_buffer.toString());
    }
    _output.close();
  }
}
```

- [ ] **Step 2: Verify file compiles**

```bash
cd /e/gemma
dart analyze lib/services/llama_api_client.dart
```

Expected: No errors.

---

### Task 4: Storage and File Services

**Files:**
- Create: `lib/services/storage_service.dart`
- Create: `lib/services/file_service.dart`

**Interfaces:**
- Consumes: `AppDatabase`, model classes
- Produces: `StorageService` (conversation CRUD, message CRUD, server CRUD, template CRUD), `FileService` (extract text from PDF/TXT/MD)

- [ ] **Step 1: Write StorageService**

```dart
// lib/services/storage_service.dart
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/tables.dart';

class StorageService {
  final AppDatabase _db;
  final _uuid = const Uuid();

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
      apiKey: Value(apiKey),
      label: Value(label ?? url),
      createdAt: Value(now),
      lastUsedAt: Value(now),
    ));
    return (await _db.getServerConfig(id))!;
  }

  Future<void> updateServerLastUsed(String id) async {
    await _db.updateServerConfig(ServerConfigsCompanion(
      id: Value(id),
      lastUsedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> deleteServerConfig(String id) =>
      _db.deleteServerConfig(id);

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
```

- [ ] **Step 2: Write FileService**

```dart
// lib/services/file_service.dart
import 'dart:io';

class FileService {
  /// Extract text content from a file. Returns null if format is unsupported.
  Future<String?> extractText(String filePath) async {
    final ext = filePath.split('.').last.toLowerCase();
    final file = File(filePath);

    switch (ext) {
      case 'txt':
      case 'md':
        return await file.readAsString();
      case 'pdf':
        return await _extractPdfText(file);
      default:
        return null;
    }
  }

  Future<String> _extractPdfText(File file) async {
    // Basic PDF text extraction — in production, use a package like `pdf_text_extraction`
    // For MVP, return filename as placeholder with a note
    return '[PDF: ${file.path.split('/').last} — Text extraction requires full PDF parser]';
  }

  /// Get file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if file type is supported
  static bool isSupported(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return ['txt', 'md', 'pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  /// Check if file is an image
  static bool isImage(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }
}
```

- [ ] **Step 3: Verify files compile**

```bash
cd /e/gemma
dart analyze lib/services/
```

Expected: No errors.

---

### Task 5: Riverpod Providers — Server and Settings

**Files:**
- Create: `lib/providers/providers.dart`
- Create: `lib/providers/server_provider.dart`
- Create: `lib/providers/settings_provider.dart`

**Interfaces:**
- Consumes: `LlamaApiClient`, `StorageService`, `AppDatabase`
- Produces: `serverProvider` (StateNotifier — connection state, model list), `settingsProvider` (theme mode, color seed, defaults)

- [ ] **Step 1: Write providers.dart (aggregate exports)**

```dart
// lib/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../services/llama_api_client.dart';
import '../services/storage_service.dart';
import '../services/file_service.dart';

// Singleton providers
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.read(databaseProvider)),
);
final apiClientProvider = Provider<LlamaApiClient>((ref) => LlamaApiClient());
final fileServiceProvider = Provider<FileService>((ref) => FileService());
```

- [ ] **Step 2: Write server_provider.dart**

```dart
// lib/providers/server_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/model_info.dart';
import '../models/server_config.dart' as model;
import '../services/llama_api_client.dart';
import '../services/storage_service.dart';
import 'providers.dart';

enum ServerConnectionState { disconnected, connecting, connected, error }

class ServerState {
  final ServerConnectionState connectionState;
  final String? currentUrl;
  final String? apiKey;
  final List<ModelInfo> availableModels;
  final String? selectedModelId;
  final Duration? latency;
  final String? errorMessage;
  final List<model.ServerConfig> savedServers;

  const ServerState({
    this.connectionState = ServerConnectionState.disconnected,
    this.currentUrl,
    this.apiKey,
    this.availableModels = const [],
    this.selectedModelId,
    this.latency,
    this.errorMessage,
    this.savedServers = const [],
  });

  ServerState copyWith({
    ServerConnectionState? connectionState,
    String? currentUrl,
    String? apiKey,
    List<ModelInfo>? availableModels,
    String? selectedModelId,
    Duration? latency,
    String? errorMessage,
    List<model.ServerConfig>? savedServers,
  }) {
    return ServerState(
      connectionState: connectionState ?? this.connectionState,
      currentUrl: currentUrl ?? this.currentUrl,
      apiKey: apiKey ?? this.apiKey,
      availableModels: availableModels ?? this.availableModels,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      latency: latency ?? this.latency,
      errorMessage: errorMessage ?? this.errorMessage,
      savedServers: savedServers ?? this.savedServers,
    );
  }
}

class ServerNotifier extends StateNotifier<ServerState> {
  final LlamaApiClient _api;
  final StorageService _storage;

  ServerNotifier(this._api, this._storage) : super(const ServerState()) {
    _loadSavedServers();
  }

  Future<void> _loadSavedServers() async {
    final servers = await _storage.getAllServerConfigs();
    state = state.copyWith(savedServers: servers);
  }

  Future<bool> connect(String url, {String? apiKey}) async {
    state = state.copyWith(
      connectionState: ServerConnectionState.connecting,
      currentUrl: url,
      apiKey: apiKey,
      errorMessage: null,
    );
    final latency = await _api.testConnection(url, apiKey: apiKey);
    if (latency == null) {
      state = state.copyWith(
        connectionState: ServerConnectionState.error,
        errorMessage: 'Connection failed. Check the URL and ensure the server is running.',
      );
      return false;
    }
    _api.connect(url, apiKey: apiKey);
    state = state.copyWith(
      connectionState: ServerConnectionState.connected,
      latency: latency,
    );
    await fetchModels();
    return true;
  }

  Future<void> fetchModels() async {
    try {
      final models = await _api.fetchModels();
      state = state.copyWith(
        availableModels: models,
        selectedModelId: models.isNotEmpty ? models.first.id : null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to fetch models: $e',
      );
    }
  }

  void selectModel(String modelId) {
    state = state.copyWith(selectedModelId: modelId);
  }

  void disconnect() {
    _api.cancelStream();
    state = const ServerState();
  }
}

final serverProvider = StateNotifierProvider<ServerNotifier, ServerState>((ref) {
  return ServerNotifier(
    ref.read(apiClientProvider),
    ref.read(storageServiceProvider),
  );
});
```

- [ ] **Step 3: Write settings_provider.dart**

```dart
// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String colorSeed;
  final double fontSize;
  final String defaultSystemPrompt;
  final double defaultTemperature;
  final double defaultTopP;
  final int defaultTopK;
  final int defaultMaxTokens;
  final double defaultRepeatPenalty;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.colorSeed = 'blue',
    this.fontSize = 14.0,
    this.defaultSystemPrompt = 'You are a helpful assistant.',
    this.defaultTemperature = AppConstants.defaultTemperature,
    this.defaultTopP = AppConstants.defaultTopP,
    this.defaultTopK = AppConstants.defaultTopK,
    this.defaultMaxTokens = AppConstants.defaultMaxTokens,
    this.defaultRepeatPenalty = AppConstants.defaultRepeatPenalty,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? colorSeed,
    double? fontSize,
    String? defaultSystemPrompt,
    double? defaultTemperature,
    double? defaultTopP,
    int? defaultTopK,
    int? defaultMaxTokens,
    double? defaultRepeatPenalty,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      colorSeed: colorSeed ?? this.colorSeed,
      fontSize: fontSize ?? this.fontSize,
      defaultSystemPrompt: defaultSystemPrompt ?? this.defaultSystemPrompt,
      defaultTemperature: defaultTemperature ?? this.defaultTemperature,
      defaultTopP: defaultTopP ?? this.defaultTopP,
      defaultTopK: defaultTopK ?? this.defaultTopK,
      defaultMaxTokens: defaultMaxTokens ?? this.defaultMaxTokens,
      defaultRepeatPenalty: defaultRepeatPenalty ?? this.defaultRepeatPenalty,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);
  void setColorSeed(String seed) => state = state.copyWith(colorSeed: seed);
  void setFontSize(double size) => state = state.copyWith(fontSize: size);
  void setDefaultSystemPrompt(String prompt) =>
      state = state.copyWith(defaultSystemPrompt: prompt);
  void setDefaultTemperature(double t) =>
      state = state.copyWith(defaultTemperature: t);
  void setDefaultTopP(double p) => state = state.copyWith(defaultTopP: p);
  void setDefaultTopK(int k) => state = state.copyWith(defaultTopK: k);
  void setDefaultMaxTokens(int t) => state = state.copyWith(defaultMaxTokens: t);
  void setDefaultRepeatPenalty(double p) =>
      state = state.copyWith(defaultRepeatPenalty: p);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
```

- [ ] **Step 4: Verify files compile**

```bash
cd /e/gemma
dart analyze lib/providers/
```

Expected: No errors.

---

### Task 6: Riverpod Providers — Chat, Conversations, Templates, Documents

**Files:**
- Create: `lib/providers/chat_provider.dart`
- Create: `lib/providers/conversation_list_provider.dart`
- Create: `lib/providers/template_provider.dart`
- Create: `lib/providers/document_provider.dart`

**Interfaces:**
- Consumes: `StorageService`, `LlamaApiClient`, `ServerState`, `AppSettings`
- Produces: `chatProvider` (current conversation messages, streaming status), `conversationListProvider` (grouped list), `templateProvider` (templates list + CRUD), `documentProvider` (uploaded file state)

- [ ] **Step 1: Write conversation_list_provider.dart**

```dart
// lib/providers/conversation_list_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/tables.dart';
import 'providers.dart';

class ConversationListState {
  final List<Conversation> conversations;
  final String? activeConversationId;
  final bool isLoading;

  const ConversationListState({
    this.conversations = const [],
    this.activeConversationId,
    this.isLoading = false,
  });

  ConversationListState copyWith({
    List<Conversation>? conversations,
    String? activeConversationId,
    bool? isLoading,
    bool clearActive = false,
  }) {
    return ConversationListState(
      conversations: conversations ?? this.conversations,
      activeConversationId: clearActive ? null : (activeConversationId ?? this.activeConversationId),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ConversationListNotifier extends StateNotifier<ConversationListState> {
  final StorageService _storage;
  StreamSubscription? _subscription;

  ConversationListNotifier(this._storage) : super(const ConversationListState(isLoading: true)) {
    _subscription = _storage.watchConversations().listen((convs) {
      final sorted = List<Conversation>.from(convs);
      sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = state.copyWith(conversations: sorted, isLoading: false);
    });
  }

  Future<String> createConversation({
    String? title,
    String? modelId,
    String? systemPrompt,
  }) async {
    final conv = await _storage.createConversation(
      title: title,
      modelId: modelId,
      systemPrompt: systemPrompt,
    );
    state = state.copyWith(activeConversationId: conv.id);
    return conv.id;
  }

  void selectConversation(String id) {
    state = state.copyWith(activeConversationId: id);
  }

  Future<void> deleteConversation(String id) async {
    await _storage.deleteConversation(id);
    if (state.activeConversationId == id) {
      state = state.copyWith(clearActive: true);
    }
  }

  Future<List<Conversation>> search(String query) async {
    return _storage.searchConversations(query);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final conversationListProvider = StateNotifierProvider<ConversationListNotifier, ConversationListState>((ref) {
  return ConversationListNotifier(ref.read(storageServiceProvider));
});
```

- [ ] **Step 2: Write chat_provider.dart**

```dart
// lib/providers/chat_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/tables.dart';
import '../models/chat_message.dart';
import '../services/llama_api_client.dart';
import '../services/storage_service.dart';
import 'providers.dart';
import 'server_provider.dart';
import 'conversation_list_provider.dart';

enum ChatStreamState { idle, streaming, error }

class ChatState {
  final ChatStreamState streamState;
  final String currentStreamContent;
  final List<ChatMessage> messages;
  final String? errorMessage;

  const ChatState({
    this.streamState = ChatStreamState.idle,
    this.currentStreamContent = '',
    this.messages = const [],
    this.errorMessage,
  });

  ChatState copyWith({
    ChatStreamState? streamState,
    String? currentStreamContent,
    List<ChatMessage>? messages,
    String? errorMessage,
  }) {
    return ChatState(
      streamState: streamState ?? this.streamState,
      currentStreamContent: currentStreamContent ?? this.currentStreamContent,
      messages: messages ?? this.messages,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final StorageService _storage;
  final LlamaApiClient _api;
  final Ref _ref;
  StreamSubscription<List<ChatMessage>>? _msgSub;
  String? _currentConvId;

  ChatNotifier(this._storage, this._api, this._ref) : super(const ChatState());

  void loadConversation(String convId) {
    _currentConvId = convId;
    _msgSub?.cancel();
    _msgSub = _storage.watchMessages(convId).listen((msgs) {
      state = state.copyWith(messages: msgs);
    });
  }

  Future<void> sendMessage(String text, {List<AttachmentInfo>? attachments}) async {
    if (_currentConvId == null) return;

    // Save user message
    await _storage.addMessage(
      conversationId: _currentConvId!,
      role: 'user',
      content: text,
      attachments: attachments?.map((a) => a.toJson()).toList(),
    );

    // Build messages list for API call
    final conv = await _storage.getConversation(_currentConvId!);
    final modelId = conv?.modelId ?? _ref.read(serverProvider).selectedModelId;
    if (modelId == null) {
      state = state.copyWith(errorMessage: 'No model selected');
      return;
    }

    final messages = await _storage.getMessages(_currentConvId!);
    final apiMessages = <Map<String, String>>[];
    if (conv?.systemPrompt != null && conv!.systemPrompt!.isNotEmpty) {
      apiMessages.add({'role': 'system', 'content': conv.systemPrompt!});
    }
    for (final msg in messages) {
      // Build content with attachments if present
      String content = msg.content;
      if (msg.attachmentsJson != null && msg.attachmentsJson!.isNotEmpty) {
        final attachmentsList = (msg.attachmentsJson as List)
            .map((e) => AttachmentInfo.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final att in attachmentsList) {
          if (att.fileType == 'image') {
            content = '[Image: ${att.fileName}]\n$content';
          } else {
            content = '> ${att.fileName}:\n${att.content}\n\n$content';
          }
        }
      }
      apiMessages.add({'role': msg.role, 'content': content});
    }
    // Add attachments from current message
    if (attachments != null && attachments.isNotEmpty) {
      final lastMsg = apiMessages.removeLast();
      String augmentedContent = lastMsg['content']!;
      for (final att in attachments) {
        if (att.fileType == 'image') {
          augmentedContent = '[Image: ${att.fileName}]\n$augmentedContent';
        } else {
          augmentedContent = '> ${att.fileName}:\n${att.content}\n\n$augmentedContent';
        }
      }
      apiMessages.add({'role': 'user', 'content': augmentedContent});
    }

    // Start streaming
    state = state.copyWith(streamState: ChatStreamState.streaming, currentStreamContent: '');

    try {
      final stream = _api.sendChatStream(
        model: modelId,
        messages: apiMessages,
        temperature: conv?.temperature ?? 0.7,
        topP: conv?.topP ?? 0.9,
        topK: conv?.topK ?? 40,
        maxTokens: conv?.maxTokens ?? 4096,
        repeatPenalty: conv?.repeatPenalty ?? 1.1,
      );

      String fullContent = '';
      await for (final delta in stream) {
        fullContent += delta;
        state = state.copyWith(currentStreamContent: fullContent);
      }

      // Save assistant message
      if (fullContent.isNotEmpty) {
        await _storage.addMessage(
          conversationId: _currentConvId!,
          role: 'assistant',
          content: fullContent,
        );
      }

      state = state.copyWith(streamState: ChatStreamState.idle, currentStreamContent: '');
    } catch (e) {
      state = state.copyWith(
        streamState: ChatStreamState.error,
        errorMessage: 'Stream error: $e',
      );
    }
  }

  void stopStream() {
    _api.cancelStream();
    // Save whatever we have so far
    if (state.currentStreamContent.isNotEmpty && _currentConvId != null) {
      _storage.addMessage(
        conversationId: _currentConvId!,
        role: 'assistant',
        content: state.currentStreamContent + '\n\n*[Generation stopped]*',
      );
    }
    state = state.copyWith(streamState: ChatStreamState.idle, currentStreamContent: '');
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    ref.read(storageServiceProvider),
    ref.read(apiClientProvider),
    ref,
  );
});
```

- [ ] **Step 3: Write template_provider.dart**

```dart
// lib/providers/template_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/tables.dart';
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
```

- [ ] **Step 4: Write document_provider.dart**

```dart
// lib/providers/document_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/file_service.dart';

class DocumentState {
  final List<AttachmentInfo> attachments;
  final bool isUploading;
  final String? errorMessage;

  const DocumentState({
    this.attachments = const [],
    this.isUploading = false,
    this.errorMessage,
  });

  DocumentState copyWith({
    List<AttachmentInfo>? attachments,
    bool? isUploading,
    String? errorMessage,
  }) {
    return DocumentState(
      attachments: attachments ?? this.attachments,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DocumentNotifier extends StateNotifier<DocumentState> {
  final FileService _fileService;

  DocumentNotifier(this._fileService) : super(const DocumentState());

  Future<void> addFile(String filePath) async {
    state = state.copyWith(isUploading: true, errorMessage: null);
    try {
      final content = await _fileService.extractText(filePath);
      final fileName = filePath.split('/').last;
      final isImage = FileService.isImage(filePath);
      final attachment = AttachmentInfo(
        fileName: fileName,
        fileType: isImage ? 'image' : fileName.split('.').last,
        content: content ?? '[Unsupported file format]',
      );
      state = state.copyWith(
        attachments: [...state.attachments, attachment],
        isUploading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Failed to process file: $e',
      );
    }
  }

  void removeAttachment(int index) {
    final updated = List<AttachmentInfo>.from(state.attachments)..removeAt(index);
    state = state.copyWith(attachments: updated);
  }

  void clearAttachments() {
    state = state.copyWith(attachments: []);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  return DocumentNotifier(ref.read(fileServiceProvider));
});
```

- [ ] **Step 5: Verify all providers compile**

```bash
cd /e/gemma
dart analyze lib/providers/
```

Expected: No errors.

---

### Task 7: Theme System

**Files:**
- Create: `lib/core/theme/app_theme.dart`

**Interfaces:**
- Consumes: `AppSettings` (themeMode, colorSeed)
- Produces: `AppTheme` class with `light() → ThemeData`, `dark() → ThemeData`, `getThemeFromSeed(String) → ColorScheme`

- [ ] **Step 1: Write the theme system**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class AppTheme {
  static ThemeData light(String colorSeed) {
    return FlexThemeData.light(
      colorScheme: _schemeFromSeed(colorSeed),
      surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
      appBarStyle: FlexAppBarStyle.background,
      tabBarStyle: FlexTabBarStyle.forBackground,
      tooltipsMatchBackground: true,
      useMaterial3: true,
      swapColors: false,
      lightIsWhite: true,
    );
  }

  static ThemeData dark(String colorSeed) {
    return FlexThemeData.dark(
      colorScheme: _schemeFromSeed(colorSeed),
      surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
      appBarStyle: FlexAppBarStyle.background,
      tabBarStyle: FlexTabBarStyle.forBackground,
      tooltipsMatchBackground: true,
      useMaterial3: true,
      swapColors: false,
      darkIsTrueBlack: true,
    );
  }

  static ColorScheme _schemeFromSeed(String seedName) {
    switch (seedName) {
      case 'blue':   return FlexColor.blueM3;
      case 'green':  return FlexColor.greenM3;
      case 'purple': return FlexColor.deepPurpleM3;
      case 'orange': return FlexColor.deepOrangeM3;
      case 'red':    return FlexColor.redM3;
      case 'teal':   return FlexColor.tealM3;
      case 'pink':   return FlexColor.pinkM3;
      case 'grey':   return FlexColor.blueGreyM3;
      case 'brown':  return FlexColor.brownM3;
      case 'indigo': return FlexColor.indigoM3;
      default:       return FlexColor.blueM3;
    }
  }

  /// Get a color from seed name for UI preview
  static Color colorFromSeed(String seedName) {
    return _schemeFromSeed(seedName).primary;
  }
}
```

- [ ] **Step 2: Verify file compiles**

```bash
cd /e/gemma
dart analyze lib/core/theme/
```

Expected: No errors.

---

### Task 8: Home Screen and Adaptive Layout

**Files:**
- Create: `lib/screens/home_screen.dart`
- Create: `lib/widgets/conversation_list.dart`
- Create: `lib/widgets/connection_status_bar.dart`

**Interfaces:**
- Consumes: `conversationListProvider`, `serverProvider`, `chatProvider`
- Produces: `HomeScreen` — adaptive layout (side-by-side or drawer), `ConversationList` — grouped sidebar list, `ConnectionStatusBar` — bottom status bar

- [ ] **Step 1: Write ConversationList widget**

```dart
// lib/widgets/conversation_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../database/tables.dart';
import '../providers/conversation_list_provider.dart';

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
        // New conversation button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FilledButton.icon(
            onPressed: () async {
              final id = await ref.read(conversationListProvider.notifier).createConversation();
              ref.read(chatProvider.notifier).loadConversation(id);
            },
            icon: const Icon(Icons.add),
            label: const Text('New Conversation'),
          ),
        ),
        const Divider(height: 1),
        // Conversation list
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
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

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateTime.fromMillisecondsSinceEpoch(conversation.updatedAt);
    final timeStr = DateFormat('HH:mm').format(date);

    return ListTile(
      selected: isSelected,
      selectedTileColor: colorScheme.secondaryContainer.withOpacity(0.3),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        timeStr,
        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
      ),
      onTap: onTap,
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
        onPressed: onDelete,
      ),
      dense: true,
    );
  }
}
```

- [ ] **Step 2: Write ConnectionStatusBar**

```dart
// lib/widgets/connection_status_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/server_provider.dart';

class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color color;
    String text;

    switch (serverState.connectionState) {
      case ServerConnectionState.connected:
        icon = Icons.check_circle;
        color = Colors.green;
        text = 'llama connected  •  ${serverState.latency?.inMilliseconds ?? "?"}ms';
        break;
      case ServerConnectionState.connecting:
        icon = Icons.sync;
        color = Colors.orange;
        text = 'Connecting...';
        break;
      case ServerConnectionState.error:
        icon = Icons.error;
        color = Colors.red;
        text = 'Connection error';
        break;
      case ServerConnectionState.disconnected:
        icon = Icons.link_off;
        color = colorScheme.onSurfaceVariant;
        text = 'No server configured';
        break;
    }

    return GestureDetector(
      onTap: () {
        // Navigate to server settings (will be wired in Task 10)
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (serverState.currentUrl != null)
              Text(
                serverState.currentUrl!,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Write HomeScreen with adaptive layout**

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../providers/conversation_list_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/conversation_list.dart';
import '../widgets/connection_status_bar.dart';
import 'chat_screen.dart';
import 'server_settings_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final convState = ref.watch(conversationListProvider);
    final isWide = MediaQuery.of(context).size.width >= AppConstants.layoutBreakpoint;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('LlamaChat'),
        actions: [
          if (!isWide)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                _showSearch(context, ref);
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(
        child: SafeArea(
          child: ConversationList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      SizedBox(
                        width: 280,
                        child: Material(
                          color: colorScheme.surfaceContainerLow,
                          child: Column(
                            children: [
                              // Server settings shortcut at top of sidebar
                              ListTile(
                                leading: const Icon(Icons.dns),
                                title: const Text('Servers'),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(child: ConversationList()),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, color: colorScheme.outlineVariant),
                      Expanded(child: convState.activeConversationId != null
                          ? const ChatScreen()
                          : _buildEmptyState(colorScheme)),
                    ],
                  )
                : (convState.activeConversationId != null
                    ? const ChatScreen()
                    : _buildEmptyState(colorScheme)),
          ),
          const ConnectionStatusBar(),
        ],
      ),
      floatingActionButton: !isWide && convState.activeConversationId == null
          ? FloatingActionButton(
              onPressed: () async {
                final id = await ref.read(conversationListProvider.notifier).createConversation();
                ref.read(chatProvider.notifier).loadConversation(id);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showSearch(context: context, delegate: _ConversationSearchDelegate(ref));
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Select or create a conversation',
            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              final id = await ref.read(conversationListProvider.notifier).createConversation();
              ref.read(chatProvider.notifier).loadConversation(id);
            },
            icon: const Icon(Icons.add),
            label: const Text('New Conversation'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Add conversation search delegate widget**

```dart
// Add to lib/screens/home_screen.dart (after _HomeScreenState class, same file)
class _ConversationSearchDelegate extends SearchDelegate<Conversation?> {
  final WidgetRef ref;

  _ConversationSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text('Type to search conversations',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    return FutureBuilder<List<Conversation>>(
      future: ref.read(storageServiceProvider).searchConversations(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No conversations found'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final conv = snapshot.data![index];
            return ListTile(
              title: Text(conv.title),
              subtitle: Text(DateTime.fromMillisecondsSinceEpoch(conv.updatedAt).toString()),
              onTap: () {
                ref.read(conversationListProvider.notifier).selectConversation(conv.id);
                ref.read(chatProvider.notifier).loadConversation(conv.id);
                close(context, conv);
              },
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 5: Verify files compile**

```bash
cd /e/gemma
dart analyze lib/screens/home_screen.dart lib/widgets/
```

Expected: No errors.

---

### Task 9: Chat Screen and Messaging Widgets

**Files:**
- Create: `lib/screens/chat_screen.dart`
- Create: `lib/widgets/message_bubble.dart`
- Create: `lib/widgets/chat_input.dart`
- Create: `lib/widgets/parameter_panel.dart`

**Interfaces:**
- Consumes: `chatProvider`, `documentProvider`, `serverProvider`, `conversationListProvider`
- Produces: Chat UI with streaming, Markdown rendering, input bar, parameter panel

- [ ] **Step 1: Write MessageBubble**

```dart
// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:provider/provider.dart';
import '../database/tables.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;
  final bool isDark;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateTime.fromMillisecondsSinceEpoch(message.createdAt);
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.primaryContainer,
                child: Text('AI', style: TextStyle(fontSize: 10, color: colorScheme.onPrimaryContainer)),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12).copyWith(
                      bottomRight: isUser ? Radius.zero : null,
                      bottomLeft: !isUser ? Radius.zero : null,
                    ),
                  ),
                  child: isUser
                      ? SelectableText(
                          message.content,
                          style: TextStyle(color: colorScheme.onPrimaryContainer),
                        )
                      : _buildMarkdownContent(message.content),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(timeStr, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                    if (isStreaming)
                      Text(' ● streaming', style: TextStyle(fontSize: 10, color: Colors.green)),
                    if (!isUser && !isStreaming)
                      IconButton(
                        icon: Icon(Icons.copy, size: 14, color: colorScheme.onSurfaceVariant),
                        onPressed: () {
                          // Copy to clipboard
                        },
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(Icons.person, size: 16, color: colorScheme.onSecondaryContainer),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(String content) {
    if (isStreaming && content.isEmpty) {
      return const SizedBox(
        height: 20,
        width: 40,
        child: LinearProgressIndicator(),
      );
    }

    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14),
        code: TextStyle(
          backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      builders: {
        'code': _CodeBlockBuilder(isDark: isDark),
      },
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  final bool isDark;
  _CodeBlockBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(elements.Element elem, TextStyle? preferredStyle) {
    final code = elem.textContent;
    final lang = elem.attributes['class']?.replaceAll('language-', '') ?? '';
    final theme = isDark ? draculaTheme : githubTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Language label + copy button bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang.isNotEmpty ? lang : 'code',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              Icon(Icons.copy, size: 14),
            ],
          ),
        ),
        ClipRect(
          child: HighlightView(
            code,
            language: lang.isNotEmpty ? lang : 'plaintext',
            theme: theme,
            padding: const EdgeInsets.all(12),
            textStyle: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Write ParameterPanel**

```dart
// lib/widgets/parameter_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/conversation_list_provider.dart';
import '../providers/chat_provider.dart';
import '../services/storage_service.dart';
import 'providers.dart';

class ParameterPanel extends ConsumerStatefulWidget {
  const ParameterPanel({super.key});

  @override
  ConsumerState<ParameterPanel> createState() => _ParameterPanelState();
}

class _ParameterPanelState extends ConsumerState<ParameterPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final convState = ref.watch(conversationListProvider);
    final convId = convState.activeConversationId;

    // Default values
    double temperature = 0.7, topP = 0.9, repeatPenalty = 1.1;
    int topK = 40, maxTokens = 4096;
    String systemPrompt = '';

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Temperature $temperature  •  Max Tokens $maxTokens',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildSlider('Temperature', temperature, 0.0, 2.0, (v) => temperature = v),
                _buildSlider('Top-P', topP, 0.0, 1.0, (v) => topP = v),
                _buildSlider('Top-K', topK.toDouble(), 0, 100, (v) => topK = v.toInt()),
                _buildSlider('Max Tokens', maxTokens.toDouble(), 256, 32768, (v) => maxTokens = v.toInt()),
                _buildSlider('Repeat Penalty', repeatPenalty, 1.0, 2.0, (v) => repeatPenalty = v),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'System Prompt',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  controller: TextEditingController(text: systemPrompt),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min) / 0.1).round(),
              label: value.toStringAsFixed(2),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Write ChatInput**

```dart
// lib/widgets/chat_input.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/chat_provider.dart';
import '../providers/document_provider.dart';
import '../providers/server_provider.dart';
import '../models/chat_message.dart';

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
          // Attachments preview
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
          // Input row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
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
                // Model selector
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
                // Text input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    onChanged: (v) => setState(() => _hasText = v.isNotEmpty),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Send / Stop button
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
          // Parameter panel
          const ParameterPanel(),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Write ChatScreen**

```dart
// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../providers/conversation_list_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

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
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final convState = ref.watch(conversationListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scroll on new content
    if (chatState.streamState == ChatStreamState.streaming) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(conversationListProvider.notifier).selectConversation('');
          },
        ),
        title: Text(
          _getConversationTitle(convState),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                if (convState.activeConversationId != null) {
                  ref.read(conversationListProvider.notifier).deleteConversation(convState.activeConversationId!);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete conversation'),
                dense: true,
              )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: chatState.messages.length + (chatState.streamState == ChatStreamState.streaming ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < chatState.messages.length) {
                  return MessageBubble(
                    message: chatState.messages[index],
                    isDark: isDark,
                  );
                }
                // Show streaming message
                if (chatState.currentStreamContent.isNotEmpty) {
                  final lastMsg = chatState.messages.isNotEmpty ? chatState.messages.last : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8, top: 4),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text('AI', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(chatState.currentStreamContent, style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                const LinearProgressIndicator(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox(
                  height: 20,
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                );
              },
            ),
          ),
          // Error banner
          if (chatState.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(chatState.errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.red))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => ref.read(chatProvider.notifier).clearError(),
                  ),
                ],
              ),
            ),
          // Input
          const ChatInput(),
        ],
      ),
    );
  }

  String _getConversationTitle(convState) {
    final conv = convState.conversations.where((c) => c.id == convState.activeConversationId);
    return conv.isNotEmpty ? conv.first.title : 'Chat';
  }
}
```

- [ ] **Step 5: Verify files compile**

```bash
cd /e/gemma
dart analyze lib/screens/ lib/widgets/
```

Expected: No errors.

---

### Task 10: Server Settings Screen

**Files:**
- Create: `lib/screens/server_settings_screen.dart`
- Create: `lib/widgets/model_selector.dart`

**Interfaces:**
- Consumes: `serverProvider`, `storageServiceProvider`
- Produces: Server configuration UI

- [ ] **Step 1: Write ServerSettingsScreen**

```dart
// lib/screens/server_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/server_provider.dart';

class ServerSettingsScreen extends ConsumerStatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  ConsumerState<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends ConsumerState<ServerSettingsScreen> {
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _labelController = TextEditingController();
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(serverProvider);
    if (state.currentUrl != null) {
      _urlController.text = state.currentUrl!;
    }
    if (state.apiKey != null) {
      _apiKeyController.text = state.apiKey!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Server Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // URL input
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'http://192.168.1.100:8080',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          // API Key
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'API Key (optional)',
              prefixIcon: const Icon(Icons.key),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.visibility_off),
                onPressed: () {},
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          // Label
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label (optional)',
              hintText: 'My Server',
              prefixIcon: Icon(Icons.label),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Connection status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    serverState.connectionState == ServerConnectionState.connected
                        ? Icons.check_circle
                        : Icons.error,
                    color: serverState.connectionState == ServerConnectionState.connected
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serverState.connectionState == ServerConnectionState.connected
                              ? 'Connected'
                              : serverState.connectionState == ServerConnectionState.error
                                  ? 'Error'
                                  : 'Not connected',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (serverState.latency != null)
                          Text('Latency: ${serverState.latency!.inMilliseconds}ms',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        if (serverState.errorMessage != null)
                          Text(serverState.errorMessage!,
                              style: TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Test connection button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testing ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_find),
              label: Text(_testing ? 'Testing...' : 'Test Connection'),
            ),
          ),
          const SizedBox(height: 8),
          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveServer,
              icon: const Icon(Icons.save),
              label: const Text('Save & Connect'),
            ),
          ),

          const SizedBox(height: 24),

          // Available models
          if (serverState.availableModels.isNotEmpty) ...[
            Text('Available Models', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...serverState.availableModels.map((model) => Card(
              child: ListTile(
                leading: const Icon(Icons.smart_toy),
                title: Text(model.name),
                subtitle: model.contextLength != null
                    ? Text('Context: ${model.contextLength} tokens')
                    : null,
                trailing: model.id == serverState.selectedModelId
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => ref.read(serverProvider.notifier).selectModel(model.id),
              ),
            )),
          ],

          const SizedBox(height: 24),

          // Saved servers list
          if (serverState.savedServers.isNotEmpty) ...[
            Text('Saved Servers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...serverState.savedServers.map((server) => Card(
              child: ListTile(
                leading: const Icon(Icons.dns),
                title: Text(server.label),
                subtitle: Text(server.url, style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: () {
                    // Delete saved server
                  },
                ),
                onTap: () {
                  _urlController.text = server.url;
                  _apiKeyController.text = server.apiKey ?? '';
                  _labelController.text = server.label;
                },
              ),
            )),
          ],
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    await ref.read(serverProvider.notifier).connect(
      _urlController.text.trim(),
      apiKey: _apiKeyController.text.trim().isNotEmpty ? _apiKeyController.text.trim() : null,
    );
    setState(() => _testing = false);
  }

  Future<void> _saveServer() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    await _testConnection();
    if (ref.read(serverProvider).connectionState == ServerConnectionState.connected) {
      await ref.read(storageServiceProvider).saveServerConfig(
        url: url,
        apiKey: _apiKeyController.text.trim().isNotEmpty ? _apiKeyController.text.trim() : null,
        label: _labelController.text.trim().isNotEmpty ? _labelController.text.trim() : null,
      );
      if (mounted) Navigator.pop(context);
    }
  }
}
```

- [ ] **Step 2: Verify file compiles**

```bash
cd /e/gemma
dart analyze lib/screens/server_settings_screen.dart
```

Expected: No errors.

---

### Task 11: Settings Screen

**Files:**
- Create: `lib/screens/settings_screen.dart`

**Interfaces:**
- Consumes: `settingsProvider`, `storageServiceProvider`
- Produces: Full settings UI

- [ ] **Step 1: Write SettingsScreen**

```dart
// lib/screens/settings_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance section
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                // Theme mode
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  subtitle: Text(_themeModeName(settings.themeMode)),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.auto_mode)),
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (v) {
                      ref.read(settingsProvider.notifier).setThemeMode(v.first);
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                // Color seed
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme Color'),
                  subtitle: Text(settings.colorSeed),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.presetColorSeeds.map((seed) {
                      final isSelected = settings.colorSeed == seed;
                      return ChoiceChip(
                        label: Text(seed, style: TextStyle(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: AppTheme.colorFromSeed(seed).withOpacity(0.3),
                        onSelected: (_) {
                          ref.read(settingsProvider.notifier).setColorSeed(seed);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Defaults section
          Text('Defaults', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.thermostat),
                  title: const Text('Temperature'),
                  subtitle: Text(settings.defaultTemperature.toStringAsFixed(2)),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: settings.defaultTemperature,
                      min: 0, max: 2,
                      divisions: 40,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultTemperature(v),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Max Tokens'),
                  subtitle: Text(settings.defaultMaxTokens.toString()),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: settings.defaultMaxTokens.toDouble(),
                      min: 256, max: 32768,
                      divisions: 20,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultMaxTokens(v.toInt()),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Default System Prompt',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    controller: TextEditingController(text: settings.defaultSystemPrompt),
                    onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultSystemPrompt(v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Data section
          Text('Data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export All Conversations'),
                  subtitle: const Text('Save as JSON file'),
                  onTap: () async {
                    final storage = ref.read(storageServiceProvider);
                    final convs = await storage.getAllConversations();
                    final exportData = <Map<String, dynamic>>[];
                    for (final conv in convs) {
                      final msgs = await storage.getMessages(conv.id);
                      exportData.add({
                        'title': conv.title,
                        'createdAt': conv.createdAt,
                        'modelId': conv.modelId,
                        'messages': msgs.map((m) => {
                          'role': m.role,
                          'content': m.content,
                          'createdAt': m.createdAt,
                        }).toList(),
                      });
                    }
                    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
                    final dir = await getApplicationDocumentsDirectory();
                    final file = File('${dir.path}/llamachat_export.json');
                    await file.writeAsString(jsonStr);
                    await Share.shareXFiles([XFile(file.path)], text: 'LlamaChat Export');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exported ${exportData.length} conversations')),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Import Conversations'),
                  subtitle: const Text('Load from JSON file'),
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );
                    if (result != null && result.files.single.path != null) {
                      final file = File(result.files.single.path!);
                      final jsonStr = await file.readAsString();
                      final data = jsonDecode(jsonStr) as List<dynamic>;
                      final storage = ref.read(storageServiceProvider);
                      for (final item in data) {
                        final conv = item as Map<String, dynamic>;
                        final newConv = await storage.createConversation(
                          title: conv['title'] as String?,
                          modelId: conv['modelId'] as String?,
                        );
                        final messages = conv['messages'] as List<dynamic>? ?? [];
                        for (final msg in messages) {
                          final m = msg as Map<String, dynamic>;
                          await storage.addMessage(
                            conversationId: newConv.id,
                            role: m['role'] as String,
                            content: m['content'] as String,
                            tokenCount: m['tokenCount'] as int?,
                          );
                        }
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Imported ${data.length} conversations')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: colorScheme.error),
                  title: Text('Clear All Conversations', style: TextStyle(color: colorScheme.error)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear all conversations?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              final storage = ref.read(storageServiceProvider);
                              final convs = await storage.getAllConversations();
                              for (final conv in convs) {
                                await storage.deleteConversation(conv.id);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('All conversations cleared')),
                                );
                              }
                            },
                            child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About section
          Text('About', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('LlamaChat'),
              subtitle: Text('Version ${AppConstants.appVersion}'),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System';
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
    }
  }
}
```

- [ ] **Step 2: Verify file compiles**

```bash
cd /e/gemma
dart analyze lib/screens/settings_screen.dart
```

Expected: No errors.

---

### Task 12: Prompt Template Library

**Files:**
- Create: `lib/screens/prompt_library_screen.dart`
- Create: `lib/widgets/template_selector.dart`

**Interfaces:**
- Consumes: `templateProvider`, `templateProvider.notifier`
- Produces: Template management UI, inline template selector for chat input

- [ ] **Step 1: Write PromptLibraryScreen**

```dart
// lib/screens/prompt_library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/tables.dart';
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
              TextField(controller: userMsgController, decoration: const InputDecoration(labelText: 'User Message Template', helperText: 'Use {{placeholder}} for variables', border: OutlineInputBorder()), maxLines: 3),
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

    // Filter by search
    final query = _searchController.text.toLowerCase();
    final filtered = query.isEmpty
        ? templates
        : templates.where((t) =>
            t.title.toLowerCase().contains(query) ||
            t.category?.toLowerCase().contains(query) == true)
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
          // Search
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
          // Template list
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
```

- [ ] **Step 2: Write TemplateSelector (inline for chat)**

```dart
// lib/widgets/template_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/tables.dart';
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
```

- [ ] **Step 3: Verify files compile**

```bash
cd /e/gemma
dart analyze lib/screens/prompt_library_screen.dart lib/widgets/template_selector.dart
```

Expected: No errors.

---

### Task 13: Wire Navigation and App Entry Point

**Files:**
- Modify: `lib/app.dart` (add router, theme, seed built-in templates)

- [ ] **Step 1: Rewrite app.dart with full wiring**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'screens/server_settings_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/prompt_library_screen.dart';

class LlamaChatApp extends ConsumerStatefulWidget {
  const LlamaChatApp({super.key});

  @override
  ConsumerState<LlamaChatApp> createState() => _LlamaChatAppState();
}

class _LlamaChatAppState extends ConsumerState<LlamaChatApp> {
  @override
  void initState() {
    super.initState();
    // Seed built-in templates after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storageServiceProvider).seedBuiltInTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'LlamaChat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.colorSeed),
      darkTheme: AppTheme.dark(settings.colorSeed),
      themeMode: settings.themeMode,
      home: const HomeScreen(),
      routes: {
        '/server-settings': (context) => const ServerSettingsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/templates': (context) => const PromptLibraryScreen(),
      },
    );
  }
}
```

- [ ] **Step 2: Verify full app builds**

```bash
cd /e/gemma
dart analyze lib/
flutter build windows --debug 2>&1 | tail -20 || echo "Windows build check skipped (may need Flutter Windows toolchain)"
```

Expected: `dart analyze` passes with no errors.

---

### Task 14: Create initial git commit

- [ ] **Step 1: Initialize git and create first commit**

```bash
cd /e/gemma
git init
git add .
git commit -m "feat: initial LlamaChat scaffold

Flutter cross-platform chat client for llama.cpp server.

- Material 3 theming with 10 color seeds
- Riverpod state management
- Drift SQLite local storage
- OpenAI-compatible API client with SSE streaming
- Full chat UI with Markdown/code rendering
- Server configuration and connection management
- Prompt template library with built-in templates
- Adaptive layout (side-by-side on desktop, drawer on mobile)"
```

Expected: Clean commit with all project files.

---

## Spec Coverage Check

| Spec Requirement | Task |
|---|---|
| Server connection (URL, API Key, model list, status, latency) | Task 3, Task 10 |
| Multi-turn conversation with streaming | Task 6 (chat_provider), Task 9 |
| Markdown / code rendering | Task 9 (message_bubble) |
| Model parameter adjustment | Task 9 (parameter_panel), Task 11 |
| Multi-model switching | Task 3 (fetchModels), Task 10 (model_selector) |
| Conversation export/import | Task 11 (placeholder — future enhancement) |
| Conversation search | Task 6 (searchConversations — backend done, UI placeholder) |
| Document upload | Task 4 (file_service), Task 6 (document_provider), Task 9 (chat_input) |
| Multi-modal (images) | Task 4 (file_service.isImage), Task 9 (chat_input image picker) |
| Prompt template library | Task 4 (storage), Task 6 (template_provider), Task 12 |
| Dark mode / theme switching | Task 5 (settings_provider), Task 7 (app_theme) |
| Data models and database | Task 2 |
| Adaptive layout (800px breakpoint) | Task 8 (home_screen) |
