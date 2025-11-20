# 📊 Analyse de la fonction `get_candidate_scores` avec fallback

## ✅ Points forts

1. **Structure claire** : 4 niveaux de fallback progressif bien organisés
2. **Utilisation correcte** : `unnest + JOIN` au lieu de `cardinality(&&)` ✅
3. **Alias corrects** : `sc`, `rc`, `lc`, `fc` pour éviter les ambiguïtés ✅
4. **Garantie de résultats** : Le fallback ultime garantit toujours des candidats ✅
5. **Critères progressifs** : Relâchement intelligent des critères ✅

---

## ⚠️ Problème critique à corriger

### Niveau 2 (Relaxé) - Ligne avec dates

**Problème** :
```sql
OR ABS(my.date_from - us.date_to) <= 30
OR ABS(us.date_from - my.date_to) <= 30
```

**Pourquoi c'est incorrect** :
- `ABS()` sur des dates (`DATE - DATE`) retourne un `INTERVAL`, pas un nombre
- On ne peut pas comparer un `INTERVAL` avec `<= 30`
- Cela va générer une erreur de type

**Solution** :
```sql
OR ABS(EXTRACT(EPOCH FROM (my.date_from - us.date_to)) / 86400) <= 30
OR ABS(EXTRACT(EPOCH FROM (us.date_from - my.date_to)) / 86400) <= 30
```

Ou plus simple (comme dans votre version originale) :
```sql
OR ABS(EXTRACT(EPOCH FROM (my.date_from - us.date_to)) / 86400) <= 30
OR ABS(EXTRACT(EPOCH FROM (us.date_from - my.date_to)) / 86400) <= 30
```

---

## 💡 Améliorations suggérées (optionnelles)

### 1. Performance : Réduire les sous-requêtes répétées

Les sous-requêtes `unnest + JOIN` sont correctes mais répétées. On pourrait les factoriser, mais ce n'est pas critique.

### 2. Niveau 3 (Loose) : Condition peut-être trop permissive

```sql
AND (
    (my.station_id IS NOT NULL AND us.station_id = my.station_id)
    OR my.station_id IS NULL
)
```

Cette condition permet de retourner des candidats même si l'utilisateur n'a pas de station. C'est bien pour le fallback, mais peut-être trop permissif pour le niveau 3. Cependant, comme le niveau 4 existe déjà, c'est acceptable.

### 3. Niveau 4 (Fallback) : JOIN redondant mais nécessaire

Le `JOIN users u` à la fin est nécessaire pour accéder à `u.last_active_at`, donc c'est correct.

---

## 🎯 Résumé

**Fonction globalement excellente** avec une seule erreur critique à corriger :

1. ✅ Structure et logique : **Parfait**
2. ✅ Syntaxe SQL (sauf dates niveau 2) : **Correct**
3. ✅ Performance : **Acceptable**
4. ⚠️ **Correction nécessaire** : Dates dans niveau 2 (relaxé)

---

## 🔧 Correction à appliquer

Remplacer dans le niveau 2 (relaxé) :

```sql
-- ❌ INCORRECT
OR ABS(my.date_from - us.date_to) <= 30
OR ABS(us.date_from - my.date_to) <= 30

-- ✅ CORRECT
OR ABS(EXTRACT(EPOCH FROM (my.date_from - us.date_to)) / 86400) <= 30
OR ABS(EXTRACT(EPOCH FROM (us.date_from - my.date_to)) / 86400) <= 30
```

Une fois cette correction appliquée, la fonction sera **parfaite** ! 🎉

