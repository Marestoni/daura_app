class UserModel {
  final String? id;
  final String name;
  final String email;
  final String? avatar;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name'] ?? json['nome'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}