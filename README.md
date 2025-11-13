# 🎿 CrewSnow Backend — branche `feature/db-schema-v1`

Application de rencontres pour skieurs & snowboarders bâtie 100 % sur Supabase (PostgreSQL + PostGIS, Edge Functions, RLS).  
Cette branche livre **toute l’infrastructure backend** finalisée (Semaines 1 → 10) et prête à être branchée sur le frontend.

---

## ✅ Ce qui est livré ici

- Migrations complètes du schéma (`supabase/migrations/`) : tables, RLS, fonctions, triggers, indexes  
- Edge Functions Deno (`supabase/functions/`) : matching, swipe, Stripe webhook, gatekeeper, GDPR, analytics  
- Tests SQL & scripts Bash (`supabase/test/`, `scripts/`) : audits RLS, E2E, Stripe, analytics, GDPR  
- Workflows n8n (`n8n/*.json`) : modération photo/message  
- CI/CD GitHub Actions (`.github/workflows/`) : pipelines dev + prod  
- Documentation détaillée : rapports Semaine 5→10, runbook incident, procédure de déploiement, launch summary  
- Feature flags + monitoring + KPI materialized views

⚠️ Aucun secret (Supabase/Stripe/n8n) n’est versionné. Chaque développeur crée ses propres `.env`.

---

## 🔜 Ce qu’il reste à faire avant la fusion finale

1. Brancher le frontend (ex. branche `feature/frontend-ui`) sur Supabase Dev  
2. Remplir les fichiers `.env` côté front/back avec vos clés (à partir des `.example`)  
3. Exécuter la stack sur **CrewSnow Dev** : `supabase db push`, déploiement des functions, variables test  
4. Tester le front connecté (auth, swipe, messaging, achats Stripe test)  
5. Lancer `./scripts/test-week10-production-ready.sh` sur Dev — tout doit être ✅  
6. Fusionner les branches dans `main`, créer tag `v1.0.0`, laisser le pipeline prod déployer

---

## 🔀 Plan de merge (backend + frontend)

1. Ouvrir une PR `feature/db-schema-v1 → main` (backend)  
2. Collègue front : créer branche `feature/frontend-ui` depuis `main` (après merge backend)  
3. Tests croisés sur Supabase Dev, corrections  
4. Merge frontend → `main`  
5. Pipeline CI/CD dev doit passer ✔️  
6. Tag `v1.0.0` → pipeline prod → déploiement final

> Toute personne qui clone ce repo doit **lier Supabase** (`supabase link`) et appliquer les migrations.

---

## 🚀 Quickstart backend

### Prérequis
- Supabase CLI : `npm install -g supabase`  
- Node.js 18+ (Edge Functions)  
- Compte Supabase (projets Dev & Prod)

### Setup initial
```bash
git clone <repo-url>
cd crewsnow

# Lier au projet Supabase (dev)
supabase link --project-ref <project-dev-ref>

# Appliquer toutes les migrations
supabase db push

# Option : reset + seeds fictifs
supabase db reset
```

### Commandes utiles
```bash
# Push migrations mises à jour
supabase db push

# Reset local (migrations + seeds tests)
supabase db reset

# Status du projet lié
supabase status

# Audit complet (Week 10)
./scripts/test-week10-production-ready.sh
```

---

## 🧪 Vérifications recommandées

```bash
# Audit sécurité + E2E + monitoring
./scripts/test-week10-production-ready.sh

# Tests ciblés (ex: Stripe / Matching / GDPR)
psql "$DATABASE_URL" -c "SELECT run_week7_complete_tests();"
psql "$DATABASE_URL" -c "SELECT run_week9_gdpr_tests();"
```

🟢 Sortie attendue : `CrewSnow ready for production launch!`

---

## 📁 Structure du repo

