class SocialLoginModel {
  final String authProvider; // 'google', 'facebook', 'apple'
  final String socialId;
  final String userName;
  final String email;
  final String? image;
  final String? fcmToken;
  final String? token;

  // This app build's own store (CurrentStoreService.storeId) — makes this a
  // genuinely separate, store-scoped buyer account server-side (see backend
  // AuthService.emailScope), not the legacy apex-wide account. Omitted only
  // on an unconfigured/default build where CurrentStoreService never resolves.
  final String? storeId;

  SocialLoginModel({
    required this.authProvider,
    required this.socialId,
    required this.userName,
    required this.email,
    this.image,
    this.fcmToken,
    this.token,
    this.storeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'authProvider': authProvider,
      'socialId': socialId,
      'userName': userName,
      'email': email,
      if (image != null) 'image': image,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (token != null) 'token': token,
      if (storeId != null) 'storeId': storeId,
    };
  }
}
