# App Mobile (Flutter)

## Lancer en dev
```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

## 4.6 Exemples d’env (NE METS PAS DE VRAIES CLÉS)
`env/dev/backend.env.example`
```env
SUPABASE_PROJECT_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=dev_anon_key
SUPABASE_SERVICE_ROLE_KEY=dev_service_role_key
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_SECRET_KEY=sk_test_xxx
