class ApiErrorMapper {
  ApiErrorMapper._();

  static const Map<String, String> _defaultCodeMessages = {
    'missing_required_fields': 'Campos obrigatórios ausentes.',
    'connection_refused': 'Sem conexão com o servidor.',
    'timeout': 'Tempo de conexão esgotado.',
    'unknown_error': 'Ocorreu um erro inesperado. Tente novamente.',
    'invalid_status': 'Status inválido.',
    'invalid_source': 'Origem inválida.',
    'invalid_type': 'Tipo inválido.',
    'invalid_payload': 'Dados inválidos. Verifique os campos.',
    'invalid_time_range': 'Intervalo de tempo inválido.',
    'invalid_email': 'E-mail inválido.',
    'invalid_password': 'Senha inválida.',
    'invalid_display_name': 'Nome de exibição inválido.',
    'invalid_weekday': 'Dia da semana inválido.',
    'routine_overlap': 'Já existe uma rotina neste horário em um dos dias selecionados.',
    'routine_exception_failed': 'Não foi possível registrar exceção na rotina.',
    'uncomplete_failed': 'Não foi possível desmarcar a rotina.',
    'invalid_credentials': 'Credenciais inválidas.',
    'invalid_limit': 'Limite inválido.',
    'invalid_cursor': 'Cursor inválido.',
    'not_found': 'Recurso não encontrado.',
    'dependency_missing': 'Serviço temporariamente indisponível. Tente novamente mais tarde.',
    'invalid_auth_header': 'Sua sessão é inválida. Faça login novamente.',
    'invalid_token': 'Sua sessão expirou. Faça login novamente.',
    'invalid_claims': 'Não foi possível validar sua sessão. Faça login novamente.',
    'missing_sub': 'Não foi possível identificar sua conta. Faça login novamente.',
    'missing_token': 'Sua sessão expirou. Faça login novamente.',
    'missing_jwt_secret': 'Não foi possível validar seu acesso agora. Tente novamente mais tarde.',
    'unauthorized': 'Você não tem permissão para acessar este recurso.',
    'internal_error': 'Algo deu errado. Tente novamente em instantes.',
    'no_active_devices': 'Nenhum dispositivo ativo encontrado para este usuário.',
    'notification_send_failed': 'Não foi possível enviar a notificação.',
  };

  static String fromResponseData(
    dynamic data, {
    required String fallbackMessage,
    Map<String, String> codeOverrides = const {},
  }) {
    if (data is Map) {
      final map = data.map((key, value) => MapEntry(key.toString(), value));
      final errorCode = map['error']?.toString();
      if (errorCode != null && errorCode.isNotEmpty) {
        return mapCode(errorCode, overrides: codeOverrides);
      }

      final message = map['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    return fallbackMessage;
  }

  static String mapCode(
    String code, {
    Map<String, String> overrides = const {},
  }) {
    if (overrides.containsKey(code)) {
      return overrides[code]!;
    }
    return _defaultCodeMessages[code] ?? code;
  }
}
