/// 笔记模型
class Note {
  final int id;
  final int userId;
  final int? folderId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    this.folderId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      folderId: json['folder_id'] as int?,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'folder_id': folderId,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'content': content,
      if (folderId != null) 'folder_id': folderId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'content': content,
      'folder_id': folderId,
    };
  }
}

/// 笔记列表响应
class NotesResponse {
  final List<Note> notes;
  final int total;
  final int page;
  final int pageSize;

  NotesResponse({
    required this.notes,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory NotesResponse.fromJson(Map<String, dynamic> json) {
    final notesList = (json['notes'] as List)
        .map((item) => Note.fromJson(item as Map<String, dynamic>))
        .toList();

    return NotesResponse(
      notes: notesList,
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
    );
  }
}
