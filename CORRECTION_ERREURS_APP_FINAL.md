# 🔧 Corrections des Erreurs App - Guide Complet

## ✅ Corrections Appliquées

### 1. Upload de Photo - RLS Policy ✅

**Problème** : `StorageException: new row violates row-level security policy (403)`

**Cause** : Le chemin d'upload incluait le préfixe `profile_photos/` alors que la RLS attend `userId/filename`

**Solution** : Corrigé dans `frontend/lib/services/photo_repository.dart`
- Avant : `'profile_photos/$userId/$fileName'`
- Après : `'$userId/$fileName'`

**Test** : L'upload de photo devrait maintenant fonctionner.

---

### 2. Station Active Manquante ⚠️

**Problème** : `No active station found: type 'Null' is not a subtype of type 'String'`

**Cause** : L'utilisateur n'a pas de ligne active dans `user_station_status`

**Solution** : Exécuter le script SQL `supabase/seed/add_active_station.sql`

**Étapes** :
1. Aller dans Supabase Dashboard > SQL Editor
2. Récupérer votre `user_id` :
   ```sql
   SELECT id, email FROM auth.users WHERE email = 'votre@email.com';
   ```
3. Récupérer une `station_id` :
   ```sql
   SELECT id, name, country_code FROM stations WHERE is_active = true LIMIT 5;
   ```
4. Exécuter le script `add_active_station.sql` en remplaçant `YOUR_USER_ID` et `STATION_ID`

**Alternative rapide** : Si vous avez déjà une station dans la base :
```sql
-- Remplacer par votre user_id et station_id
INSERT INTO user_station_status (
  user_id, station_id, date_from, date_to, radius_km, is_active
)
VALUES (
  'VOTRE_USER_ID'::UUID,
  'STATION_ID'::UUID,
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '7 days',
  50,
  true
);
```

---

### 3. Consentement GPS ✅

**Problème** : `Invalid consent purpose: gps_tracking`

**Cause** : Le code utilisait `'gps_tracking'` mais l'Edge Function n'accepte que `'gps'`

**Solution** : Déjà corrigé dans `frontend/lib/features/privacy/repositories/privacy_repository.dart`
- Mapping automatique : `'gps_tracking'` → `'gps'`
- Mapping automatique : `'location_sharing'` → `'gps'`

**Test** : Le consentement GPS devrait maintenant fonctionner.

**Note iPhone** : N'oubliez pas d'autoriser la localisation dans :
- Réglages → Confidentialité → Services de localisation → CrewSnow
- Autoriser "Quand l'app est active" ou "Toujours"

---

### 4. Pas de Profils à Matcher ⚠️

**Problème** : Aucun candidat n'apparaît dans le feed

**Cause** : Le matching nécessite :
- Même station active
- Dates qui se chevauchent
- Rayon de recherche compatible
- Score de compatibilité suffisant
- Pas déjà matché/bloqué

**Solutions** :

#### Option A : Créer un 2ème compte
1. Créer un nouveau compte dans l'app
2. Compléter l'onboarding avec :
   - **Même station** que votre compte principal
   - **Mêmes dates** (ou dates qui se chevauchent)
   - **Rayon de recherche** suffisant (ex: 50km)

#### Option B : Utiliser les utilisateurs de test
Si vous avez créé des utilisateurs de test avec `create_many_test_users.sql`, vérifiez qu'ils ont une station active :
```sql
-- Vérifier les stations actives
SELECT 
  u.email,
  s.name AS station,
  uss.date_from,
  uss.date_to,
  uss.radius_km
FROM user_station_status uss
JOIN users u ON u.id = uss.user_id
JOIN stations s ON s.id = uss.station_id
WHERE uss.is_active = true;
```

Si nécessaire, mettre à jour leurs stations pour qu'elles correspondent :
```sql
-- Mettre à jour les stations des utilisateurs de test
UPDATE user_station_status
SET 
  station_id = 'VOTRE_STATION_ID'::UUID,
  date_from = CURRENT_DATE,
  date_to = CURRENT_DATE + INTERVAL '7 days',
  radius_km = 50
WHERE user_id IN (
  SELECT id FROM users WHERE email LIKE '%test%@example.com'
);
```

---

### 5. RenderFlex Overflow (Layout) ⚠️

**Problème** : `RenderFlex overflowed by X pixels on the right`

**Cause** : Layout Flutter - éléments trop larges pour l'écran

**Solutions** :
- Remplacer `Row` par `Wrap` si possible
- Utiliser `Expanded` ou `Flexible` pour les éléments flexibles
- Ajouter `SingleChildScrollView(scrollDirection: Axis.horizontal)` pour les listes horizontales

**Note** : Non-bloquant, mais à corriger pour une meilleure UX.

---

### 6. Paramètres Inaccessibles ❓

**Problème** : Impossible d'accéder à l'écran des paramètres

**À vérifier** :
1. Le routeur GoRouter contient-il la route `/settings` ?
2. Le bouton de navigation vers settings est-il présent dans la bottom bar ?
3. Y a-t-il une condition qui bloque l'accès (ex: onboarding non complété) ?

**Debug** :
```dart
// Dans app_router.dart, vérifier :
GoRoute(
  path: '/settings',
  builder: (context, state) => SettingsScreen(),
),
```

---

## 📋 Checklist de Vérification

- [ ] Upload de photo fonctionne (corrigé ✅)
- [ ] Station active ajoutée pour votre utilisateur
- [ ] Consentement GPS fonctionne (corrigé ✅)
- [ ] Au moins 2 utilisateurs avec même station/dates pour tester le matching
- [ ] Localisation autorisée sur iPhone
- [ ] Layout Flutter corrigé (non-bloquant)

---

## 🚀 Prochaines Étapes

1. **Exécuter le script SQL** pour ajouter votre station active
2. **Tester l'upload de photo** - devrait maintenant fonctionner
3. **Créer un 2ème compte** ou utiliser des utilisateurs de test pour tester le matching
4. **Vérifier les permissions iPhone** pour la localisation

---

## 📞 Si Problèmes Persistent

Fournir :
1. Logs complets de l'erreur
2. Code de `PhotoRepository.uploadPhoto` (déjà corrigé)
3. Code du routeur pour `/settings`
4. Résultat de la requête SQL pour vérifier les stations actives

