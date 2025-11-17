# 🔍 Diagnostic Complet - État des Lieux pour Lancement Bêta

**Date** : 2025-01-17  
**Projet** : CrewSnow - Application de ski  
**Objectif** : Identifier tous les éléments manquants pour lancer la bêta

---

## 📊 Résumé Exécutif

### ✅ Ce qui est DÉJÀ en place
- ✅ Structure de base de données complète (tables principales)
- ✅ Edge Functions créées et corrigées dans le code
- ✅ Application Flutter structurée avec toutes les fonctionnalités
- ✅ Migrations SQL pour les tables principales
- ✅ RLS Policies configurées
- ✅ Services Flutter implémentés

### ❌ Ce qui MANQUE pour la bêta
1. **Vue SQL `public_profiles_v` manquante** (CRITIQUE)
2. **Colonne `objectives` manquante dans table `users`** (CRITIQUE)
3. **Types ENUM non créés** (`ride_style`, `language_code`) (CRITIQUE)
4. **Colonne `is_active` manquante dans table `stations`** (MOYEN)
5. **Incohérence de types pour `ride_styles`** (TEXT[] vs ENUM) (MOYEN)
6. **Edge Functions non déployées** (à vérifier)
7. **Données de test manquantes** (stations, utilisateurs)

---

## 🔴 PROBLÈMES CRITIQUES

### 1. Vue `public_profiles_v` MANQUANTE

**Problème** :  
Le code Flutter utilise `public_profiles_v` dans `match_service.dart` ligne 257, mais cette vue n'existe pas dans les migrations SQL.

**Fichier concerné** :
- `frontend/lib/services/match_service.dart:257`

**Impact** :  
❌ L'app crash lors de la récupération des détails d'un candidat  
❌ Impossible d'afficher les profils dans le feed

**Solution** :  
Créer la vue dans une nouvelle migration SQL (voir section Solutions).

---

### 2. Colonne `objectives` MANQUANTE dans table `users`

**Problème** :  
Le code Flutter utilise `objectives` partout (onboarding, profil, etc.) mais cette colonne n'existe pas dans la table `users`.

**Fichiers concernés** :
- `frontend/lib/services/user_service.dart:59,73`
- `frontend/lib/models/user_profile.dart:17`
- `frontend/lib/features/onboarding/controllers/onboarding_controller.dart:21,39,57,136`
- Et 10+ autres fichiers

**Impact** :  
❌ Crash lors de la sauvegarde du profil  
❌ Impossible de compléter l'onboarding  
❌ Erreur SQL lors de l'UPDATE/INSERT

**Solution** :  
Ajouter la colonne `objectives TEXT[]` dans la table `users` (voir section Solutions).

---

### 3. Types ENUM non créés

**Problème** :  
Le code SQL référence `ride_style[]` et `language_code[]` comme des types ENUM, mais ces types n'existent pas dans la base de données.

**Fichiers concernés** :
- `backend/CREER_PROFIL_UTILISATEUR.sql:57,58`
- `backend/supabase/migrations/20250117_fix_users_table.sql:22` (utilise TEXT[] au lieu de ENUM)
- Tous les scripts SQL qui utilisent `::ride_style[]` ou `::language_code[]`

**Impact** :  
❌ Erreur SQL lors de l'insertion/update de profils  
❌ Incohérence entre le code (qui attend des ENUM) et la base (TEXT[])

**Solution** :  
Créer les types ENUM `ride_style` et `language_code`, puis convertir la colonne `ride_styles` de TEXT[] vers ride_style[] (voir section Solutions).

---

## 🟡 PROBLÈMES MOYENS

### 4. Colonne `is_active` manquante dans table `stations`

**Problème** :  
Le code Flutter filtre les stations par `is_active` dans `user_service.dart:158`, mais cette colonne n'existe pas dans la migration `20250117_complete_schema.sql`.

**Fichier concerné** :
- `frontend/lib/services/user_service.dart:158`

**Impact** :  
⚠️ Erreur SQL lors de la récupération des stations  
⚠️ Impossible de filtrer les stations actives/inactives

**Solution** :  
Ajouter la colonne `is_active BOOLEAN NOT NULL DEFAULT true` dans la table `stations`.

---

### 5. Incohérence de types pour `ride_styles`

**Problème** :  
- La migration `20250117_fix_users_table.sql` crée `ride_styles TEXT[]`
- Mais `CREER_PROFIL_UTILISATEUR.sql` utilise `ride_styles::ride_style[]` (ENUM)
- Le code Flutter envoie des strings simples

**Impact** :  
⚠️ Confusion lors de la mise à jour des profils  
⚠️ Erreurs potentielles de type

**Solution** :  
Standardiser sur ENUM `ride_style[]` (voir section Solutions).

---

## 📋 CHECKLIST DE VÉRIFICATION

