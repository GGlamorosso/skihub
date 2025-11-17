-- Script de vérification complète pour la bêta CrewSnow
-- Exécutez ce script pour vous assurer que tout est correctement configuré

-- ========================================
-- VÉRIFICATIONS TECHNIQUES
-- ========================================

-- 1. Vérifier les structures de base
DO $$
DECLARE
  view_count INTEGER;
  objectives_count INTEGER;
  ride_style_count INTEGER;
  language_code_count INTEGER;
  stations_is_active_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO view_count FROM information_schema.views WHERE table_name = 'public_profiles_v';
  SELECT COUNT(*) INTO objectives_count FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'objectives';
  SELECT COUNT(*) INTO ride_style_count FROM pg_type WHERE typname = 'ride_style';
  SELECT COUNT(*) INTO language_code_count FROM pg_type WHERE typname = 'language_code';
  SELECT COUNT(*) INTO stations_is_active_count FROM information_schema.columns WHERE table_name = 'stations' AND column_name = 'is_active';

  RAISE NOTICE '=== VÉRIFICATIONS TECHNIQUES ===';
  RAISE NOTICE 'Vue public_profiles_v: %', CASE WHEN view_count = 1 THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Colonne objectives: %', CASE WHEN objectives_count = 1 THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Type ride_style: %', CASE WHEN ride_style_count = 1 THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Type language_code: %', CASE WHEN language_code_count = 1 THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Colonne stations.is_active: %', CASE WHEN stations_is_active_count = 1 THEN '✅' ELSE '❌' END;
END $$;

-- 2. Vérifier les données de base
DO $$
DECLARE
  stations_count INTEGER;
  active_users_count INTEGER;
  complete_profiles_count INTEGER;
  station_statuses_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO stations_count FROM public.stations WHERE is_active = true;
  SELECT COUNT(*) INTO active_users_count FROM public.users WHERE is_active = true;
  SELECT COUNT(*) INTO complete_profiles_count FROM public.users WHERE onboarding_completed = true AND is_active = true;
  SELECT COUNT(*) INTO station_statuses_count FROM public.user_station_status WHERE is_active = true;

  RAISE NOTICE '=== VÉRIFICATIONS DONNÉES ===';
  RAISE NOTICE 'Stations actives: % stations', stations_count;
  RAISE NOTICE 'Utilisateurs actifs: % users', active_users_count;
  RAISE NOTICE 'Profils complets: % users', complete_profiles_count;
  RAISE NOTICE 'Statuts station actifs: % statuts', station_statuses_count;
  
  -- Recommandations
  IF stations_count < 5 THEN
    RAISE NOTICE '⚠️  Recommandation: Ajoutez plus de stations (minimum 5-10)';
  END IF;
  
  IF complete_profiles_count < 2 THEN
    RAISE NOTICE '⚠️  Recommandation: Créez au moins 2-3 utilisateurs de test pour tester le feed';
  END IF;
  
  IF station_statuses_count = 0 THEN
    RAISE NOTICE '⚠️  Recommandation: Créez des statuts de station pour vos utilisateurs de test';
  END IF;
END $$;

-- ========================================
-- TESTS DE LA VUE PUBLIC_PROFILES_V
-- ========================================

-- 3. Tester la vue avec quelques exemples
SELECT 
  '=== TEST VUE PUBLIC_PROFILES_V ===' as test_section;

SELECT 
  id,
  username,
  level,
  array_length(ride_styles, 1) as nb_ride_styles,
  array_length(languages, 1) as nb_languages,
  array_length(objectives, 1) as nb_objectives,
  age,
  current_station,
  CASE 
    WHEN main_photo_path IS NOT NULL THEN 'Photo présente'
    ELSE 'Pas de photo'
  END as photo_status
FROM public.public_profiles_v
LIMIT 5;

-- ========================================
-- VÉRIFICATIONS DE COHÉRENCE
-- ========================================

-- 4. Vérifier les types de colonnes
SELECT 
  '=== VÉRIFICATION TYPES COLONNES ===' as test_section;

SELECT 
  table_name,
  column_name,
  data_type,
  udt_name
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users'
  AND column_name IN ('ride_styles', 'languages', 'objectives', 'level')
ORDER BY column_name;

-- 5. Vérifier les contraintes et index
SELECT 
  '=== VÉRIFICATION INDEX ===' as test_section;

SELECT 
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('users', 'stations', 'matches', 'likes', 'messages')
  AND indexname LIKE '%idx_%'
ORDER BY tablename, indexname;

-- ========================================
-- TESTS DE COMPATIBILITÉ API
-- ========================================

-- 6. Simuler les requêtes de l'API match-candidates
SELECT 
  '=== SIMULATION API MATCH-CANDIDATES ===' as test_section;

-- Test : récupérer des candidats avec différents niveaux
SELECT 
  'Candidats niveau beginner' as test_type,
  COUNT(*) as count
FROM public.public_profiles_v
WHERE level = 'beginner';

SELECT 
  'Candidats niveau intermediate' as test_type,
  COUNT(*) as count
FROM public.public_profiles_v
WHERE level = 'intermediate';

