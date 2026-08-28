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
  Future<String?> getToken() => _safeRead(_tokenKey);

  // Salvar dados do usuário (como JSON)
  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  // Obter dados do usuário
  Future<String?> getUser() => _safeRead(_userKey);

  // Limpar todos os dados (logout)
  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (_) {}
  }

  // Verificar se está logado
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Leitura resiliente do secure storage. Se a leitura falhar (ex.: a chave
  /// do Android Keystore se perde ao reinstalar o app sobre dados antigos),
  /// reseta o storage e trata como "sem valor" — evitando travar o app.
  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }
}
