const defaultCodeMessages: Record<string, string> = {
  missing_required_fields: "Campos obrigatórios ausentes.",
  connection_refused: "Sem conexão com o servidor.",
  timeout: "Tempo de conexão esgotado.",
  invalid_status: "Status inválido.",
  invalid_source: "Origem inválida.",
  invalid_type: "Tipo inválido.",
  invalid_payload: "Dados inválidos. Verifique os campos.",
  invalid_time_range: "Intervalo de tempo inválido.",
  invalid_email: "E-mail inválido.",
  invalid_password: "Senha inválida.",
  invalid_display_name: "Nome de exibição inválido.",
  invalid_weekday: "Dia da semana inválido.",
  routine_overlap: "Já existe uma rotina neste horário em um dos dias selecionados.",
  routine_exception_failed: "Não foi possível registrar exceção na rotina.",
  uncomplete_failed: "Não foi possível desmarcar a rotina.",
  invalid_credentials: "Credenciais inválidas.",
  invalid_limit: "Limite inválido.",
  invalid_cursor: "Cursor inválido.",
  not_found: "Recurso não encontrado.",
  dependency_missing: "Dependência necessária não configurada.",
  invalid_auth_header: "Cabeçalho de autorização inválido.",
  invalid_token: "Token inválido.",
  invalid_claims: "Token com dados inválidos.",
  missing_sub: "Usuário não identificado no token.",
  missing_jwt_secret: "Erro de configuração de segurança (JWT).",
  unauthorized: "Não autorizado.",
  internal_error: "Erro interno do servidor.",
  no_active_devices: "Nenhum dispositivo ativo encontrado para este usuário.",
  notification_send_failed: "Não foi possível enviar a notificação.",
};

export function mapErrorCode(
  code?: string,
  overrides: Record<string, string> = {},
): string {
  if (!code) {
    return "Erro inesperado.";
  }

  return overrides[code] || defaultCodeMessages[code] || code;
}
