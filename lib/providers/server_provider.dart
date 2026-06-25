import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/model_info.dart';
import '../database/database.dart';
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
  final List<ServerConfig> savedServers;

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
    List<ServerConfig>? savedServers,
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

  Future<void> refreshSavedServers() async {
    final servers = await _storage.getAllServerConfigs();
    state = state.copyWith(savedServers: servers);
  }
}

final serverProvider = StateNotifierProvider<ServerNotifier, ServerState>((ref) {
  return ServerNotifier(
    ref.read(apiClientProvider),
    ref.read(storageServiceProvider),
  );
});