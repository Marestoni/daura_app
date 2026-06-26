import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Salvar token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Obter token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Salvar dados do usuário (como JSON)
  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  // Obter dados do usuário
  Future<String?> getUser() async {
    return await _storage.read(key: _userKey);
  }

  // Limpar todos os dados (logout)
  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  // Verificar se está logado
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
