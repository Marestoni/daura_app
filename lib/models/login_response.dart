import 'user_model.dart'; // ✅ Certifique-se que esta linha existe

class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 Parseando LoginResponse: $json');

    // Pega o token
    final token = json['accessToken'] ?? json['token'];

    // Pega o usuário
    UserModel? user;
    if (json['user'] != null) {
      user = UserModel.fromJson(json['user']);
    }

    // Considera sucesso se tiver usuário
    final success = json['success'] ?? (user != null);

    return LoginResponse(
      success: success,
      message: json['message'] ?? json['msg'] ?? 'Login realizado com sucesso!',
      token: token,
      user: user,
    );
  }
}
