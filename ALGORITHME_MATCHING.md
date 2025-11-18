# 🎯 Algorithme de Matching - Fallback Progressif

## 📊 Comment fonctionne l'algorithme

L'algorithme de matching fonctionne en **4 niveaux progressifs** pour garantir qu'il y a **TOUJOURS** quelqu'un à swiper, même si les critères sont progressivement relâchés.

---

## 🔍 Niveau 1 : Matching STRICT (meilleure compatibilité)

**Critères** :
- ✅ Même station OU stations proches (dans le rayon de recherche)
- ✅ Dates qui se chevauchent exactement
- ✅ Distance dans le rayon acceptable
- ✅ Pas déjà liké/matché/bloqué

**Scoring** :
- Niveau identique : **4 points**
- Niveau adjacent : **2 points**
- Styles de ski communs : **2 points par style**
- Langues communes : **1 point par langue**
- Dates qui se chevauchent : **1 point**
- Distance : **10 / (1 + distance_km)** points

**Résultat** : Les candidats les plus compatibles en premier

---

## 🔍 Niveau 2 : Matching RELAXÉ (si niveau 1 = 0 résultats)

**Critères** :
- ✅ Même station OU stations proches
- ⚠️ Dates **proches** (dans les 30 jours) OU qui se chevauchent
- ✅ Distance dans le rayon acceptable
- ✅ Pas déjà liké/matché/bloqué

**Scoring** (réduit) :
- Niveau identique : **3 points** (au lieu de 4)
- Niveau adjacent : **1 point** (au lieu de 2)
- Styles de ski communs : **2 points par style**
- Langues communes : **1 point par langue**
- Dates : **0 point** (pas de bonus car dates peuvent ne pas se chevaucher)
- Distance : **8 / (1 + distance_km)** points (réduit)

**Résultat** : Candidats compatibles mais avec dates moins strictes

---

## 🔍 Niveau 3 : Matching LOOSE (si niveau 2 = 0 résultats)

**Critères** :
- ✅ Même station (si l'utilisateur a une station)
- ❌ Pas de contrainte de dates
- ❌ Pas de contrainte de distance
- ✅ Pas déjà liké/matché/bloqué

**Scoring** (minimal) :
- Niveau identique : **2 points**
- Niveau adjacent : **1 point**
- Styles de ski communs : **1 point par style** (réduit)
- Langues communes : **1 point par langue**
- Distance : **5 / (1 + distance_km)** points (très réduit)

**Résultat** : Candidats à la même station, peu importe les dates/distance

---

## 🔍 Niveau 4 : FALLBACK ULTIME (si niveau 3 = 0 résultats)

**Critères** :
- ✅ Utilisateur actif
- ✅ Pas banni
- ❌ Pas de contrainte de station
- ❌ Pas de contrainte de dates
- ❌ Pas de contrainte de distance
- ✅ Pas déjà liké/matché/bloqué

**Scoring** (très minimal) :
- Niveau identique : **1 point**
- Styles de ski communs : **0.5 point par style**
- Langues communes : **0.5 point par langue**
- Score de base : **0.1 point**

**Résultat** : Tous les utilisateurs actifs, triés par compatibilité minimale et dernière activité

**Limite** : 50 candidats maximum pour éviter trop de résultats

---

## 🎯 Garantie

**L'algorithme garantit qu'il y a TOUJOURS des candidats à proposer**, sauf si :
- Tous les utilisateurs sont déjà likés/matchés/bloqués
- Il n'y a vraiment personne d'actif dans la base

---

## 📈 Ordre de priorité

Les candidats sont toujours triés par :
1. **Score de compatibilité** (décroissant)
2. **Distance** (croissante)
3. **Dernière activité** (pour le fallback ultime)

---

## 🔧 Comment tester

### Vérifier que l'algorithme fonctionne

```sql
-- Tester avec votre user_id
SELECT * FROM get_candidate_scores('VOTRE_USER_ID') LIMIT 10;
```

**Résultat attendu** : Au moins quelques candidats, même si les critères sont relâchés

### Vérifier les différents niveaux

```sql
-- Compter les candidats par niveau (approximatif)
-- Niveau 1 (strict) : score > 5
SELECT COUNT(*) FROM get_candidate_scores('VOTRE_USER_ID') WHERE score > 5;

-- Niveau 2-3 (relaxé/loose) : score entre 2 et 5
SELECT COUNT(*) FROM get_candidate_scores('VOTRE_USER_ID') WHERE score BETWEEN 2 AND 5;

-- Niveau 4 (fallback) : score < 2
SELECT COUNT(*) FROM get_candidate_scores('VOTRE_USER_ID') WHERE score < 2;
```

---

## 🚀 Migration à appliquer

Pour activer cet algorithme amélioré :

1. **Exécuter la migration** dans Supabase Dashboard → SQL Editor :
   ```sql
   -- Copier-coller le contenu de :
   -- supabase/migrations/20250118_get_candidate_scores_with_fallback.sql
   ```

2. **Vérifier** que la fonction fonctionne :
   ```sql
   SELECT COUNT(*) FROM get_candidate_scores('VOTRE_USER_ID');
   ```

3. **Relancer l'app** et vérifier que des candidats apparaissent

---

## 📊 Exemple de progression

**Scénario** : Vous êtes à la station A du 20-27 décembre, niveau intermediate

1. **Niveau 1** : Cherche des utilisateurs à la station A, du 20-27 déc, niveau intermediate/beginner/advanced
2. **Si 0 résultats** → **Niveau 2** : Cherche à la station A, dates proches (15 déc - 5 jan), niveau compatible
3. **Si 0 résultats** → **Niveau 3** : Cherche à la station A, peu importe les dates
4. **Si 0 résultats** → **Niveau 4** : Cherche tous les utilisateurs actifs, triés par compatibilité minimale

**Résultat** : Vous verrez toujours quelqu'un à swiper, même si les critères sont très relâchés !

