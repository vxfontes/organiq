class Validators {
  Validators._();

  static String? email(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'Informe seu email.';
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(email)) return 'Email inválido.';
    return null;
  }

  static String? password(String value) {
    final password = value.trim();
    if (password.isEmpty) return 'Informe sua senha.';
    if (password.length < 6) return 'Senha muito curta.';
    return null;
  }

  static String? name(String value) {
    final name = value.trim();
    if (name.isEmpty) return 'Informe seu nome.';
    if (name.length < 2) return 'Nome muito curto.';
    return null;
  }

  static String? localeAndTimezone({
    required String locale,
    required String timezone,
  }) {
    if (locale.isEmpty || timezone.isEmpty) {
      return 'Configuração do dispositivo invalida.';
    }
    return null;
  }
}
