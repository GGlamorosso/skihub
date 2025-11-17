-- Script de vérification de l'état actuel de la base de données CrewSnow
-- Exécutez ceci pour voir ce qui existe déjà dans votre projet Supabase

-- ========================================
-- VÉRIFICATION DES STRUCTURES EXISTANTES
-- ========================================

-- 1. Vérifier les colonnes de la table users
SELECT 
  'TABLE USERS - COLONNES EXISTANTES' as section;

SELECT 
  column_name,
  data_type,
  udt_name,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- 2. Vérifier les types ENUM existants
SELECT 
  'TYPES ENUM EXISTANTS' as section;

SELECT 
  typname as enum_name,
  unnest(enum_range(NULL::enum_type)) as enum_value
FROM pg_type 
WHERE typtype = 'e'
  AND typname IN ('ride_style', 'language_code')
ORDER BY typname, enum_value;

-- Alternative si la requête ci-dessus ne marche pas :
SELECT 
  'TYPES ENUM ALTERNATIF' as section;

SELECT typname as enum_name
FROM pg_type 
WHERE typtype = 'e'
  AND typname LIKE '%ride%' OR typname LIKE '%language%';

-- 3. Vérifier les vues existantes
SELECT 
  'VUES EXISTANTES' as section;

SELECT 
  table_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name LIKE '%profile%'
ORDER BY table_name;

-- 4. Vérifier les colonnes de la table stations
SELECT 
  'TABLE STATIONS - COLONNES EXISTANTES' as section;

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'stations'
ORDER BY ordinal_position;

-- 5. Compter les données existantes
SELECT 
  'DONNÉES EXISTANTES' as section;

-- Compter les utilisateurs
SELECT 'utilisateurs totaux' as type, COUNT(*) as count FROM public.users
UNION ALL
SELECT 'utilisateurs actifs' as type, COUNT(*) as count FROM public.users WHERE is_active = true
UNION ALL
SELECT 'utilisateurs avec onboarding complet' as type, COUNT(*) as count FROM public.users WHERE onboarding_completed = true
UNION ALL
SELECT 'stations totales' as type, COUNT(*) as count FROM public.stations
UNION ALL
SELECT 'stations actives' as type, COUNT(*) as count FROM public.stations WHERE is_active = true;

-- 6. Vérifier les Edge Functions (tables de métadonnées)
SELECT 
  'EDGE FUNCTIONS DANS MÉTADONNÉES' as section;

-- Cette requête peut ne pas marcher selon la configuration Supabase
SELECT 
  name,
  status,
  version
FROM extensions.pg_net_http_request_queue
WHERE name LIKE '%match%' OR name LIKE '%gate%' OR name LIKE '%consent%'
LIMIT 5;

-- 7. Tester la vue public_profiles_v si elle existe
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'public_profiles_v') THEN
    RAISE NOTICE '✅ Vue public_profiles_v EXISTE - Test de sélection...';
    PERFORM COUNT(*) FROM public.public_profiles_v;
    RAISE NOTICE 'Nombre de profils dans la vue : %', (SELECT COUNT(*) FROM public.public_profiles_v);
  ELSE
    RAISE NOTICE '❌ Vue public_profiles_v N''EXISTE PAS';
  END IF;
END $$;

-- 8. Résumé diagnostique
DO $$
DECLARE
  objectives_exists BOOLEAN;
  ride_styles_type TEXT;
  languages_type TEXT;
  stations_is_active BOOLEAN;
  profiles_view_exists BOOLEAN;
BEGIN
  -- Vérifications
  SELECT COUNT(*) = 1 INTO objectives_exists 
  FROM information_schema.columns 
  WHERE table_name = 'users' AND column_name = 'objectives';
  
  SELECT udt_name INTO ride_styles_type
  FROM information_schema.columns
  WHERE table_name = 'users' AND column_name = 'ride_styles';
  
  SELECT udt_name INTO languages_type
  FROM information_schema.columns
  WHERE table_name = 'users' AND column_name = 'languages';
  
  SELECT COUNT(*) = 1 INTO stations_is_active
  FROM information_schema.columns 
  WHERE table_name = 'stations' AND column_name = 'is_active';
  
  SELECT COUNT(*) = 1 INTO profiles_view_exists
  FROM information_schema.views 
  WHERE table_name = 'public_profiles_v';

  RAISE NOTICE '=== DIAGNOSTIC ÉTAT ACTUEL ===';
  RAISE NOTICE 'Colonne users.objectives : %', CASE WHEN objectives_exists THEN '✅ EXISTE' ELSE '❌ MANQUE' END;
  RAISE NOTICE 'Type ride_styles : %', COALESCE(ride_styles_type, 'MANQUE');
  RAISE NOTICE 'Type languages : %', COALESCE(languages_type, 'MANQUE');
  RAISE NOTICE 'Colonne stations.is_active : %', CASE WHEN stations_is_active THEN '✅ EXISTE' ELSE '❌ MANQUE' END;
  RAISE NOTICE 'Vue public_profiles_v : %', CASE WHEN profiles_view_exists THEN '✅ EXISTE' ELSE '❌ MANQUE' END;
  
  -- Recommandations
  RAISE NOTICE '=== ACTIONS NÉCESSAIRES ===';
  
  IF NOT objectives_exists THEN
    RAISE NOTICE '🔧 REQUIS: Ajouter colonne objectives à users';
  END IF;
  
  IF ride_styles_type != '_ride_style' AND ride_styles_type != 'ARRAY' THEN
    RAISE NOTICE '🔧 REQUIS: Créer type ride_style et convertir colonne';
  END IF;
  
  IF languages_type != '_language_code' AND languages_type != 'ARRAY' THEN
    RAISE NOTICE '🔧 REQUIS: Créer type language_code et convertir colonne';
  END IF;
  
  IF NOT stations_is_active THEN
    RAISE NOTICE '🔧 REQUIS: Ajouter colonne is_active à stations';
  END IF;
  
  IF NOT profiles_view_exists THEN
    RAISE NOTICE '🔧 REQUIS: Créer vue public_profiles_v';
  END IF;
  
  IF objectives_exists AND ride_styles_type IS NOT NULL AND languages_type IS NOT NULL AND stations_is_active AND profiles_view_exists THEN
    RAISE NOTICE '🎉 TOUT EST DÉJÀ EN PLACE ! Votre base est prête pour la bêta';
  END IF;
END $$;
