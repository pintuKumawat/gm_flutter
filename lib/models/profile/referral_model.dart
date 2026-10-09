class ReferralModel {
  final double totalEarned;
  final List<ReferredFriendModel> friends;

  const ReferralModel({
    this.totalEarned = 0.0,
    this.friends = const [],
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total_earned'] ?? 0;
    final totalVal = rawTotal is num
        ? rawTotal.toDouble()
        : double.tryParse(rawTotal.toString()) ?? 0.0;

    final rawList = json['friends'] as List? ?? [];
    final parsedFriends = rawList
        .map((e) => ReferredFriendModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReferralModel(
      totalEarned: totalVal,
      friends: parsedFriends,
    );
  }
}

class ReferredFriendModel {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String createdAt;

  const ReferredFriendModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.phone,
    required this.createdAt,
  });

  factory ReferredFriendModel.fromJson(Map<String, dynamic> json) {
    return ReferredFriendModel(
      id: json['id'] as int? ?? 0,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      createdAt: json['created_date'] as String? ?? 
                 json['created_at'] as String? ?? 
                 DateTime.now().toIso8601String(),
    );
  }

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      return '${firstName!} ${lastName ?? ''}'.trim();
    }
    return phone ?? 'User';
  }

  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      return '${firstName![0]}${lastName != null && lastName!.isNotEmpty ? lastName![0] : ''}'.toUpperCase();
    }
    if (phone != null && phone!.isNotEmpty) {
      return phone![0];
    }
    return 'U';
  }
}
