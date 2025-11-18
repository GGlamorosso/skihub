# 🎯 Action immédiate : Diagnostic 0 candidats

## 📋 Étape 1 : Exécuter le script de diagnostic

Dans **Supabase Dashboard → SQL Editor** :

1. **Ouvrir** le fichier : `supabase/seed/diagnostic_0_candidates.sql`
2. **Remplacer** `VOTRE_USER_ID` par votre UUID (dans la ligne `\set user_id`)
3. **Exécuter** tout le script

Le script va vous montrer **exactement** pourquoi vous n'avez pas de candidats.

---

## 🔍 Ce que le script vérifie

1. ✅ Votre profil existe et est actif
2. ✅ Vous avez une station active
3. ✅ Nombre d'utilisateurs actifs dans la base
4. ✅ Nombre d'utilisateurs avec station active
5. ✅ Utilisateurs à la même station que vous
6. ✅ Utilisateurs avec dates qui se chevauchent
7. ✅ Utilisateurs avec niveau compatible
8. ✅ Utilisateurs avec tranche d'âge similaire
9. ✅ Utilisateurs déjà likés (exclus)
10. ✅ Utilisateurs déjà matchés (exclus)
11. ✅ Utilisateurs bloqués (exclus)
12. ✅ Test de `get_candidate_scores` directement
13. ✅ Test de `get_optimized_candidates` directement
14. ✅ Diagnostic complet avec tous les critères

---

## 🎯 Causes les plus probables

### 1. Migration SQL non exécutée
**Solution** : Exécuter `20250118_get_candidate_scores_with_fallback.sql`

### 2. Utilisateurs de test sans station active
**Solution** : Vérifier que les utilisateurs de test ont `user_station_status` avec `is_active = true`

### 3. Dates qui ne se chevauchent pas
**Solution** : Vérifier que vos dates et celles des utilisateurs de test se chevauchent

### 4. Critères trop stricts (niveau 1)
**Solution** : Vérifier niveau de ski et tranche d'âge dans le diagnostic

### 5. Tous les utilisateurs déjà likés/matchés
**Solution** : Réinitialiser les likes/matches ou créer de nouveaux utilisateurs

---

## ✅ Après le diagnostic

Une fois le script exécuté, vous saurez **exactement** quelle est la cause. Ensuite, on pourra corriger le problème spécifique.

---

## 📝 Exemple de résultat attendu

Si tout fonctionne, vous devriez voir :
- ✅ Des candidats dans les tests 12, 13, 14, 15
- ✅ Des candidats éligibles dans le diagnostic complet (16)

Si vous voyez 0 partout, le diagnostic vous dira **pourquoi** (station manquante, dates incompatibles, etc.)

