import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
    try {
      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();

      if (text.trim().isEmpty) {
        return '[PDF: ${file.path.split('/').last} — No extractable text found (scanned document?)]';
      }
      return text;
    } catch (e) {
      return '[PDF: ${file.path.split('/').last} — Text extraction failed: $e]';
    }
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