# 🚀 Activer l'algorithme de matching avec fallback progressif

## 🎯 Objectif

Garantir qu'il y a **TOUJOURS** quelqu'un à swiper, même si les critères sont progressivement relâchés.

---

## ⚡ Action immédiate

### Étape 1 : Exécuter la migration SQL

Dans **Supabase Dashboard → SQL Editor**, exécutez :

```sql
-- Copier-coller TOUT le contenu de :
-- supabase/migrations/20250118_get_candidate_scores_with_fallback.sql
```

Cette migration remplace `get_candidate_scores` par une version avec **4 niveaux de fallback progressif**.

---

## 🔍 Comment ça fonctionne

### Niveau 1 : STRICT (meilleure compatibilité)
- ✅ Même station OU stations proches
- ✅ Dates qui se chevauchent
- ✅ Distance dans le rayon
- **Score** : 5-15 points

### Niveau 2 : RELAXÉ (si niveau 1 = 0)
- ✅ Même station OU stations proches
- ⚠️ Dates **proches** (dans les 30 jours)
- ✅ Distance dans le rayon
- **Score** : 2-5 points

### Niveau 3 : LOOSE (si niveau 2 = 0)
- ✅ Même station (si vous en avez une)
- ❌ Pas de contrainte dates/distance
- **Score** : 1-2 points

### Niveau 4 : FALLBACK ULTIME (si niveau 3 = 0)
- ✅ Tous les utilisateurs actifs
- ❌ Pas de contrainte station/dates/distance
- **Score** : 0.1-1 point
- **Tri** : Par compatibilité minimale + dernière activité

---

## ✅ Résultat attendu

Après activation :
- ✅ **TOUJOURS** quelqu'un à swiper
- ✅ Les candidats les plus compatibles en premier
- ✅ Les candidats moins compatibles ensuite (mais ils apparaissent quand même)
- ✅ Même si les dates ne se chevauchent pas
- ✅ Même si les stations sont différentes
- ✅ Même si les niveaux/styles ne correspondent pas

---

## 🧪 Tester

```sql
-- Remplacer VOTRE_USER_ID par votre UUID
SELECT COUNT(*) FROM get_candidate_scores('VOTRE_USER_ID');
```

**Résultat attendu** : Au moins quelques candidats

---

## 📊 Ordre de priorité

Les candidats sont triés par :
1. **Score de compatibilité** (décroissant) - Les meilleurs matchs en premier
2. **Distance** (croissante) - Les plus proches en premier
3. **Dernière activité** (pour le fallback) - Les plus actifs en premier

---

## 🎉 C'est tout !

Une fois la migration exécutée, relancez l'app et vous devriez voir des candidats dans le feed, même si les critères sont relâchés.

