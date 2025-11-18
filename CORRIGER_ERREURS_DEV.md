# 🔧 Guide de correction des erreurs de développement

## ✅ Corrections automatiques appliquées

### 1. Fonctions SQL manquantes
- ✅ `check_user_consent` créée/vérifiée
- ✅ `grant_consent` créée/vérifiée
- ✅ Tables `consents` et `daily_usage` créées/vérifiées

### 2. Photo upload
- ✅ `file_size_bytes` rendu nullable dans la migration
- ✅ Code Flutter corrigé pour envoyer `file_size_bytes` lors de l'upload

### 3. Quota gatekeeper
- ✅ Fonctions dev créées pour augmenter/réinitialiser les quotas

---

## 📝 Étapes pour appliquer les corrections

### Étape 1 : Exécuter la migration SQL

Dans Supabase Dashboard → SQL Editor, exécutez :

```sql
-- Copier-coller le contenu de :
-- supabase/migrations/20250111_fix_missing_functions_and_dev.sql
```

Ou via terminal :

```bash
cd /Users/user/Desktop/SKIAPP/crewsnow
supabase db push
```

### Étape 2 : Augmenter votre quota en dev

Dans Supabase Dashboard → SQL Editor, exécutez (remplacez `VOTRE_USER_ID` par votre UUID) :

```sql
-- Augmenter la limite quotidienne à 1000 swipes
SELECT increase_daily_limit_for_dev('VOTRE_USER_ID', 1000);

-- OU réinitialiser le compteur du jour
SELECT reset_daily_usage_for_dev('VOTRE_USER_ID');
```

Pour trouver votre `user_id` :

```sql
SELECT id, email, username 
FROM users 
WHERE email = 'votre@email.com';
```

### Étape 3 : Vérifier que tout fonctionne

```sql
-- Vérifier les fonctions
SELECT check_user_consent('VOTRE_USER_ID', 'gps', 1);
SELECT grant_consent('VOTRE_USER_ID', 'gps', 1);

-- Vérifier votre quota
SELECT * FROM daily_usage 
WHERE user_id = 'VOTRE_USER_ID' 
AND date = CURRENT_DATE;
```

---

## 🎯 Tout est modifiable depuis l'app

### ✅ Station
- **Écran** : Profil → "Modifier ma station"
- **Fonctionnalité** : Choisir station, dates, rayon de recherche
- **Code** : `frontend/lib/features/profile/presentation/edit_station_screen.dart`

### ✅ Niveau
- **Écran** : Profil → "Modifier mon profil"
- **Fonctionnalité** : Changer le niveau (beginner, intermediate, advanced, expert)
- **Code** : `frontend/lib/features/profile/presentation/edit_profile_screen.dart`

### ✅ Styles de ski
- **Écran** : Profil → "Modifier mon profil"
- **Fonctionnalité** : Sélectionner plusieurs styles (freestyle, freeride, park, etc.)
- **Code** : `frontend/lib/features/profile/presentation/edit_profile_screen.dart`

### ✅ Langues
- **Écran** : Profil → "Modifier mon profil"
- **Fonctionnalité** : Sélectionner les langues parlées
- **Code** : `frontend/lib/features/profile/presentation/edit_profile_screen.dart`

### ✅ Bio
- **Écran** : Profil → "Modifier mon profil"
- **Fonctionnalité** : Modifier la bio
- **Code** : `frontend/lib/features/profile/presentation/edit_profile_screen.dart`

### ✅ Photos
- **Écran** : Profil → Galerie de photos
- **Fonctionnalité** : Ajouter, supprimer, définir photo principale
- **Code** : `frontend/lib/services/photo_repository.dart`

---

## 🐛 Erreurs corrigées

### ❌ Avant
- `Could not find the function public.check_user_consent(...)`
- `Could not find the function public.grant_consent(...)`
- `null value in column "file_size_bytes" violates not-null constraint`
- `Quota dépassé - swipes daily limit reached`

### ✅ Après
- ✅ Fonctions créées automatiquement
- ✅ `file_size_bytes` géré correctement
- ✅ Quota augmentable en dev

---

## 🚀 Prochaines étapes

1. **Exécuter la migration SQL** (étape 1)
2. **Augmenter votre quota** (étape 2)
3. **Relancer l'app** : `flutter run -d <device> --directory frontend`
4. **Tester** :
   - Modifier votre station depuis l'app
   - Modifier votre niveau/styles/langues depuis l'app
   - Uploader une photo
   - Swiper des profils (devrait fonctionner maintenant)

---

## 📞 Si vous avez encore des erreurs

1. Vérifiez que la migration a bien été exécutée :
   ```sql
   SELECT proname FROM pg_proc 
   WHERE proname IN ('check_user_consent', 'grant_consent');
   ```

2. Vérifiez que votre quota est bien augmenté :
   ```sql
   SELECT * FROM daily_usage 
   WHERE user_id = 'VOTRE_USER_ID';
   ```

3. Vérifiez que vous avez une station active :
   ```sql
   SELECT * FROM user_station_status 
   WHERE user_id = 'VOTRE_USER_ID' 
   AND is_active = true;
   ```

---

**Tout est maintenant modifiable depuis l'application, sans toucher à la base de données !** 🎉

