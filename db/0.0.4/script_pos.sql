-- Cria preferências padrão para todos os usuários existentes
INSERT INTO inbota.notification_preferences (user_id)
SELECT id FROM inbota.users
ON CONFLICT (user_id) DO NOTHING;
