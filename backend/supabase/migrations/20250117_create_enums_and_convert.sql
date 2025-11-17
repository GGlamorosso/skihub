-- Migration: Créer types ENUM ride_style et language_code, et convertir les colonnes existantes
-- Cette migration standardise les types pour ride_styles et languages

-- ============================================
-- 1. Créer type ENUM ride_style
-- ============================================
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

-- ============================================
-- 2. Créer type ENUM language_code
-- ============================================
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

-- ============================================
-- 3. Convertir ride_styles de TEXT[] vers ride_style[]
-- ============================================
DO $$
DECLARE
  col_exists BOOLEAN;
  col_type TEXT;
BEGIN
  -- Vérifier si la colonne existe
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' 
      AND table_name = 'users' 
      AND column_name = 'ride_styles'
  ) INTO col_exists;
  
  IF col_exists THEN
    -- Récupérer le type actuel
    SELECT udt_name INTO col_type
    FROM information_schema.columns
    WHERE table_schema = 'public' 
      AND table_name = 'users' 
      AND column_name = 'ride_styles';
    
    -- Si c'est un array de text, convertir vers ride_style[]
    IF col_type = 'ARRAY' THEN
      -- Vérifier d'abord s'il y a des valeurs invalides
      -- Si oui, on les nettoie en les convertissant en NULL ou en supprimant les valeurs invalides
      ALTER TABLE public.users 
      ALTER COLUMN ride_styles TYPE ride_style[] 
      USING (
        CASE 
          WHEN ride_styles IS NULL THEN ARRAY[]::ride_style[]
          ELSE ARRAY(
            SELECT unnest(ride_styles::TEXT[])::ride_style
            WHERE unnest(ride_styles::TEXT[])::TEXT IN (
              'alpine', 'freeride', 'freestyle', 'park', 
              'racing', 'touring', 'powder', 'moguls', 'snowboard'
            )
          )
        END
      );
    END IF;
  ELSE
    -- Si la colonne n'existe pas, la créer directement avec le bon type
    ALTER TABLE public.users 
    ADD COLUMN ride_styles ride_style[] DEFAULT ARRAY[]::ride_style[];
  END IF;
END $$;

-- ============================================
-- 4. Convertir languages de TEXT[] vers language_code[]
-- ============================================
DO $$
DECLARE
  col_exists BOOLEAN;
  col_type TEXT;
BEGIN
  -- Vérifier si la colonne existe
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' 
      AND table_name = 'users' 
      AND column_name = 'languages'
  ) INTO col_exists;
  
  IF col_exists THEN
    -- Récupérer le type actuel
    SELECT udt_name INTO col_type
    FROM information_schema.columns
    WHERE table_schema = 'public' 
      AND table_name = 'users' 
      AND column_name = 'languages';
    
    -- Si c'est un array de text, convertir vers language_code[]
    IF col_type = 'ARRAY' THEN
      ALTER TABLE public.users 
      ALTER COLUMN languages TYPE language_code[] 
      USING (
        CASE 
          WHEN languages IS NULL THEN ARRAY[]::language_code[]
          ELSE ARRAY(
            SELECT unnest(languages::TEXT[])::language_code
            WHERE unnest(languages::TEXT[])::TEXT IN (
              'fr', 'en', 'de', 'it', 'es', 'pt', 'nl', 'ru', 'ja', 'zh'
            )
          )
        END
      );
    END IF;
  ELSE
    -- Si la colonne n'existe pas, la créer directement avec le bon type
    ALTER TABLE public.users 
    ADD COLUMN languages language_code[] DEFAULT ARRAY[]::language_code[];
  END IF;
END $$;

-- ============================================
-- 5. Commentaires
-- ============================================
COMMENT ON TYPE ride_style IS 'Styles de ski/snowboard';
COMMENT ON TYPE language_code IS 'Codes de langue ISO 639-1';
COMMENT ON COLUMN public.users.ride_styles IS 'Styles de ski/snowboard préférés (array de ride_style)';
COMMENT ON COLUMN public.users.languages IS 'Langues parlées par l''utilisateur (array de language_code)';

