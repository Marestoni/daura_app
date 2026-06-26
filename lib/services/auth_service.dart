import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class AuthService {
  final http.Client _client = http.Client();
  final StorageService _storage = StorageService();

  Future<UserModel> login(String email, String password) async {
    try {
      print(
        '📡 Enviando requisição para: ${Constants.baseUrl}${Constants.loginEndpoint}',
      );

      final url = Uri.parse('${Constants.baseUrl}${Constants.loginEndpoint}');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('📡 Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final loginResponse = LoginResponse.fromJson(data);

        if (loginResponse.user != null) {
          // ✅ Salvar token e usuário
          if (loginResponse.token != null) {
            await _storage.saveToken(loginResponse.token!);
          }
          await _storage.saveUser(jsonEncode(loginResponse.user!.toJson()));

          print('✅ Login bem-sucedido: ${loginResponse.user!.name}');
          return loginResponse.user!;
        } else {
          throw Exception(loginResponse.message);
        }
      } else if (response.statusCode == 401) {
        throw Exception('E-mail ou senha inválidos');
      } else {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Erro ao fazer login';
        throw Exception(message);
      }
    } on http.ClientException catch (e) {
      print('❌ Erro de conexão: $e');
      throw Exception('Erro de conexão com o servidor');
    } catch (e) {
      print('❌ Erro geral: $e');
      rethrow;
    }
  }

  // ✅ Método para logout
  Future<void> logout() async {
    await _storage.clearAll();
  }

  // ✅ Verificar se está logado
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  // ✅ Obter usuário salvo
  Future<UserModel?> getSavedUser() async {
    final userJson = await _storage.getUser();
    if (userJson == null) return null;
    try {
      final Map<String, dynamic> data = jsonDecode(userJson);
      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
