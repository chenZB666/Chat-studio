import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../services/storage_service.dart';
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