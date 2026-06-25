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