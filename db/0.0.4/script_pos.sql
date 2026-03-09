-- Cria preferências padrão para todos os usuários existentes
INSERT INTO inbota.notification_preferences (user_id)
SELECT id FROM inbota.users
ON CONFLICT (user_id) DO NOTHING;

-- Garante token para quem já tinha prefs antes do campo existir (segurança / idempotência)
UPDATE inbota.notification_preferences
SET daily_summary_token = gen_random_uuid()::text
WHERE daily_summary_token IS NULL OR daily_summary_token = '';

-- Seed: templates de mensagens por tipo e gatilho
-- Placeholders suportados: {{title}}, {{lead_mins}}
INSERT INTO inbota.notification_templates (type, trigger_key, title_template, body_template) VALUES
    ('reminder', 'at_time',       'Lembrete agora', '{{title}}'),
    ('reminder', 'lead_time',     'Lembrete em {{lead_mins}} minutos', '{{title}}'),
    ('event',    'at_time',       'Evento começando', '{{title}} começa agora.'),
    ('event',    'lead_time',     'Evento em {{lead_mins}} minutos', '{{title}} começa em {{lead_mins}} minutos.'),
    ('event',    'lead_time_day', 'Evento amanhã', '{{title}} começa amanhã.'),
    ('task',     'at_time',       'Prazo agora', '{{title}} vence agora.'),
    ('task',     'lead_time',     'Prazo em {{lead_mins}} minutos', '{{title}} vence em {{lead_mins}} minutos.'),
    ('task',     'lead_time_day', 'Prazo amanhã', '{{title}} vence amanhã.'),
    ('routine',  'at_time',       'Hora da rotina', '{{title}} começa agora.'),
    ('routine',  'lead_time',     'Rotina em {{lead_mins}} minutos', '{{title}} começa em {{lead_mins}} minutos.')
ON CONFLICT (type, trigger_key) DO NOTHING;
commit;

-- Seed: configurações do scheduler e notificações
INSERT INTO inbota.app_config (key, value, description) VALUES
    ('scheduler.ticker_interval_seconds', '60',
        'Intervalo de execução do scheduler em segundos'),
    ('scheduler.reminder_lookahead_hours', '2',
        'Janela de lookahead para reminders (horas)'),
    ('scheduler.event_lookahead_hours', '24',
        'Janela de lookahead para eventos (horas)'),
    ('scheduler.task_lookahead_hours', '24',
        'Janela de lookahead para tasks (horas)'),
    ('scheduler.day_threshold_mins', '1440',
        'Minutos mínimos para usar o template de "dia antes" (ex: amanhã)'),
    ('notification.test_title', 'Teste de Notificação',
        'Título da notificação de teste'),
    ('notification.test_body', 'Isso é um teste do Inbota! 🎉',
        'Corpo da notificação de teste')
ON CONFLICT (key) DO NOTHING;
