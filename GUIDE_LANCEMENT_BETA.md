# 🚀 Guide de Lancement Bêta - CrewSnow

**Temps estimé** : 30-45 minutes  
**Date** : 2025-01-17

---

## 📋 Résumé des Actions

Vous devez :
1. ✅ Exécuter 4 nouvelles migrations SQL (15 min)
2. ✅ Vérifier/redéployer les Edge Functions (5 min)
3. ✅ Créer votre profil utilisateur (2 min)
4. ✅ Créer des stations de test (5 min)
5. ✅ Créer des utilisateurs de test (10 min)
6. ✅ Rebuild et lancer l'app (2 min)

---

## ÉTAPE 1 : Exécuter les Migrations SQL (15 minutes)

### Dans Supabase Dashboard > SQL Editor

Exécutez les migrations dans cet ordre :

#### 1.1 Ajouter colonne `objectives`
```sql
-- Copier le contenu de :
backend/supabase/migrations/20250117_add_objectives_column.sql
```

#### 1.2 Créer les ENUMs et convertir les colonnes
```sql
-- Copier le contenu de :
backend/supabase/migrations/20250117_create_enums_and_convert.sql
```

⚠️ **Attention** : Cette migration peut prendre quelques secondes si vous avez beaucoup de données.

#### 1.3 Ajouter `is_active` aux stations
```sql
-- Copier le contenu de :
backend/supabase/migrations/20250117_add_stations_is_active.sql
```

#### 1.4 Créer la vue `public_profiles_v`
```sql
-- Copier le contenu de :
backend/supabase/migrations/20250117_create_public_profiles_view.sql
```

### Vérification

Après avoir exécuté toutes les migrations, vérifiez que tout est en place :

```sql
-- Vérifier que tout est créé
SELECT 
  (SELECT COUNT(*) FROM information_schema.views WHERE table_name = 'public_profiles_v') as view_exists,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'objectives') as objectives_exists,
  (SELECT COUNT(*) FROM pg_type WHERE typname = 'ride_style') as ride_style_enum_exists,
  (SELECT COUNT(*) FROM pg_type WHERE typname = 'language_code') as language_code_enum_exists,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stations' AND column_name = 'is_active') as stations_is_active_exists;
```

**Résultat attendu** : Tous les résultats doivent être `1`.

---

## ÉTAPE 2 : Vérifier/Redéployer les Edge Functions (5 minutes)

### Dans Supabase Dashboard > Edge Functions

Vérifiez que ces 3 fonctions sont déployées :

1. **match-candidates**
2. **gatekeeper**
3. **manage-consent**

### Si une fonction n'est pas déployée ou doit être mise à jour :

1. Cliquez sur la fonction
2. Copiez le contenu du fichier correspondant :
   - `backend/supabase/functions/match-candidates/index.ts`
   - `backend/supabase/functions/gatekeeper/index.ts`
   - `backend/supabase/functions/manage-consent/index.ts`
3. Collez dans l'éditeur
4. Cliquez sur **Deploy**

### Test rapide

Dans Edge Functions > match-candidates > Invoke :

```json
{
  "limit": 10
}
```

**Résultat attendu** : `{"candidates": [...], "nextCursor": null}` (ou une liste de candidats)

---

## ÉTAPE 3 : Créer Votre Profil Utilisateur (2 minutes)

### 3.1 Trouver votre USER_ID

1. Allez dans **Supabase Dashboard > Authentication > Users**
2. Trouvez votre utilisateur
3. Copiez l'**UUID** (ex: `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11`)

### 3.2 Créer/Mettre à jour votre profil

Dans **SQL Editor**, exécutez (remplacez `VOTRE_USER_ID` par votre UUID) :

```sql
UPDATE public.users 
SET 
  onboarding_completed = true,
  is_active = true,
  level = 'intermediate',
  ride_styles = ARRAY['alpine', 'snowboard']::ride_style[],
  languages = ARRAY['fr', 'en']::language_code[],
  objectives = ARRAY['rencontrer des gens', 'améliorer ma technique'],
  bio = 'Passionné de ski !',
  last_active_at = NOW(),
  updated_at = NOW()
WHERE id = 'VOTRE_USER_ID';
```

### 3.3 Vérifier

```sql
SELECT 
  id, 
  username, 
  email, 
  onboarding_completed, 
  is_active, 
  level, 
  ride_styles,
  languages,
  objectives
FROM public.users 
WHERE id = 'VOTRE_USER_ID';
```

**Résultat attendu** : Votre profil avec toutes les colonnes remplies.

---

## ÉTAPE 4 : Créer des Stations de Test (5 minutes)

Dans **SQL Editor**, exécutez :

```sql
-- Insérer quelques stations de test
INSERT INTO public.stations (name, country_code, region, latitude, longitude, is_active)
VALUES
  ('Chamonix-Mont-Blanc', 'FR', 'Haute-Savoie', 45.9237, 6.8694, true),
  ('Val d''Isère', 'FR', 'Savoie', 45.4481, 6.9794, true),
  ('Courchevel', 'FR', 'Savoie', 45.4147, 6.6344, true),
  ('Zermatt', 'CH', 'Valais', 46.0207, 7.7491, true),
  ('St. Anton', 'AT', 'Tyrol', 47.1275, 10.2636, true),
  ('Verbier', 'CH', 'Valais', 46.0992, 7.2264, true),
  ('Tignes', 'FR', 'Savoie', 45.4736, 6.9094, true),
  ('Les Arcs', 'FR', 'Savoie', 45.5681, 6.8081, true)
ON CONFLICT (name, country_code) DO NOTHING;

-- Vérifier
SELECT id, name, country_code, is_active 
FROM public.stations 
ORDER BY name;
```

