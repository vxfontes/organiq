import 'package:connectivity_plus/connectivity_plus.dart';

// ConnectivityService — verifica disponibilidade de rede no momento da chamada.
//
// Importante: connectivity_plus reporta o tipo de interface (wifi, mobile,
// ethernet) mas NÃO garante acesso à internet de fato. Para o padrão
// cache-first adotado aqui, isso é suficiente: se não há interface ativa,
// servimos do cache; se há interface, tentamos a API e tratamos falha de rede
// via ExceptionMapper (que já cobre DioException e SocketException).
//
// A verificação é point-in-time (não reativa) porque os repositórios decidem
// a estratégia a cada chamada, sem precisar de stream contínuo de estado.

abstract class IConnectivityService {
  /// Retorna true se há pelo menos uma interface de rede ativa.
  Future<bool> isOnline();
}

class ConnectivityService implements IConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      // Em caso de erro na verificação, assume online para não bloquear
      // o acesso à API desnecessariamente; o repositório tratará falha de rede.
      return true;
    }
  }
}
