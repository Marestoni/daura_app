class Constants {
  static const String appName = 'Gestão Daura';

  // ✅ CELULAR FÍSICO NA REDE (Wi-Fi) — IP do PC onde a API roda:
  static const String baseUrl = 'http://192.168.2.11:3000/api';

  // Emulador Android:
  // static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Web (Chrome):
  // static const String baseUrl = 'http://localhost:3000/api';

  static const String loginEndpoint = '/auth/login';
  static const int minPasswordLength = 6;
}
