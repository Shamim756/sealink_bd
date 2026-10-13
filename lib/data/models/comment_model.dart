class CommentModel {
  final int id;
  final int userId;
  final String userName;
  final String userUsername;
  final int? parentCommentId;
  final String content;
  final String createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userUsername,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> j) => CommentModel(
        id: j['id'],
        userId: j['user_id'] ?? 0,
        userName: j['user_name'] ?? 'User',
        userUsername: j['user_username'] ?? '',
        parentCommentId: j['parent_comment_id'],
        content: j['content'] ?? '',
        createdAt: j['created_at'] ?? '',
      );

  String get timeAgo {
    try {
      final dt = DateTime.parse(createdAt.replaceAll(' ', 'T'));
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} d ago';
      return '${(diff.inDays / 7).floor()} w ago';
    } catch (_) {
      return '';
    }
  }
}
