import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  ConnectivityService() {
    _init();
  }

  void _init() {
    // ✅ Verificar imediatamente
    _checkConnection();

    // ✅ Escutar mudanças
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnection(results);
    });
  }

  Future<void> _checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnection(results);
    } catch (e) {
      print('❌ Erro ao verificar conectividade: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void _updateConnection(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected =
        results.isNotEmpty && results.first != ConnectivityResult.none;

    if (_isConnected != wasConnected) {
      notifyListeners();
      print(
        '🌐 Status de conexão: ${_isConnected ? "Conectado" : "Desconectado"}',
      );
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
