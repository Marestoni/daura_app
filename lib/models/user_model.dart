class UserModel {
  final String id; // ✅ DEVE SER String, NÃO String?
  final String name;
  final String email;
  final String? role;
  final String? avatar;

  UserModel({
    required this.id, // ✅ REQUIRED
    required this.name,
    required this.email,
    this.role,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('🔍 Parseando UserModel: $json');

    // ✅ GARANTIR QUE O ID SEJA EXTRAÍDO CORRETAMENTE
    String id = '';

    // Tenta diferentes nomes de campo
    if (json['id'] != null) {
      id = json['id'].toString();
    } else if (json['_id'] != null) {
      id = json['_id'].toString();
    } else if (json['userId'] != null) {
      id = json['userId'].toString();
    }

    print('🔍 ID extraído: "$id"');
    print('🔍 ID está vazio? ${id.isEmpty}');

    if (id.isEmpty) {
      print('⚠️ ATENÇÃO: ID está vazio! Verifique o JSON da API.');
    }

    final name = json['name'] ?? json['nome'] ?? 'Usuário';
    final email = json['email'] ?? '';
    final role = json['role'] ?? json['cargo'];
    final avatar = json['avatar'] ?? json['profileImage'];

    return UserModel(
      id: id,
      name: name,
      email: email,
      role: role,
      avatar: avatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar,
    };
  }
}
