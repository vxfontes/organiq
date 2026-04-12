import 'package:shared_preferences/shared_preferences.dart';

// AppPreferences — ponto de acesso global à instância de SharedPreferences.
//
// SharedPreferences.getInstance() é assíncrono e precisa ser chamado após
// WidgetsFlutterBinding.ensureInitialized(). A inicialização é feita uma
// única vez em main(), antes do runApp, e a instância fica disponível para
// todo o grafo de dependências sem precisar ser passada via construtor.
class AppPreferences {
  AppPreferences._();

  static late final SharedPreferences _instance;

  static SharedPreferences get instance => _instance;

  static Future<void> initialize() async {
    _instance = await SharedPreferences.getInstance();
  }
}
