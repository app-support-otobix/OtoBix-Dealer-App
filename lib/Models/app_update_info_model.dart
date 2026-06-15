class AppUpdateInfoModel {
  String? id;
  String appKey;
  bool enabled;
  PlatformType android;
  PlatformType ios;
  DateTime? updatedAt;

  AppUpdateInfoModel({
    this.id,
    required this.appKey,
    required this.enabled,
    required this.android,
    required this.ios,
    this.updatedAt,
  });

  factory AppUpdateInfoModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfoModel(
      id: (json['_id'] ?? '').toString(),
      appKey: (json['appKey'] ?? '').toString(),
      enabled: json['enabled'] == true,
      android: PlatformType.fromJson(json['android'] ?? {}),
      ios: PlatformType.fromJson(json['ios'] ?? {}),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "appKey": appKey,
    "enabled": enabled,
    "android": android.toJson(),
    "ios": ios.toJson(),
  };
}

class PlatformType {
  String packageName;
  String latestVersion;
  String minSupportedVersion;
  String storeUrl;
  String releaseNotes;

  PlatformType({
    required this.packageName,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.storeUrl,
    required this.releaseNotes,
  });

  factory PlatformType.fromJson(Map<String, dynamic> json) {
    return PlatformType(
      packageName: (json['packageName'] ?? '').toString(),
      latestVersion: (json['latestVersion'] ?? '').toString(),
      minSupportedVersion: (json['minSupportedVersion'] ?? '').toString(),
      storeUrl: (json['storeUrl'] ?? '').toString(),
      releaseNotes: (json['releaseNotes'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "packageName": packageName,
    "latestVersion": latestVersion,
    "minSupportedVersion": minSupportedVersion,
    "storeUrl": storeUrl,
    "releaseNotes": releaseNotes,
  };
}
