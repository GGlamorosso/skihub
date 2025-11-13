# 📋 Checklist finale - Configuration environnement CrewSnow

## ✅ **Ce qui a été fait automatiquement**

- [x] **CLI Supabase** installée (via `npx supabase`)
- [x] **Structure Supabase** créée (`supabase/` avec config, migrations, seed)
- [x] **Scripts helper** pour DEV/PROD (`scripts/supabase-*.sh`)
- [x] **Documentation complète** (`supabase/README.md`, `docs/cicd-github-setup.md`)
- [x] **.gitignore sécurisé** (protection des `.env*`)
- [x] **Script use-env.sh** pour charger les variables
- [x] **Template env** (`env.example.txt`)

## 🔄 **Actions manuelles requises**

### 1. **Créer les fichiers .env à la racine**

```bash
cd /Users/user/Desktop/SKIAPP/crewsnow

# Créer le fichier public (OK côté client)
cat > .env.dev << 'EOF'
# === Supabase public (DEV) ===
SUPABASE_URL=https://qzpinzxiqupetortbczh.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6cGluenhpcXVwZXRvcnRiY3poIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NDg4NjQsImV4cCI6MjA3ODUyNDg2NH0.LRM-2lME0KWXXUkQE8MQgTXDi_lRxdWrt51Xm3i7ONU

# === Flags produit (DEV) ===
ENV=dev
FEATURE_TRACKER_ENABLED=true
FEATURE_CREW_MODE=true
FEATURE_PING_STATION=true
EOF

# Créer le fichier serveur (⚠️ SECRETS)
cat > .env.server.dev << 'EOF'
# === Supabase serveur (DEV) - ⚠️ JAMAIS côté mobile/web ===
SUPABASE_URL=https://qzpinzxiqupetortbczh.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6cGluenhpcXVwZXRvcnRiY3poIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mjk0ODg2NCwiZXhwIjoyMDc4NTI0ODY0fQ.hHv0ytEGwRMQ_27K-ZyUdghBBiYZto7wKZLXbGXTtOI
SUPABASE_PROJECT_REF=qzpinzxiqupetortbczh
SUPABASE_DB_PASSWORD=CrewSnowR&L.corp

# === Webhooks & Intégrations (DEV) ===
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
N8N_BASE_URL=https://n8n-dev.example.com
N8N_AUTH_TOKEN=...
MODERATION_API_KEY=...

# === Observabilité (DEV) ===
POSTHOG_API_KEY=...
POSTHOG_HOST=https://eu.posthog.com
SENTRY_DSN=...

# === Flags produit (DEV) ===
ENV=dev
RLS_ENFORCED=true
ALLOW_SIGNUPS=true
EOF
```

### 2. **Se connecter à Supabase CLI**

```bash
# Ouvrez votre terminal et exécutez :
cd /Users/user/Desktop/SKIAPP/crewsnow
npx supabase login
```

**Où récupérer l'Access Token :**
1. https://supabase.com/dashboard
2. Profil (en haut à droite) → Access Tokens
3. Generate new token → copiez-le → collez dans le terminal

### 3. **Lier le projet DEV**

```bash
./scripts/supabase-link-dev.sh
```

### 4. **Tester la configuration**

```bash
# Vérifier le statut
./scripts/supabase-status.sh

# Tester l'API REST
source .env.dev
curl -i "$SUPABASE_URL/rest/v1/" \\
  -H "apikey: $SUPABASE_ANON_KEY" \\
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

## 🎯 **Usage quotidien**

### **Flutter (mobile)**
```bash
# Charger les variables DEV
source .env.dev

# Lancer l'app avec les bonnes variables
flutter run \\
  --dart-define=SUPABASE_URL=$SUPABASE_URL \\
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

### **Backend/CLI**
```bash
# Charger les secrets serveur
source .env.server.dev

# Utiliser la CLI Supabase
npx supabase db push
npx supabase gen types typescript --local > types/supabase.ts
```

### **Script helper**
```bash
# Charger automatiquement les bonnes variables
bash scripts/use-env.sh dev mobile    # pour Flutter
bash scripts/use-env.sh dev backend   # pour serveur
```

## 🚀 **Basculer vers PROD (plus tard)**

```bash
# Créer .env.prod et .env.server.prod avec les clés PROD
# Puis :
./scripts/supabase-link-prod.sh
```

## 🔐 **Configuration GitHub Actions**

Suivez le guide : `docs/cicd-github-setup.md`

**Secrets à ajouter dans GitHub :**
- `SUPABASE_URL_DEV` / `SUPABASE_URL_PROD`
- `SUPABASE_ANON_KEY_DEV` / `SUPABASE_ANON_KEY_PROD`  
- `SERVICE_ROLE_KEY_DEV` / `SERVICE_ROLE_KEY_PROD`
- `PROJECT_REF_DEV` / `PROJECT_REF_PROD`
- `SUPABASE_ACCESS_TOKEN`

## ✅ **Validation finale**

Une fois les actions manuelles terminées :

- [ ] `.env.dev` créé et fonctionnel
- [ ] `.env.server.dev` créé avec secrets
- [ ] `npx supabase login` réussi  
- [ ] `./scripts/supabase-link-dev.sh` réussi
- [ ] `./scripts/supabase-status.sh` montre DEV lié
- [ ] Test API REST réussi
- [ ] Variables chargées avec `scripts/use-env.sh`

🎉 **Votre environnement CrewSnow est prêt pour le développement !**
