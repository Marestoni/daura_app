import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class LoginController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _error;
  UserModel? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get user => _user;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔵 Tentando login com: $email');
      final user = await _authService.login(email, password);
      print('✅ Login bem-sucedido: ${user.name}');
      _user = user;
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ Erro no login: $e');
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // ✅ Método para logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  // ✅ Verificar se está logado
  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  // ✅ Carregar usuário salvo
  Future<void> loadSavedUser() async {
    final user = await _authService.getSavedUser();
    if (user != null) {
      _user = user;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
