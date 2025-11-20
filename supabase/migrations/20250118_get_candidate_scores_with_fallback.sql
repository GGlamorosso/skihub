-- ============================================================================
-- Version améliorée de get_candidate_scores avec fallback progressif
-- ============================================================================
-- Cette fonction classe les candidats par niveau de compatibilité décroissant.
-- Elle applique quatre niveaux successifs :
--   1. Matching strict : même station, dates qui se chevauchent, distance OK,
--      niveaux adjacents, styles et langues communs, tranche d’âge similaire.
--   2. Matching relâché : même station (ou stations proches), dates proches,
--      critères plus souples.
--   3. Matching loose : même station uniquement, pas de contrainte sur les dates.
--   4. Fallback ultime : tous les utilisateurs actifs (hors exclus), pour
--      garantir qu’il y ait toujours des candidats.
-- Le score est calculé en mettant plus de poids sur les points communs (langues,
-- styles, niveau), puis sur la proximité (distance, dates).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_candidate_scores(p_user UUID)
RETURNS TABLE(candidate_id UUID, score NUMERIC, distance_km NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
    v_strict_count INTEGER := 0;
    v_relaxed_count INTEGER := 0;
    v_loose_count INTEGER := 0;
    v_has_station BOOLEAN := false;
BEGIN
    -- Vérifier si l'utilisateur a une station active
    SELECT EXISTS (
        SELECT 1 FROM user_station_status
        WHERE user_id = p_user AND is_active = true
    ) INTO v_has_station;

    -- Si l'utilisateur n'a pas de station active, on passe directement au fallback ultime
    IF NOT v_has_station THEN
        -- Fallback ultime exécuté plus bas
    ELSE
        -- ============================================================================
        -- NIVEAU 1 : MATCHING STRICT
        --   - même station ou stations proches
        --   - dates qui se chevauchent
        --   - distance dans le rayon combiné
        --   - niveau identique ou adjacent
        --   - tranche d’âge similaire (±5 ans)
        --   - on classe par score décroissant (langues, styles, niveau, dates, distance)
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
                -- Score sur le niveau de ski (4 points si identique, 2 points si adjacent)
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
                -- Score sur les styles de ride (2 points par style en commun)
                -- ✅ Corrigé : utiliser unnest + JOIN au lieu de cardinality(&&)
                COALESCE((
                    SELECT COUNT(*) * 2
                    FROM unnest(u.ride_styles) AS s(style)
                    JOIN unnest(me.ride_styles) AS m(style) ON s.style = m.style
                ), 0) AS style_score,
                -- Score sur les langues (1 point par langue en commun)
                -- ✅ Corrigé : utiliser unnest + JOIN au lieu de cardinality(&&)
                COALESCE((
                    SELECT COUNT(*)
                    FROM unnest(u.languages) AS s(lang)
                    JOIN unnest(me.languages) AS m(lang) ON s.lang = m.lang
                ), 0) AS lang_score,
                -- Bonus si les dates se chevauchent
                CASE WHEN my.date_from <= us.date_to AND my.date_to >= us.date_from THEN 1 ELSE 0 END AS date_score
            FROM users u
            JOIN my_status my ON TRUE
            JOIN me ON TRUE
            JOIN user_station_status us ON us.user_id = u.id AND us.is_active = true
            JOIN stations s_user ON s_user.id = my.station_id
            JOIN stations s_cand ON s_cand.id = us.station_id
            WHERE u.id <> p_user
                AND u.is_active = true
                AND u.is_banned = false
                -- Même station ou stations proches (rayon combiné)
                AND (
                    us.station_id = my.station_id OR
                    ST_DWithin(
                        s_user.geom::geography,
                        s_cand.geom::geography,
                        (my.radius_km + us.radius_km) * 1000
                    )
                )
                -- Dates qui se chevauchent
                AND my.date_from <= us.date_to
                AND my.date_to >= us.date_from
                -- Niveau adjoint
                AND (
                    u.level = me.level
                    OR (u.level = 'beginner' AND me.level = 'intermediate')
                    OR (u.level = 'intermediate' AND me.level = 'beginner')
                    OR (u.level = 'intermediate' AND me.level = 'advanced')
                    OR (u.level = 'advanced' AND me.level = 'intermediate')
                    OR (u.level = 'advanced' AND me.level = 'expert')
                    OR (u.level = 'expert' AND me.level = 'advanced')
                )
                -- Tranche d'âge ±5 ans
                AND u.birth_date IS NOT NULL
                AND me.birth_date IS NOT NULL
                AND ABS(
                    EXTRACT(YEAR FROM AGE(CURRENT_DATE, u.birth_date)) -
                    EXTRACT(YEAR FROM AGE(CURRENT_DATE, me.birth_date))
                ) <= 5
                -- Exclusions : déjà liké, déjà matché, déjà bloqué
                AND NOT EXISTS (SELECT 1 FROM likes l WHERE l.liker_id = p_user AND l.liked_id = u.id)
                AND NOT EXISTS (SELECT 1 FROM matches m WHERE (m.user1_id = p_user AND m.user2_id = u.id) OR (m.user2_id = p_user AND m.user1_id = u.id))
                AND NOT EXISTS (SELECT 1 FROM friends f WHERE ((f.requester_id = p_user AND f.addressee_id = u.id) OR (f.requester_id = u.id AND f.addressee_id = p_user)) AND f.status = 'blocked')
        )
        SELECT
            sc.candidate_id,
            -- Score final : on valorise davantage les points communs, puis la distance et la date
            (sc.level_score + sc.style_score + sc.lang_score + sc.date_score + (10.0 / (1.0 + sc.distance_km)))::NUMERIC AS score,
            sc.distance_km::NUMERIC
        FROM strict_candidates sc
        ORDER BY score DESC, sc.distance_km ASC;

        GET DIAGNOSTICS v_strict_count = ROW_COUNT;
        IF v_strict_count > 0 THEN
            RETURN;
        END IF;

        -- ============================================================================
        -- NIVEAU 2 : MATCHING RELÂCHÉ
        --   - même station ou stations proches
        --   - dates proches (chevauchement ou écart ≤30 jours)
        --   - niveau adjacent (mais poids réduit)
        --   - pas de contrainte sur l’âge
        -- ============================================================================
        RETURN QUERY
        WITH my_status AS (
            SELECT station_id, date_from, date_to, radius_km
            FROM user_station_status
            WHERE user_id = p_user AND is_active = true
            LIMIT 1
        ),
        me AS (
            SELECT level, ride_styles, languages
            FROM users
            WHERE id = p_user
        ),
        relaxed_candidates AS (
            SELECT
                u.id AS candidate_id,
                ST_DistanceSphere(s_user.geom, s_cand.geom) / 1000 AS distance_km,
                -- Score niveau (valeur 3 si identique, 1 si adjacent)
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
                -- Score styles (toujours 2 points par style commun)
                -- ✅ Corrigé : utiliser unnest + JOIN au lieu de cardinality(&&)
                COALESCE((
                    SELECT COUNT(*) * 2
                    FROM unnest(u.ride_styles) AS s(style)
                    JOIN unnest(me.ride_styles) AS m(style) ON s.style = m.style
                ), 0) AS style_score,
                -- Score langues (1 point par langue commune)
                -- ✅ Corrigé : utiliser unnest + JOIN au lieu de cardinality(&&)
                COALESCE((
                    SELECT COUNT(*)
                    FROM unnest(u.languages) AS s(lang)
                    JOIN unnest(me.languages) AS m(lang) ON s.lang = m.lang
                ), 0) AS lang_score,
                -- 0 pour date_score car dates relâchées
                0 AS date_score
            FROM users u
            JOIN my_status my ON TRUE
            JOIN me ON TRUE
            JOIN user_station_status us ON us.user_id = u.id AND us.is_active = true
            JOIN stations s_user ON s_user.id = my.station_id
            JOIN stations s_cand ON s_cand.id = us.station_id
            WHERE u.id <> p_user
                AND u.is_active = true
                AND u.is_banned = false
                -- Même station ou stations proches
                AND (
                    us.station_id = my.station_id OR
                    ST_DWithin(
                        s_user.geom::geography,
                        s_cand.geom::geography,
                        (my.radius_km + us.radius_km) * 1000
                    )
                )
                -- Dates relâchées : chevauchement OU proximité ±30 jours
                -- ✅ Corrigé : DATE - DATE retourne déjà un INTEGER (nombre de jours), pas besoin de EXTRACT
                AND (
                    (my.date_from <= us.date_to AND my.date_to >= us.date_from) OR
                    ABS(my.date_from - us.date_to) <= 30 OR
                    ABS(us.date_from - my.date_to) <= 30
                )
                -- Exclusions
                AND NOT EXISTS (SELECT 1 FROM likes l WHERE l.liker_id = p_user AND l.liked_id = u.id)
                AND NOT EXISTS (SELECT 1 FROM matches m WHERE (m.user1_id = p_user AND m.user2_id = u.id) OR (m.user2_id = p_user AND m.user1_id = u.id))
                AND NOT EXISTS (SELECT 1 FROM friends f WHERE ((f.requester_id = p_user AND f.addressee_id = u.id) OR (f.requester_id = u.id AND f.addressee_id = p_user)) AND f.status = 'blocked')
        )
        SELECT
            rc.candidate_id,
            (rc.level_score + rc.style_score + rc.lang_score + rc.date_score + (8.0 / (1.0 + rc.distance_km)))::NUMERIC AS score,
            rc.distance_km::NUMERIC
        FROM relaxed_candidates rc
        ORDER BY score DESC, rc.distance_km ASC;

        GET DIAGNOSTICS v_relaxed_count = ROW_COUNT;
        IF v_relaxed_count > 0 THEN
            RETURN;
        END IF;

        -- ============================================================================
        -- NIVEAU 3 : MATCHING LOOSE
        --   - même station seulement
        --   - on assouplit encore le score
        -- ============================================================================
        RETURN QUERY
        WITH my_status AS (
            SELECT station_id, date_from, date_to, radius_km
            FROM user_station_status
            WHERE user_id = p_user AND is_active = true
            LIMIT 1
        ),
        me AS (
            SELECT level, ride_styles, languages
            FROM users
            WHERE id = p_user
        ),
        loose_candidates AS (
            SELECT
                u.id AS candidate_id,
                COALESCE(
                    CASE
                        WHEN us.station_id IS NOT NULL AND my.station_id IS NOT NULL THEN
                            ST_DistanceSphere(s_user.geom, s_cand.geom) / 1000
                        ELSE
                            999
                    END,
                    999
                ) AS distance_km,
                -- Score niveau plus faible (2 points identique, 1 point adjoint)
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
                -- Score style réduit
                -- ✅ Corrigé : utiliser unnest + JOIN au lieu de cardinality(&&)
                COALESCE((
                    SELECT COUNT(*) * 1
                    FROM unnest(u.ride_styles) AS s(style)
                    JOIN unnest(me.ride_styles) AS m(style) ON s.style = m.style
                ), 0) AS style_score,
                -- Score langues réduit
                -- ✅ Corrigé : utiliser unnest + JOIN au lieu de cardinality(&&)
                COALESCE((
                    SELECT COUNT(*)
                    FROM unnest(u.languages) AS s(lang)
                    JOIN unnest(me.languages) AS m(lang) ON s.lang = m.lang
                ), 0) AS lang_score,
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
                -- On garde la même station si possible
                AND (
                    (my.station_id IS NOT NULL AND us.station_id = my.station_id) OR
                    my.station_id IS NULL
                )
                -- Exclusions
                AND NOT EXISTS (SELECT 1 FROM likes l WHERE l.liker_id = p_user AND l.liked_id = u.id)
                AND NOT EXISTS (SELECT 1 FROM matches m WHERE (m.user1_id = p_user AND m.user2_id = u.id) OR (m.user2_id = p_user AND m.user1_id = u.id))
                AND NOT EXISTS (SELECT 1 FROM friends f WHERE ((f.requester_id = p_user AND f.addressee_id = u.id) OR (f.requester_id = u.id AND f.addressee_id = p_user)) AND f.status = 'blocked')
        )
        SELECT
            lc.candidate_id,
            (lc.level_score + lc.style_score + lc.lang_score + lc.date_score + (5.0 / (1.0 + lc.distance_km)))::NUMERIC AS score,
            lc.distance_km::NUMERIC
        FROM loose_candidates lc
        ORDER BY score DESC, lc.distance_km ASC;

        GET DIAGNOSTICS v_loose_count = ROW_COUNT;
        IF v_loose_count > 0 THEN
            RETURN;
        END IF;
    END IF; -- Fin du test station active

    -- ============================================================================
    -- NIVEAU 4 : FALLBACK ULTIME
    --   - tous les utilisateurs actifs (hors exclus)
    --   - score minimal basé uniquement sur niveau/styles/langues
    -- ============================================================================
    RETURN QUERY
    WITH me AS (
        SELECT level, ride_styles, languages
        FROM users
        WHERE id = p_user
    ),
    fallback_candidates AS (
        SELECT
            u.id AS candidate_id,
            999 AS distance_km,
            -- Score minimal : 1 point si même niveau, sinon 0
            CASE WHEN u.level = me.level THEN 1 ELSE 0 END AS level_score,
            -- Styles et langues valant 0.5 point par match
            -- ✅ Corrigé : utiliser unnest + JOIN au lieu de cardinality(&&)
            COALESCE((
                SELECT COUNT(*) * 0.5
                FROM unnest(u.ride_styles) AS s(style)
                JOIN unnest(me.ride_styles) AS m(style) ON s.style = m.style
            ), 0) AS style_score,
            COALESCE((
                SELECT COUNT(*) * 0.5
                FROM unnest(u.languages) AS s(lang)
                JOIN unnest(me.languages) AS m(lang) ON s.lang = m.lang
            ), 0) AS lang_score,
            0 AS date_score
        FROM users u
        CROSS JOIN me
        WHERE u.id <> p_user
            AND u.is_active = true
            AND u.is_banned = false
            -- Exclusions
            AND NOT EXISTS (SELECT 1 FROM likes l WHERE l.liker_id = p_user AND l.liked_id = u.id)
            AND NOT EXISTS (SELECT 1 FROM matches m WHERE (m.user1_id = p_user AND m.user2_id = u.id) OR (m.user2_id = p_user AND m.user1_id = u.id))
            AND NOT EXISTS (SELECT 1 FROM friends f WHERE ((f.requester_id = p_user AND f.addressee_id = u.id) OR (f.requester_id = u.id AND f.addressee_id = p_user)) AND f.status = 'blocked')
    )
    SELECT
        fc.candidate_id,
        (fc.level_score + fc.style_score + fc.lang_score + fc.date_score + 0.1)::NUMERIC AS score,
        999::NUMERIC AS distance_km
    FROM fallback_candidates fc
    JOIN users u ON u.id = fc.candidate_id
    ORDER BY score DESC, u.last_active_at DESC NULLS LAST
    LIMIT 50;

END;
$$;

COMMENT ON FUNCTION public.get_candidate_scores(UUID) IS
'Fonction de matching avec relâchement progressif :
1. Matching strict : mêmes station/dates/âge, distance OK, niveaux adjacents ; on valorise langues, styles et niveau.
2. Matching relâché : mêmes station(s) ou proches, dates proches ; score réduit.
3. Matching loose : même station uniquement ; score minimal.
4. Fallback ultime : tous les utilisateurs actifs ; score très faible mais toujours un résultat.
Les candidats sont triés du plus compatible au moins compatible.';
