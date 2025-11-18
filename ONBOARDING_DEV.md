# 🚀 Guide d'Onboarding - CrewSnow

## ⚡ Quick Start (15 minutes)

### 1. Prérequis
```bash
# Installer les outils
npm install -g supabase
flutter --version  # Doit être 3.13+
dart --version     # Doit être 3.1+
```

### 2. Setup Backend
```bash
cd crewsnow

# Lier à Supabase (remplacer <project-ref> par votre ref)
supabase link --project-ref <project-ref>

# Appliquer toutes les migrations
supabase db push

# Vérifier que ça fonctionne
supabase status
```

### 3. Setup Frontend
```bash
cd frontend

# Installer dépendances
flutter pub get

# Configurer environnement
cp ../env.example.txt .env.dev
# Éditer .env.dev avec vos clés Supabase

# Lancer l'app
flutter run
```

---

## 📖 Fichiers à Lire en Priorité

### Pour comprendre l'architecture globale
1. **`ARCHITECTURE_COMPLETE.md`** ← Commencez ici !
2. **`README.md`** (racine) : Vue d'ensemble backend
3. **`frontend/README.md`** : Vue d'ensemble frontend

### Pour comprendre le code
1. **`frontend/lib/main.dart`** : Point d'entrée Flutter
2. **`frontend/lib/router/app_router.dart`** : Navigation
3. **`supabase/migrations/20241113_create_core_data_model.sql`** : Schéma DB
4. **`supabase/functions/match-candidates/index.ts`** : Exemple Edge Function

---

## 🎯 Tâches Courantes

### Ajouter une nouvelle feature Flutter
1. Créer dossier dans `frontend/lib/features/nom_feature/`
2. Structure : `controllers/`, `presentation/`, `services/`, `models/`
3. Ajouter route dans `app_router.dart`
4. Créer provider Riverpod dans `controllers/`

### Ajouter une nouvelle table SQL
1. Créer migration : `supabase/migrations/YYYYMMDD_description.sql`
2. Ajouter table, indexes, RLS policies
3. Exécuter : `supabase db push`
4. Documenter dans `ARCHITECTURE_COMPLETE.md`

### Ajouter une Edge Function
1. Créer dossier : `supabase/functions/nom-function/`
2. Créer `index.ts` et `deno.json`
3. Déployer : `supabase functions deploy nom-function`
4. Configurer secrets dans Supabase Dashboard

### Modifier le matching
1. Fonction SQL : `supabase/migrations/20250110_candidate_scoring_views.sql`
2. Edge Function : `supabase/functions/match-candidates/index.ts`
3. Service Flutter : `frontend/lib/services/match_service.dart`
4. Controller : `frontend/lib/features/feed/controllers/feed_controller.dart`

---

## 🐛 Debugging

### Erreur "Function does not exist"
→ Vérifier que la migration SQL a été exécutée (`supabase db push`)

### Erreur "No profile found"
→ Créer profil utilisateur dans `public.users` (voir `supabase/seed/FIX_ALL_ISSUES.sql`)

### Erreur RLS "permission denied"
→ Vérifier que vous êtes connecté (`SupabaseService.instance.isAuthenticated`)
→ Vérifier les policies dans `supabase/migrations/20241116_rls_and_indexes.sql`

### Erreur Edge Function 500
→ Vérifier les logs dans Supabase Dashboard > Edge Functions > Logs
→ Vérifier que les secrets sont configurés

### Flutter ne se connecte pas à Supabase
→ Vérifier `.env.dev` (SUPABASE_URL, SUPABASE_ANON_KEY)
→ Vérifier que `EnvConfig.load()` est appelé dans `main.dart`

---

## 📁 Structure des Features Flutter

Chaque feature suit ce pattern :

```
features/nom_feature/
├── controllers/
│   └── nom_controller.dart      # Riverpod providers
├── presentation/
│   └── nom_screen.dart          # Écrans UI
├── services/
│   └── nom_service.dart         # Services spécifiques
├── models/
│   └── nom_model.dart           # Modèles de données
└── widgets/
    └── nom_widget.dart          # Widgets réutilisables
```

**Exemple** : `features/feed/` (swipe/matching)

---

## 🔄 Workflow de Développement

### 1. Modifier le Backend
```bash
# Créer/modifier migration
vim supabase/migrations/YYYYMMDD_ma_migration.sql

# Appliquer
supabase db push

# Tester
psql "$DATABASE_URL" -c "SELECT ma_fonction();"
```

### 2. Modifier une Edge Function
```bash
# Éditer
vim supabase/functions/nom-function/index.ts

# Déployer
supabase functions deploy nom-function

# Tester
curl -X POST https://<project>.supabase.co/functions/v1/nom-function \
  -H "Authorization: Bearer <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

### 3. Modifier le Frontend
```bash
cd frontend

# Éditer code
vim lib/features/nom_feature/...

# Hot reload (automatique)
# Ou rebuild
flutter run
```

---

## 🧪 Tests

### Tests SQL
```sql
-- Dans Supabase Dashboard > SQL Editor
SELECT run_rls_comprehensive_audit();
SELECT run_week6_matching_tests();
```

### Tests Flutter
```bash
cd frontend
flutter test
```

### Tests E2E
```bash
./scripts/test-e2e-complete-scenario.sh
```

---

## 📞 Besoin d'Aide ?

1. **Documentation** : Lire `ARCHITECTURE_COMPLETE.md`
2. **Erreurs** : Vérifier `EXPLICATION_ERREURS_LOGS.md`
3. **Déploiement** : Vérifier `DEPLOYMENT_PROCEDURE.md`
4. **Runbook** : Vérifier `INCIDENT_RUNBOOK.md`

---

## ✅ Checklist Avant de Commencer à Coder

- [ ] Supabase CLI installé et connecté
- [ ] Migrations appliquées (`supabase db push`)
- [ ] Edge Functions déployées
- [ ] Flutter configuré (`.env.dev` rempli)
- [ ] App Flutter lance sans erreur
- [ ] Compte utilisateur de test créé
- [ ] Documentation lue (`ARCHITECTURE_COMPLETE.md`)

---

**🎿 Bon développement ! ⛷️**

