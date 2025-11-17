# 🔍 Diagnostic Complet - Pourquoi aucun profil n'est visible

## ✅ Corrections Appliquées

### 1. Requête profil utilisateur
- **Fichier** : `frontend/lib/services/user_service.dart`
- **Correction** : `profile_photos!inner` → `profile_photos!profile_photos_user_id_fkey`
- **Status** : ✅ Corrigé

### 2. RenderFlex overflow TrackerScreen
- **Fichier** : `frontend/lib/features/tracking/presentation/tracker_screen.dart`
- **Correction** : Ajout de `SingleChildScrollView` avec `mainAxisSize: MainAxisSize.min`
- **Status** : ✅ Corrigé

### 3. Google Fonts
- **Fichier** : `frontend/lib/main.dart`
- **Correction** : `GoogleFonts.config.allowRuntimeFetching = false`
- **Status** : ✅ Corrigé

### 4. GPS Tracking
- **Fichier** : `frontend/lib/services/match_service.dart`
- **Correction** : Position GPS envoyée à l'API `match-candidates`
- **Status** : ✅ Corrigé

## 📋 Checklist de Diagnostic

### Étape 1 : Vérifier l'authentification
```dart
// Dans les logs, vous devriez voir :
✅ User signed in: votre-email@exemple.com
✅ Supabase initialized successfully
```

**Si pas connecté :**
- Connectez-vous via l'écran de login
- Vérifiez que votre compte existe dans Supabase Auth

### Étape 2 : Vérifier les Edge Functions
Les fonctions doivent être déployées dans Supabase :
- `match-candidates`
- `gatekeeper`
- `manage-consent`

**Comment vérifier :**
1. Allez sur [Supabase Dashboard](https://app.supabase.com)
2. Edge Functions > Vérifiez que les 3 fonctions sont listées
3. Si absentes, déployez-les (voir `backend/DEPLOY_INSTRUCTIONS.md`)

### Étape 3 : Vérifier les données
**Dans Supabase SQL Editor, exécutez :**
```sql
-- Vérifier les utilisateurs actifs
SELECT 
  id, 
  email, 
  username, 
  onboarding_completed, 
  is_active,
  level,
  ride_styles
FROM users 
WHERE onboarding_completed = true 
AND is_active = true
ORDER BY created_at DESC;
```

**Résultat attendu :**
- Au moins 2 utilisateurs (vous + au moins 1 autre)
- `onboarding_completed = true`
- `is_active = true`

**Si aucun autre utilisateur :**
- Créez des utilisateurs de test (voir `backend/supabase/seed/test_users.sql`)

### Étape 4 : Vérifier les statuts de station
```sql
-- Vérifier les statuts de station actifs
SELECT 
  uss.user_id,
  uss.station_id,
  uss.date_from,
  uss.date_to,
  uss.is_active,
  s.name as station_name
FROM user_station_status uss
JOIN stations s ON uss.station_id = s.id
WHERE uss.is_active = true
AND uss.date_from <= CURRENT_DATE
AND uss.date_to >= CURRENT_DATE;
```

**Résultat attendu :**
- Au moins 2 utilisateurs avec des statuts de station actifs
- Dates qui se chevauchent (même période)
- Même station ou stations proches

### Étape 5 : Vérifier la vue public_profiles_v
```sql
-- Vérifier la vue public_profiles_v
SELECT 
  id,
  username,
  age,
  level,
  is_active,
  onboarding_completed
FROM public_profiles_v
LIMIT 10;
```

**Si la vue n'existe pas ou est vide :**
- La vue doit être créée dans votre schéma
- Vérifiez les permissions RLS

### Étape 6 : Tester l'Edge Function manuellement
**Dans Supabase Dashboard > Edge Functions > match-candidates > Invoke :**

```json
{
  "limit": 10,
  "latitude": 45.5,
  "longitude": 6.0
}
```

**Résultat attendu :**
```json
{
  "candidates": [...],
  "nextCursor": "..."
}
```

**Si erreur :**
- Vérifiez les logs de la fonction
- Vérifiez que l'utilisateur est bien authentifié
- Vérifiez que la vue `public_profiles_v` existe

### Étape 7 : Vérifier les logs de l'app
**Dans le terminal où vous avez lancé `flutter run`, cherchez :**

```
📍 GPS position sent: 45.5, 6.0
✅ Function called: match-candidates
```

**Si vous voyez des erreurs :**
- `❌ Function call failed` → Edge Function non déployée ou erreur
- `⚠️ GPS position not available` → Permissions GPS non accordées
- `API Error: 401` → Problème d'authentification
- `API Error: 500` → Erreur dans l'Edge Function

## 🛠️ Solutions aux Problèmes Courants

### Problème 1 : "Aucun profil visible" mais pas d'erreur
**Cause** : Pas d'autres utilisateurs dans la base

**Solution** :
1. Créez des utilisateurs de test (voir `backend/supabase/seed/test_users.sql`)
2. Assurez-vous qu'ils ont `onboarding_completed = true`
3. Créez des statuts de station pour ces utilisateurs

### Problème 2 : "API Error: 404" ou "Function not found"
**Cause** : Edge Function non déployée

**Solution** :
1. Déployez les Edge Functions (voir `backend/DEPLOY_INSTRUCTIONS.md`)
2. Vérifiez dans Supabase Dashboard que les fonctions sont listées

### Problème 3 : "API Error: 401" ou "Unauthorized"
**Cause** : Problème d'authentification

**Solution** :
1. Vérifiez que vous êtes bien connecté
2. Vérifiez que le token JWT est valide
3. Reconnectez-vous si nécessaire

### Problème 4 : "API Error: 500"
**Cause** : Erreur dans l'Edge Function

**Solution** :
1. Vérifiez les logs de l'Edge Function dans Supabase Dashboard
2. Vérifiez que la vue `public_profiles_v` existe
3. Vérifiez les permissions RLS

### Problème 5 : Profil utilisateur ne se charge pas
**Cause** : Requête SQL incorrecte ou permissions

**Solution** :
1. Vérifiez que `profile_photos!profile_photos_user_id_fkey` est correct
2. Vérifiez que la foreign key existe dans votre schéma
3. Testez la requête directement dans SQL Editor

## 📝 Actions Immédiates

1. **Déployer les Edge Functions** (5 minutes)
   - Suivez `backend/DEPLOY_INSTRUCTIONS.md`

2. **Exécuter la migration SQL** (2 minutes)
   - Copiez `backend/supabase/migrations/20250114_add_matches_last_message_at.sql`
   - Exécutez dans Supabase SQL Editor

3. **Créer des utilisateurs de test** (10 minutes)
   - Suivez `backend/supabase/seed/test_users.sql`

4. **Relancer l'app** (1 minute)
   ```bash
   cd frontend
   flutter run
   ```

5. **Vérifier les logs** (2 minutes)
   - Cherchez les messages `📍 GPS position sent`
   - Cherchez les erreurs éventuelles

## 🎯 Résultat Attendu

Après toutes ces corrections :
- ✅ Vous devriez voir des profils à swiper
- ✅ Le GPS devrait être fonctionnel
- ✅ Votre profil devrait se charger correctement
- ✅ Les dates de séjour devraient être configurables

---

**Si le problème persiste après ces étapes, partagez les logs du terminal et les erreurs spécifiques.**

