# 🎿 CrewSnow Backend

Une application de rencontres et social pour skieurs et snowboarders, avec matching géolocalisé et fonctionnalités premium.

## 🚀 Quickstart Backend

### Prérequis

- **Supabase CLI** : [Installation](https://supabase.com/docs/guides/cli)
  ```bash
  npm install -g supabase
  ```
- **Node.js** 18+ (pour Edge Functions)
- Compte Supabase (dev et prod)

### 🔗 Setup Initial

1. **Cloner et naviguer**
   ```bash
   git clone <repo-url>
   cd crewsnow
   ```

2. **Lier à votre projet Supabase**
   ```bash
   # Development
   supabase link --project-ref <your-dev-project-id>
   
   # Production (optionnel)
   supabase link --project-ref <your-prod-project-id>
   ```

3. **Pousser le schéma**
   ```bash
   supabase db push
   ```

4. **Charger les données de test**
   ```bash
   # Reset complet avec seed data
   supabase db reset
   
   # Ou charger manuellement
   supabase db run --file supabase/seed/01_seed_stations.sql
   supabase db run --file supabase/seed/02_seed_test_users.sql
   ```

### ⚡ Commandes Essentielles

```bash
# 🔄 Reset complet (migrations + seed)
supabase db reset

# 📤 Pousser nouvelles migrations
supabase db push

# 🗄️ Générer types TypeScript
supabase gen types typescript --local > types/database.types.ts

# 📋 Status du projet
supabase status

# 🔍 Vérifier la base
./scripts/verify-database.sh
```

### 🧪 Vérification

Après setup, vérifiez que tout fonctionne :

```bash
# Test des fonctions core
supabase db run --file supabase/verification_complete.sql

# Ou via le script
./scripts/verify-database.sh
```

**Expected output** : ✅ All tests passed, database ready

### 📊 Données Incluses

- **60+ stations de ski** européennes (France, Suisse, Autriche, Italie...)
- **10 utilisateurs de test** avec profils variés
- **Matches et messages** d'exemple
- **Stats de ski** réalistes pour testing

### 🏗️ Architecture

```
supabase/
├── migrations/          # Schema et fonctions SQL
├── seed/               # Données de test
├── functions/          # Edge Functions (Stripe webhook)
└── docs/              # ERD et documentation

.github/workflows/      # CI/CD automatisé
scripts/               # Utilitaires (verify-database.sh)
```

### 🔐 Configuration Production

#### Supabase Dashboard
1. **Database → Replication** : Activer realtime sur `matches`, `messages`
2. **Storage** : Créer bucket `profile-photos` (private)
3. **Edge Functions** : Deploy `stripe-webhook`

#### Variables d'environnement
```bash
# GitHub Secrets requis
SUPABASE_ACCESS_TOKEN=supa_...
SUPABASE_PROJECT_REF_DEV=...
SUPABASE_PROJECT_REF_PROD=...
STRIPE_SECRET_KEY_PROD=sk_live_...
STRIPE_WEBHOOK_SECRET_PROD=whsec_...
```

### 📈 Features Activées

- ✅ **Matching géolocalisé** avec PostGIS
- ✅ **Chat temps réel** via Supabase Realtime  
- ✅ **Upload photos** avec modération
- ✅ **Tracking activités** pour gamification
- ✅ **Monétisation Stripe** (subscriptions + boosts)
- ✅ **Groupes/crews** pour sorties collectives
- ✅ **Performance optimisée** (< 200ms matching)

### 🛠️ Développement

#### Tests
```bash
# Tests complets
supabase test db

# Performance analysis
supabase db run --file supabase/verification_complete.sql
```

#### Migrations
```bash
# Nouvelle migration
supabase migration new <nom_migration>

# Reset local pour test
supabase db reset

# Push vers remote
supabase db push
```

#### Edge Functions
```bash
# Développer localement
supabase functions serve

# Deploy
supabase functions deploy stripe-webhook
```

### 📋 Point In Time Recovery (PITR)

- ✅ **PROD** : Activé automatiquement sur Supabase Pro
- ⚠️ **DEV** : Non nécessaire (données de test)
- 📝 **Backup** : Point-in-time recovery jusqu'à 7 jours (Pro)

### 🔧 Troubleshooting

#### Seeds ne passent pas
```bash
# Si RLS bloque les seeds en dev
supabase db run --file - <<< "
  ALTER TABLE users DISABLE ROW LEVEL SECURITY;
  -- Run your seeds
  ALTER TABLE users ENABLE ROW LEVEL SECURITY;
"
```

#### Liens projet cassés
```bash
supabase projects list
supabase link --project-ref <correct-project-id>
```

#### Performance lente
```bash
# Analyser les requêtes
supabase db run --file - <<< "
  SELECT query, mean_exec_time 
  FROM pg_stat_statements 
  ORDER BY mean_exec_time DESC LIMIT 10;
"
```

### 📚 Documentation

- **ERD** : `docs/schema.dbml` ([Visualiser](https://dbdiagram.io/))
- **API Contracts** : `docs/api-contracts.md`
- **Architecture** : `docs/architecture.md`
- **Modèle de données** : `supabase/README_DATA_MODEL.md`
- **Rapport de vérification** : `supabase/VERIFICATION_REPORT.md`

### 🎯 Version

**Current** : `v0.1.0-db` (Semaine 1 - Schema Foundation)

**Next** : API Development (Semaine 2)

### 📞 Support

- Issues GitHub pour bugs/features
- Vérifications complètes dans `supabase/verification_complete.sql`
- Performance monitoring dans CI/CD

---

**🎿 Ready to connect ski enthusiasts worldwide! ⛷️**