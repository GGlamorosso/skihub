-- ============================================================================
-- DIAGNOSTIC : Pourquoi 0 candidats sont retournés
-- ============================================================================
-- Remplacez VOTRE_USER_ID par votre UUID dans toutes les requêtes
-- ============================================================================

-- ⚠️ REMPLACER PAR VOTRE UUID
\set user_id 'VOTRE_USER_ID'

-- ============================================================================
-- 1. VÉRIFIER QUE L'UTILISATEUR EXISTE ET A UNE STATION
-- ============================================================================

SELECT 
    '1. Votre profil' as check_name,
    u.id,
    u.username,
    u.level,
    u.birth_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.birth_date)) as age,
    u.is_active,
    u.is_banned
FROM users u
WHERE u.id = :'user_id';

SELECT 
    '2. Votre station active' as check_name,
    uss.id,
    uss.station_id,
    s.name as station_name,
    uss.date_from,
    uss.date_to,
    uss.radius_km,
    uss.is_active
FROM user_station_status uss
JOIN stations s ON s.id = uss.station_id
WHERE uss.user_id = :'user_id' AND uss.is_active = true
ORDER BY uss.created_at DESC
LIMIT 1;

-- ============================================================================
-- 2. VÉRIFIER LES UTILISATEURS DISPONIBLES
-- ============================================================================

SELECT 
    '3. Total utilisateurs actifs' as check_name,
    COUNT(*) as total_users
FROM users 
WHERE is_active = true AND is_banned = false;

SELECT 
    '4. Utilisateurs avec station active' as check_name,
    COUNT(DISTINCT u.id) as users_with_station
FROM users u
JOIN user_station_status uss ON uss.user_id = u.id AND uss.is_active = true
WHERE u.is_active = true AND u.is_banned = false;

-- ============================================================================
-- 3. VÉRIFIER LES CRITÈRES DE MATCHING
-- ============================================================================

-- Utilisateurs à la même station
SELECT 
    '5. Utilisateurs à la même station' as check_name,
    COUNT(*) as count
FROM users u
JOIN user_station_status uss ON uss.user_id = u.id AND uss.is_active = true
JOIN user_station_status my_uss ON my_uss.user_id = :'user_id' AND my_uss.is_active = true
WHERE u.id != :'user_id'
    AND u.is_active = true
    AND u.is_banned = false
    AND uss.station_id = my_uss.station_id;

-- Utilisateurs avec dates qui se chevauchent
SELECT 
    '6. Utilisateurs avec dates qui se chevauchent' as check_name,
    COUNT(*) as count
FROM users u
JOIN user_station_status uss ON uss.user_id = u.id AND uss.is_active = true
JOIN user_station_status my_uss ON my_uss.user_id = :'user_id' AND my_uss.is_active = true
WHERE u.id != :'user_id'
    AND u.is_active = true
    AND u.is_banned = false
    AND uss.station_id = my_uss.station_id
    AND my_uss.date_from <= uss.date_to 
    AND my_uss.date_to >= uss.date_from;

-- Utilisateurs avec niveau compatible (identique ou adjacent)
SELECT 
    '7. Utilisateurs avec niveau compatible' as check_name,
    COUNT(*) as count
FROM users u
CROSS JOIN (SELECT level FROM users WHERE id = :'user_id') me
WHERE u.id != :'user_id'
    AND u.is_active = true
    AND u.is_banned = false
    AND (
        u.level = me.level
        OR (u.level = 'beginner' AND me.level = 'intermediate')
        OR (u.level = 'intermediate' AND me.level = 'beginner')
        OR (u.level = 'intermediate' AND me.level = 'advanced')
        OR (u.level = 'advanced' AND me.level = 'intermediate')
        OR (u.level = 'advanced' AND me.level = 'expert')
        OR (u.level = 'expert' AND me.level = 'advanced')
    );

-- Utilisateurs avec tranche d'âge similaire (±5 ans)
SELECT 
    '8. Utilisateurs avec tranche d'âge similaire (±5 ans)' as check_name,
    COUNT(*) as count
FROM users u
CROSS JOIN (SELECT birth_date FROM users WHERE id = :'user_id') me
WHERE u.id != :'user_id'
    AND u.is_active = true
    AND u.is_banned = false
    AND u.birth_date IS NOT NULL
    AND me.birth_date IS NOT NULL
    AND ABS(
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.birth_date)) - 
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, me.birth_date))
    ) <= 5;

-- ============================================================================
-- 4. VÉRIFIER LES EXCLUSIONS (likes, matches, blocked)
-- ============================================================================

SELECT 
    '9. Utilisateurs déjà likés' as check_name,
    COUNT(*) as count
FROM likes 
WHERE liker_id = :'user_id';

SELECT 
    '10. Utilisateurs déjà matchés' as check_name,
    COUNT(*) as count