**Résultat attendu** : Au moins 5-8 stations créées.

---

## ÉTAPE 5 : Créer des Utilisateurs de Test (10 minutes)

### Option A : Via Supabase Dashboard (Recommandé)

1. Allez dans **Authentication > Users**
2. Cliquez sur **Add User**
3. Créez 2-3 utilisateurs de test avec des emails différents
4. Notez leurs UUIDs

### Option B : Via SQL (si vous avez un script de seed)

Voir `backend/supabase/seed/test_users.sql` (si disponible)

### Après création des utilisateurs

Pour chaque utilisateur créé, exécutez (remplacez `USER_ID_TEST_1`, etc.) :

```sql
-- Utilisateur de test 1
UPDATE public.users 
SET 
  onboarding_completed = true,
  is_active = true,
  level = 'advanced',
  ride_styles = ARRAY['freeride', 'powder']::ride_style[],
  languages = ARRAY['fr', 'en']::language_code[],
  objectives = ARRAY['trouver un partenaire de ski', 'explorer de nouvelles pistes'],
  bio = 'Passionné de freeride et de poudreuse !',
  username = 'skier_pro',
  last_active_at = NOW(),
  updated_at = NOW()
WHERE id = 'USER_ID_TEST_1';

-- Utilisateur de test 2
UPDATE public.users 
SET 
  onboarding_completed = true,
  is_active = true,
  level = 'beginner',
  ride_styles = ARRAY['alpine']::ride_style[],
  languages = ARRAY['fr']::language_code[],
  objectives = ARRAY['apprendre à skier', 'rencontrer des gens'],
  bio = 'Débutant enthousiaste !',
  username = 'beginner_skier',
  last_active_at = NOW(),
  updated_at = NOW()
WHERE id = 'USER_ID_TEST_2';
```

**Important** : Créez au moins 2-3 utilisateurs de test pour pouvoir tester le feed.

---

## ÉTAPE 6 : Rebuild et Lancer l'App (2 minutes)

```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

---

## ✅ Checklist de Vérification Finale

### Dans Supabase Dashboard

- [ ] Vue `public_profiles_v` visible dans Table Editor > Views
- [ ] Colonne `objectives` visible dans table `users`
- [ ] Types `ride_style` et `language_code` visibles dans Database > Types
- [ ] Colonne `is_active` visible dans table `stations`
- [ ] 3 Edge Functions déployées et actives
- [ ] Au moins 2-3 utilisateurs avec profils complétés
- [ ] Au moins 5 stations créées

### Dans l'app Flutter

- [ ] App démarre sans crash
- [ ] Login/Inscription fonctionne
- [ ] Onboarding se complète sans erreur
- [ ] Profil utilisateur se charge
- [ ] Feed affiche des candidats (si d'autres utilisateurs existent)
- [ ] Pas d'erreur dans les logs

---

## 🚨 Résolution de Problèmes

### Erreur : "column users.objectives does not exist"
**Solution** : Exécutez `20250117_add_objectives_column.sql`

### Erreur : "relation public_profiles_v does not exist"
**Solution** : Exécutez `20250117_create_public_profiles_view.sql`

### Erreur : "type ride_style does not exist"
**Solution** : Exécutez `20250117_create_enums_and_convert.sql`

### Erreur : "column stations.is_active does not exist"
**Solution** : Exécutez `20250117_add_stations_is_active.sql`

### Erreur : "Cannot coerce the result to a single JSON object" (0 rows)
**Solution** : Vérifiez que votre profil existe et que `onboarding_completed = true`

### Erreur : "Function match-candidates not found"
**Solution** : Déployez la fonction dans Supabase Dashboard > Edge Functions

### Le feed est vide
**Solution** : C'est normal si vous n'avez qu'un seul utilisateur. Créez 2-3 utilisateurs de test.

---

## 📊 Fichiers Créés

Les migrations suivantes ont été créées :

1. ✅ `backend/supabase/migrations/20250117_add_objectives_column.sql`
2. ✅ `backend/supabase/migrations/20250117_create_enums_and_convert.sql`
3. ✅ `backend/supabase/migrations/20250117_add_stations_is_active.sql`
4. ✅ `backend/supabase/migrations/20250117_create_public_profiles_view.sql`

**Documentation complète** : Voir `DIAGNOSTIC_COMPLET_BETA.md`

---

## 🎯 Prochaines Étapes Après la Bêta

Une fois la bêta lancée et testée :

1. **Collecter les retours** des utilisateurs bêta
2. **Corriger les bugs** identifiés
3. **Optimiser les performances** (index, requêtes)
4. **Ajouter des fonctionnalités** manquantes
5. **Préparer le lancement** en production

---

**Bon lancement de bêta ! 🚀**

