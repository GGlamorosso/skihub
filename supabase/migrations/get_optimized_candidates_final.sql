CREATE OR REPLACE FUNCTION public.get_optimized_candidates(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    use_cache BOOLEAN DEFAULT true -- Conservé pour compatibilité avec l'Edge Function
) RETURNS TABLE (
    candidate_id UUID,
    username TEXT,
    bio TEXT,
    level user_level,
    compatibility_score NUMERIC,
    distance_km NUMERIC,
    station_name TEXT,
    score_breakdown JSONB,
    is_premium BOOLEAN,
    last_active_at TIMESTAMPTZ,
    photo_url TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1) Vérifier que l'utilisateur a bien une station active
    IF NOT EXISTS (
        SELECT 1 
        FROM user_station_status 
        WHERE user_id = p_user_id 
          AND is_active = true
    ) THEN
        RAISE EXCEPTION 'L''utilisateur % n''a pas de station configurée', p_user_id;
    END IF;

    -- 2) Retourner les candidats optimisés
    RETURN QUERY
    WITH base AS (
        SELECT 
            c.candidate_id,
            c.score AS compatibility_score,
            c.distance_km AS distance_km
        FROM get_candidate_scores(p_user_id) AS c
        ORDER BY c.score DESC, c.distance_km ASC
        LIMIT p_limit
    ),
    station_for_candidate AS (
        SELECT DISTINCT ON (uss.user_id)
            uss.user_id,
            s.name::TEXT AS station_name
        FROM user_station_status uss
        JOIN stations s ON s.id = uss.station_id
        WHERE uss.is_active = true
          AND uss.user_id IN (SELECT b.candidate_id FROM base b)
        ORDER BY uss.user_id, uss.date_from DESC
    ),
    candidate_details AS (
        SELECT 
            b.candidate_id,
            u.level               AS candidate_level,
            u.ride_styles,
            u.languages,
            my.level              AS my_level,
            my.ride_styles        AS my_ride_styles,
            my.languages          AS my_languages,
            b.distance_km,
            CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM user_station_status uss1
                    JOIN user_station_status uss2 
                        ON uss1.station_id = uss2.station_id
                    WHERE uss1.user_id = p_user_id 
                      AND uss2.user_id = b.candidate_id
                      AND uss1.is_active = true 
                      AND uss2.is_active = true
                      AND uss1.date_from <= uss2.date_to 
                      AND uss2.date_from <= uss1.date_to
                )
                THEN 1 ELSE 0
            END AS has_date_overlap
        FROM base b
        JOIN users u ON u.id = b.candidate_id
        CROSS JOIN (
            SELECT 
                u2.level, 
                u2.ride_styles, 
                u2.languages
            FROM users u2
            WHERE u2.id = p_user_id
        ) my
    )
    SELECT 
        b.candidate_id,
        u.username::TEXT,
        u.bio,
        u.level,
        b.compatibility_score,
        b.distance_km,
        COALESCE(sf.station_name, 'Non spécifiée')::TEXT AS station_name,
        jsonb_build_object(
            'level_score', CASE 
                WHEN cd.candidate_level = cd.my_level THEN 4
                WHEN (cd.candidate_level = 'beginner'    AND cd.my_level = 'intermediate') OR 
                     (cd.candidate_level = 'intermediate' AND cd.my_level = 'beginner')    OR
                     (cd.candidate_level = 'intermediate' AND cd.my_level = 'advanced')    OR
                     (cd.candidate_level = 'advanced'     AND cd.my_level = 'intermediate') OR
                     (cd.candidate_level = 'advanced'     AND cd.my_level = 'expert')      OR
                     (cd.candidate_level = 'expert'       AND cd.my_level = 'advanced')
                THEN 2
                ELSE 0
            END,
            -- 🔁 ICI : on remplace cardinality(&&) par unnest + join
            'styles_score', COALESCE((
                SELECT COUNT(*) * 2
                FROM unnest(cd.ride_styles) AS s(style)
                JOIN unnest(cd.my_ride_styles) AS m(style)
                  ON s.style = m.style
            ), 0),
            'languages_score', COALESCE((
                SELECT COUNT(*)
                FROM unnest(cd.languages) AS s(lang)
                JOIN unnest(cd.my_languages) AS m(lang)
                  ON s.lang = m.lang
            ), 0),
            'distance_score', COALESCE(
                (10.0 / (1.0 + cd.distance_km))::NUMERIC,
                0
            ),
            'overlap_score', cd.has_date_overlap
        ) AS score_breakdown,
        u.is_premium,
        u.last_active_at,
        (
            SELECT p.storage_path
            FROM profile_photos p
            WHERE p.user_id = u.id
              AND p.moderation_status = 'approved'
              AND p.is_main = true
            ORDER BY p.created_at DESC
            LIMIT 1
        ) AS photo_url
    FROM base b
    JOIN users u 
      ON u.id = b.candidate_id
    LEFT JOIN station_for_candidate sf 
      ON sf.user_id = b.candidate_id
    LEFT JOIN candidate_details cd 
      ON cd.candidate_id = b.candidate_id
    ORDER BY b.compatibility_score DESC, b.distance_km ASC;
END;
$$;

COMMENT ON FUNCTION public.get_optimized_candidates(UUID, INTEGER, BOOLEAN) IS 
'Version optimisée de get_optimized_candidates utilisant get_candidate_scores, avec score_breakdown détaillé.';
