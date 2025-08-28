enum PaymentStatus {
  idle,
  processing,
  success,
  failed,
  cancelled
}

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool enabled;
  final List<String> supportedMethods;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.enabled,
    required this.supportedMethods,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      enabled: json['enabled'] ?? false,
      supportedMethods: List<String>.from(json['supported_methods'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'enabled': enabled,
      'supported_methods': supportedMethods,
    };
  }
}

class PaymentOrder {
  final String paymentId;
  final String? gatewayOrderId;
  final String? keyId;
  final int? amount;
  final String? currency;
  final String? orderNumber;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? paymentMethod;

  PaymentOrder({
    required this.paymentId,
    this.gatewayOrderId,
    this.keyId,
    this.amount,
    this.currency,
    this.orderNumber,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.paymentMethod,
  });

  // Add getter properties for compatibility
  String get id => paymentId;
  String? get receipt => orderNumber;
  String? get contact => customerPhone;
  String? get email => customerEmail;
  String? get name => customerName;

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      paymentId: json['payment_id'] ?? '',
      gatewayOrderId: json['gateway_order_id'],
      keyId: json['key_id'],
      amount: json['amount'],
      currency: json['currency'],
      orderNumber: json['order_number'],
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      customerPhone: json['customer_phone'],
      paymentMethod: json['payment_method'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'gateway_order_id': gatewayOrderId,
      'key_id': keyId,
      'amount': amount,
      'currency': currency,
      'order_number': orderNumber,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'payment_method': paymentMethod,
    };
  }
}

class Payment {
  final String id;
  final String orderId;
  final String? orderNumber;
  final String? customerName;
  final String paymentMethod;
  final double amount;
  final String currency;
  final String status;
  final String? gatewayPaymentId;
  final String? gatewayOrderId;
  final String? transactionId;
  final String? referenceNumber;
  final String? failureReason;
  final double refundedAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;

  Payment({
    required this.id,
    required this.orderId,
    this.orderNumber,
    this.customerName,
    required this.paymentMethod,
    required this.amount,
    required this.currency,
    required this.status,
    this.gatewayPaymentId,
    this.gatewayOrderId,
    this.transactionId,
    this.referenceNumber,
    this.failureReason,
    required this.refundedAmount,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      orderId: json['order'] ?? '',
      orderNumber: json['order_number'],
      customerName: json['customer_name'],
      paymentMethod: json['payment_method'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'INR',
      status: json['status'] ?? '',
      gatewayPaymentId: json['gateway_payment_id'],
      gatewayOrderId: json['gateway_order_id'],
      transactionId: json['transaction_id'],
      referenceNumber: json['reference_number'],
      failureReason: json['failure_reason'],
      refundedAmount: double.tryParse(json['refunded_amount']?.toString() ?? '0') ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': orderId,
      'order_number': orderNumber,
      'customer_name': customerName,
      'payment_method': paymentMethod,
      'amount': amount.toString(),
      'currency': currency,
      'status': status,
      'gateway_payment_id': gatewayPaymentId,
      'gateway_order_id': gatewayOrderId,
      'transaction_id': transactionId,
      'reference_number': referenceNumber,
      'failure_reason': failureReason,
      'refunded_amount': refundedAmount.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  bool get isSuccessful => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get canBeRefunded => status == 'completed' && refundedAmount < amount;
}

class RazorpayOptions {
  final String key;
  final int amount;
  final String currency;
  final String name;
  final String description;
  final String orderId;
  final Map<String, dynamic> prefill;
  final Map<String, dynamic> theme;
  final Map<String, dynamic> notes;

  RazorpayOptions({
    required this.key,
    required this.amount,
    required this.currency,
    required this.name,
    required this.description,
    required this.orderId,
    required this.prefill,
    required this.theme,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'amount': amount,
      'currency': currency,
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': prefill,
      'theme': theme,
      'notes': notes,
    };
  }
}