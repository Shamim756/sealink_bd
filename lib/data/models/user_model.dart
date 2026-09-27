class UserModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String role;
  final bool emailVerified;
  final bool phoneVerified;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.emailVerified,
    required this.phoneVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        name: j['name'],
        username: j['username'],
        email: j['email'],
        phone: j['phone'],
        role: j['role'],
        emailVerified: j['emailVerified'] ?? false,
        phoneVerified: j['phoneVerified'] ?? false,
      );
}