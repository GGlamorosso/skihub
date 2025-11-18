# 🧹 Nettoyage des fichiers redondants

## ⚠️ Problème identifié

Il y a **5 fichiers** qui définissent la fonction `get_optimized_candidates` :

1. `20250110_candidate_scoring_views.sql` - Version originale (base)
2. `20250111_get_optimized_candidates_improved.sql` - Version améliorée ❌ **REDONDANT**
3. `20250111_get_optimized_candidates_final.sql` - Version "finale" ❌ **REDONDANT**
4. `20250118_fix_candidate_id_ambiguity.sql` - Version corrigée (ambiguïté)
5. `20250118_fix_all_critical_errors.sql` - Version corrigée (tous les problèmes) ✅ **LA PLUS RÉCENTE**

---

## ✅ Solution : Garder seulement la version la plus récente

### Fichiers à **GARDER** :
- ✅ `20250110_candidate_scoring_views.sql` - Version originale (peut contenir d'autres choses importantes)
- ✅ `20250118_fix_all_critical_errors.sql` - Version la plus récente et complète (corrige tous les problèmes)

### Fichiers à **SUPPRIMER** (redondants) :
- ❌ `20250111_get_optimized_candidates_improved.sql`
- ❌ `20250111_get_optimized_candidates_final.sql`
- ❌ `20250118_fix_candidate_id_ambiguity.sql` (si `fix_all_critical_errors.sql` contient la même correction)

---

## 🔍 Vérification

La fonction `get_optimized_candidates` dans `20250118_fix_all_critical_errors.sql` :
- ✅ Corrige l'ambiguïté `candidate_id`
- ✅ Utilise `get_candidate_scores` (qui sera remplacée par la version avec fallback)
- ✅ Retourne tous les détails nécessaires

**C'est la version à utiliser !**

---

## 📝 Différence entre les 2 fonctions

### `get_candidate_scores(p_user UUID)`
- **Rôle** : Calcule juste les scores (fonction de base)
- **Retourne** : `(candidate_id, score, distance_km)` - 3 colonnes
- **Fichier** : `20250118_get_candidate_scores_with_fallback.sql` ✅ (version avec fallback progressif)

### `get_optimized_candidates(p_user_id, p_limit, use_cache)`
- **Rôle** : Enrichit avec tous les détails (fonction complète)
- **Retourne** : `(candidate_id, username, bio, level, compatibility_score, distance_km, station_name, score_breakdown, is_premium, last_active_at, photo_url)` - 11 colonnes
- **Fichier** : `20250118_fix_all_critical_errors.sql` ✅ (version la plus récente)

---

## 🎯 Action recommandée

1. **Vérifier** que `20250118_fix_all_critical_errors.sql` contient bien la version corrigée de `get_optimized_candidates`
2. **Supprimer** les fichiers redondants :
   - `20250111_get_optimized_candidates_improved.sql`
   - `20250111_get_optimized_candidates_final.sql`
   - `20250118_fix_candidate_id_ambiguity.sql` (si la correction est déjà dans `fix_all_critical_errors.sql`)

---

## ⚠️ Attention

Avant de supprimer, vérifier que :
- Les migrations ont déjà été exécutées dans Supabase
- La version dans `20250118_fix_all_critical_errors.sql` est bien la bonne
- Aucune autre fonction importante n'est définie dans les fichiers à supprimer

