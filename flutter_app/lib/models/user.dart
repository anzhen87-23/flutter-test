/// 用户模型
class User {
  final int id;
  final String username;
  final String? phone;
  final String? email;
  final String nickname;
  final String avatarUrl;
  final DateTime? birthday;

  User({
    required this.id,
    required this.username,
    this.phone,
    this.email,
    required this.nickname,
    required this.avatarUrl,
    this.birthday,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      birthday: json['birthday'] != null
          ? DateTime.parse(json['birthday'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phone': phone,
      'email': email,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'birthday': birthday?.toIso8601String(),
    };
  }

  String get displayName => nickname.isNotEmpty ? nickname : username;
  String get account => phone ?? email ?? username;
}
