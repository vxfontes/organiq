# Release v0.3.0

Rebrand do produto para **Organiq** e migração completa de notificações de `ntfy` para **push notifications com Firebase Cloud Messaging (FCM)**.

## Novidades
- **Marca:** o nome visível do app foi atualizado para `Organiq` em Android, iOS e widget, junto com textos institucionais e comunicações do produto.
- **Push Notifications:** o app e o backend deixaram de usar `ntfy` e agora usam `FCM`, com suporte a Android e iOS.
- **iOS/Widget:** ajustes de bundle ids, App Group e configuração do widget para alinhar a nova identidade do app.
- **Infra Firebase:** integração com `firebase_core`, `firebase_messaging` e Firebase Admin SDK no backend.

## Backend
- **Envio de push:** substituição do cliente `ntfy` por cliente FCM no backend Go.
- **Registro de dispositivos:** o endpoint `/v1/devices/token` passou a registrar `pushToken` em vez de tópico `ntfy`.
- **Entrega resiliente:** tokens inválidos agora são desativados automaticamente quando o FCM rejeita o envio.
- **Teste de push:** o endpoint `/v1/notifications/test` agora considera sucesso quando ao menos um dispositivo válido recebe a notificação.

## App
- **Registro de token:** o app sincroniza o token FCM do dispositivo com o backend após autenticação e refresh do token.
- **Foreground push:** comportamento ajustado para evitar notificações duplicadas no iOS com o app aberto.
- **Configurações:** a área de notificações do dispositivo foi simplificada; o token não é mais exposto para o usuário, mas o botão de teste foi mantido.
- **Bootstrap Firebase:** inicialização do Firebase/FCM adicionada ao startup do app.

## Banco
- **Migração 0.3.0:** a pasta [db/0.3.0](/Users/vanessa/Desktop/coding/personal/inbota/db/0.3.0) consolida a transição para `push_token`.
- **Limpeza de legado:** tokens antigos no formato `inbota_*` e `organiq_*` ficam inativos para não quebrar os primeiros envios via FCM.

## Observações de rollout
- **Firebase iOS/Android:** exige `google-services.json`, `GoogleService-Info.plist` e `firebase_options.dart` configurados fora do git.
- **Backend:** exige `GOOGLE_APPLICATION_CREDENTIALS` apontando para a service account do Firebase Admin.
- **Apple:** push no iOS depende de App IDs, App Group e APNs configurados no Apple Developer.
