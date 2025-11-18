-- ============================================================================
-- Version améliorée de get_candidate_scores avec fallback progressif
-- ============================================================================
-- Cette fonction garantit qu'il y a TOUJOURS des candidats à proposer,
-- même si les critères sont progressivement relâchés.
-- ============================================================================

-- Supprimer l'ancienne version
DROP FUNCTION IF EXISTS public.get_candidate_scores(UUID);

CREATE OR REPLACE FUNCTION public.get_candidate_scores(p_user UUID)
RETURNS TABLE(candidate_id UUID, score NUMERIC, distance_km NUMERIC) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_strict_count INTEGER := 0;
    v_relaxed_count INTEGER := 0;
    v_loose_count INTEGER := 0;
    v_fallback_count INTEGER := 0;
    v_has_station BOOLEAN := false;
BEGIN
    -- Vérifier si l'utilisateur a une station active
    SELECT EXISTS (
        SELECT 1 FROM user_station_status 
        WHERE user_id = p_user AND is_active = true
    ) INTO v_has_station;
    
    -- Si pas de station, passer directement au fallback ultime
    IF NOT v_has_station THEN
        -- Aller directement au niveau 4 (fallback ultime)
        -- (le code du niveau 4 est plus bas)
    ELSE
        -- ============================================================================
        -- NIVEAU 1 : MATCHING STRICT
        -- Critères : même station, dates qui se chevauchent, distance OK,
        --            niveau de ski compatible (identique ou adjacent),
        --            tranche d'âge similaire (±5 ans)
        -- ============================================================================
        
        RETURN QUERY
        WITH my_status AS (
            SELECT station_id, date_from, date_to, radius_km
            FROM user_station_status
            WHERE user_id = p_user AND is_active = true
            LIMIT 1
        ),
    me AS (
        SELECT 
            level, 
            ride_styles, 
            languages,
            birth_date
        FROM users 
        WHERE id = p_user
    ),
    strict_candidates AS (
        SELECT 
            u.id AS candidate_id,
            ST_DistanceSphere(s_user.geom, s_cand.geom) / 1000 AS distance_km,
            -- Scoring détaillé
            CASE
                WHEN u.level = me.level THEN 4
                WHEN (u.level = 'beginner' AND me.level = 'intermediate') OR 
                     (u.level = 'intermediate' AND me.level = 'beginner') OR
                     (u.level = 'intermediate' AND me.level = 'advanced') OR
                     (u.level = 'advanced' AND me.level = 'intermediate') OR
                     (u.level = 'advanced' AND me.level = 'expert') OR
                     (u.level = 'expert' AND me.level = 'advanced') THEN 2
                ELSE 0
            END AS level_score,
            cardinality(u.ride_styles && me.ride_styles) * 2 AS style_score,
            cardinality(u.languages && me.languages) AS lang_score,
            CASE WHEN my.date_from <= us.date_to AND my.date_to >= us.date_from THEN 1 ELSE 0 END AS date_score
        FROM users u
        JOIN my_status my ON TRUE
        CROSS JOIN me
        JOIN user_station_status us ON us.user_id = u.id AND us.is_active = true
        JOIN stations s_user ON s_user.id = my.station_id
        JOIN stations s_cand ON s_cand.id = us.station_id
        WHERE u.id <> p_user
            AND u.is_active = true
            AND u.is_banned = false
            AND us.is_active = true
            -- Même station ou stations proches
            AND (us.station_id = my.station_id OR ST_DWithin(s_user.geom::geography, s_cand.geom::geography, (my.radius_km + us.radius_km) * 1000))
            -- Dates qui se chevauchent
            AND my.date_from <= us.date_to 
            AND my.date_to >= us.date_from
            -- ✅ NOUVEAU : Niveau de ski compatible (identique ou adjacent uniquement)
            AND (
                u.level = me.level -- Niveau identique
                OR
                (u.level = 'beginner' AND me.level = 'intermediate')
                OR
                (u.level = 'intermediate' AND me.level = 'beginner')
                OR
                (u.level = 'intermediate' AND me.level = 'advanced')
                OR
                (u.level = 'advanced' AND me.level = 'intermediate')
                OR
                (u.level = 'advanced' AND me.level = 'expert')
                OR
                (u.level = 'expert' AND me.level = 'advanced')
            )
            -- ✅ NOUVEAU : Tranche d'âge similaire (±5 ans maximum)
            -- Calcul de l'âge en tenant compte de la date complète (mois/jour)
            AND u.birth_date IS NOT NULL
            AND me.birth_date IS NOT NULL
            AND ABS(
                EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.birth_date)) - 
                EXTRACT(YEAR FROM AGE(CURRENT_DATE, me.birth_date))
            ) <= 5
            -- Exclusions
            AND NOT EXISTS (SELECT 1 FROM likes l WHERE l.liker_id = p_user AND l.liked_id = u.id)
            AND NOT EXISTS (SELECT 1 FROM matches m WHERE (m.user1_id = p_user AND m.user2_id = u.id) OR (m.user2_id = p_user AND m.user1_id = u.id))
            AND NOT EXISTS (SELECT 1 FROM friends f WHERE ((f.requester_id = p_user AND f.addressee_id = u.id) OR (f.requester_id = u.id AND f.addressee_id = p_user)) AND f.status = 'blocked')
    )
    SELECT 
        candidate_id,
        (level_score + style_score + lang_score + date_score + (10.0 / (1.0 + distance_km)))::NUMERIC AS score,
        distance_km::NUMERIC
    FROM strict_candidates
    ORDER BY score DESC, distance_km ASC;
    
    GET DIAGNOSTICS v_strict_count = ROW_COUNT;
    
    -- Si on a des résultats stricts, on s'arrête là
    IF v_strict_count > 0 THEN
        RETURN;
    END IF;
    
    -- ============================================================================
    -- NIVEAU 2 : MATCHING RELAXÉ (même station, dates relâchées, distance OK)
    -- ============================================================================
    
    RETURN QUERY
    WITH my_status AS (
        SELECT station_id, date_from, date_to, radius_km
        FROM user_station_status
        WHERE user_id = p_user AND is_active = true
        LIMIT 1
    ),
    me AS (
        SELECT level, ride_styles, languages FROM users WHERE id = p_user
    ),
    relaxed_candidates AS (
        SELECT 
            u.id AS candidate_id,
            ST_DistanceSphere(s_user.geom, s_cand.geom) / 1000 AS distance_km,
            -- Scoring (légèrement réduit car critères relâchés)
            CASE
                WHEN u.level = me.level THEN 3
                WHEN (u.level = 'beginner' AND me.level = 'intermediate') OR 
                     (u.level = 'intermediate' AND me.level = 'beginner') OR
                     (u.level = 'intermediate' AND me.level = 'advanced') OR
                     (u.level = 'advanced' AND me.level = 'intermediate') OR
                     (u.level = 'advanced' AND me.level = 'expert') OR
                     (u.level = 'expert' AND me.level = 'advanced') THEN 1
                ELSE 0
            END AS level_score,
            cardinality(u.ride_styles && me.ride_styles) * 2 AS style_score,
            cardinality(u.languages && me.languages) AS lang_score,
            0 AS date_score -- Pas de bonus date car dates peuvent ne pas se chevaucher
        FROM users u
        JOIN my_status my ON TRUE
        CROSS JOIN me
        JOIN user_station_status us ON us.user_id = u.id AND us.is_active = true
        JOIN stations s_user ON s_user.id = my.station_id
        JOIN stations s_cand ON s_cand.id = us.station_id
        WHERE u.id <> p_user
            AND u.is_active = true
            AND u.is_banned = false
            AND us.is_active = true
            -- Même station ou stations proches (distance OK)
            AND (us.station_id = my.station_id OR ST_DWithin(s_user.geom::geography, s_cand.geom::geography, (my.radius_km + us.radius_km) * 1000))
            -- Dates relâchées : on accepte même si elles ne se chevauchent pas
            -- (mais on préfère quand même celles qui se chevauchent)
            AND (
                -- Dates qui se chevauchent (bonus)
                (my.date_from <= us.date_to AND my.date_to >= us.date_from)
                OR
                -- Dates proches (dans les 30 jours)
                (ABS(EXTRACT(EPOCH FROM (my.date_from - us.date_to)) / 86400) <= 30)
                OR
                (ABS(EXTRACT(EPOCH FROM (us.date_from - my.date_to)) / 86400) <= 30)
            )
            -- Exclusions
            AND NOT EXISTS (SELECT 1 FROM likes l WHERE l.liker_id = p_user AND l.liked_id = u.id)
            AND NOT EXISTS (SELECT 1 FROM matches m WHERE (m.user1_id = p_user AND m.user2_id = u.id) OR (m.user2_id = p_user AND m.user1_id = u.id))
            AND NOT EXISTS (SELECT 1 FROM friends f WHERE ((f.requester_id = p_user AND f.addressee_id = u.id) OR (f.requester_id = u.id AND f.addressee_id = p_user)) AND f.status = 'blocked')
    )
    SELECT 
        candidate_id,
        (level_score + style_score + lang_score + date_score + (8.0 / (1.0 + distance_km)))::NUMERIC AS score, -- Score réduit
        distance_km::NUMERIC
    FROM relaxed_candidates
    ORDER BY score DESC, distance_km ASC;
    
    GET DIAGNOSTICS v_relaxed_count = ROW_COUNT;
    
    IF v_relaxed_count > 0 THEN
        RETURN;
    END IF;
    
    -- ============================================================================
    -- NIVEAU 3 : MATCHING LOOSE (même station, pas de contrainte de dates/distance)
    -- ============================================================================
    
    RETURN QUERY
    WITH my_status AS (
        SELECT station_id, date_from, date_to, radius_km
        FROM user_station_status
        WHERE user_id = p_user AND is_active = true
        LIMIT 1
    ),
    me AS (
        SELECT level, ride_styles, languages FROM users WHERE id = p_user
    ),
    loose_candidates AS (
        SELECT 
            u.id AS candidate_id,
            COALESCE(
                CASE 
                    WHEN us.station_id IS NOT NULL AND my.station_id IS NOT NULL THEN
                        ST_DistanceSphere(s_user.geom, s_cand.geom) / 1000
                    ELSE 999
                END,
                999
            ) AS distance_km,
            -- Scoring minimal (juste compatibilité de base)
            CASE
                WHEN u.level = me.level THEN 2
                WHEN (u.level = 'beginner' AND me.level = 'intermediate') OR 
                     (u.level = 'intermediate' AND me.level = 'beginner') OR
                     (u.level = 'intermediate' AND me.level = 'advanced') OR
                     (u.level = 'advanced' AND me.level = 'intermediate') OR
                     (u.level = 'advanced' AND me.level = 'expert') OR
                     (u.level = 'expert' AND me.level = 'advanced') THEN 1
                ELSE 0
            END AS level_score,
            cardinality(u.ride_styles && me.ride_styles) * 1 AS style_score, -- Score réduit
            cardinality(u.languages && me.languages) AS lang_score,
            0 AS date_score
        FROM users u
        CROSS JOIN me
        LEFT JOIN my_status my ON TRUE
        LEFT JOIN user_station_status us ON us.user_id = u.id AND us.is_active = true
        LEFT JOIN stations s_user ON s_user.id = my.station_id
        LEFT JOIN stations s_cand ON s_cand.id = us.station_id
        WHERE u.id <> p_user
            AND u.is_active = true
            AND u.is_banned = false
            -- Même station (si les deux ont une station) OU pas de contrainte
            AND (
                (my.station_id IS NOT NULL AND us.station_id = my.station_id)
                OR my.station_id IS NULL
            )
            -- Exclusions
            AND NOT EXISTS (SELECT 1 FROM likes l WHERE l.liker_id = p_user AND l.liked_id = u.id)
            AND NOT EXISTS (SELECT 1 FROM matches m WHERE (m.user1_id = p_user AND m.user2_id = u.id) OR (m.user2_id = p_user AND m.user1_id = u.id))
            AND NOT EXISTS (SELECT 1 FROM friends f WHERE ((f.requester_id = p_user AND f.addressee_id = u.id) OR (f.requester_id = u.id AND f.addressee_id = p_user)) AND f.status = 'blocked')
    )
    SELECT 
        candidate_id,
        (level_score + style_score + lang_score + date_score + (5.0 / (1.0 + distance_km)))::NUMERIC AS score, -- Score encore plus réduit
        distance_km::NUMERIC
    FROM loose_candidates
    ORDER BY score DESC, distance_km ASC;
    
    GET DIAGNOSTICS v_loose_count = ROW_COUNT;
    
    IF v_loose_count > 0 THEN
        RETURN;
    END IF;
    
    END IF; -- Fin du IF v_has_station
    
    -- ============================================================================
    -- NIVEAU 4 : FALLBACK ULTIME (tous les utilisateurs actifs, peu importe)
    -- ============================================================================
    -- Ce niveau s'exécute si :
    -- - L'utilisateur n'a pas de station active
    -- - OU tous les niveaux précédents ont retourné 0 résultats
    -- ============================================================================
    
    RETURN QUERY
    WITH me AS (
        SELECT level, ride_styles, languages FROM users WHERE id = p_user
    ),
    fallback_candidates AS (
        SELECT 
            u.id AS candidate_id,
            999 AS distance_km, -- Distance par défaut
            -- Scoring minimal (juste pour trier)
            CASE
                WHEN u.level = me.level THEN 1
                ELSE 0
            END AS level_score,
            cardinality(u.ride_styles && me.ride_styles) * 0.5 AS style_score, -- Score très réduit
            cardinality(u.languages && me.languages) * 0.5 AS lang_score,
            0 AS date_score -- Pas de bonus date dans le fallback
        FROM users u
        CROSS JOIN me
        WHERE u.id <> p_user
            AND u.is_active = true
            AND u.is_banned = false
            -- Exclusions (on garde quand même les exclusions de base)
            AND NOT EXISTS (SELECT 1 FROM likes l WHERE l.liker_id = p_user AND l.liked_id = u.id)
            AND NOT EXISTS (SELECT 1 FROM matches m WHERE (m.user1_id = p_user AND m.user2_id = u.id) OR (m.user2_id = p_user AND m.user1_id = u.id))
            AND NOT EXISTS (SELECT 1 FROM friends f WHERE ((f.requester_id = p_user AND f.addressee_id = u.id) OR (f.requester_id = u.id AND f.addressee_id = p_user)) AND f.status = 'blocked')
    )
    SELECT 
        fc.candidate_id,
        (fc.level_score + fc.style_score + fc.lang_score + fc.date_score + 0.1)::NUMERIC AS score, -- Score minimal
        999::NUMERIC AS distance_km
    FROM fallback_candidates fc
    JOIN users u ON u.id = fc.candidate_id
    ORDER BY score DESC, u.last_active_at DESC NULLS LAST
    LIMIT 50; -- Limiter à 50 pour éviter trop de résultats
    
    -- Si même le fallback ne retourne rien, c'est qu'il n'y a vraiment personne
    -- (peut arriver si tous les utilisateurs sont déjà likés/matchés/bloqués)
    
END;
$$;

COMMENT ON FUNCTION public.get_candidate_scores(UUID) IS 
'Version améliorée avec fallback progressif :
- Niveau 1 : Matching strict (même station, dates qui se chevauchent, distance OK)
- Niveau 2 : Matching relaxé (même station, dates proches, distance OK)
- Niveau 3 : Matching loose (même station, pas de contrainte dates/distance)
- Niveau 4 : Fallback ultime (tous les utilisateurs actifs)
Garantit qu''il y a toujours des candidats à proposer.';

