# Configuration Supabase CLI - CrewSnow

## 📋 Prérequis

La CLI Supabase est disponible via `npx supabase` (pas d'installation globale nécessaire).

## 🔐 Première configuration

### 1. Connexion à Supabase

```bash
# Dans votre terminal (pas via l'IDE)
cd /Users/user/Desktop/SKIAPP/crewsnow
npx supabase login
```

**Où récupérer votre Access Token :**
1. Allez sur https://supabase.com/dashboard
2. Cliquez sur votre profil (en haut à droite)
3. Allez dans "Access Tokens"
4. "Generate new token" → copiez-le → collez dans le terminal

### 2. Lier au projet DEV

```bash
./scripts/supabase-link-dev.sh
```

## 🚀 Scripts utiles

| Script | Description |
|--------|-------------|
| `./scripts/supabase-status.sh` | Voir le statut actuel (projet lié, connexion) |
| `./scripts/supabase-link-dev.sh` | Basculer vers le projet DEV |
| `./scripts/supabase-link-prod.sh` | Basculer vers le projet PROD (⚠️ prudence) |

## 📂 Structure

```
supabase/
├── config.toml          # Configuration locale (ports, options)
├── migrations/          # Migrations SQL versionnées (commitées)
├── seed/               # Scripts de seed pour données de test
├── functions/          # Edge Functions Supabase
└── .gitignore          # Fichiers à ignorer (logs, temp)
```

## 🔧 Commandes courantes

```bash
# Statut et informations
npx supabase projects list
npx supabase status

# Migrations
npx supabase db pull        # Récupérer le schema distant
npx supabase db push        # Pousser les migrations locales
npx supabase db reset       # Reset + migrations + seed

# Génération
npx supabase gen types typescript --local > types/supabase.ts
```

## 🌍 Environnements

### DEV (qzpinzxiqupetortbczh)
- **Objectif :** Développement, tests, expérimentation
- **Données :** Fictives, reset autorisé
- **URL :** https://qzpinzxiqupetortbczh.supabase.co
- **Basculer :** `./scripts/supabase-link-dev.sh`

### PROD (ahxezvuxxqfwgztivfle)
- **Objectif :** Production, utilisateurs réels
- **Données :** Réelles, protégées (RGPD)
- **URL :** https://ahxezvuxxqfwgztivfle.supabase.co  
- **Basculer :** `./scripts/supabase-link-prod.sh` (⚠️ confirmation)

## 🛡️ Bonnes pratiques

1. **Toujours vérifier** l'environnement avant `db push` : `./scripts/supabase-status.sh`
2. **Tester en DEV** avant de pousser en PROD
3. **Commiter les migrations** dans Git
4. **Jamais de `db reset`** en PROD
5. **Variables d'env** séparées : `env/dev/` vs `env/prod/`

## 🚨 Dépannage

```bash
# Problème de connexion
npx supabase login
npx supabase projects list

# Problème de liaison
./scripts/supabase-link-dev.sh
cat supabase/.branches/default    # Voir le projet lié

# Permissions
# Vérifiez que vous êtes Owner/Member sur l'organisation CrewSnow
```
