class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  // Convert Note to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'tags': tags.join(','),
    };
  }

  // Create Note from Map (database retrieval)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      tags: map['tags'] != null && map['tags'].isNotEmpty 
          ? map['tags'].split(',') 
          : [],
    );
  }

  // Create a copy of Note with optional parameter updates
  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'Note{id: $id, title: $title, content: ${content.length > 50 ? content.substring(0, 50) + "..." : content}, createdAt: $createdAt, updatedAt: $updatedAt, tags: $tags}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.content == content;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ content.hashCode;
  }
}

enum AIOperationType {
  summarize,
  rewrite,
  paraphrase,
  expand,
  simplify,
}

extension AIOperationTypeExtension on AIOperationType {
  String get displayName {
    switch (this) {
      case AIOperationType.summarize:
        return 'Summarize';
      case AIOperationType.rewrite:
        return 'Rewrite';
      case AIOperationType.paraphrase:
        return 'Paraphrase';
      case AIOperationType.expand:
        return 'Expand';
      case AIOperationType.simplify:
        return 'Simplify';
    }
  }

  String get prompt {
    switch (this) {
      case AIOperationType.summarize:
        return 'Please summarize the following text concisely:';
      case AIOperationType.rewrite:
        return 'Please rewrite the following text to improve clarity and flow:';
      case AIOperationType.paraphrase:
        return 'Please paraphrase the following text using different words while maintaining the same meaning:';
      case AIOperationType.expand:
        return 'Please expand on the following text with more details and explanations:';
      case AIOperationType.simplify:
        return 'Please simplify the following text to make it easier to understand:';
    }
  }

  String get icon {
    switch (this) {
      case AIOperationType.summarize:
        return '📝';
      case AIOperationType.rewrite:
        return '✏️';
      case AIOperationType.paraphrase:
        return '🔄';
      case AIOperationType.expand:
        return '📈';
      case AIOperationType.simplify:
        return '💡';
    }
  }
}
