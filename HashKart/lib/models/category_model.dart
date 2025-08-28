class Category {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? image;
  final String? parentId;
  final List<Category>? children;
  final int productCount;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    this.parentId,
    this.children,
    required this.productCount,
    required this.isActive,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      image: json['image'],
      parentId: json['parent_id'] ?? json['parent'],
      children: json['children'] != null
          ? (json['children'] as List<dynamic>)
              .map((child) => Category.fromJson(child))
              .toList()
          : null,
      productCount: json['product_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      order: json['order'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image': image,
      'parent_id': parentId,
      'children': children?.map((child) => child.toJson()).toList(),
      'product_count': productCount,
      'is_active': isActive,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? image,
    String? parentId,
    List<Category>? children,
    int? productCount,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      image: image ?? this.image,
      parentId: parentId ?? this.parentId,
      children: children ?? this.children,
      productCount: productCount ?? this.productCount,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasChildren => children != null && children!.isNotEmpty;
  
  bool get isTopLevel => parentId == null || parentId!.isEmpty;
  
  // Get all descendant categories (recursive)
  List<Category> get allDescendants {
    final descendants = <Category>[];
    if (children != null) {
      for (final child in children!) {
        descendants.add(child);
        descendants.addAll(child.allDescendants);
      }
    }
    return descendants;
  }
  
  // Get breadcrumb path (requires parent categories to be loaded)
  List<String> getBreadcrumb(List<Category> allCategories) {
    final breadcrumb = <String>[name];
    
    if (parentId != null && parentId!.isNotEmpty) {
      final parent = allCategories.firstWhere(
        (cat) => cat.id == parentId,
        orElse: () => Category(
          id: '',
          name: '',
          slug: '',
          productCount: 0,
          isActive: false,
          order: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      if (parent.id.isNotEmpty) {
        breadcrumb.insertAll(0, parent.getBreadcrumb(allCategories));
      }
    }
    
    return breadcrumb;
  }
}
