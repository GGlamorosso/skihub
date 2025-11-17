-- Script pour créer votre profil utilisateur
-- ÉTAPE 1 : Trouver votre USER_ID
-- Allez dans Supabase Dashboard > Authentication > Users
-- Copiez votre UUID

-- ÉTAPE 2 : Vérifier la structure de la table users
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- ÉTAPE 3 : Ajouter les colonnes manquantes (si nécessaire)
-- Exécutez seulement si les colonnes n'existent pas

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS level TEXT;

-- Note: ride_styles est de type ride_style[] (enum), pas TEXT[]
-- Ne pas créer cette colonne si elle existe déjà avec le bon type
-- Si elle n'existe pas, vous devrez la créer avec le bon type enum

-- Note: languages est de type language_code[] (enum), pas TEXT[]
-- Ne pas créer cette colonne si elle existe déjà avec le bon type

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS bio TEXT;

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS birth_date DATE;

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ;

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ÉTAPE 4 : Créer votre profil
-- REMPLACEZ 'VOTRE_USER_ID' par votre UUID réel
-- Exemple : 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'

-- Option A : Si votre profil existe déjà (UPDATE)
UPDATE public.users 
SET 
  onboarding_completed = true,
  is_active = true,
  level = 'intermediate',
  ride_styles = ARRAY['alpine', 'snowboard']::ride_style[],
  languages = ARRAY['fr', 'en']::language_code[],
  bio = 'Passionné de ski !',
  last_active_at = NOW(),
  updated_at = NOW()
WHERE id = 'VOTRE_USER_ID';

-- Option B : Si votre profil n'existe pas (INSERT)
-- Décommentez et utilisez cette partie si l'UPDATE ne trouve rien
/*
INSERT INTO public.users (
  id,
  email,
  username,
  onboarding_completed,
  is_active,
  level,
  ride_styles,
  languages,
  bio,
  created_at,
  updated_at,
  last_active_at
) VALUES (
  'VOTRE_USER_ID',
  'votre-email@exemple.com',  -- Remplacez par votre email
  'votre-username',             -- Remplacez par un username
  true,
  true,
  'intermediate',
  ARRAY['alpine', 'snowboard']::ride_style[],
  ARRAY['fr', 'en']::language_code[],
  'Passionné de ski !',
  NOW(),
  NOW(),
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  onboarding_completed = EXCLUDED.onboarding_completed,
  is_active = EXCLUDED.is_active,
  level = EXCLUDED.level,
  ride_styles = EXCLUDED.ride_styles::ride_style[],
  languages = EXCLUDED.languages,
  bio = EXCLUDED.bio,
  updated_at = NOW(),
  last_active_at = NOW();
*/

-- ÉTAPE 5 : Vérifier que ça a marché
SELECT 
  id, 
  email, 
  username, 
  onboarding_completed, 
  is_active, 
  level, 
  ride_styles,
  languages
FROM public.users 
WHERE id = 'VOTRE_USER_ID';

