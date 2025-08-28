class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.data,
    this.actionUrl,
    this.imageUrl,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['is_read'] ?? false,
      data: json['data'],
      actionUrl: json['action_url'],
      imageUrl: json['image_url'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null 
          ? DateTime.tryParse(json['read_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'data': data,
      'action_url': actionUrl,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