SELECT 
  'Candidats niveau advanced' as test_type,
  COUNT(*) as count
FROM public.public_profiles_v
WHERE level = 'advanced';

SELECT 
  'Candidats niveau expert' as test_type,
  COUNT(*) as count
FROM public.public_profiles_v
WHERE level = 'expert';

-- Test : récupérer des candidats avec des ride_styles spécifiques
SELECT 
  'Candidats alpine' as test_type,
  COUNT(*) as count
FROM public.public_profiles_v
WHERE 'alpine' = ANY(ride_styles);

SELECT 
  'Candidats freeride' as test_type,
  COUNT(*) as count
FROM public.public_profiles_v
WHERE 'freeride' = ANY(ride_styles);

SELECT 
  'Candidats snowboard' as test_type,
  COUNT(*) as count
FROM public.public_profiles_v
WHERE 'snowboard' = ANY(ride_styles);

-- ========================================
-- DIAGNOSTIC DE PROBLÈMES POTENTIELS
-- ========================================

-- 7. Détecter les données invalides
DO $$
DECLARE
  invalid_users INTEGER;
  users_without_objectives INTEGER;
  users_without_ride_styles INTEGER;
  users_without_station INTEGER;
BEGIN
  SELECT COUNT(*) INTO invalid_users FROM public.users WHERE onboarding_completed = true AND (username IS NULL OR username = '');
  SELECT COUNT(*) INTO users_without_objectives FROM public.users WHERE onboarding_completed = true AND (objectives IS NULL OR array_length(objectives, 1) IS NULL);
  SELECT COUNT(*) INTO users_without_ride_styles FROM public.users WHERE onboarding_completed = true AND (ride_styles IS NULL OR array_length(ride_styles, 1) IS NULL);
  SELECT COUNT(*) INTO users_without_station FROM public.users u WHERE onboarding_completed = true AND NOT EXISTS (SELECT 1 FROM public.user_station_status uss WHERE uss.user_id = u.id AND uss.is_active = true);

  RAISE NOTICE '=== DIAGNOSTIC PROBLÈMES ===';
  IF invalid_users > 0 THEN
    RAISE NOTICE '❌ % utilisateurs avec username invalide', invalid_users;
  END IF;
  
  IF users_without_objectives > 0 THEN
    RAISE NOTICE '⚠️  % utilisateurs sans objectifs', users_without_objectives;
  END IF;
  
  IF users_without_ride_styles > 0 THEN
    RAISE NOTICE '⚠️  % utilisateurs sans ride_styles', users_without_ride_styles;
  END IF;
  
  IF users_without_station > 0 THEN
    RAISE NOTICE '⚠️  % utilisateurs sans station active', users_without_station;
  END IF;
  
  IF invalid_users = 0 AND users_without_objectives = 0 AND users_without_ride_styles = 0 THEN
    RAISE NOTICE '✅ Aucun problème détecté dans les données utilisateur';
  END IF;
END $$;

-- ========================================
-- RÉSUMÉ FINAL
-- ========================================

DO $$
DECLARE
  total_issues INTEGER := 0;
  view_exists BOOLEAN;
  objectives_exists BOOLEAN;
  enums_exist BOOLEAN;
  enough_data BOOLEAN;
BEGIN
  -- Vérifier les éléments critiques
  SELECT COUNT(*) = 1 INTO view_exists FROM information_schema.views WHERE table_name = 'public_profiles_v';
  SELECT COUNT(*) = 1 INTO objectives_exists FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'objectives';
  SELECT COUNT(*) >= 2 INTO enums_exist FROM pg_type WHERE typname IN ('ride_style', 'language_code');
  SELECT (SELECT COUNT(*) FROM public.public_profiles_v) >= 2 INTO enough_data;
  
  RAISE NOTICE '=== RÉSUMÉ FINAL ===';
  
  IF NOT view_exists THEN
    RAISE NOTICE '❌ Vue public_profiles_v manquante';
    total_issues := total_issues + 1;
  END IF;
  
  IF NOT objectives_exists THEN
    RAISE NOTICE '❌ Colonne objectives manquante';
    total_issues := total_issues + 1;
  END IF;
  
  IF NOT enums_exist THEN
    RAISE NOTICE '❌ Types ENUM manquants';
    total_issues := total_issues + 1;
  END IF;
  
  IF NOT enough_data THEN
    RAISE NOTICE '❌ Pas assez de données de test';
    total_issues := total_issues + 1;
  END IF;
  
  IF total_issues = 0 THEN
    RAISE NOTICE '🎉 BÊTA PRÊTE À LANCER !';
    RAISE NOTICE '✅ Toutes les vérifications sont passées';
    RAISE NOTICE '📱 Vous pouvez maintenant compiler et tester votre app';
    RAISE NOTICE '🚀 Prochaine étape: flutter clean && flutter pub get && flutter run';
  ELSE
    RAISE NOTICE '⚠️  % problème(s) détecté(s) - Consultez les détails ci-dessus', total_issues;
    RAISE NOTICE '📖 Consultez DEPLOY_BETA_COMPLETE.md pour les solutions';
  END IF;
END $$;
