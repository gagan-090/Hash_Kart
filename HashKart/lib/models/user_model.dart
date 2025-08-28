import '../core/utils/date_utils.dart' as date_utils;

class User {
  final String? id;
  final String email;
  final String firstName;
  final String lastName;
  final String userType;
  final String? phone;
  final String? dateOfBirth;
  final String? profileImage;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isActive;
  final bool isStaff;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActive;

  User({
    this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.userType = 'customer',
    this.phone,
    this.dateOfBirth,
    this.profileImage,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isActive = true,
    this.isStaff = false,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActive,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      userType: json['user_type'] ?? 'customer',
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'],
      profileImage: json['profile_image'],
      isEmailVerified: json['is_email_verified'] ?? false,
      isPhoneVerified: json['is_phone_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      isStaff: json['is_staff'] ?? false,
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
      lastActive: date_utils.DateUtils.safeParseDate(json['last_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'profile_image': profileImage,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'is_active': isActive,
      'is_staff': isStaff,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? userType,
    String? phone,
    String? dateOfBirth,
    String? profileImage,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isActive,
    bool? isStaff,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userType: userType ?? this.userType,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImage: profileImage ?? this.profileImage,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isActive: isActive ?? this.isActive,
      isStaff: isStaff ?? this.isStaff,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

class UserAddress {
  final String? id;
  final String userId;
  final String addressType;
  final String firstName;
  final String lastName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAddress({
    this.id,
    required this.userId,
    this.addressType = 'home',
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'India',
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2?.isNotEmpty == true) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id']?.toString(),
      userId: json['user']?.toString() ?? '',
      addressType: json['address_type'] ?? 'home',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['address_line_1'] ?? '',
      addressLine2: json['address_line_2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? 'India',
      isDefault: json['is_default'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'address_type': addressType,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UserPreference {
  final String userId;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;
  final bool marketingEmails;
  final String language;
  final String currency;
  final String timezone;
  final bool profileVisibility;
  final bool showOnlineStatus;
  final String? defaultShippingAddressId;
  final String? defaultBillingAddressId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPreference({
    required this.userId,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.pushNotifications = true,
    this.marketingEmails = false,
    this.language = 'en',
    this.currency = 'INR',
    this.timezone = 'Asia/Kolkata',
    this.profileVisibility = true,
    this.showOnlineStatus = true,
    this.defaultShippingAddressId,
    this.defaultBillingAddressId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      userId: json['user']?.toString() ?? '',
      emailNotifications: json['email_notifications'] ?? true,
      smsNotifications: json['sms_notifications'] ?? false,
      pushNotifications: json['push_notifications'] ?? true,
      marketingEmails: json['marketing_emails'] ?? false,
      language: json['language'] ?? 'en',
      currency: json['currency'] ?? 'INR',
      timezone: json['timezone'] ?? 'Asia/Kolkata',
      profileVisibility: json['profile_visibility'] ?? true,
      showOnlineStatus: json['show_online_status'] ?? true,
      defaultShippingAddressId: json['default_shipping_address']?.toString(),
      defaultBillingAddressId: json['default_billing_address']?.toString(),
      createdAt: date_utils.DateUtils.safeParseDate(json['created_at']),
      updatedAt: date_utils.DateUtils.safeParseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'email_notifications': emailNotifications,
      'sms_notifications': smsNotifications,
      'push_notifications': pushNotifications,
      'marketing_emails': marketingEmails,
      'language': language,
      'currency': currency,
      'timezone': timezone,
      'profile_visibility': profileVisibility,
      'show_online_status': showOnlineStatus,
      'default_shipping_address': defaultShippingAddressId,
      'default_billing_address': defaultBillingAddressId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
