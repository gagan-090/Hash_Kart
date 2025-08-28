import 'user_model.dart';

class Review {
  final String id;
  final String productId;
  final User user;
  final int rating;
  final String? title;
  final String comment;
  final List<String>? images;
  final int helpfulCount;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? vendorResponse;
  final DateTime? vendorResponseAt;

  Review({
    required this.id,
    required this.productId,
    required this.user,
    required this.rating,
    this.title,
    required this.comment,
    this.images,
    required this.helpfulCount,
    required this.isVerifiedPurchase,
    required this.createdAt,
    this.updatedAt,
    this.vendorResponse,
    this.vendorResponseAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? json['product'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      rating: json['rating'] ?? 0,
      title: json['title'],
      comment: json['comment'] ?? '',
      images: json['images'] != null 
          ? List<String>.from(json['images'])
          : null,
      helpfulCount: json['helpful_count'] ?? 0,
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'])
          : null,
      vendorResponse: json['vendor_response'],
      vendorResponseAt: json['vendor_response_at'] != null
          ? DateTime.tryParse(json['vendor_response_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user': user.toJson(),
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images,
      'helpful_count': helpfulCount,
      'is_verified_purchase': isVerifiedPurchase,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'vendor_response': vendorResponse,
      'vendor_response_at': vendorResponseAt?.toIso8601String(),
    };
  }

  Review copyWith({
    String? id,
    String? productId,
    User? user,
    int? rating,
    String? title,
    String? comment,
    List<String>? images,
    int? helpfulCount,
    bool? isVerifiedPurchase,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? vendorResponse,
    DateTime? vendorResponseAt,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      user: user ?? this.user,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      vendorResponse: vendorResponse ?? this.vendorResponse,
      vendorResponseAt: vendorResponseAt ?? this.vendorResponseAt,
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
