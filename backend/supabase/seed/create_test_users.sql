-- Script pour créer des utilisateurs de test pour la bêta CrewSnow
-- 
-- PRÉREQUIS : Vous devez d'abord créer les comptes via Supabase Dashboard > Authentication > Users
-- Ce script met à jour leurs profils avec des données de test réalistes
--
-- ÉTAPES :
-- 1. Créez 3-4 comptes dans Authentication > Users (emails différents)
-- 2. Notez leurs UUIDs
-- 3. Remplacez les UUIDs ci-dessous par les vrais
-- 4. Exécutez ce script

-- ========================================
-- CONFIGURATION DES UTILISATEURS DE TEST
-- ========================================

-- ⚠️ IMPORTANT : Remplacez ces UUIDs par les vrais UUIDs de vos utilisateurs de test
-- Créés dans Supabase Dashboard > Authentication > Users

-- UTILISATEUR DE TEST 1 : Expert en freeride
DO $$
DECLARE
  test_user_1 UUID := 'REMPLACER_PAR_UUID_1'; -- ⚠️ À remplacer
  station_chamonix UUID;
BEGIN
  -- Récupérer l'ID de Chamonix
  SELECT id INTO station_chamonix FROM public.stations WHERE name = 'Chamonix-Mont-Blanc' LIMIT 1;
  
  -- Mettre à jour le profil
  UPDATE public.users 
  SET 
    username = 'freeride_expert',
    onboarding_completed = true,
    is_active = true,
    level = 'expert',
    ride_styles = ARRAY['freeride', 'powder', 'touring']::ride_style[],
    languages = ARRAY['fr', 'en']::language_code[],
    objectives = ARRAY['explorer de nouveaux terrains', 'partager ma passion du freeride', 'trouver des partenaires expérimentés'],
    bio = 'Expert en freeride avec 15 ans d''expérience. Passionné de poudreuse et de ski de randonnée. Toujours à la recherche de nouvelles aventures hors-piste !',
    birth_date = '1985-03-15',
    last_active_at = NOW(),
    updated_at = NOW()
  WHERE id = test_user_1;

  -- Créer un statut de station (sera à Chamonix pour les 2 prochaines semaines)
  INSERT INTO public.user_station_status (user_id, station_id, date_from, date_to, radius_km, is_active)
  VALUES (test_user_1, station_chamonix, CURRENT_DATE, CURRENT_DATE + INTERVAL '14 days', 30, true)
  ON CONFLICT (user_id, station_id) DO UPDATE SET
    date_from = EXCLUDED.date_from,
    date_to = EXCLUDED.date_to,
    is_active = true;

  RAISE NOTICE 'Utilisateur de test 1 créé : freeride_expert (UUID: %)', test_user_1;
END $$;

-- UTILISATEUR DE TEST 2 : Débutant enthousiaste
DO $$
DECLARE
  test_user_2 UUID := 'REMPLACER_PAR_UUID_2'; -- ⚠️ À remplacer
  station_courchevel UUID;
BEGIN
  -- Récupérer l'ID de Courchevel
  SELECT id INTO station_courchevel FROM public.stations WHERE name = 'Courchevel' LIMIT 1;
  
  -- Mettre à jour le profil
  UPDATE public.users 
  SET 
    username = 'ski_newbie',
    onboarding_completed = true,
    is_active = true,
    level = 'beginner',
    ride_styles = ARRAY['alpine']::ride_style[],
    languages = ARRAY['fr']::language_code[],
    objectives = ARRAY['apprendre les bases du ski', 'rencontrer des gens sympas', 'découvrir de belles pistes'],
    bio = 'Tout nouveau dans le monde du ski ! Très motivé pour apprendre et découvrir ce sport incroyable. Cherche des personnes patientes pour m''accompagner 😊',
    birth_date = '1995-07-22',
    last_active_at = NOW(),
    updated_at = NOW()
  WHERE id = test_user_2;

  -- Créer un statut de station (sera à Courchevel pour la semaine)
  INSERT INTO public.user_station_status (user_id, station_id, date_from, date_to, radius_km, is_active)
  VALUES (test_user_2, station_courchevel, CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 20, true)
  ON CONFLICT (user_id, station_id) DO UPDATE SET
    date_from = EXCLUDED.date_from,
    date_to = EXCLUDED.date_to,
    is_active = true;

  RAISE NOTICE 'Utilisateur de test 2 créé : ski_newbie (UUID: %)', test_user_2;
END $$;

-- UTILISATEUR DE TEST 3 : Snowboardeur confirmé
DO $$
DECLARE
  test_user_3 UUID := 'REMPLACER_PAR_UUID_3'; -- ⚠️ À remplacer
  station_val_isere UUID;
