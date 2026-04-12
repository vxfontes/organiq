import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// CacheService — armazenamento local de dados JSON com TTL.
//
// Decisão de lib: shared_preferences com JSON serializado.
//
// Motivos da escolha frente às alternativas:
//   - hive/isar: requerem geração de adaptadores por tipo; exige acoplamento
//     de código gerado a cada modelo do domínio, quebrando a transparência
//     para os usecases e aumentando overhead de build.
//   - sqflite: overhead relacional desnecessário para cache de respostas HTTP
//     que já chegam como JSON; migrações e schema management adicionam
//     complexidade sem benefício real neste caso.
//   - shared_preferences: lib já presente como dependência transitiva em
//     projetos Firebase/Flutter, zero overhead de geração de código, suporta
//     strings arbitrárias (JSON), funciona em Android e iOS sem configuração
//     nativa adicional. A única limitação (sem índice/query) não importa aqui
//     porque o acesso é sempre por chave exata derivada do endpoint.
//
// Contrato de uso nos repositórios:
//   - chave: string derivada do path de API (ex: 'cache:/tasks')
//   - TTL padrão: 5 minutos para listas; pode ser sobrescrito por chamador
//   - o cache armazena o JSON cru que o model já sabe deserializar
//   - usecases não conhecem este serviço — só os repositórios o usam

abstract class ICacheService {
  /// Retorna o dado em cache se a chave existe e o TTL não expirou.
  /// Retorna null se ausente ou expirado.
  Future<Map<String, dynamic>?> get(String key);

  /// Persiste [data] sob [key] com validade de [ttl].
  Future<void> set(
    String key,
    Map<String, dynamic> data, {
    Duration ttl = CacheService.defaultTtl,
  });

  /// Remove uma chave específica do cache.
  Future<void> invalidate(String key);

  /// Remove todo o cache gerenciado por este serviço.
  Future<void> clear();
}

class CacheService implements ICacheService {
  CacheService(this._prefs);

  final SharedPreferences _prefs;

  static const Duration defaultTtl = Duration(minutes: 5);

  // Prefixos internos para separar dados de metadados no SharedPreferences.
  static const String _dataPrefix = '_cache_data:';
  static const String _expiryPrefix = '_cache_expiry:';

  @override
  Future<Map<String, dynamic>?> get(String key) async {
    final expiryMs = _prefs.getInt(_expiryPrefix + key);
    if (expiryMs == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now > expiryMs) {
      // Entrada expirada: remove silenciosamente para liberar espaço.
      await _removeKeys(key);
      return null;
    }

    final raw = _prefs.getString(_dataPrefix + key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      // JSON corrompido — descarta.
      await _removeKeys(key);
      return null;
    }
  }

  @override
  Future<void> set(
    String key,
    Map<String, dynamic> data, {
    Duration ttl = CacheService.defaultTtl,
  }) async {
    final expiryMs =
        DateTime.now().add(ttl).millisecondsSinceEpoch;

    await Future.wait([
      _prefs.setString(_dataPrefix + key, jsonEncode(data)),
      _prefs.setInt(_expiryPrefix + key, expiryMs),
    ]);
  }

  @override
  Future<void> invalidate(String key) async {
    await _removeKeys(key);
  }

  @override
  Future<void> clear() async {
    final allKeys = _prefs.getKeys();
    final cacheKeys = allKeys
        .where((k) => k.startsWith(_dataPrefix) || k.startsWith(_expiryPrefix))
        .toList();

    await Future.wait(cacheKeys.map(_prefs.remove));
  }

  Future<void> _removeKeys(String key) async {
    await Future.wait([
      _prefs.remove(_dataPrefix + key),
      _prefs.remove(_expiryPrefix + key),
    ]);
  }
}
