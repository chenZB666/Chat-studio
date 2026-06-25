import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/file_service.dart';
import 'providers.dart';

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