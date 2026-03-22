INSERT INTO organiq.app_config (key, value, description)
VALUES
    ('ai.create.enabled', 'true', 'Habilita o modo Criar/Organizar com IA no app'),
    ('ai.suggestion.enabled', 'true', 'Habilita o modo Sugerir com IA no app'),
    ('settings.notifications.admin_emails', '[]', 'Lista de e-mails autorizados a ver itens administrativos em Configurações > Notificações')
ON CONFLICT (key) DO NOTHING;

UPDATE organiq.app_config
SET value = '["nessa1vane@gmail.com","nessa1vane@icloud.com"]'
WHERE key = 'settings.notifications.admin_emails';

commit;