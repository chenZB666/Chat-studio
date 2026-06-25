import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../services/llama_api_client.dart';
import '../services/storage_service.dart';
import '../services/file_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.read(databaseProvider)),
);
final apiClientProvider = Provider<LlamaApiClient>((ref) => LlamaApiClient());
final fileServiceProvider = Provider<FileService>((ref) => FileService());