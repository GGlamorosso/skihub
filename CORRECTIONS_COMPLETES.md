# ✅ Corrections Complètes - CrewSnow App

## 📋 Résumé des Problèmes Corrigés

### 1. ✅ match-candidates : colonne `objectives` et `age` inexistantes

**Problème** : La fonction essayait d'utiliser `age` dans les filtres alors que cette colonne n'existe pas.

**Correction** :
- Supprimé le filtre `age` (l'âge doit être calculé depuis `birth_date` en SQL si nécessaire)
- Vérifié que le SELECT n'inclut que les colonnes existantes

**Fichier modifié** : `backend/supabase/functions/match-candidates/index.ts`

### 2. ✅ Profil utilisateur : erreur "0 rows" non gérée

**Problème** : `getUserProfile` utilisait `.single()` qui échoue si 0 rows, causant des crashes.

**Correction** :
- Remplacé `.single()` par `.maybeSingle()` dans `UserService.getUserProfile()`
- Remplacé `.single()` par `.maybeSingle()` dans `app_router.dart` pour les vérifications onboarding
- Ajouté gestion du cas `response == null`

**Fichiers modifiés** :
- `frontend/lib/services/user_service.dart`
- `frontend/lib/router/app_router.dart`

### 3. ✅ gatekeeper : retour null causant crash

**Problème** : `getCurrentQuotas()` essayait de parser `data['quota_info']` mais gatekeeper retournait `quotaInfo` (camelCase) ou null.

**Correction** :
- Modifié `getCurrentQuotas()` pour gérer les cas null et formats invalides
- Utilisé `action: 'swipe'` au lieu de `'check'` pour obtenir quotaInfo
- Ajouté fallback vers `QuotaService.getQuotaInfo()` si gatekeeper échoue
- Gatekeeper retourne maintenant toujours `quotaInfo` avec la bonne structure

**Fichiers modifiés** :
- `frontend/lib/services/match_service.dart`
- `backend/supabase/functions/gatekeeper/index.ts` (déjà corrigé précédemment)

### 4. ✅ manage-consent : table `user_consents` manquante

**Problème** : La fonction essayait d'accéder à une table qui n'existait pas.

**Correction** :
- Créé migration SQL pour créer la table `user_consents`
- Modifié `manage-consent` pour gérer gracieusement l'absence de table (retourne false par défaut)
- Ajouté RLS policies pour la sécurité

**Fichiers créés/modifiés** :
- `backend/supabase/migrations/20250117_create_user_consents.sql` (NOUVEAU)
- `backend/supabase/functions/manage-consent/index.ts` (déjà corrigé précédemment)

### 5. ✅ Google Fonts : erreur AssetManifest.json

**Problème** : Google Fonts ne pouvait pas charger AssetManifest.json.

**Correction** :
- `GoogleFonts.config.allowRuntimeFetching = false` déjà configuré dans `main.dart`
- Nettoyage du build Flutter effectué (`flutter clean`)

**Action requise** : Relancer `flutter pub get` puis `flutter run`

**Fichiers** :
- `frontend/lib/main.dart` (déjà corrigé)
- `frontend/lib/theme/app_typography.dart` (utilise GoogleFonts.poppins directement)

### 6. ✅ Création automatique de profil utilisateur

**Problème** : Le profil n'était pas créé automatiquement lors de l'inscription.

**Correction** :
- Amélioré `_createInitialProfile()` pour vérifier si le profil existe avant de créer
- Modifié `onboarding_controller.dart` pour utiliser `upsert()` au lieu de `update()`
- Le profil est maintenant créé soit à l'inscription, soit pendant l'onboarding

**Fichiers modifiés** :
- `frontend/lib/features/auth/controllers/auth_controller.dart`
- `frontend/lib/features/onboarding/controllers/onboarding_controller.dart`

## 🚀 Actions Requises

### 1. Exécuter les migrations SQL

Dans **Supabase Dashboard > SQL Editor**, exécutez dans l'ordre :

**a) Créer table user_consents** :
```sql
-- Copier le contenu de backend/supabase/migrations/20250117_create_user_consents.sql
```

