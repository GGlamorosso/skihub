# 🔍 Diagnostic : 0 candidats retournés

## 📊 Problème identifié

Les logs montrent :
```
📊 Match-candidates returned 0 candidates
Response data: {candidates: [], has_more: false, total_found: 0}
```

## 🔍 Causes potentielles

### 1. Migration SQL non exécutée
- La fonction `get_candidate_scores` avec fallback n'a peut-être pas été exécutée
- La fonction `get_optimized_candidates` peut être obsolète

### 2. Utilisateurs de test sans station active
- Les utilisateurs de test peuvent ne pas avoir de `user_station_status` avec `is_active = true`

### 3. Dates qui ne se chevauchent pas
- Vos dates et celles des utilisateurs de test peuvent ne pas se chevaucher

### 4. Critères trop stricts (niveau 1)
- Niveau de ski incompatible (écart trop grand)
- Tranche d'âge trop restrictive (±5 ans)
- Tous les utilisateurs peuvent être déjà likés/matchés

### 5. Fonction SQL qui échoue silencieusement
- `get_optimized_candidates` peut lever une exception qui n'est pas loggée

## ✅ Vérifications à faire

### Étape 1 : Vérifier que les migrations sont exécutées

Dans Supabase Dashboard → SQL Editor :

```sql
-- Vérifier que get_candidate_scores existe avec fallback
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'get_candidate_scores';

-- Vérifier que get_optimized_candidates existe
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'get_optimized_candidates';
```

### Étape 2 : Vérifier vos utilisateurs de test

```sql
-- Vérifier que vous avez des utilisateurs actifs
SELECT COUNT(*) as total_users 
FROM users 
WHERE is_active = true AND is_banned = false;

-- Vérifier que les utilisateurs ont une station active
SELECT 
    u.id,
    u.username,
    u.level,
    u.birth_date,
    uss.station_id,
    uss.date_from,
    uss.date_to,
    uss.is_active
FROM users u
LEFT JOIN user_station_status uss ON uss.user_id = u.id AND uss.is_active = true
WHERE u.is_active = true AND u.is_banned = false
LIMIT 10;
```

### Étape 3 : Tester get_candidate_scores directement

```sql
-- Remplacer VOTRE_USER_ID par votre UUID
SELECT * 
FROM get_candidate_scores('VOTRE_USER_ID') 
LIMIT 10;
```

**Résultat attendu** : Au moins quelques candidats (même avec fallback)

### Étape 4 : Tester get_optimized_candidates directement

```sql
-- Remplacer VOTRE_USER_ID par votre UUID
SELECT * 
FROM get_optimized_candidates('VOTRE_USER_ID', 10, false) 
LIMIT 10;
```

**Résultat attendu** : Au moins quelques candidats avec tous les détails

### Étape 5 : Vérifier vos likes/matches

```sql
-- Vérifier si tous les utilisateurs sont déjà likés
SELECT COUNT(*) as total_likes
FROM likes 
WHERE liker_id = 'VOTRE_USER_ID';

-- Vérifier si tous les utilisateurs sont déjà matchés
SELECT COUNT(*) as total_matches
FROM matches 
WHERE user1_id = 'VOTRE_USER_ID' OR user2_id = 'VOTRE_USER_ID';
```

## 🎯 Action immédiate

1. **Exécuter la migration** `20250118_get_candidate_scores_with_fallback.sql` si pas encore fait
2. **Vérifier** que vos utilisateurs de test ont une station active
3. **Tester** `get_candidate_scores` directement dans SQL Editor
4. **Vérifier** les logs Edge Function dans Supabase Dashboard