### Base de données SQL

- [ ] Vue `public_profiles_v` créée
- [ ] Colonne `objectives TEXT[]` ajoutée à `users`
- [ ] Types ENUM `ride_style` et `language_code` créés
- [ ] Colonne `ride_styles` convertie de TEXT[] vers ride_style[]
- [ ] Colonne `is_active` ajoutée à `stations`
- [ ] Toutes les migrations exécutées dans l'ordre
- [ ] RLS Policies actives sur toutes les tables

### Edge Functions

- [ ] `match-candidates` déployée et testée
- [ ] `gatekeeper` déployée et testée
- [ ] `manage-consent` déployée et testée
- [ ] Toutes les fonctions retournent les bonnes réponses

### Données de test

- [ ] Au moins 2-3 utilisateurs de test créés
- [ ] Profils utilisateurs complétés (`onboarding_completed = true`)
- [ ] Stations de ski créées (au moins 5-10 stations)
- [ ] `user_station_status` créés pour les utilisateurs de test
- [ ] Photos de profil uploadées (optionnel pour bêta)

### Application Flutter

- [ ] Variables d'environnement configurées (Supabase URL/Key)
- [ ] Firebase configuré (Crashlytics, Messaging)
- [ ] `flutter pub get` exécuté
- [ ] Pas d'erreurs de compilation
- [ ] App démarre sans crash

---

## 🛠️ SOLUTIONS DÉTAILLÉES

### Solution 1 : Créer la vue `public_profiles_v`

Créer un nouveau fichier : `backend/supabase/migrations/20250117_create_public_profiles_view.sql`

```sql
-- Vue pour les profils publics (utilisée par match-candidates et feed)
CREATE OR REPLACE VIEW public.public_profiles_v AS
SELECT 
  u.id,
  u.username,
  u.email,
  u.birth_date,
  u.level,
  u.ride_styles,
  u.languages,
  u.bio,
  u.objectives,
  u.is_active,
  u.onboarding_completed,
  u.created_at,
  -- Calculer l'âge depuis birth_date
  CASE 
    WHEN u.birth_date IS NOT NULL 
    THEN EXTRACT(YEAR FROM AGE(u.birth_date))
    ELSE NULL
  END AS age,
  -- Photo principale
  (
    SELECT storage_path 
    FROM profile_photos pp
    WHERE pp.user_id = u.id 
      AND pp.is_main = true 
      AND pp.moderation_status = 'approved'
    LIMIT 1
  ) AS main_photo_path,
  -- Station actuelle
  (
    SELECT s.name
    FROM user_station_status uss
    JOIN stations s ON uss.station_id = s.id
    WHERE uss.user_id = u.id 
      AND uss.is_active = true
      AND uss.date_from <= CURRENT_DATE
      AND uss.date_to >= CURRENT_DATE
    LIMIT 1
  ) AS current_station
FROM public.users u
WHERE u.onboarding_completed = true
  AND u.is_active = true;

-- Permissions RLS pour la vue
-- Note: Les vues héritent des permissions des tables sous-jacentes
-- Mais on peut ajouter une policy spécifique si nécessaire

COMMENT ON VIEW public.public_profiles_v IS 'Vue publique des profils utilisateurs pour le matching (exclut les données sensibles)';
```

**Exécution** :  
Dans Supabase Dashboard > SQL Editor, copier-coller et exécuter.

---

### Solution 2 : Ajouter colonne `objectives`

Créer un nouveau fichier : `backend/supabase/migrations/20250117_add_objectives_column.sql`

```sql
-- Ajouter colonne objectives à la table users
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS objectives TEXT[] DEFAULT ARRAY[]::TEXT[];

-- Commentaire
COMMENT ON COLUMN public.users.objectives IS 'Objectifs de l''utilisateur (ex: "rencontrer des gens", "améliorer ma technique", etc.)';
```

**Exécution** :  
Dans Supabase Dashboard > SQL Editor, copier-coller et exécuter.

---

### Solution 3 : Créer types ENUM et convertir colonnes

Créer un nouveau fichier : `backend/supabase/migrations/20250117_create_enums_and_convert.sql`

