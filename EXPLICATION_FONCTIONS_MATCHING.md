# 🔍 Explication : Différence entre les fonctions de matching

## 📊 Les 2 fonctions principales

### 1. `get_candidate_scores(p_user UUID)`
**Rôle** : Fonction de **base** qui calcule juste les scores de compatibilité
- **Retourne** : `(candidate_id, score, distance_km)` - 3 colonnes seulement
- **Utilisée par** : `get_optimized_candidates`
- **Fichier** : `20250118_get_candidate_scores_with_fallback.sql` ✅ (version la plus récente avec fallback progressif)

### 2. `get_optimized_candidates(p_user_id, p_limit, use_cache)`
**Rôle** : Fonction **complète** qui retourne tous les détails des candidats
- **Retourne** : `(candidate_id, username, bio, level, compatibility_score, distance_km, station_name, score_breakdown, is_premium, last_active_at, photo_url)` - 11 colonnes
- **Utilisée par** : Edge Function `match-candidates`
- **Fichiers** : Plusieurs versions existent (voir ci-dessous)

---

## ⚠️ Problème : Fichiers redondants

Il y a **plusieurs versions** de `get_optimized_candidates` :

1. `20250111_get_optimized_candidates_improved.sql` - Version améliorée
2. `20250111_get_optimized_candidates_final.sql` - Version "finale"
3. Probablement aussi dans `20250118_fix_all_critical_errors.sql` ou `20250118_fix_candidate_id_ambiguity.sql`

**Résultat** : Confusion sur quelle version est la bonne !

---

## ✅ Solution : Garder seulement la version la plus récente

### Fichier à garder :
- `20250118_fix_candidate_id_ambiguity.sql` ou `20250118_fix_all_critical_errors.sql` (si elle contient la version corrigée)

### Fichiers à supprimer (redondants) :
- `20250111_get_optimized_candidates_improved.sql` ❌
- `20250111_get_optimized_candidates_final.sql` ❌

---

## 🔄 Comment ça fonctionne ensemble

```
Edge Function match-candidates
    ↓
Appelle get_optimized_candidates()
    ↓
get_optimized_candidates() appelle get_candidate_scores()
    ↓
get_candidate_scores() retourne les scores
    ↓
get_optimized_candidates() enrichit avec username, bio, photo_url, etc.
    ↓
Edge Function retourne les candidats au frontend
```

---

## 📝 Action recommandée

1. **Vérifier** quelle version de `get_optimized_candidates` est la plus récente/correcte
2. **Supprimer** les fichiers redondants
3. **S'assurer** que `get_optimized_candidates` utilise bien la nouvelle version de `get_candidate_scores` (avec fallback progressif)

---

## 🎯 Résumé

- **`get_candidate_scores`** = Calcul des scores (fonction de base)
- **`get_optimized_candidates`** = Enrichissement avec tous les détails (fonction complète)
- **Problème** : Plusieurs versions de `get_optimized_candidates` créent de la confusion
- **Solution** : Garder seulement la version la plus récente/correcte

