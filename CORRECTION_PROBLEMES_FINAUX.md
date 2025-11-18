# 🔧 Corrections des problèmes finaux

## ✅ Corrections appliquées

### 1. **Erreur "candidate_id is ambiguous"**
- **Fichier** : `supabase/migrations/20250118_fix_candidate_id_ambiguity.sql`
- **Problème** : Ambiguïté dans la fonction SQL `get_optimized_candidates`
- **Solution** : Qualification explicite de toutes les colonnes avec `base.candidate_id`, `base.distance_km`, etc.
- **Action** : Exécuter cette migration dans Supabase Dashboard → SQL Editor

### 2. **"0 stations disponibles"**
- **Fichier** : `frontend/lib/services/user_service.dart`
- **Problème** : Conversion snake_case → camelCase manquante
- **Solution** : 
  - Conversion automatique de toutes les colonnes
  - Gestion des valeurs null
  - Logs de debug ajoutés
  - Recherche avec `ilike` activée

### 3. **"Results contain 2 rows" (multiple stations actives)**
- **Fichier** : `frontend/lib/features/profile/controllers/profile_controller.dart`
- **Problème** : Plusieurs stations actives pour le même utilisateur
- **Solution** : Utilisation de `.limit(1).order('created_at', ascending: false)` pour prendre la plus récente

### 4. **Fonctions manquantes (check_user_consent, grant_consent)**
- **Fichier** : `supabase/migrations/20250111_fix_missing_functions_and_dev.sql`
- **Solution** : Création automatique des fonctions si elles n'existent pas
- **Action** : Exécuter cette migration (déjà créée)

### 5. **Quota dépassé**
- **Solution** : Utiliser la fonction `increase_daily_limit_for_dev()` créée dans la migration
- **Action** : Exécuter dans SQL Editor :
  ```sql
  SELECT increase_daily_limit_for_dev('VOTRE_USER_ID', 1000);
  ```

---

## 📝 Actions à faire

### Étape 1 : Exécuter les migrations SQL

Dans **Supabase Dashboard → SQL Editor**, exécutez dans cet ordre :

1. **Migration de correction candidate_id** :
   ```sql
   -- Copier-coller le contenu de :
   -- supabase/migrations/20250118_fix_candidate_id_ambiguity.sql
   ```

2. **Migration des fonctions manquantes** (si pas déjà fait) :
   ```sql
   -- Copier-coller le contenu de :
   -- supabase/migrations/20250111_fix_missing_functions_and_dev.sql
   ```

### Étape 2 : Augmenter votre quota

```sql
-- Remplacer VOTRE_USER_ID par votre UUID
SELECT increase_daily_limit_for_dev('VOTRE_USER_ID', 1000);
```

### Étape 3 : Vérifier les stations dans la base

```sql
-- Vérifier qu'il y a des stations actives
SELECT COUNT(*) FROM stations WHERE is_active = true;

-- Voir quelques stations
SELECT id, name, country_code, region 
FROM stations 
WHERE is_active = true 
LIMIT 10;
```

### Étape 4 : Corriger les stations actives multiples

Si vous avez plusieurs stations actives :

```sql
-- Désactiver toutes sauf la plus récente
UPDATE user_station_status
SET is_active = false
WHERE user_id = 'VOTRE_USER_ID'
  AND id NOT IN (
    SELECT id FROM user_station_status
    WHERE user_id = 'VOTRE_USER_ID'
    ORDER BY created_at DESC
    LIMIT 1
  );
```

### Étape 5 : Relancer l'app

```bash
flutter run -d 00008140-000E2C412E00401C --directory frontend
```

---

## 🔍 Diagnostic

Si vous voyez toujours "0 stations disponibles", vérifiez dans les logs :

1. **Logs de chargement** :
   - `🔍 Fetching stations...`
   - `📊 Stations response: X stations found`
   - `✅ Successfully parsed X stations`

2. **Si 0 stations trouvées** :
   - Vérifier que `stations.is_active = true` dans la base
   - Vérifier les permissions RLS sur la table `stations`

3. **Si erreur de parsing** :
   - Les logs afficheront `❌ Error parsing station: ...`
   - Vérifier que toutes les colonnes requises existent

---

## ✅ Résultat attendu

Après ces corrections :
- ✅ Les stations se chargent correctement
- ✅ La recherche fonctionne
- ✅ Le matching fonctionne (plus d'erreur "candidate_id ambiguous")
- ✅ Plus d'erreur "multiple rows" pour les stations
- ✅ Les fonctions de consentement fonctionnent
- ✅ Le quota est augmenté pour le dev

