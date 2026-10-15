class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        tokenType: (json['tokenType'] as String?) ?? 'Bearer',
      );

  final String accessToken;
  final String refreshToken;
  final String tokenType;
}
