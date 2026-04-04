INSERT INTO organiq.app_config (key, value, description)
VALUES
    ('app.version.min_mandatory', '0.7.1', 'Versão mínima obrigatória para uso do app'),
    ('app.version.latest_suggested', '0.8.0', 'Versão mais recente sugerida para os usuários'),
    ('app.store.android.url', 'https://play.google.com/store/apps/details?id=com.organiq.app', 'Link da Play Store'),
    ('app.store.ios.url', 'https://apps.apple.com/app/organiq/id123456789', 'Link da App Store')
ON CONFLICT (key) DO NOTHING;

commit;
