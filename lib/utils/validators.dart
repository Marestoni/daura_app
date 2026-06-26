class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Digite seu e-mail';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'E-mail inválido';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Digite sua senha';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}