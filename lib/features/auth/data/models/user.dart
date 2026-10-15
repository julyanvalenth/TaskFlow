class User {
  const User({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String email;
  final DateTime createdAt;
}
