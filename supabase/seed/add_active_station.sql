-- Script pour ajouter une station active à un utilisateur
-- Usage: Remplacez YOUR_USER_ID et STATION_ID par vos valeurs

-- 1. Récupérer votre user_id depuis auth.users
-- SELECT id, email FROM auth.users WHERE email = 'votre@email.com';

-- 2. Récupérer une station_id depuis stations
-- SELECT id, name, country_code FROM stations WHERE is_active = true LIMIT 5;

-- 3. Exécuter l'INSERT ci-dessous avec vos valeurs

-- ========================================
-- AJOUTER STATION ACTIVE POUR UTILISATEUR
-- ========================================

-- Désactiver toutes les stations existantes pour cet utilisateur
UPDATE user_station_status
SET is_active = false
WHERE user_id = 'YOUR_USER_ID'::UUID;

-- Ajouter une nouvelle station active
INSERT INTO user_station_status (
  user_id,
  station_id,
  date_from,
  date_to,
  radius_km,
  is_active
)
VALUES (
  'YOUR_USER_ID'::UUID,           -- ⚠️ REMPLACER par votre user_id
  'STATION_ID'::UUID,             -- ⚠️ REMPLACER par une station_id valide
  CURRENT_DATE,                    -- Date début (aujourd'hui)
  CURRENT_DATE + INTERVAL '7 days', -- Date fin (dans 7 jours)
  50,                              -- Rayon de recherche en km
  true                             -- Active
)
ON CONFLICT DO NOTHING;

-- Vérifier que la station a été ajoutée
SELECT 
  uss.id,
  u.email,
  s.name AS station_name,
  s.country_code,
  uss.date_from,
  uss.date_to,
  uss.radius_km,
  uss.is_active
FROM user_station_status uss
JOIN users u ON u.id = uss.user_id
JOIN stations s ON s.id = uss.station_id
WHERE uss.user_id = 'YOUR_USER_ID'::UUID
  AND uss.is_active = true;

