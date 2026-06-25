import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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
          receiveTimeout: const Duration(seconds: 120),
          headers: {'Content-Type': 'application/json'},
        ));

  String? get baseUrl => _baseUrl;

  /// Test connection and return latency. Returns null on failure.
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
  void connect(String url, {String? apiKey}) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _apiKey = apiKey;
    _dio.options.baseUrl = _baseUrl!;
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
    } else {
      _dio.options.headers.remove('Authorization');
    }
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
      final response = await _dio.post<ResponseBody>(
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

      // Process SSE (Server-Sent Events) stream manually
      final body = response.data;
      if (body == null) return;
      final lineStream = body.stream
          .transform(_sseDecoder());
      await for (final chunk in lineStream) {
        if (chunk.startsWith('data: ')) {
          final jsonStr = chunk.substring(6);
          if (jsonStr == '[DONE]') break;
          try {
            final Map<String, dynamic> json =
                jsonDecode(jsonStr) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices == null || choices.isEmpty) continue;
            final delta = choices[0] as Map<String, dynamic>;
            final content = delta['delta']?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          } catch (_) {
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
}

/// SSE decoder: converts a byte stream into individual SSE message lines.
///
/// Combines UTF-8 decoding + line splitting into a single transformer,
/// avoiding `Utf8Decoder` type compatibility issues in Dart 3.12+.
StreamTransformer<Uint8List, String> _sseDecoder() {
  return StreamTransformer<Uint8List, String>.fromHandlers(
    handleData: (data, sink) {
      final str = utf8.decode(data);
      for (final line in str.split('\n')) {
        if (line.isNotEmpty) {
          sink.add(line);
        }
      }
    },
  );
}
