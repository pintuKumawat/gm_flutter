/// Response model for Customer Profile API (`GET /api/me`)
class UserProfileResponse {
  final bool success;
  final String? message;
  final UserModel? user;

  UserProfileResponse({
    required this.success,
    this.message,
    this.user,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (user != null) 'user': user!.toJson(),
    };
  }
}

/// User details model returned by `/api/me`
class UserModel {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? userRole;
  final String? createdDate;
  final dynamic isActive;

  UserModel({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.userRole,
    this.createdDate,
    this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      userRole: json['user_role'] as String?,
      createdDate: json['created_date'] as String?,
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'user_role': userRole,
      'created_date': createdDate,
      'is_active': isActive,
    };
  }

  /// Helper to get formatted full name
  String get fullName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : 'User';
  }
}