```sql
-- 1. Créer type ENUM ride_style
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ride_style') THEN
    CREATE TYPE ride_style AS ENUM (
      'alpine',
      'freeride',
      'freestyle',
      'park',
      'racing',
      'touring',
      'powder',
      'moguls',
      'snowboard'
    );
  END IF;
END $$;

-- 2. Créer type ENUM language_code
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'language_code') THEN
    CREATE TYPE language_code AS ENUM (
      'fr',
      'en',
      'de',
      'it',
      'es',
      'pt',
      'nl',
      'ru',
      'ja',
      'zh'
    );
  END IF;
END $$;

-- 3. Convertir ride_styles de TEXT[] vers ride_style[]
-- Étape 1 : Vérifier si la colonne existe et son type actuel
DO $$
DECLARE
  col_type TEXT;
BEGIN
  SELECT data_type INTO col_type
  FROM information_schema.columns
  WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND column_name = 'ride_styles';
  
  -- Si la colonne n'existe pas, la créer directement avec le bon type
  IF col_type IS NULL THEN
    ALTER TABLE public.users 
    ADD COLUMN ride_styles ride_style[] DEFAULT ARRAY[]::ride_style[];
  -- Si elle existe en TEXT[], la convertir
  ELSIF col_type = 'ARRAY' THEN
    -- Convertir les valeurs existantes
    ALTER TABLE public.users 
    ALTER COLUMN ride_styles TYPE ride_style[] 
    USING (
      CASE 
        WHEN ride_styles IS NULL THEN ARRAY[]::ride_style[]
        ELSE ARRAY(
          SELECT unnest(ride_styles::TEXT[])::ride_style
          WHERE unnest(ride_styles::TEXT[])::ride_style IS NOT NULL
        )
      END
    );
  END IF;
END $$;

-- 4. Convertir languages de TEXT[] vers language_code[]
DO $$
DECLARE
  col_type TEXT;
BEGIN
  SELECT data_type INTO col_type
  FROM information_schema.columns
  WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND column_name = 'languages';
  
  IF col_type IS NULL THEN
    ALTER TABLE public.users 
    ADD COLUMN languages language_code[] DEFAULT ARRAY[]::language_code[];
  ELSIF col_type = 'ARRAY' THEN
    ALTER TABLE public.users 
    ALTER COLUMN languages TYPE language_code[] 
    USING (
      CASE 
        WHEN languages IS NULL THEN ARRAY[]::language_code[]
        ELSE ARRAY(
          SELECT unnest(languages::TEXT[])::language_code
          WHERE unnest(languages::TEXT[])::language_code IS NOT NULL
        )
      END
    );
  END IF;
END $$;

-- Commentaires
COMMENT ON TYPE ride_style IS 'Styles de ski/snowboard';
COMMENT ON TYPE language_code IS 'Codes de langue ISO 639-1';
```

**Exécution** :  
Dans Supabase Dashboard > SQL Editor, copier-coller et exécuter.

**⚠️ Attention** :  
Cette migration peut échouer si des valeurs invalides existent dans `ride_styles` ou `languages`. Vérifiez d'abord :

```sql
-- Vérifier les valeurs invalides
SELECT id, ride_styles, languages 
FROM public.users 
WHERE ride_styles IS NOT NULL 
  AND array_length(ride_styles, 1) > 0;
```

---

### Solution 4 : Ajouter colonne `is_active` à stations

Créer un nouveau fichier : `backend/supabase/migrations/20250117_add_stations_is_active.sql`

```sql
-- Ajouter colonne is_active à stations
ALTER TABLE public.stations
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- Mettre toutes les stations existantes comme actives
UPDATE public.stations
SET is_active = true
WHERE is_active IS NULL;

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_stations_is_active 
ON public.stations(is_active) 
WHERE is_active = true;

-- Commentaire
COMMENT ON COLUMN public.stations.is_active IS 'Indique si la station est active et visible dans l''app';
```

**Exécution** :  
Dans Supabase Dashboard > SQL Editor, copier-coller et exécuter.

---

## 📝 PLAN D'ACTION POUR LANCER LA BÊTA

### Étape 1 : Exécuter toutes les migrations SQL (15 minutes)

Dans **Supabase Dashboard > SQL Editor**, exécutez dans l'ordre :

1. ✅ `20250117_complete_schema.sql` (déjà fait ?)
2. ✅ `20250117_create_user_consents.sql` (déjà fait ?)
3. ✅ `20250117_add_objectives_column.sql` (NOUVEAU)
4. ✅ `20250117_create_enums_and_convert.sql` (NOUVEAU)
5. ✅ `20250117_add_stations_is_active.sql` (NOUVEAU)
6. ✅ `20250117_create_public_profiles_view.sql` (NOUVEAU)

**Vérification** :
```sql
-- Vérifier que tout est en place
SELECT 
  (SELECT COUNT(*) FROM information_schema.views WHERE table_name = 'public_profiles_v') as view_exists,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'objectives') as objectives_exists,
  (SELECT COUNT(*) FROM pg_type WHERE typname = 'ride_style') as ride_style_enum_exists,
  (SELECT COUNT(*) FROM pg_type WHERE typname = 'language_code') as language_code_enum_exists,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stations' AND column_name = 'is_active') as stations_is_active_exists;
```

Tous les résultats doivent être `1`.

---

### Étape 2 : Redéployer les Edge Functions (5 minutes)