**b) Migration matches (si pas déjà fait)** :
```sql
-- Copier le contenu de backend/supabase/migrations/20250114_add_matches_last_message_at.sql
```

### 2. Redéployer les Edge Functions

Dans **Supabase Dashboard > Edge Functions** :

**a) match-candidates** :
- Ouvrir la fonction
- Remplacer le code par celui de `backend/supabase/functions/match-candidates/index.ts`
- Cliquer sur **Deploy**

**b) gatekeeper** :
- Déjà corrigé, vérifier qu'il est déployé

**c) manage-consent** :
- Déjà corrigé, vérifier qu'il est déployé

### 3. Créer votre profil utilisateur

Dans **SQL Editor**, exécutez :
```sql
-- Trouver votre USER_ID dans Authentication > Users
-- Puis exécuter (remplacer VOTRE_USER_ID) :

UPDATE public.users 
SET 
  onboarding_completed = true,
  is_active = true,
  level = 'intermediate',
  ride_styles = ARRAY['alpine', 'snowboard']::ride_style[],
  languages = ARRAY['fr', 'en']::language_code[],
  bio = 'Passionné de ski !',
  last_active_at = NOW(),
  updated_at = NOW()
WHERE id = 'VOTRE_USER_ID';
```

### 4. Rebuild Flutter

```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

## 📊 Flux Complet Corrigé

### Login → Onboarding → Profil → Feed

1. **Inscription/Login** :
   - `auth_controller.dart` crée automatiquement un profil de base
   - Si échec, l'onboarding le créera avec `upsert()`

2. **Vérification Onboarding** :
   - `app_router.dart` vérifie `onboarding_completed` avec `.maybeSingle()`
   - Si profil n'existe pas (`null`) → redirige vers onboarding
   - Si `onboarding_completed = false` → redirige vers onboarding
   - Si `onboarding_completed = true` → redirige vers feed

3. **Onboarding** :
   - L'utilisateur remplit son profil étape par étape
   - À la fin, `onboarding_controller.dart` utilise `upsert()` pour créer/mettre à jour
   - `onboarding_completed = true` est défini

4. **Feed** :
   - `match-candidates` retourne des candidats (sans erreur `objectives`)
   - `gatekeeper` retourne les quotas correctement
   - Les profils s'affichent

5. **Profil** :
   - `UserService.getUserProfile()` utilise `.maybeSingle()` pour gérer 0 rows
   - Si pas de profil → affiche message ou redirige vers onboarding

6. **GPS/Tracker** :
   - `manage-consent` gère l'absence de table gracieusement
   - Les permissions GPS sont demandées et gérées

## ✅ Vérifications Finales

Après toutes les corrections, vous devriez voir :

✅ Plus d'erreur `column users.objectives does not exist`
✅ Plus d'erreur `Cannot coerce the result to a single JSON object` (0 rows)
✅ Plus d'erreur `type 'Null' is not a subtype` pour gatekeeper
✅ Plus d'erreur `Could not find the table 'public.user_consents'`
✅ Les profils s'affichent dans le feed
✅ Votre profil se charge dans l'onglet Profil
✅ Le GPS fonctionne (avec gestion consentement)

## 📝 Fichiers Modifiés

### Flutter
- `frontend/lib/services/user_service.dart`
- `frontend/lib/services/match_service.dart`
- `frontend/lib/router/app_router.dart`
- `frontend/lib/features/auth/controllers/auth_controller.dart`
- `frontend/lib/features/onboarding/controllers/onboarding_controller.dart`

### Supabase Edge Functions
- `backend/supabase/functions/match-candidates/index.ts`
- `backend/supabase/functions/gatekeeper/index.ts` (déjà corrigé)
- `backend/supabase/functions/manage-consent/index.ts` (déjà corrigé)

### Migrations SQL
- `backend/supabase/migrations/20250114_add_matches_last_message_at.sql` (déjà créé)
- `backend/supabase/migrations/20250117_create_user_consents.sql` (NOUVEAU)

---

**Toutes les corrections sont appliquées dans le code. Il reste à :**
1. Exécuter les migrations SQL
2. Redéployer match-candidates
3. Créer votre profil
4. Rebuild Flutter

