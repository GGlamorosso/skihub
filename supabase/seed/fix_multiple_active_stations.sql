-- ============================================================================
-- Script pour corriger les utilisateurs avec plusieurs stations actives
-- ============================================================================

-- Désactiver toutes les stations sauf la plus récente pour chaque utilisateur
UPDATE user_station_status
SET is_active = false
WHERE id NOT IN (
    SELECT DISTINCT ON (user_id) id
    FROM user_station_status
    WHERE is_active = true
    ORDER BY user_id, created_at DESC
);

-- Vérifier le résultat
SELECT 
    user_id,
    COUNT(*) as active_stations_count
FROM user_station_status
WHERE is_active = true
GROUP BY user_id
HAVING COUNT(*) > 1;

-- Si cette requête retourne des lignes, il y a encore des problèmes
-- Sinon, tout est corrigé ✅

