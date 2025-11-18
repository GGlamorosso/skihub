# 🚨 CORRECTION URGENTE - Erreurs critiques

## ❌ Erreurs identifiées dans les logs

1. **`column reference "candidate_id" is ambiguous`** (lignes 851, 985)
   - **Cause** : La migration `20250118_fix_candidate_id_ambiguity.sql` n'a pas été exécutée
   - **Impact** : Aucun profil ne peut être chargé dans le feed

2. **`Could not find the function public.check_user_consent(...)`** (ligne 966)
   - **Cause** : La fonction existe mais avec une mauvaise signature
   - **Impact** : Le GPS consent ne peut pas être vérifié

## ✅ Solution : Exécuter la migration complète

### Étape 1 : Exécuter la migration SQL (OBLIGATOIRE)

Dans **Supabase Dashboard → SQL Editor**, exécutez :

```sql
-- Copier-coller TOUT le contenu de :
-- supabase/migrations/20250118_fix_all_critical_errors.sql
```

Cette migration corrige :
- ✅ L'erreur "candidate_id is ambiguous"
- ✅ Les signatures de `check_user_consent` et `grant_consent`
- ✅ Crée `revoke_consent` si manquante

### Étape 2 : Vérifier que la migration a été appliquée

```sql
-- Vérifier get_optimized_candidates
SELECT proname, pg_get_function_arguments(oid) as args
FROM pg_proc 
WHERE proname = 'get_optimized_candidates';

-- Vérifier check_user_consent
SELECT proname, pg_get_function_arguments(oid) as args
FROM pg_proc 
WHERE proname = 'check_user_consent';

-- Vérifier grant_consent
SELECT proname, pg_get_function_arguments(oid) as args
FROM pg_proc 
WHERE proname = 'grant_consent';
```

### Étape 3 : Tester les fonctions

```sql
-- Tester get_optimized_candidates (remplacer VOTRE_USER_ID)
SELECT COUNT(*) FROM get_optimized_candidates('VOTRE_USER_ID', 10, false);

-- Tester check_user_consent (remplacer VOTRE_USER_ID)
SELECT check_user_consent('VOTRE_USER_ID', 'gps', 1);
```

### Étape 4 : Redéployer l'Edge Function match-candidates

```bash
cd /Users/user/Desktop/SKIAPP/crewsnow
supabase functions deploy match-candidates
```

### Étape 5 : Relancer l'app et vérifier

Après avoir exécuté la migration et redéployé l'Edge Function :

1. **Relancer l'app Flutter**
2. **Vérifier les logs** :
   - Plus d'erreur "candidate_id is ambiguous"
   - Plus d'erreur "check_user_consent not found"
   - Les profils devraient apparaître dans le feed

## 📊 Résultat attendu

Après ces corrections :
- ✅ Le feed charge des candidats
- ✅ Le GPS consent fonctionne
- ✅ Plus d'erreurs 500 dans les Edge Functions

## ⚠️ Si les erreurs persistent

1. **Vérifier les logs Edge Function** dans Supabase Dashboard
2. **Vérifier que la table `consents` existe** :
   ```sql
   SELECT * FROM information_schema.tables 
   WHERE table_name = 'consents';
   ```
3. **Vérifier que la table `user_station_status` a des données** :
   ```sql
   SELECT COUNT(*) FROM user_station_status WHERE is_active = true;
   ```

