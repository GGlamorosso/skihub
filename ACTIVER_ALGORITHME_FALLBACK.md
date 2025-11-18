# 🚀 Activer l'algorithme de matching avec fallback progressif

## 🎯 Objectif

Garantir qu'il y a **TOUJOURS** quelqu'un à swiper, même si les critères sont progressivement relâchés.

---

## 📋 Étape 1 : Exécuter la migration SQL

Dans **Supabase Dashboard → SQL Editor**, exécutez :

```sql
-- Copier-coller TOUT le contenu de :
-- supabase/migrations/20250118_get_candidate_scores_with_fallback.sql
```

Cette migration remplace `get_candidate_scores` par une version avec **4 niveaux de fallback progressif**.

---

## 📋 Étape 2 : Vérifier que ça fonctionne

### Test 1 : Vérifier que la fonction retourne des résultats

```sql
-- Remplacer VOTRE_USER_ID par votre UUID
SELECT COUNT(*) as total_candidates 
FROM get_candidate_scores('VOTRE_USER_ID');
```

**Résultat attendu** : Au moins quelques candidats (même si les critères sont relâchés)

### Test 2 : Voir les candidats par niveau de score

```sql
-- Candidats avec score élevé (niveau 1 - strict)
SELECT candidate_id, score, distance_km 
FROM get_candidate_scores('VOTRE_USER_ID') 
WHERE score > 5 
ORDER BY score DESC 
LIMIT 10;

-- Candidats avec score moyen (niveau 2-3 - relaxé/loose)
SELECT candidate_id, score, distance_km 
FROM get_candidate_scores('VOTRE_USER_ID') 
WHERE score BETWEEN 2 AND 5 
ORDER BY score DESC 
LIMIT 10;

-- Candidats avec score faible (niveau 4 - fallback)
SELECT candidate_id, score, distance_km 
FROM get_candidate_scores('VOTRE_USER_ID') 
WHERE score < 2 
ORDER BY score DESC 
LIMIT 10;
```

---

## 📋 Étape 3 : Tester dans l'app

1. **Relancer l'app Flutter**
2. **Aller sur le feed** (`/feed`)
3. **Vérifier** que des candidats apparaissent

**Si vous voyez des candidats** : ✅ L'algorithme fonctionne !

**Si vous ne voyez toujours rien** :
- Vérifier les logs Edge Function dans Supabase Dashboard
- Vérifier que vous avez bien des utilisateurs actifs dans la base
- Vérifier que les utilisateurs ne sont pas tous déjà likés/matchés

---

## 🔍 Comment l'algorithme fonctionne

### Niveau 1 : STRICT (meilleure compatibilité)
- Même station OU stations proches
- Dates qui se chevauchent
- Distance dans le rayon
- **Score élevé** (5-15 points)

### Niveau 2 : RELAXÉ (si niveau 1 = 0)
- Même station OU stations proches
- Dates **proches** (dans les 30 jours)
- Distance dans le rayon
- **Score moyen** (2-5 points)

### Niveau 3 : LOOSE (si niveau 2 = 0)
- Même station (si vous en avez une)
- Pas de contrainte dates/distance
- **Score faible** (1-2 points)

### Niveau 4 : FALLBACK ULTIME (si niveau 3 = 0)
- Tous les utilisateurs actifs
- Peu importe station/dates/distance
- **Score minimal** (0.1-1 point)
- Triés par dernière activité

---

## 📊 Résultat attendu

Après avoir activé cet algorithme :

✅ **Vous verrez TOUJOURS quelqu'un à swiper**, même si :
- Les autres utilisateurs sont à des stations différentes
- Les dates ne se chevauchent pas exactement
- Les niveaux/styles ne correspondent pas parfaitement

✅ **Les candidats les plus compatibles apparaissent en premier**

✅ **Les candidats moins compatibles apparaissent ensuite** (mais ils apparaissent quand même)

---

## 🐛 Diagnostic si ça ne fonctionne pas

### Problème : Toujours 0 candidats

**Vérifier** :
1. Avez-vous des utilisateurs actifs dans la base ?
   ```sql
   SELECT COUNT(*) FROM users WHERE is_active = true AND is_banned = false;
   ```

2. Tous les utilisateurs sont-ils déjà likés/matchés ?
   ```sql
   -- Vérifier vos likes
   SELECT COUNT(*) FROM likes WHERE liker_id = 'VOTRE_USER_ID';
   
   -- Vérifier vos matches
   SELECT COUNT(*) FROM matches 
   WHERE user1_id = 'VOTRE_USER_ID' OR user2_id = 'VOTRE_USER_ID';
   ```

3. Avez-vous une station active ?
   ```sql
   SELECT * FROM user_station_status 
   WHERE user_id = 'VOTRE_USER_ID' AND is_active = true;
   ```

### Solution

Si vous avez des utilisateurs mais qu'ils sont tous likés/matchés :
- Créer de nouveaux utilisateurs de test
- Ou réinitialiser vos likes/matches pour tester

---

## ✅ Checklist

- [ ] Migration SQL exécutée
- [ ] Fonction `get_candidate_scores` retourne des résultats
- [ ] L'app affiche des candidats dans le feed
- [ ] Les candidats sont triés par compatibilité (meilleurs en premier)

Une fois tout ça fait, vous devriez avoir **TOUJOURS** quelqu'un à swiper ! 🎉

