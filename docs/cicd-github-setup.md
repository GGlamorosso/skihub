# Configuration CI/CD GitHub Actions - CrewSnow

## 🔐 Secrets GitHub à configurer

Allez dans **Repo → Settings → Secrets and variables → Actions**

### 🔧 Secrets DEV

| Nom | Valeur | Usage |
|-----|--------|-------|
| `SUPABASE_URL_DEV` | `https://qzpinzxiqupetortbczh.supabase.co` | URL API DEV |
| `SUPABASE_ANON_KEY_DEV` | `eyJhbGciOiJIUzI1Ni...` | Clé publique DEV |
| `SERVICE_ROLE_KEY_DEV` | `eyJhbGciOiJIUzI1Ni...` | ⚠️ Clé serveur DEV |
| `PROJECT_REF_DEV` | `qzpinzxiqupetortbczh` | Project ID DEV |
| `SUPABASE_DB_PASSWORD_DEV` | `CrewSnowR&L.corp` | Mot de passe DB DEV |

### 🚀 Secrets PROD

| Nom | Valeur | Usage |
|-----|--------|-------|
| `SUPABASE_URL_PROD` | `https://ahxezvuxxqfwgztivfle.supabase.co` | URL API PROD |
| `SUPABASE_ANON_KEY_PROD` | `eyJhbGciOiJIUzI1Ni...` | Clé publique PROD |
| `SERVICE_ROLE_KEY_PROD` | `eyJhbGciOiJIUzI1Ni...` | ⚠️ Clé serveur PROD |
| `PROJECT_REF_PROD` | `ahxezvuxxqfwgztivfle` | Project ID PROD |
| `SUPABASE_DB_PASSWORD_PROD` | `CrewSnowR&L.corp` | Mot de passe DB PROD |

### 🛠️ Secrets généraux

| Nom | Valeur | Usage |
|-----|--------|-------|
| `SUPABASE_ACCESS_TOKEN` | Token depuis dashboard | Authentification CLI |

## 📝 Exemple de workflow GitHub Actions

### Déploiement DEV (sur push main)

```yaml
name: Deploy to DEV

on:
  push:
    branches: [ main ]

jobs:
  deploy-dev:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      
      - name: Install Supabase CLI
        run: npx supabase --version
      
      - name: Link to DEV project
        run: npx supabase link --project-ref ${{ secrets.PROJECT_REF_DEV }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
      
      - name: Push migrations to DEV
        run: npx supabase db push
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
      
      - name: Run tests against DEV
        run: |
          export SUPABASE_URL="${{ secrets.SUPABASE_URL_DEV }}"
          export SUPABASE_ANON_KEY="${{ secrets.SUPABASE_ANON_KEY_DEV }}"
          # Vos tests ici
```

### Déploiement PROD (sur tag)

```yaml
name: Deploy to PROD

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    environment: production  # Nécessite une approbation manuelle
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      
      - name: Install Supabase CLI
        run: npx supabase --version
      
      - name: Link to PROD project
        run: npx supabase link --project-ref ${{ secrets.PROJECT_REF_PROD }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
      
      - name: Push migrations to PROD
        run: npx supabase db push
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
```

## 🛡️ Sécurité renforcée

### Scanner de secrets (recommandé)

```yaml
name: Security Scan

on: [push, pull_request]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Protection des branches

1. **Settings → Branches → Add rule**
2. **Branch name pattern:** `main`
3. **Cochez:**
   - Require status checks to pass
   - Require review from CODEOWNERS
   - Restrict pushes that create files

## 🏗️ Environments GitHub

Créez des environnements pour plus de sécurité :

1. **Settings → Environments**
2. **New environment:** `production`
3. **Environment protection rules:**
   - Required reviewers (vous)
   - Wait timer (5 min)
   - Deployment branches (tags only)

## 🔄 Workflows prêts à l'emploi

### Mobile (Flutter)

```yaml
- name: Build Flutter DEV
  run: |
    export SUPABASE_URL="${{ secrets.SUPABASE_URL_DEV }}"
    export SUPABASE_ANON_KEY="${{ secrets.SUPABASE_ANON_KEY_DEV }}"
    flutter build apk \
      --dart-define=SUPABASE_URL=$SUPABASE_URL \
      --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

### Backend (avec secrets)

```yaml
- name: Deploy Backend
  run: |
    # Charger les secrets serveur
    echo "SUPABASE_SERVICE_ROLE_KEY=${{ secrets.SERVICE_ROLE_KEY_DEV }}" >> .env.server.dev
    echo "STRIPE_SECRET_KEY=${{ secrets.STRIPE_SECRET_KEY_DEV }}" >> .env.server.dev
    
    # Déployer
    source .env.server.dev
    ./scripts/deploy-backend.sh
```

## ⚠️ Important

- **Jamais de SERVICE_ROLE_KEY** dans les logs ou artifacts
- **Utilisez des environments** pour PROD (review obligatoire)  
- **Scannez les secrets** en continu
- **Rotez les clés** si compromission
