import 'package:flutter_test/flutter_test.dart';

import 'package:llamachat/core/constants/app_constants.dart';
import 'package:llamachat/models/model_info.dart';
import 'package:llamachat/models/chat_message.dart';

void main() {
  group('AppConstants', () {
    test('has correct app name', () {
      expect(AppConstants.appName, 'LlamaChat');
    });

    test('has 10 preset color seeds', () {
      expect(AppConstants.presetColorSeeds.length, 10);
    });

    test('has reasonable default values', () {
      expect(AppConstants.defaultTemperature, 0.7);
      expect(AppConstants.defaultMaxTokens, 4096);
      expect(AppConstants.defaultTopP, 0.9);
    });
  });

  group('ModelInfo', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 'llama3.2:3b',
        'object': 'model',
        'context_length': 8192,
      };
      final model = ModelInfo.fromJson(json);
      expect(model.id, 'llama3.2:3b');
      expect(model.name, 'llama3.2:3b');
      expect(model.contextLength, 8192);
    });

    test('handles missing context_length', () {
      final json = {
        'id': 'qwen2.5:7b',
      };
      final model = ModelInfo.fromJson(json);
      expect(model.id, 'qwen2.5:7b');
      expect(model.name, 'qwen2.5:7b');
      expect(model.contextLength, isNull);
    });
  });

  group('AttachmentInfo', () {
    test('serializes and deserializes', () {
      final att = AttachmentInfo(
        fileName: 'test.txt',
        fileType: 'txt',
        content: 'hello world',
      );
      final json = att.toJson();
      final restored = AttachmentInfo.fromJson(json);
      expect(restored.fileName, 'test.txt');
      expect(restored.fileType, 'txt');
      expect(restored.content, 'hello world');
    });
  });
}