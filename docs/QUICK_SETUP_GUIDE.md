# ⚡ Quick Setup Guide - Services Essentiels Beta

## 🎯 Setup Rapide (2-3 heures)

Guide condensé pour configurer uniquement l'essentiel pour lancer la beta.

---

## 1️⃣ Stripe (30 min) 💳

```bash
# 1. Créer compte
https://dashboard.stripe.com/register

# 2. Récupérer clés
Dashboard → Developers → API keys
- Publishable key (pk_test_xxx) → frontend/lib/core/config/app_config.dart
- Secret key (sk_test_xxx) → env/dev/backend.env

# 3. Créer produits
Products → Add product
- Premium Mensuel: €9.99/mois
- Premium Saisonnier: €29.99/3 mois

# 4. Webhook
Developers → Webhooks → Add endpoint
URL: https://qzpinzxiqupetortbczh.supabase.co/functions/v1/stripe-webhook-enhanced
Events: payment_intent.succeeded, customer.subscription.*
Secret (whsec_xxx) → env/dev/backend.env
```

---

## 2️⃣ PostHog (15 min) 📊

```bash
# 1. Créer compte
https://eu.posthog.com/signup

# 2. Récupérer API key
Project Settings → API Keys → Copy (phc_xxx)  
→ env/dev/backend.env: POSTHOG_API_KEY
→ frontend/lib/core/config/app_config.dart: posthog_api_key

# 3. Host
https://eu.posthog.com → posthog_host
```

---

## 3️⃣ Firebase (45 min) 🔥

```bash
# 1. Créer projet
https://console.firebase.google.com → Add project → "CrewSnow"

# 2. iOS App
Add app → iOS
Bundle ID: com.crewsnow.app.dev
Télécharger GoogleService-Info.plist
→ Copier dans frontend/ios/Runner/

# 3. Android App  
Add app → Android
Package: com.crewsnow.app.dev
Télécharger google-services.json
→ Copier dans frontend/android/app/

# 4. Activer Crashlytics
Build → Crashlytics → Enable
Suivre instructions iOS + Android

# 5. Activer Cloud Messaging
Build → Cloud Messaging → Enable
iOS: Upload APNs key (si disponible)
```

---

## 4️⃣ Google Play Console (1h) 🤖

```bash
# 1. Créer compte ($25 one-time)
https://play.google.com/console → Pay $25

# 2. Créer app
Create app → "CrewSnow" → Free app

# 3. Store listing
Store presence → Main store listing
- Titre: CrewSnow
- Description: (voir store_assets/google_play/release_notes.txt)
- Icône: 512x512px
- Screenshots: Min 2

# 4. Internal testing
Release → Testing → Internal testing
Create release → Upload AAB
Ajouter testeurs (emails)

# 5. Service account (Fastlane)
Setup → API access → Create service account
Télécharger JSON → fastlane/api-key.json
```

---

## 5️⃣ Email Service (30 min) 📧

```bash
# Option 1: SendGrid (gratuit 100 emails/jour)
https://sendgrid.com → Sign up
Settings → API Keys → Create key
→ env/dev/backend.env: SENDGRID_API_KEY

# Option 2: Supabase Auth (gratuit, limité)
Utiliser emails Supabase Auth directement
Pas de config supplémentaire
```

---

## 6️⃣ Slack (15 min) 💬

```bash
# 1. Créer workspace
https://slack.com/create → "CrewSnow Beta"

# 2. Créer channels
#general, #bugs, #deployments

# 3. Webhook
Apps → Incoming Webhooks → Add to Slack
Choisir #deployments
Copier URL → env/dev/backend.env: SLACK_WEBHOOK_URL
```

---

## 7️⃣ Domain & Email (1h) 🌐

```bash
# 1. Acheter domaine
Namecheap/Google Domains → crewsnow.com (~$10/an)

# 2. Email professionnel
Option A: Zoho Mail (gratuit 5 users)
Option B: Google Workspace ($6/user/mois)
Option C: Email forwarding (gratuit)

# 3. Créer adresses
support@crewsnow.com
beta@crewsnow.com
hello@crewsnow.com
```

---

## ✅ Checklist Rapide

### Minimum Beta (2h)
- [ ] Stripe (paiements)
- [ ] PostHog (analytics)
- [ ] Firebase (crashlytics)
- [ ] Google Play Console (Android beta)

### Recommandé (3h)
- [ ] Email Service (support)
- [ ] Slack (communication)
- [ ] Domain (professionnel)

### Optionnel
- [ ] App Store Connect (iOS - $99/an)
- [ ] Sentry (alternative crash)
- [ ] n8n (workflows)

---

## 🔧 Variables à Configurer

### env/dev/backend.env
```bash
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
POSTHOG_API_KEY=phc_xxx
SENDGRID_API_KEY=SG.xxx
SLACK_WEBHOOK_URL=https://hooks.slack.com/xxx
```

### frontend/lib/core/config/app_config.dart
```dart
'stripe_publishable_key': 'pk_test_xxx',
'posthog_api_key': 'phc_xxx',
'posthog_host': 'https://eu.posthog.com',
```

---

## 🚀 Test Final

```bash
# 1. Vérifier toutes clés configurées
grep -r "xxx\|test_key\|example" env/ frontend/lib/core/config/

# 2. Build Android
cd frontend
./scripts/build-android.sh dev release

# 3. Installer et tester
adb install build/app/outputs/flutter-apk/app-dev-release.apk

# 4. Vérifier services
- Stripe: Test payment
- PostHog: Voir events
- Firebase: Tester crash
- FCM: Envoyer notification
```

---

**🎯 Une fois ces 7 services configurés, beta ready ! ⛷️**
