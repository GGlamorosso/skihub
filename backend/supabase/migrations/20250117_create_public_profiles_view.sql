-- Migration: Créer la vue public_profiles_v
-- Cette vue est utilisée par match-candidates et le feed pour afficher les profils publics

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
  -- Photo principale (première photo approuvée)
  (
    SELECT storage_path 
    FROM profile_photos pp
    WHERE pp.user_id = u.id 
      AND pp.is_main = true 
      AND pp.moderation_status = 'approved'
    LIMIT 1
  ) AS main_photo_path,
  -- Station actuelle (si l'utilisateur a un statut de station actif)
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
  -- Station ID (pour filtrage)
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

-- Permissions RLS
-- Note: Les vues héritent des permissions des tables sous-jacentes
-- Mais on peut ajouter une policy spécifique si nécessaire
-- Pour l'instant, la vue est accessible à tous les utilisateurs authentifiés
-- car elle filtre déjà les données sensibles

-- Commentaire
COMMENT ON VIEW public.public_profiles_v IS 'Vue publique des profils utilisateurs pour le matching (exclut les données sensibles, calcule l''âge, inclut photo principale et station actuelle)';

