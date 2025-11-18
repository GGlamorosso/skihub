-- ============================================================================
-- Créer des utilisateurs de test pour CrewSnow Bêta
-- ============================================================================
-- 
-- INSTRUCTIONS :
-- 1. Créez d'abord les comptes dans Supabase Dashboard > Authentication > Users
-- 2. Notez leurs UUIDs
-- 3. Remplacez les UUIDs ci-dessous (cherchez "REMPLACER_PAR_UUID")
-- 4. Exécutez ce fichier avec : supabase db execute --file supabase/seed/create_test_users_simple.sql
--
-- ============================================================================

-- ============================================================================
-- UTILISATEUR 1 : Expert Freeride
-- ============================================================================
DO $$
DECLARE
  user_1_id UUID := 'REMPLACER_PAR_UUID_1'; -- ⚠️ Remplacez par le vrai UUID
  station_id UUID;
BEGIN
  -- Trouver une station (Chamonix ou première disponible)
  SELECT id INTO station_id 
  FROM public.stations 
  WHERE is_active = true 
  ORDER BY name 
  LIMIT 1;
  
  -- Mettre à jour le profil
  UPDATE public.users 
  SET 
    username = 'freeride_expert',
    onboarding_completed = true,
    is_active = true,
    level = 'expert',
    ride_styles = ARRAY['freeride', 'powder', 'touring']::ride_style[],
    languages = ARRAY['fr', 'en']::language_code[],
    objectives = ARRAY['explorer de nouveaux terrains', 'partager ma passion', 'trouver des partenaires expérimentés'],
    bio = 'Expert en freeride avec 15 ans d''expérience. Passionné de poudreuse et de ski de randonnée !',
    birth_date = '1985-03-15',
    last_active_at = NOW(),
    updated_at = NOW()
  WHERE id = user_1_id;
  
  -- Ajouter la station
  IF station_id IS NOT NULL THEN
    INSERT INTO public.user_station_status (user_id, station_id, date_from, date_to, radius_km, is_active)
    VALUES (user_1_id, station_id, CURRENT_DATE, CURRENT_DATE + INTERVAL '14 days', 30, true)
    ON CONFLICT (user_id, station_id) DO UPDATE SET
      date_from = EXCLUDED.date_from,
      date_to = EXCLUDED.date_to,
      is_active = true;
  END IF;
  
  RAISE NOTICE '✅ Utilisateur 1 créé : freeride_expert';
END $$;

-- ============================================================================
-- UTILISATEUR 2 : Débutant Enthousiaste
-- ============================================================================
DO $$
DECLARE
  user_2_id UUID := 'REMPLACER_PAR_UUID_2'; -- ⚠️ Remplacez par le vrai UUID
  station_id UUID;
BEGIN
  SELECT id INTO station_id 
  FROM public.stations 
  WHERE is_active = true 
  ORDER BY name 
  LIMIT 1;
  
  UPDATE public.users 
  SET 
    username = 'ski_newbie',
    onboarding_completed = true,
    is_active = true,
    level = 'beginner',
    ride_styles = ARRAY['alpine']::ride_style[],
    languages = ARRAY['fr']::language_code[],
    objectives = ARRAY['apprendre les bases', 'rencontrer des gens', 'découvrir de belles pistes'],
    bio = 'Tout nouveau dans le monde du ski ! Très motivé pour apprendre 😊',
    birth_date = '1995-07-22',
    last_active_at = NOW(),
    updated_at = NOW()
  WHERE id = user_2_id;
  
  IF station_id IS NOT NULL THEN
    INSERT INTO public.user_station_status (user_id, station_id, date_from, date_to, radius_km, is_active)
    VALUES (user_2_id, station_id, CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 20, true)
    ON CONFLICT (user_id, station_id) DO UPDATE SET
      date_from = EXCLUDED.date_from,
      date_to = EXCLUDED.date_to,
      is_active = true;
  END IF;
  
  RAISE NOTICE '✅ Utilisateur 2 créé : ski_newbie';
