import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../models/chat_message.dart' as chat_model;
import '../services/llama_api_client.dart';
import '../services/storage_service.dart';
import 'providers.dart';
import 'server_provider.dart';

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

  Future<void> sendMessage(String text, {List<chat_model.AttachmentInfo>? attachments}) async {
    if (_currentConvId == null) return;

    await _storage.addMessage(
      conversationId: _currentConvId!,
      role: 'user',
      content: text,
      attachments: attachments?.map((a) => a.toJson()).toList(),
    );

    final conv = await _storage.getConversation(_currentConvId!);
    final serverState = _ref.read(serverProvider);
    final modelId = conv?.modelId ?? serverState.selectedModelId;
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
      String content = msg.content;
      if (msg.attachmentsJson != null && msg.attachmentsJson!.isNotEmpty) {
        final attList = jsonDecode(msg.attachmentsJson!) as List<dynamic>;
        for (final att in attList) {
          final a = chat_model.AttachmentInfo.fromJson(att as Map<String, dynamic>);
          content = a.fileType == 'image'
              ? '[Image: ${a.fileName}]\n$content'
              : '> ${a.fileName}:\n${a.content}\n\n$content';
        }
      }
      apiMessages.add({'role': msg.role, 'content': content});
    }

    if (attachments != null && attachments.isNotEmpty) {
      if (apiMessages.isNotEmpty) {
        final lastMsg = apiMessages.removeLast();
        String augmented = lastMsg['content']!;
        for (final a in attachments) {
          augmented = a.fileType == 'image'
              ? '[Image: ${a.fileName}]\n$augmented'
              : '> ${a.fileName}:\n${a.content}\n\n$augmented';
        }
        apiMessages.add({'role': 'user', 'content': augmented});
      }
    }

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
    if (state.currentStreamContent.isNotEmpty && _currentConvId != null) {
      _storage.addMessage(
        conversationId: _currentConvId!,
        role: 'assistant',
        content: '${state.currentStreamContent}\n\n*[Generation stopped]*',
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