class DeviceToken {
  final String token;
  final String? platform;
  final String? appVersion;
  final String? deviceId;
  final String? userType;
  final int? userId;

  DeviceToken({
    required this.token,
    this.platform,
    this.appVersion,
    this.deviceId,
    this.userType,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'token': token,
    };
    
    if (platform != null) data['platform'] = platform;
    if (appVersion != null) data['app_version'] = appVersion;
    if (deviceId != null) data['device_id'] = deviceId;
    if (userType != null) data['user_type'] = userType;
    if (userId != null) data['user_id'] = userId;
    
    return data;
  }

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    return DeviceToken(
      token: json['token'],
      platform: json['platform'],
      appVersion: json['app_version'],
      deviceId: json['device_id'],
      userType: json['user_type'],
      userId: json['user_id'],
    );
  }

  @override
  String toString() {
    return 'DeviceToken{token: $token, platform: $platform, appVersion: $appVersion, deviceId: $deviceId, userType: $userType, userId: $userId}';
  }
}
