-- Script complet pour préparer la base de données pour la BÊTA CrewSnow
-- Exécuter ce script dans Supabase Dashboard > SQL Editor
-- Temps d'exécution estimé : 2-3 minutes

-- ========================================
-- ÉTAPE 1 : Migrations critiques
-- ========================================

-- 1.1 Ajouter colonne objectives
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS objectives TEXT[] DEFAULT ARRAY[]::TEXT[];

-- 1.2 Créer types ENUM
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

-- 1.3 Convertir les colonnes existantes
DO $$
DECLARE
  col_exists BOOLEAN;
  col_type TEXT;
BEGIN
  -- Convertir ride_styles
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' 
      AND table_name = 'users' 
      AND column_name = 'ride_styles'
  ) INTO col_exists;
  
  IF col_exists THEN
    SELECT udt_name INTO col_type
    FROM information_schema.columns
    WHERE table_schema = 'public' 
      AND table_name = 'users' 
      AND column_name = 'ride_styles';
    
    IF col_type = '_text' THEN  -- Array of text
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
    ALTER TABLE public.users 
    ADD COLUMN ride_styles ride_style[] DEFAULT ARRAY[]::ride_style[];
  END IF;
  
  -- Convertir languages
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' 
      AND table_name = 'users' 
      AND column_name = 'languages'
  ) INTO col_exists;
  
  IF col_exists THEN
    SELECT udt_name INTO col_type
    FROM information_schema.columns
    WHERE table_schema = 'public' 
      AND table_name = 'users' 
      AND column_name = 'languages';
    
    IF col_type = '_text' THEN  -- Array of text
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
    ALTER TABLE public.users 
    ADD COLUMN languages language_code[] DEFAULT ARRAY[]::language_code[];
  END IF;
END $$;

-- 1.4 Ajouter is_active aux stations
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

-- 1.5 Créer la vue public_profiles_v
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
    THEN EXTRACT(YEAR FROM AGE(u.birth_date))::INTEGER
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
  ) AS current_station,
  -- Station ID
  (
    SELECT s.id
    FROM user_station_status uss
    JOIN stations s ON uss.station_id = s.id
    WHERE uss.user_id = u.id 
      AND uss.is_active = true
      AND uss.date_from <= CURRENT_DATE
      AND uss.date_to >= CURRENT_DATE
    LIMIT 1
  ) AS current_station_id
FROM public.users u
WHERE u.onboarding_completed = true
  AND u.is_active = true;

-- ========================================
-- ÉTAPE 2 : Créer stations de test
-- ========================================

INSERT INTO public.stations (name, country_code, region, latitude, longitude, is_active)
VALUES
  -- Stations françaises
  ('Chamonix-Mont-Blanc', 'FR', 'Haute-Savoie', 45.9237, 6.8694, true),
  ('Val d''Isère', 'FR', 'Savoie', 45.4481, 6.9794, true),
  ('Courchevel', 'FR', 'Savoie', 45.4147, 6.6344, true),
  ('Tignes', 'FR', 'Savoie', 45.4736, 6.9094, true),
  ('Les Arcs', 'FR', 'Savoie', 45.5681, 6.8081, true),
  ('Méribel', 'FR', 'Savoie', 45.3849, 6.5697, true),
  ('Avoriaz', 'FR', 'Haute-Savoie', 46.1933, 6.7725, true),
  ('La Plagne', 'FR', 'Savoie', 45.5147, 6.6775, true),
  ('Alpe d''Huez', 'FR', 'Isère', 45.0939, 6.0694, true),
  ('Les Deux Alpes', 'FR', 'Isère', 45.0139, 6.1225, true),
  
  -- Stations suisses
  ('Zermatt', 'CH', 'Valais', 46.0207, 7.7491, true),
  ('Verbier', 'CH', 'Valais', 46.0992, 7.2264, true),
  ('Sankt Moritz', 'CH', 'Grisons', 46.4908, 9.8355, true),
  ('Davos', 'CH', 'Grisons', 46.8037, 9.8340, true),
  ('Wengen', 'CH', 'Berne', 46.6081, 7.9225, true),
  
  -- Stations autrichiennes
  ('St. Anton am Arlberg', 'AT', 'Tyrol', 47.1275, 10.2636, true),
  ('Innsbruck', 'AT', 'Tyrol', 47.2692, 11.4041, true),
  ('Saalbach', 'AT', 'Salzburg', 47.3886, 12.6344, true),
  ('Kitzbühel', 'AT', 'Tyrol', 47.4464, 12.3928, true),
  
  -- Stations italiennes
  ('Cortina d''Ampezzo', 'IT', 'Vénétie', 46.5369, 12.1357, true),
  ('Val Gardena', 'IT', 'Trentino-Haut-Adige', 46.5569, 11.6794, true)
ON CONFLICT (name, country_code) DO UPDATE SET
  is_active = EXCLUDED.is_active,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude;

-- ========================================
-- ÉTAPE 3 : Vérifications
-- ========================================

-- Vérifier que tout est en place
DO $$
DECLARE
  view_count INTEGER;
  objectives_count INTEGER;
  ride_style_count INTEGER;
  language_code_count INTEGER;
  stations_is_active_count INTEGER;
  stations_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO view_count FROM information_schema.views WHERE table_name = 'public_profiles_v';
  SELECT COUNT(*) INTO objectives_count FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'objectives';
  SELECT COUNT(*) INTO ride_style_count FROM pg_type WHERE typname = 'ride_style';
  SELECT COUNT(*) INTO language_code_count FROM pg_type WHERE typname = 'language_code';
  SELECT COUNT(*) INTO stations_is_active_count FROM information_schema.columns WHERE table_name = 'stations' AND column_name = 'is_active';
  SELECT COUNT(*) INTO stations_count FROM public.stations WHERE is_active = true;

  -- Afficher les résultats
  RAISE NOTICE '=== VÉRIFICATION SETUP BÊTA ===';
  RAISE NOTICE 'Vue public_profiles_v créée: %', CASE WHEN view_count = 1 THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Colonne objectives créée: %', CASE WHEN objectives_count = 1 THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Type ride_style créé: %', CASE WHEN ride_style_count = 1 THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Type language_code créé: %', CASE WHEN language_code_count = 1 THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Colonne stations.is_active créée: %', CASE WHEN stations_is_active_count = 1 THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Stations créées: % stations actives', stations_count;
  
  IF view_count = 1 AND objectives_count = 1 AND ride_style_count = 1 AND language_code_count = 1 AND stations_is_active_count = 1 AND stations_count > 0 THEN
    RAISE NOTICE '🎉 SETUP BÊTA TERMINÉ AVEC SUCCÈS !';
  ELSE
    RAISE NOTICE '❌ ERREURS DÉTECTÉES - Vérifiez les logs ci-dessus';
  END IF;
END $$;

-- ========================================
-- COMMENTAIRES
-- ========================================
COMMENT ON TYPE ride_style IS 'Styles de ski/snowboard pour CrewSnow';
COMMENT ON TYPE language_code IS 'Codes de langue ISO 639-1 pour CrewSnow';
COMMENT ON COLUMN public.users.objectives IS 'Objectifs de l''utilisateur (ex: "rencontrer des gens", "améliorer ma technique")';
COMMENT ON COLUMN public.stations.is_active IS 'Indique si la station est active et visible dans l''app CrewSnow';
COMMENT ON VIEW public.public_profiles_v IS 'Vue publique des profils utilisateurs pour le matching CrewSnow (exclut les données sensibles)';

-- Script terminé - Prêt pour la bêta ! 🚀