END $$;

-- ============================================================================
-- UTILISATEUR 3 : Snowboardeur Confirmé
-- ============================================================================
DO $$
DECLARE
  user_3_id UUID := 'REMPLACER_PAR_UUID_3'; -- ⚠️ Remplacez par le vrai UUID
  station_id UUID;
BEGIN
  SELECT id INTO station_id 
  FROM public.stations 
  WHERE is_active = true 
  ORDER BY name 
  LIMIT 1;
  
  UPDATE public.users 
  SET 
    username = 'snowboard_pro',
    onboarding_completed = true,
    is_active = true,
    level = 'advanced',
    ride_styles = ARRAY['snowboard', 'freestyle', 'park']::ride_style[],
    languages = ARRAY['fr', 'en', 'es']::language_code[],
    objectives = ARRAY['progresser en freestyle', 'rider avec d''autres', 'découvrir de nouveaux spots'],
    bio = 'Snowboardeur depuis 8 ans, passionné de freestyle et de park 🏂',
    birth_date = '1990-11-08',
    last_active_at = NOW(),
    updated_at = NOW()
  WHERE id = user_3_id;
  
  IF station_id IS NOT NULL THEN
    INSERT INTO public.user_station_status (user_id, station_id, date_from, date_to, radius_km, is_active)
    VALUES (user_3_id, station_id, CURRENT_DATE, CURRENT_DATE + INTERVAL '10 days', 25, true)
    ON CONFLICT (user_id, station_id) DO UPDATE SET
      date_from = EXCLUDED.date_from,
      date_to = EXCLUDED.date_to,
      is_active = true;
  END IF;
  
  RAISE NOTICE '✅ Utilisateur 3 créé : snowboard_pro';
END $$;

-- ============================================================================
-- UTILISATEUR 4 : Skieuse Intermédiaire
-- ============================================================================
DO $$
DECLARE
  user_4_id UUID := 'REMPLACER_PAR_UUID_4'; -- ⚠️ Remplacez par le vrai UUID
  station_id UUID;
BEGIN
  SELECT id INTO station_id 
  FROM public.stations 
  WHERE is_active = true 
  ORDER BY name 
  LIMIT 1;
  
  UPDATE public.users 
  SET 
    username = 'alpine_lover',
    onboarding_completed = true,
    is_active = true,
    level = 'intermediate',
    ride_styles = ARRAY['alpine', 'racing']::ride_style[],
    languages = ARRAY['fr', 'en', 'de']::language_code[],
    objectives = ARRAY['améliorer ma technique', 'profiter des paysages', 'faire de nouvelles rencontres'],
    bio = 'Passionnée de ski alpin ! J''aime découvrir de nouveaux domaines et partager de bons moments ☕️',
    birth_date = '1988-02-14',
    last_active_at = NOW(),
    updated_at = NOW()
  WHERE id = user_4_id;
  
  IF station_id IS NOT NULL THEN
    INSERT INTO public.user_station_status (user_id, station_id, date_from, date_to, radius_km, is_active)
    VALUES (user_4_id, station_id, CURRENT_DATE, CURRENT_DATE + INTERVAL '12 days', 20, true)
    ON CONFLICT (user_id, station_id) DO UPDATE SET
      date_from = EXCLUDED.date_from,
      date_to = EXCLUDED.date_to,
      is_active = true;
  END IF;
  
  RAISE NOTICE '✅ Utilisateur 4 créé : alpine_lover';
END $$;

-- ============================================================================
-- VÉRIFICATION
-- ============================================================================
SELECT 
  username,
  level,
  ride_styles,
  objectives,
  onboarding_completed,
  is_active
FROM public.users 
WHERE username IN ('freeride_expert', 'ski_newbie', 'snowboard_pro', 'alpine_lover')
ORDER BY username;

RAISE NOTICE '🎉 Script terminé ! Vérifiez les utilisateurs ci-dessus.';

