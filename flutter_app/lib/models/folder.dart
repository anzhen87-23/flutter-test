/// 文件夹模型
class Folder {
  final int id;
  final int userId;
  final String name;
  final int noteCount;
  final DateTime createdAt;

  Folder({
    required this.id,
    required this.userId,
    required this.name,
    required this.noteCount,
    required this.createdAt,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      noteCount: json['note_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'note_count': noteCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