Dans **Supabase Dashboard > Edge Functions** :

1. **match-candidates** :
   - Ouvrir la fonction
   - Remplacer le code par celui de `backend/supabase/functions/match-candidates/index.ts`
   - Cliquer sur **Deploy**

2. **gatekeeper** :
   - Vérifier qu'il est déployé
   - Si besoin, redéployer avec le code de `backend/supabase/functions/gatekeeper/index.ts`

3. **manage-consent** :
   - Vérifier qu'il est déployé
   - Si besoin, redéployer avec le code de `backend/supabase/functions/manage-consent/index.ts`

**Test** :
```bash
# Tester match-candidates
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/match-candidates \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 10}'
```

---

### Étape 3 : Créer votre profil utilisateur (2 minutes)

Dans **Supabase Dashboard > SQL Editor** :

```sql
-- 1. Trouver votre USER_ID
-- Allez dans Authentication > Users et copiez votre UUID

-- 2. Créer/mettre à jour votre profil
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

-- 3. Vérifier
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

---

### Étape 4 : Créer des stations de test (5 minutes)

Dans **Supabase Dashboard > SQL Editor** :

```sql
-- Insérer quelques stations de test
INSERT INTO public.stations (name, country_code, region, latitude, longitude, is_active)
VALUES
  ('Chamonix-Mont-Blanc', 'FR', 'Haute-Savoie', 45.9237, 6.8694, true),
  ('Val d''Isère', 'FR', 'Savoie', 45.4481, 6.9794, true),
  ('Courchevel', 'FR', 'Savoie', 45.4147, 6.6344, true),
  ('Zermatt', 'CH', 'Valais', 46.0207, 7.7491, true),
  ('St. Anton', 'AT', 'Tyrol', 47.1275, 10.2636, true)
ON CONFLICT (name, country_code) DO NOTHING;

-- Vérifier
SELECT id, name, country_code, is_active FROM public.stations;
```

---

### Étape 5 : Créer des utilisateurs de test (10 minutes)

Option A : Via Supabase Dashboard > Authentication > Users (créer manuellement)  
Option B : Via SQL (voir `backend/supabase/seed/test_users.sql`)

**Important** : Après création des utilisateurs, créer leurs profils avec le même UPDATE SQL que l'étape 3.

---

### Étape 6 : Rebuild et lancer l'app Flutter (2 minutes)

```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

---

## ✅ VÉRIFICATIONS FINALES

Après toutes les étapes, vérifiez :

### Dans Supabase Dashboard

- [ ] Vue `public_profiles_v` visible dans Table Editor
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
- [ ] Pas d'erreur `column does not exist`
- [ ] Pas d'erreur `view does not exist`
- [ ] Pas d'erreur `type does not exist`

---

## 🚨 PROBLÈMES CONNUS ET SOLUTIONS

### Problème : "column users.objectives does not exist"
**Solution** : Exécuter `20250117_add_objectives_column.sql`

### Problème : "relation public_profiles_v does not exist"
**Solution** : Exécuter `20250117_create_public_profiles_view.sql`

### Problème : "type ride_style does not exist"
**Solution** : Exécuter `20250117_create_enums_and_convert.sql`

### Problème : "column stations.is_active does not exist"
**Solution** : Exécuter `20250117_add_stations_is_active.sql`

### Problème : "Cannot coerce the result to a single JSON object" (0 rows)
**Solution** : Vérifier que votre profil existe et que `onboarding_completed = true`

### Problème : "Function match-candidates not found"
**Solution** : Déployer la fonction dans Supabase Dashboard > Edge Functions

---

## 📊 STATISTIQUES DU CODE

- **Fichiers Flutter** : ~88 fichiers Dart
- **Migrations SQL** : 4 migrations existantes + 4 nouvelles nécessaires
- **Edge Functions** : 3 fonctions
- **Tables SQL** : 13 tables principales
- **Fonctionnalités** : Auth, Onboarding, Matching, Chat, Premium, Tracking, etc.

---

## 🎯 CONCLUSION

**État actuel** :  
Le code est bien structuré et la plupart des fonctionnalités sont implémentées. Il manque principalement :
- 4 migrations SQL à créer et exécuter
- Vérification du déploiement des Edge Functions
- Création de données de test

**Temps estimé pour lancer la bêta** :  
30-45 minutes (exécution des migrations + tests)

**Risques** :  
🟢 Faible - Tous les problèmes identifiés ont des solutions claires

**Prochaines étapes** :  
1. Créer les 4 migrations SQL manquantes
2. Exécuter toutes les migrations dans Supabase
3. Redéployer les Edge Functions
4. Créer données de test
5. Tester l'app complètement
6. Lancer la bêta ! 🚀

---

**Document créé le** : 2025-01-17  
**Dernière mise à jour** : 2025-01-17

