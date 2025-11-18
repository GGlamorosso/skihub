# ✅ Checklist complète - Vérification CrewSnow

## 🎯 Objectif
Vérifier que toutes les routes Flutter sont fonctionnelles et correctement reliées au backend Supabase.

---

## 📋 ÉTAPE 1 : Exécuter les migrations SQL critiques

### ⚠️ OBLIGATOIRE - Exécuter en premier

Dans **Supabase Dashboard → SQL Editor**, exécutez dans cet ordre :

1. **Migration de correction complète** :
   ```sql
   -- Copier-coller TOUT le contenu de :
   -- supabase/migrations/20250118_fix_all_critical_errors.sql
   ```
   Cette migration corrige :
   - ✅ L'erreur "candidate_id is ambiguous"
   - ✅ Les signatures de `check_user_consent` et `grant_consent`
   - ✅ Crée `revoke_consent`

2. **Vérification** :
   ```sql
   -- Copier-coller le contenu de :
   -- supabase/seed/verify_all_functions.sql
   ```
   Ce script vérifie que toutes les fonctions existent.

---

## 📋 ÉTAPE 2 : Vérifier les Edge Functions

### Edge Functions à déployer

```bash
cd /Users/user/Desktop/SKIAPP/crewsnow

# Déployer toutes les Edge Functions
supabase functions deploy match-candidates
supabase functions deploy gatekeeper
supabase functions deploy manage-consent
supabase functions deploy swipe-enhanced
supabase functions deploy send-message-enhanced
supabase functions deploy stripe-webhook
supabase functions deploy create-stripe-customer
supabase functions deploy analytics-posthog
supabase functions deploy export-user-data
supabase functions deploy delete-user-account
```

### Vérifier dans Supabase Dashboard

Allez dans **Edge Functions** et vérifiez que toutes ces fonctions sont déployées :
- ✅ match-candidates
- ✅ gatekeeper
- ✅ manage-consent
- ✅ swipe-enhanced
- ✅ send-message-enhanced
- ✅ (autres selon besoins)

---

## 📋 ÉTAPE 3 : Vérifier les routes Flutter

### Routes d'authentification

- [ ] `/login` → Utilise `SupabaseService.instance.signInWithEmail()`
- [ ] `/signup` → Utilise `SupabaseService.instance.signUpWithEmail()`
- [ ] `/forgot-password` → Utilise `SupabaseService.instance.resetPassword()`

**Vérification** : Après inscription, un row doit être créé dans `public.users` avec `id = auth.uid()`

### Routes d'onboarding

- [ ] `/onboarding/name` → `UPDATE users SET username = ...`
- [ ] `/onboarding/age` → `UPDATE users SET birth_date = ...`
- [ ] `/onboarding/photo` → Upload storage + `INSERT profile_photos`
- [ ] `/onboarding/level` → `UPDATE users SET level = ..., ride_styles = ...`
- [ ] `/onboarding/objectives` → `UPDATE users SET objectives = ...`
- [ ] `/onboarding/languages` → `UPDATE users SET languages = ...`
- [ ] `/onboarding/station-dates` → 
  - `SELECT * FROM stations WHERE is_active = true`
  - `INSERT/UPDATE user_station_status`
- [ ] `/onboarding/gps` → Appel `manage-consent` avec `action: 'grant', purpose: 'gps'`
- [ ] `/onboarding/complete` → `UPDATE users SET onboarding_completed = true` (si colonne existe)

### Routes principales

- [ ] `/feed` → 
  - Appel `match-candidates` Edge Function
  - Envoie position GPS
  - Affiche les candidats retournés
  
- [ ] `/candidate-details/:candidateId` → 
  - Affiche détails d'un candidat
  - Utilise `public_profiles_v` ou `users` + `profile_photos`

- [ ] `/profile` → 
  - `SELECT * FROM users WHERE id = current_user_id`
  - `SELECT * FROM profile_photos WHERE user_id = ... AND is_main = true`
  - `SELECT * FROM user_station_status WHERE user_id = ... AND is_active = true`

- [ ] `/edit-profile` → 
  - `UPDATE users SET bio = ..., level = ..., ride_styles = ..., languages = ..., objectives = ...`

- [ ] `/matches` → 
  - `SELECT * FROM recent_matches_with_users` ou `matches` + `users`
  - Filtre par `user1_id = current_user OR user2_id = current_user`

- [ ] `/chat/:matchId` → 
  - Subscribe Realtime à `messages WHERE match_id = ...`
  - `INSERT INTO messages` sur envoi
  - RLS : user ne voit que ses conversations

- [ ] `/photo-gallery` → 
  - Upload dans `storage.profile_photos`
  - `INSERT/UPDATE/DELETE profile_photos`
  - Une seule photo `is_main = true` par user

- [ ] `/edit-station` → 
  - `SELECT * FROM stations WHERE is_active = true`
  - `UPDATE user_station_status SET is_active = false WHERE user_id = ...`
  - `INSERT/UPDATE user_station_status` avec nouvelle station

- [ ] `/tracker` → 
  - Appel `check_user_consent('gps', version, user_id)`
  - Envoie position périodiquement
  - `INSERT INTO user_locations` ou équivalent

- [ ] `/stats` → 
  - Agrégations sur `ride_stats_daily`, `matches`, `likes`

---

## 📋 ÉTAPE 4 : Vérifier les fonctions SQL/RPC

### Fonctions critiques (doivent exister)