FROM matches 
WHERE user1_id = :'user_id' OR user2_id = :'user_id';

SELECT 
    '11. Utilisateurs bloqués' as check_name,
    COUNT(*) as count
FROM friends 
WHERE ((requester_id = :'user_id' AND addressee_id IS NOT NULL) 
    OR (requester_id IS NOT NULL AND addressee_id = :'user_id'))
    AND status = 'blocked';

-- ============================================================================
-- 5. TESTER get_candidate_scores DIRECTEMENT
-- ============================================================================

SELECT 
    '12. Test get_candidate_scores' as check_name,
    COUNT(*) as candidates_found
FROM get_candidate_scores(:'user_id'::UUID);

-- Afficher les candidats trouvés
SELECT 
    '13. Candidats trouvés par get_candidate_scores' as check_name,
    candidate_id,
    score,
    distance_km
FROM get_candidate_scores(:'user_id'::UUID)
ORDER BY score DESC
LIMIT 10;

-- ============================================================================
-- 6. TESTER get_optimized_candidates DIRECTEMENT
-- ============================================================================

SELECT 
    '14. Test get_optimized_candidates' as check_name,
    COUNT(*) as candidates_found
FROM get_optimized_candidates(:'user_id'::UUID, 10, false);

-- Afficher les candidats trouvés
SELECT 
    '15. Candidats trouvés par get_optimized_candidates' as check_name,
    candidate_id,
    username,
    level,
    compatibility_score,
    distance_km,
    station_name
FROM get_optimized_candidates(:'user_id'::UUID, 10, false)
ORDER BY compatibility_score DESC
LIMIT 10;

-- ============================================================================
-- 7. DIAGNOSTIC COMPLET : TOUS LES CRITÈRES EN UNE FOIS
-- ============================================================================

WITH my_user AS (
    SELECT 
        u.id,
        u.level,
        u.birth_date,
        uss.station_id,
        uss.date_from,
        uss.date_to,
        uss.radius_km
    FROM users u
    JOIN user_station_status uss ON uss.user_id = u.id AND uss.is_active = true
    WHERE u.id = :'user_id'
    LIMIT 1
),
potential_candidates AS (
    SELECT 
        u.id,
        u.username,
        u.level,
        u.birth_date,
        uss.station_id,
        uss.date_from,
        uss.date_to,
        -- Vérifications
        CASE WHEN uss.station_id = my.station_id THEN '✅' ELSE '❌' END as same_station,
        CASE WHEN my.date_from <= uss.date_to AND my.date_to >= uss.date_from THEN '✅' ELSE '❌' END as dates_overlap,
        CASE WHEN u.level = my.level THEN '✅' 
             WHEN (u.level = 'beginner' AND my.level = 'intermediate') OR 
                  (u.level = 'intermediate' AND my.level = 'beginner') OR
                  (u.level = 'intermediate' AND my.level = 'advanced') OR
                  (u.level = 'advanced' AND my.level = 'intermediate') OR
                  (u.level = 'advanced' AND my.level = 'expert') OR
                  (u.level = 'expert' AND my.level = 'advanced') THEN '✅' 
             ELSE '❌' END as level_compatible,
        CASE WHEN u.birth_date IS NOT NULL AND my.birth_date IS NOT NULL AND
                  ABS(EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.birth_date)) - 
                      EXTRACT(YEAR FROM AGE(CURRENT_DATE, my.birth_date))) <= 5 
             THEN '✅' ELSE '❌' END as age_compatible,
        CASE WHEN EXISTS (SELECT 1 FROM likes l WHERE l.liker_id = my.id AND l.liked_id = u.id) THEN '❌' ELSE '✅' END as not_liked,
        CASE WHEN EXISTS (SELECT 1 FROM matches m WHERE (m.user1_id = my.id AND m.user2_id = u.id) OR (m.user2_id = my.id AND m.user1_id = u.id)) THEN '❌' ELSE '✅' END as not_matched
    FROM users u
    JOIN user_station_status uss ON uss.user_id = u.id AND uss.is_active = true
    CROSS JOIN my_user my
    WHERE u.id != my.id
        AND u.is_active = true
        AND u.is_banned = false
)
SELECT 
    '16. Diagnostic complet des candidats potentiels' as check_name,
    id,
    username,
    level,
    same_station,
    dates_overlap,
    level_compatible,
    age_compatible,
    not_liked,
    not_matched,
    CASE 
        WHEN same_station = '✅' AND dates_overlap = '✅' AND level_compatible = '✅' AND age_compatible = '✅' AND not_liked = '✅' AND not_matched = '✅'
        THEN '✅ ÉLIGIBLE'
        ELSE '❌ NON ÉLIGIBLE'
    END as eligible
FROM potential_candidates
ORDER BY eligible DESC, username
LIMIT 20;

