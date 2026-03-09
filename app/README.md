# Inbota App (Flutter)

App Flutter do Inbota. Esta pasta contem apenas o app (o backend fica em `../backend`).

## Requisitos
- Flutter 3.35.x
- Dart (via Flutter)

## Rodar local
```bash
cd app
flutter pub get
cp .env.example .env
# edite API_HOST no .env
set -a
source .env
set +a
flutter run --dart-define-from-file=.env
```

## Gerar IPA para iOS (macOS):
```bash
cd app
flutter build ipa --release --dart-define-from-file=.env
flutter build ipa --release --export-method development --dart-define-from-file=.env
```

## Gerar APK para Android:
```bash
cd app
flutter build apk --release --dart-define-from-file=.env
```

## Configuracao
- A base URL da API usa `API_HOST` via `--dart-define` (arquivo: `lib/shared/config/app_env.dart`).
- Nao commite `.env` com valores reais. O repositório inclui apenas `.env.example`.
- Em CI/CD (GitHub Actions, Render etc), defina `API_HOST` como secret/env e rode build com `--dart-define=API_HOST=$API_HOST`.
- Todas as rotas protegidas usam `Authorization: Bearer <token>`.

## Qualidade
```bash
cd app
dart format .
dart analyze
```

## gerar json_serializable
```bash
cd app
find . -name "*.g.dart" -type f -delete
flutter pub run build_runner build --delete-conflicting-outputs
```

## Gerar imagens

1. Abra o SVG no Preview.
2. File > Export... e salve como PNG 1024x1024 em `app/assets/app_icon.png`.

Depois rode:

```bash
flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons.yaml
flutter pub run flutter_native_splash:create
```
