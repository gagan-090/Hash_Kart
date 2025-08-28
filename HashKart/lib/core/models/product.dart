class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String vendorId;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final Map<String, dynamic>? attributes;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.vendorId,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isAvailable = true,
    this.attributes,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      vendorId: json['vendorId'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'vendorId': vendorId,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'attributes': attributes,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    String? vendorId,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    Map<String, dynamic>? attributes,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      vendorId: vendorId ?? this.vendorId,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      attributes: attributes ?? this.attributes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price)';
  }
}
