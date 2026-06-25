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