-- Migration: Vérifier et créer les colonnes manquantes dans users

-- 1. Vérifier quelles colonnes existent déjà
-- (Exécutez d'abord ceci pour voir la structure actuelle)
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- 2. Ajouter les colonnes manquantes si elles n'existent pas
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS level TEXT;

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS ride_styles TEXT[];

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS languages TEXT[];

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

-- 3. Créer votre profil (remplacez VOTRE_USER_ID par votre UUID)
-- Exécutez cette partie après avoir trouvé votre USER_ID
/*
UPDATE public.users 
SET 
  onboarding_completed = true,
  is_active = true,
  level = 'intermediate',
  ride_styles = ARRAY['alpine', 'snowboard'],
  languages = ARRAY['fr', 'en'],
  bio = 'Passionné de ski !',
  last_active_at = NOW(),
  updated_at = NOW()
WHERE id = 'VOTRE_USER_ID';
*/

