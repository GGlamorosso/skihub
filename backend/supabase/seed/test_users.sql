-- Seed: Créer des utilisateurs de test pour le matching
-- À exécuter manuellement dans Supabase SQL Editor après avoir créé votre compte principal

-- IMPORTANT: Remplacez 'VOTRE_USER_ID' par l'ID de votre compte utilisateur principal
-- pour tester le matching avec d'autres profils

-- Exemple de création d'utilisateurs de test
-- Note: Ces utilisateurs doivent être créés via Supabase Auth d'abord,
-- puis leurs profils peuvent être insérés ici

-- 1. Créer des profils de test (après création des comptes Auth)
-- Remplacez les UUIDs par les vrais IDs des utilisateurs créés dans Auth

INSERT INTO users (
  id,
  email,
  username,
  birth_date,
  level,
  ride_styles,
  languages,
  bio,
  onboarding_completed,
  is_active,
  created_at
) VALUES
-- Utilisateur test 1
(
  gen_random_uuid(), -- Remplacez par un UUID réel après création Auth
  'test1@crewsnow.app',
  'skier_pro_2024',
  '1995-06-15'::date,
  'advanced',
  ARRAY['alpine', 'freestyle'],
  ARRAY['fr', 'en'],
  'Passionné de ski depuis 10 ans, j''adore les pistes noires et le freestyle !',
  true,
  true,
  NOW()
),
-- Utilisateur test 2
(
  gen_random_uuid(), -- Remplacez par un UUID réel après création Auth
  'test2@crewsnow.app',
  'snowboard_lover',
  '1998-03-22'::date,
  'intermediate',
  ARRAY['snowboard', 'freeride'],
  ARRAY['fr', 'en'],
  'Snowboarder passionné, toujours partant pour de nouvelles aventures !',
  true,
  true,
  NOW()
),
-- Utilisateur test 3
(
  gen_random_uuid(), -- Remplacez par un UUID réel après création Auth
  'test3@crewsnow.app',
  'ski_freeride',
  '1992-11-08'::date,
  'expert',
  ARRAY['freeride', 'alpine'],
  ARRAY['fr'],
  'Expert en freeride, je cherche des partenaires pour explorer les hors-pistes.',
  true,
  true,
  NOW()
)
ON CONFLICT (id) DO NOTHING;

-- 2. Créer des statuts de station pour ces utilisateurs
-- Remplacez les user_id et station_id par des valeurs réelles

-- Exemple (à adapter avec vos IDs réels):
/*
INSERT INTO user_station_status (
  user_id,
  station_id,
  date_from,
  date_to,
  radius_km,
  is_active
) VALUES
(
  'USER_ID_1', -- Remplacez
  'STATION_ID', -- Remplacez par un ID de station existant
  '2024-12-20'::date,
  '2025-01-10'::date,
  50,
  true
),
(
  'USER_ID_2', -- Remplacez
  'STATION_ID', -- Même station pour tester le matching
  '2024-12-20'::date,
  '2025-01-10'::date,
  50,
  true
),
(
  'USER_ID_3', -- Remplacez
  'STATION_ID', -- Même station pour tester le matching
  '2024-12-20'::date,
  '2025-01-10'::date,
  50,
  true
)
ON CONFLICT DO NOTHING;
*/

-- Instructions pour créer les utilisateurs de test:
-- 1. Allez dans Supabase Dashboard > Authentication > Users
-- 2. Créez 3 nouveaux utilisateurs avec les emails ci-dessus
-- 3. Copiez les UUIDs générés
-- 4. Remplacez les gen_random_uuid() dans ce script par les vrais UUIDs
-- 5. Exécutez ce script dans Supabase SQL Editor
-- 6. Créez des photos de profil pour ces utilisateurs (optionnel mais recommandé)

