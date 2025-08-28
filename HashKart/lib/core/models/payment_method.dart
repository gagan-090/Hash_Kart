class PaymentMethod {
  final String id;
  final String type;
  final String last4;
  final String brand;
  final String holderName;
  final String expiryMonth;
  final String expiryYear;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.brand,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
    this.isDefault = false,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      type: json['type'] ?? 'card',
      last4: json['last4'] ?? '',
      brand: json['brand'] ?? 'Unknown',
      holderName: json['holderName'] ?? '',
      expiryMonth: json['expiryMonth'] ?? '',
      expiryYear: json['expiryYear'] ?? '',
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'last4': last4,
      'brand': brand,
      'holderName': holderName,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PaymentMethod copyWith({
    String? id,
    String? type,
    String? last4,
    String? brand,
    String? holderName,
    String? expiryMonth,
    String? expiryYear,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      holderName: holderName ?? this.holderName,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedExpiry => '$expiryMonth/$expiryYear';
  String get formattedCardNumber => '**** **** **** $last4';
  String get displayName => '$brand •••• $last4';
}
