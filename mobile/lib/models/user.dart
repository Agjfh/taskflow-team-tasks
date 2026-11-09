class User {
  User({required this.id, required this.name, required this.email, this.phone});

  final int id;
  final String name;
  final String email;
  final String? phone;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
      );
}
