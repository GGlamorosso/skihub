# ✅ Vérifier que les utilisateurs de test sont visibles dans l'app

## 📋 Checklist avant de tester dans l'app

### 1. ✅ Script SQL exécuté avec succès

Vérifiez dans **Supabase Dashboard > SQL Editor** que le script s'est exécuté sans erreur. Vous devriez voir :
- `✅ Utilisateur créé : freeride_expert`
- `✅ Utilisateur créé : alpine_master`
- ... (22 messages au total)
- `🎉 22 utilisateurs de test créés avec des dates de séjour variées !`

### 2. 🔍 Vérifier dans la base de données

Exécutez cette requête dans **SQL Editor** pour vérifier :

```sql
-- Vérifier que les 22 utilisateurs sont bien créés
SELECT 
    username,
    level,
    ride_styles,
    is_active
FROM public.users 
WHERE username IN (
    'freeride_expert', 'alpine_master', 'snowboard_pro', 'touring_enthusiast',
    'freestyle_king', 'alpine_lover', 'powder_seeker', 'snowboard_advanced',
    'ski_advanced', 'backcountry_lover', 'intermediate_skier', 'snowboard_intermediate',
    'weekend_skier', 'park_rider', 'alpine_intermediate', 'snowboard_weekend',
    'ski_intermediate', 'freestyle_intermediate', 'ski_newbie', 'snowboard_beginner',
    'beginner_skier', 'new_skier'
)
ORDER BY level DESC, username;
```

Vous devriez voir **22 utilisateurs**.

### 3. 📍 Vérifier les stations et dates

```sql
-- Vérifier que les utilisateurs ont des stations configurées
SELECT 
    u.username,
    u.level,
    s.name as station,
    uss.date_from,
    uss.date_to,
    uss.radius_km
FROM public.users u
JOIN public.user_station_status uss ON u.id = uss.user_id AND uss.is_active = true
JOIN public.stations s ON uss.station_id = s.id
WHERE u.username IN (
    'freeride_expert', 'alpine_master', 'snowboard_pro', 'touring_enthusiast',
    'freestyle_king', 'alpine_lover', 'powder_seeker', 'snowboard_advanced',
    'ski_advanced', 'backcountry_lover', 'intermediate_skier', 'snowboard_intermediate',
    'weekend_skier', 'park_rider', 'alpine_intermediate', 'snowboard_weekend',
    'ski_intermediate', 'freestyle_intermediate', 'ski_newbie', 'snowboard_beginner',
    'beginner_skier', 'new_skier'
)
ORDER BY u.level DESC, u.username;
```

Vous devriez voir **22 lignes** avec des stations et des dates.

---

## 🚀 Pour voir les utilisateurs dans l'app

### ⚠️ IMPORTANT : Configuration requise

Pour que l'app affiche les utilisateurs de test, **vous devez être connecté avec un compte utilisateur qui a aussi une station configurée** !

### Étapes :

1. **Connectez-vous à l'app** avec un compte utilisateur (pas un des 22 comptes de test)

2. **Complétez l'onboarding** si ce n'est pas déjà fait :
   - Sélectionnez une station
   - Définissez vos dates de séjour
   - Configurez votre profil (niveau, styles, etc.)

3. **Allez sur l'écran de matching** (swipe)

4. **Les utilisateurs de test devraient apparaître** si :
   - ✅ Votre station est la même ou proche de la leur
   - ✅ Vos dates de séjour se chevauchent
   - ✅ Vous n'avez pas déjà liké/matché ces utilisateurs

---

## 🧪 Tester le matching avec un utilisateur de test

Si vous voulez vous connecter avec un des utilisateurs de test :

1. **Dans Supabase Dashboard > Authentication > Users**, trouvez l'UUID d'un utilisateur de test

2. **Créez un mot de passe** pour cet utilisateur (ou utilisez "Reset password")

3. **Connectez-vous dans l'app** avec l'email de cet utilisateur

4. **Vous devriez voir les autres utilisateurs de test** dans le matching !

---

## 🔧 Dépannage

### ❌ "Aucun utilisateur trouvé"

**Causes possibles :**
- Votre station n'est pas la même ou proche des utilisateurs de test
- Vos dates de séjour ne se chevauchent pas
- Vous avez déjà liké tous les utilisateurs disponibles

**Solution :**
1. Vérifiez votre station dans l'app
2. Ajustez vos dates de séjour pour qu'elles chevauchent avec les utilisateurs de test
3. Les dates des utilisateurs de test sont réparties sur plusieurs semaines (voir le script SQL)

### ❌ "Erreur lors du chargement"

**Vérifiez :**
1. Que l'Edge Function `match-candidates` est déployée
2. Que les RLS policies permettent la lecture des utilisateurs
3. Les logs dans Supabase Dashboard > Edge Functions > Logs

---

## 📊 Vérifier le matching SQL directement

Pour tester le matching sans passer par l'app :

```sql
-- Remplacer <VOTRE_USER_ID> par votre UUID
SELECT * FROM get_potential_matches('<VOTRE_USER_ID>'::UUID, 20);
```

Cette requête vous montrera les utilisateurs qui matchent avec vous selon l'algorithme.

---

## ✅ Résumé

- ✅ **22 utilisateurs de test créés** avec profils variés
- ✅ **Dates réparties sur plusieurs semaines** pour tester le matching temporel
- ✅ **Stations variées** (Chamonix, Val d'Isère, Courchevel, etc.)
- ✅ **Niveaux variés** (expert, advanced, intermediate, beginner)
- ✅ **Styles variés** (alpine, freestyle, freeride, park, etc.)

**Vous pouvez maintenant tester le matching dans l'app !** 🎉

