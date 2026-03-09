-- Cria preferências padrão para todos os usuários existentes
INSERT INTO inbota.notification_preferences (user_id)
SELECT id FROM inbota.users
ON CONFLICT (user_id) DO NOTHING;

-- Seed: templates de mensagens por tipo e gatilho
-- Placeholders suportados: {{title}}, {{lead_mins}}
INSERT INTO inbota.notification_templates (type, trigger_key, title_template, body_template) VALUES
    ('reminder', 'at_time',       '{{title}}', 'Lembrete agora'),
    ('reminder', 'lead_time',     '{{title}}', 'Lembrete em {{lead_mins}} minutos'),
    ('event',    'at_time',       '{{title}}', 'Evento começando agora'),
    ('event',    'lead_time',     '{{title}}', 'Evento em {{lead_mins}} minutos'),
    ('event',    'lead_time_day', '{{title}}', 'Evento amanhã'),
    ('task',     'at_time',       '{{title}}', 'Tarefa vence agora'),
    ('task',     'lead_time',     '{{title}}', 'Tarefa vence em {{lead_mins}} minutos'),
    ('task',     'lead_time_day', '{{title}}', 'Tarefa vence amanhã'),
    ('routine',  'at_time',       '{{title}}', 'Hora da sua rotina'),
    ('routine',  'lead_time',     '{{title}}', 'Rotina em {{lead_mins}} minutos')
ON CONFLICT (type, trigger_key) DO NOTHING;

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