```
supabase/
├── migrations/                    # Semaine 1→10 : schema, fonctions, triggers, indexes
├── functions/                     # Edge Functions Deno (stripe, matching, gatekeeper, gdpr...)
├── test/                          # Tests SQL (RLS, matching, Stripe, GDPR, KPI...)
├── verification_complete.sql      # Audit global DB
│
n8n/                               # Workflows modération photo/message
scripts/                           # Scripts bash (tests, e2e, production readiness)
.github/workflows/                 # Pipelines CI/CD (dev + prod)
docs & rapports/                   # Runbook, launch, résumés semaines, checklists
```

---

## 🔐 Configuration Supabase / Stripe / n8n

### Supabase Dashboard
1. **Extensions** : activer `pgcrypto`, `pgjwt`, `postgis`, `pg_cron`, `pgsodium`, `pgaudit`  
2. **Storage** : buckets `profile_photos` (private), `exports` (private), `public-photos` (optionnel)  
3. **Realtime** : `matches`, `messages`  
4. **Variables d’environnement Edge Functions** :  
   - `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`  
   - `N8N_WEBHOOK_URL`, `N8N_WEBHOOK_SECRET`  
   - `SERVICE_ROLE_KEY`, `POSTHOG_API_KEY`, etc.

### GitHub Secrets (CI/CD)
```
SUPABASE_ACCESS_TOKEN
SUPABASE_PROJECT_ID_DEV
SUPABASE_PROJECT_ID_PROD
SUPABASE_DB_PASSWORD
STRIPE_SECRET_KEY_PROD
STRIPE_WEBHOOK_SECRET_PROD
```

### `.env.example`
```
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
STRIPE_SECRET_KEY=
STRIPE_PUBLISHABLE_KEY=
N8N_WEBHOOK_URL=
N8N_WEBHOOK_SECRET=
POSTHOG_API_KEY=
```

---

## 📦 Historique (Semaines 1 → 10)

| Semaine | Contenu livré |
|---------|---------------|
| 1–2 | Schéma DB, RLS, seeds stations/users |
| 3–4 | Matching initial + messaging temps réel |
| 5 | Modération images/messages (n8n) |
| 6 | Matching avancé + filtrage collaboratif |
| 7 | Stripe (subscriptions, boosts) + quotas |
| 8 | Analytics, KPI, performance monitoring |
| 9 | GDPR (export, delete, consent, audit) |
| 10 | Production readiness, CI/CD, feature flags, runbook |

---

## 📚 Documentation clé

- `FINAL_LAUNCH_SUMMARY.md` – synthèse globale  
- `RAPPORT_FINAL_SEMAINE_10_PRODUCTION.md` – détails semaine 10  
- `INCIDENT_RUNBOOK.md` – réponse aux incidents  
- `DEPLOYMENT_PROCEDURE.md` – déploiement dev/prod  
- `README_MESSAGING_SYSTEM.md`, `RAPPORT_SPECIFIC_MESSAGING_RLS_POLICIES.md` – messagerie & RLS  
- `supabase/test/*.sql`, `scripts/test-*.sh` – scripts d’audit et tests

---

## 🔧 Troubleshooting rapide

```bash
# RLS bloque les seeds en dev ?
supabase db run --file - <<< "
  ALTER TABLE users DISABLE ROW LEVEL SECURITY;
  -- seed...
  ALTER TABLE users ENABLE ROW LEVEL SECURITY;
"

# Mauvais projet lié ?
supabase projects list
supabase link --project-ref <project-id>

# Analyse des requêtes lentes
supabase db run --file - <<< "
  SELECT query, mean_exec_time
  FROM pg_stat_statements
  ORDER BY mean_exec_time DESC LIMIT 10;
"
```

---

## 🏁 Prochaines étapes (résumé)

1. Lancer l’infra sur Supabase Dev ✅  
2. Brancher le frontend (nouvelle branche) ✅  
3. Exécuter tous les tests (scripts semaine 5→10) ✅  
4. Fusionner front + back dans `main` ✅  
5. Tag `v1.0.0` → pipeline prod ✅  
6. Vérifier monitoring + launch 🎉

---

**🎿 Ready to connect ski enthusiasts worldwide! ⛷️**  
*Branche `feature/db-schema-v1` — prête à être fusionnée après intégration frontend.*