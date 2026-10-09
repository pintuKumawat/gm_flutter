import 'package:grahmitracus/core/config/env_config.dart';

/// Model representing a Spotlight Offer Banner / Ad from `/api/spotlight`.
class SpotlightBannerModel {
  final int id;
  final String title;
  final String? imagePath;
  final String? mobileImagePath;
  final String? desktopImagePath;
  final String? targetUrl;
  final String? displayLocation;
  final int? categoryGroupId;
  final int? isActive;

  const SpotlightBannerModel({
    required this.id,
    required this.title,
    this.imagePath,
    this.mobileImagePath,
    this.desktopImagePath,
    this.targetUrl,
    this.displayLocation,
    this.categoryGroupId,
    this.isActive,
  });

  /// Formatted image URL
  String? get fullImageUrl {
    final raw = mobileImagePath ?? imagePath ?? desktopImagePath;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = EnvConfig.baseUrl.endsWith('/')
        ? EnvConfig.baseUrl.substring(0, EnvConfig.baseUrl.length - 1)
        : EnvConfig.baseUrl;
    final cleanPath = raw.startsWith('/') ? raw : '/$raw';
    return '$base$cleanPath';
  }

  factory SpotlightBannerModel.fromJson(Map<String, dynamic> json) {
    return SpotlightBannerModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] as String? ?? 'Special Offer',
      imagePath: json['image_path'] as String?,
      mobileImagePath: (json['mobile_image_path'] ?? json['mobileImagePath']) as String?,
      desktopImagePath: (json['desktop_image_path'] ?? json['desktopImagePath']) as String?,
      targetUrl: (json['target_url'] ?? json['targetUrl']) as String?,
      displayLocation: (json['display_location'] ?? json['displayLocation']) as String?,
      categoryGroupId: json['category_group_id'] is int
          ? json['category_group_id'] as int
          : int.tryParse(json['category_group_id']?.toString() ?? ''),
      isActive: json['is_active'] is int
          ? json['is_active'] as int
          : int.tryParse(json['is_active']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image_path': imagePath,
        'mobile_image_path': mobileImagePath,
        'desktop_image_path': desktopImagePath,
        'target_url': targetUrl,
        'display_location': displayLocation,
        'category_group_id': categoryGroupId,
        'is_active': isActive,
      };
}