- [ ] `get_optimized_candidates(p_user_id UUID, p_limit INTEGER, use_cache BOOLEAN)`
- [ ] `get_candidate_scores(p_user UUID)`
- [ ] `check_user_consent(p_user_id UUID, p_purpose TEXT, p_required_version INTEGER)`
- [ ] `grant_consent(p_user_id UUID, p_purpose TEXT, p_version INTEGER)`
- [ ] `revoke_consent(p_user_id UUID, p_purpose TEXT)`
- [ ] `check_and_increment_usage(p_user_id UUID, p_usage_type TEXT, p_limit INTEGER)`

### Fonctions optionnelles

- [ ] `mark_match_read(p_match_id UUID, p_user_id UUID)`
- [ ] `get_total_unread_count(p_user_id UUID)`
- [ ] `is_feature_enabled(p_feature_name TEXT)`
- [ ] `get_user_feature_flags(p_user_id UUID)`

**Vérification** : Exécuter `supabase/seed/verify_all_functions.sql`

---

## 📋 ÉTAPE 5 : Vérifier les tables et colonnes

### Tables critiques

- [ ] `users` (avec colonnes : `id`, `username`, `email`, `level`, `ride_styles`, `languages`, `objectives`, `bio`, `birth_date`, `is_active`, `is_banned`, `is_premium`, `last_active_at`)
- [ ] `profile_photos` (avec colonnes : `id`, `user_id`, `storage_path`, `is_main`, `moderation_status`, `file_size_bytes` (nullable))
- [ ] `stations` (avec colonnes : `id`, `name`, `country_code`, `region`, `latitude`, `longitude`, `elevation_m`, `is_active`)
- [ ] `user_station_status` (avec colonnes : `id`, `user_id`, `station_id`, `date_from`, `date_to`, `radius_km`, `is_active`)
- [ ] `likes` (avec colonnes : `id`, `liker_id`, `liked_id`, `direction`, `created_at`)
- [ ] `matches` (avec colonnes : `id`, `user1_id`, `user2_id`, `created_at`)
- [ ] `messages` (avec colonnes : `id`, `match_id`, `sender_id`, `content`, `created_at`, `read_at`)
- [ ] `consents` (avec colonnes : `id`, `user_id`, `purpose`, `granted_at`, `revoked_at`, `version`)
- [ ] `daily_usage` (avec colonnes : `id`, `user_id`, `usage_type`, `usage_date`, `count`)

### Vues

- [ ] `public_profiles_v` (optionnel)
- [ ] `candidate_scores_v` (optionnel)
- [ ] `active_users_with_location` (optionnel)
- [ ] `recent_matches_with_users` (optionnel)

---

## 📋 ÉTAPE 6 : Vérifier les RLS (Row Level Security)

### Tables avec RLS

- [ ] `users` : User ne voit que son propre profil (sauf vues publiques)
- [ ] `profile_photos` : User peut voir ses photos + photos approuvées des autres
- [ ] `user_station_status` : User ne voit que ses propres stations
- [ ] `likes` : User ne voit que ses propres likes
- [ ] `matches` : User ne voit que ses propres matches
- [ ] `messages` : User ne voit que les messages de ses matches
- [ ] `consents` : User ne voit que ses propres consentements
- [ ] `daily_usage` : User ne voit que son propre usage

---

## 📋 ÉTAPE 7 : Tests de bout en bout

### Test 1 : Inscription et onboarding

1. Créer un compte via `/signup`
2. Vérifier dans Supabase : row créé dans `public.users`
3. Compléter l'onboarding étape par étape
4. Vérifier que toutes les données sont sauvegardées

### Test 2 : Feed et matching

1. Se connecter avec un compte ayant une station active
2. Aller sur `/feed`
3. Vérifier que des candidats apparaissent
4. Vérifier les logs Edge Function `match-candidates`

### Test 3 : Swipe et match

1. Swiper (like) sur un candidat
2. Vérifier dans Supabase : row créé dans `likes`
3. Si match : vérifier row créé dans `matches`

### Test 4 : Chat

1. Aller sur `/matches`
2. Ouvrir un match
3. Envoyer un message
4. Vérifier dans Supabase : row créé dans `messages`

### Test 5 : Profil et photos

1. Aller sur `/profile`
2. Modifier le profil via `/edit-profile`
3. Ajouter une photo via `/photo-gallery`
4. Vérifier dans Supabase : données mises à jour

---

## 🚨 Erreurs courantes et solutions

### Erreur : "candidate_id is ambiguous"
**Solution** : Exécuter `20250118_fix_all_critical_errors.sql`

### Erreur : "check_user_consent not found"
**Solution** : Exécuter `20250118_fix_all_critical_errors.sql`

### Erreur : "User has no active station"
**Solution** : Créer une station active via `/edit-station` ou SQL

### Erreur : "Quota dépassé"
**Solution** : Exécuter `SELECT increase_daily_limit_for_dev('USER_ID', 1000);`

### Erreur : "file_size_bytes not null"
**Solution** : Migration `20250111_fix_missing_functions_and_dev.sql` rend cette colonne nullable

---

## ✅ Résultat final attendu

Après avoir suivi cette checklist :
- ✅ Toutes les routes Flutter fonctionnent
- ✅ Toutes les fonctions SQL existent avec les bonnes signatures
- ✅ Toutes les Edge Functions sont déployées
- ✅ Les données sont correctement sauvegardées
- ✅ Les RLS sont correctement configurées
- ✅ Plus d'erreurs 404/500 dans les logs

