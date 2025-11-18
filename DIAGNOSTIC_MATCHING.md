# 🔍 Diagnostic : Pourquoi aucun profil à swiper ?

## 📋 Checklist de diagnostic

### 1. Vérifier que la migration SQL a été exécutée

Dans **Supabase Dashboard → SQL Editor**, exécutez :

```sql
-- Vérifier si la fonction existe avec la bonne signature
SELECT proname, pg_get_function_arguments(oid) as args
FROM pg_proc 
WHERE proname = 'get_optimized_candidates';
```

Si elle n'existe pas ou a une erreur, exécutez :
```sql
-- Copier-coller le contenu de :
-- supabase/migrations/20250118_fix_candidate_id_ambiguity.sql
```

### 2. Exécuter le script de diagnostic

Dans **Supabase Dashboard → SQL Editor**, exécutez :

```sql
-- Copier-coller le contenu de :
-- supabase/seed/diagnostic_matching.sql
```

Ce script va :
- ✅ Vérifier que `get_candidate_scores` fonctionne
- ✅ Vérifier que `get_optimized_candidates` fonctionne
- ✅ Compter les utilisateurs actifs avec stations
- ✅ Compter les paires avec dates qui se chevauchent
- ✅ Tester avec votre user_id spécifique

### 3. Vérifier votre station active

```sql
-- Remplacer VOTRE_USER_ID par votre UUID
SELECT 
    uss.*,
    s.name as station_name,
    s.country_code
FROM user_station_status uss
JOIN stations s ON s.id = uss.station_id
WHERE uss.user_id = 'VOTRE_USER_ID'
  AND uss.is_active = true;
```

**Résultat attendu** : 1 ligne (une seule station active)

### 4. Vérifier les autres utilisateurs à la même station

```sql
-- Remplacer VOTRE_STATION_ID par l'ID de votre station
SELECT 
    u.id,
    u.username,
    u.level,
    uss.date_from,
    uss.date_to,
    uss.radius_km
FROM users u
JOIN user_station_status uss ON uss.user_id = u.id
WHERE uss.station_id = 'VOTRE_STATION_ID'
  AND uss.is_active = true
  AND u.id != 'VOTRE_USER_ID'  -- Exclure vous-même
  AND u.is_active = true
  AND u.is_banned = false;
```

**Résultat attendu** : Au moins 1 autre utilisateur

### 5. Tester la fonction directement

```sql
-- Remplacer VOTRE_USER_ID par votre UUID
SELECT * FROM get_optimized_candidates('VOTRE_USER_ID', 20, false);
```

**Si erreur "candidate_id is ambiguous"** :
→ La migration `20250118_fix_candidate_id_ambiguity.sql` n'a pas été exécutée

**Si 0 résultats** :
→ Vérifier les points 3 et 4 ci-dessus

---

## 🔧 Corrections à appliquer

### Correction 1 : Exécuter la migration SQL

**Fichier** : `supabase/migrations/20250118_fix_candidate_id_ambiguity.sql`

**Action** : Copier-coller dans Supabase Dashboard → SQL Editor et exécuter

### Correction 2 : Redéployer l'Edge Function

```bash
cd /Users/user/Desktop/SKIAPP/crewsnow
supabase functions deploy match-candidates
```

### Correction 3 : Augmenter votre quota (pour tester)

```sql
-- Remplacer VOTRE_USER_ID par votre UUID
SELECT increase_daily_limit_for_dev('VOTRE_USER_ID', 1000);
```

### Correction 4 : Vérifier les logs Edge Function

Dans **Supabase Dashboard → Edge Functions → match-candidates → Logs**, vous devriez voir :

```
🔍 Fetching candidates for user ...
✅ get_optimized_candidates returned X candidates
✅ Final result: X candidates
```

Si vous voyez :
```
❌ get_optimized_candidates failed: column reference "candidate_id" is ambiguous
```
→ La migration SQL n'a pas été exécutée

Si vous voyez :
```
⚠️ WARNING: Returning 0 candidates
```
→ Il n'y a pas d'utilisateurs qui matchent (voir points 3 et 4)

---

## 🎯 Solutions selon le problème

### Problème : "candidate_id is ambiguous"
**Solution** : Exécuter `20250118_fix_candidate_id_ambiguity.sql`

### Problème : "0 candidates" mais il y a des utilisateurs
**Causes possibles** :
1. Dates qui ne se chevauchent pas
2. Distance trop grande
3. Tous les utilisateurs déjà likés/matchés
4. Critères de matching trop stricts

**Solution** : Vérifier les dates et distances dans le diagnostic SQL

### Problème : Aucun utilisateur à la même station
**Solution** : Créer des utilisateurs de test avec la même station (voir `create_many_test_users.sql`)

---

## 📊 Logs à vérifier

Dans les logs Flutter, vous devriez voir :
```
📊 Match-candidates returned X candidates
```

Si X = 0, vérifier les logs Edge Function dans Supabase Dashboard.