BEGIN
  -- Récupérer l'ID de Val d'Isère
  SELECT id INTO station_val_isere FROM public.stations WHERE name = 'Val d''Isère' LIMIT 1;
  
  -- Mettre à jour le profil
  UPDATE public.users 
  SET 
    username = 'snowboard_pro',
    onboarding_completed = true,
    is_active = true,
    level = 'advanced',
    ride_styles = ARRAY['snowboard', 'freestyle', 'park']::ride_style[],
    languages = ARRAY['fr', 'en', 'es']::language_code[],
    objectives = ARRAY['progresser en freestyle', 'rider avec d''autres snowboardeurs', 'découvrir de nouveaux spots'],
    bio = 'Snowboardeur depuis 8 ans, passionné de freestyle et de park. J''adore tester de nouveaux tricks et explorer les hors-pistes. Toujours partant pour une session ! 🏂',
    birth_date = '1990-11-08',
    last_active_at = NOW(),
    updated_at = NOW()
  WHERE id = test_user_3;

  -- Créer un statut de station (sera à Val d'Isère pour 10 jours)
  INSERT INTO public.user_station_status (user_id, station_id, date_from, date_to, radius_km, is_active)
  VALUES (test_user_3, station_val_isere, CURRENT_DATE, CURRENT_DATE + INTERVAL '10 days', 25, true)
  ON CONFLICT (user_id, station_id) DO UPDATE SET
    date_from = EXCLUDED.date_from,
    date_to = EXCLUDED.date_to,
    is_active = true;

  RAISE NOTICE 'Utilisateur de test 3 créé : snowboard_pro (UUID: %)', test_user_3;
END $$;

-- UTILISATEUR DE TEST 4 : Skieuse intermédiaire sociable
DO $$
DECLARE
  test_user_4 UUID := 'REMPLACER_PAR_UUID_4'; -- ⚠️ À remplacer
  station_tignes UUID;
BEGIN
  -- Récupérer l'ID de Tignes
  SELECT id INTO station_tignes FROM public.stations WHERE name = 'Tignes' LIMIT 1;
  
  -- Mettre à jour le profil
  UPDATE public.users 
  SET 
    username = 'alpine_lover',
    onboarding_completed = true,
    is_active = true,
    level = 'intermediate',
    ride_styles = ARRAY['alpine', 'racing']::ride_style[],
    languages = ARRAY['fr', 'en', 'de']::language_code[],
    objectives = ARRAY['améliorer ma technique', 'profiter des paysages', 'faire de nouvelles rencontres'],
    bio = 'Passionnée de ski alpin et de belles descentes ! J''aime découvrir de nouveaux domaines et partager de bons moments sur les pistes. Amateur de vin chaud en terrasse ☕️',
    birth_date = '1988-02-14',
    last_active_at = NOW(),
    updated_at = NOW()
  WHERE id = test_user_4;

  -- Créer un statut de station (sera à Tignes pour 12 jours)
  INSERT INTO public.user_station_status (user_id, station_id, date_from, date_to, radius_km, is_active)
  VALUES (test_user_4, station_tignes, CURRENT_DATE, CURRENT_DATE + INTERVAL '12 days', 20, true)
  ON CONFLICT (user_id, station_id) DO UPDATE SET
    date_from = EXCLUDED.date_from,
    date_to = EXCLUDED.date_to,
    is_active = true;

  RAISE NOTICE 'Utilisateur de test 4 créé : alpine_lover (UUID: %)', test_user_4;
END $$;

-- ========================================
-- VÉRIFICATION FINALE
-- ========================================

-- Vérifier les utilisateurs créés
SELECT 
  u.username,
  u.level,
  u.ride_styles,
  u.objectives[1] as first_objective,
  s.name as current_station,
  uss.date_from,
  uss.date_to
FROM public.users u
LEFT JOIN public.user_station_status uss ON u.id = uss.user_id AND uss.is_active = true
LEFT JOIN public.stations s ON uss.station_id = s.id
WHERE u.onboarding_completed = true 
  AND u.username IN ('freeride_expert', 'ski_newbie', 'snowboard_pro', 'alpine_lover')
ORDER BY u.username;

-- Compter les utilisateurs actifs
DO $$
DECLARE
  active_users_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO active_users_count 
  FROM public.users 
  WHERE onboarding_completed = true AND is_active = true;
  
  RAISE NOTICE '✅ Utilisateurs actifs créés : %', active_users_count;
  
  IF active_users_count >= 4 THEN
    RAISE NOTICE '🎉 UTILISATEURS DE TEST CRÉÉS AVEC SUCCÈS !';
    RAISE NOTICE '📱 Vous pouvez maintenant tester le feed dans l''app';
  ELSE
    RAISE NOTICE '⚠️ Vérifiez que vous avez bien remplacé les UUIDs et créé les comptes dans Authentication';
  END IF;
END $$;
