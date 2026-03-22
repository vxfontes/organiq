INSERT INTO organiq.app_config (key, value, description)
VALUES
    ('ai.create.enabled', 'true', 'Habilita o modo Criar/Organizar com IA no app'),
    ('ai.suggestion.enabled', 'true', 'Habilita o modo Sugerir com IA no app')
ON CONFLICT (key) DO NOTHING;

commit;