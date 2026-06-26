class Constants {
  static const String appName = 'Gestão Daura';

  // PARA ANDROID (EMULADOR) - USE ESTE:
  //static const String baseUrl = 'http://10.0.2.2:3000/api';

  // PARA WEB (CHROME) - DESCOMENTE ESTE:
  static const String baseUrl = 'http://localhost:3000/api';

  // PARA DISPOSITIVO FÍSICO (USB) - USE O IP DA SUA MÁQUINA:
  // static const String baseUrl = 'http://192.168.1.100:3000/api';

  static const String loginEndpoint = '/auth/login';
  static const int minPasswordLength = 6;
}
