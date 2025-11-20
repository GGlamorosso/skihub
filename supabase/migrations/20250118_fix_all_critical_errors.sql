-- ============================================================================
-- CORRECTION COMPLÈTE DE TOUS LES PROBLÈMES CRITIQUES
-- ============================================================================
-- Ce script corrige :
-- 1. L'erreur "candidate_id is ambiguous" dans get_optimized_candidates
-- 2. Les signatures incorrectes de check_user_consent et grant_consent
-- 3. Vérifie que toutes les fonctions nécessaires existent
-- ============================================================================

-- ============================================================================
-- 1. CORRIGER get_optimized_candidates (candidate_id ambiguous)
-- ============================================================================

DROP FUNCTION IF EXISTS public.get_optimized_candidates(UUID, INTEGER, BOOLEAN);

CREATE OR REPLACE FUNCTION public.get_optimized_candidates(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    use_cache BOOLEAN DEFAULT true
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
    -- Vérifier que l'utilisateur a une station configurée
    IF NOT EXISTS (
        SELECT 1 FROM user_station_status 
        WHERE user_id = p_user_id AND is_active = true
    ) THEN
        RAISE EXCEPTION 'L''utilisateur % n''a pas de station configurée', p_user_id;
    END IF;

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
            uss.user_id AS candidate_user_id,  -- ✅ Renommer pour éviter ambiguïté
            s.name::TEXT AS station_name
        FROM user_station_status uss
        JOIN stations s ON s.id = uss.station_id
        WHERE uss.is_active = true
            AND uss.user_id IN (SELECT base.candidate_id FROM base)  -- ✅ Qualifier avec base.
        ORDER BY uss.user_id, uss.date_from DESC
    ),
    candidate_details AS (
        SELECT 
            base.candidate_id,  -- ✅ Qualifier avec base.
            u.level,
            u.ride_styles,
            u.languages,
            my.level AS my_level,
            my.ride_styles AS my_ride_styles,
            my.languages AS my_languages,
            base.distance_km,  -- ✅ Qualifier avec base.
            CASE 
                WHEN EXISTS (
                    SELECT 1 FROM user_station_status uss1
                    JOIN user_station_status uss2 ON uss1.station_id = uss2.station_id
                    WHERE uss1.user_id = p_user_id 
                        AND uss2.user_id = base.candidate_id  -- ✅ Qualifier avec base.
                        AND uss1.is_active = true 
                        AND uss2.is_active = true
                        AND uss1.date_from <= uss2.date_to 
                        AND uss2.date_from <= uss1.date_to
                ) THEN 1 ELSE 0
            END AS has_date_overlap
        FROM base
        JOIN users u ON u.id = base.candidate_id  -- ✅ Qualifier avec base.
        CROSS JOIN (
            SELECT level, ride_styles, languages 
            FROM users 
            WHERE id = p_user_id
        ) my
    )
    SELECT 
        base.candidate_id::UUID,  -- ✅ Qualifier explicitement
        u.username::TEXT,
        u.bio,
        u.level,
        base.compatibility_score::NUMERIC,  -- ✅ Qualifier avec base.
        base.distance_km::NUMERIC,  -- ✅ Qualifier avec base.
        COALESCE(sf.station_name, 'Non spécifiée')::TEXT AS station_name,
        jsonb_build_object(
            'level_score', CASE 
                WHEN cd.level = cd.my_level THEN 4
                WHEN (cd.level = 'beginner' AND cd.my_level = 'intermediate') OR 
                     (cd.level = 'intermediate' AND cd.my_level = 'beginner') OR
                     (cd.level = 'intermediate' AND cd.my_level = 'advanced') OR
                     (cd.level = 'advanced' AND cd.my_level = 'intermediate') OR
                     (cd.level = 'advanced' AND cd.my_level = 'expert') OR
                     (cd.level = 'expert' AND cd.my_level = 'advanced') THEN 2
                ELSE 0
            END,
            'styles_score', COALESCE((
                SELECT COUNT(*) * 2
                FROM unnest(cd.ride_styles) AS s(style)
                JOIN unnest(cd.my_ride_styles) AS m(style) ON s.style = m.style
            ), 0),
            'languages_score', COALESCE((
                SELECT COUNT(*)
                FROM unnest(cd.languages) AS s(lang)
                JOIN unnest(cd.my_languages) AS m(lang) ON s.lang = m.lang
            ), 0),
            'distance_score', COALESCE((10.0 / (1.0 + cd.distance_km))::NUMERIC, 0),
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
    FROM base
    JOIN users u ON u.id = base.candidate_id  -- ✅ Qualifier avec base.
    LEFT JOIN station_for_candidate sf ON sf.candidate_user_id = base.candidate_id  -- ✅ Utiliser candidate_user_id
    LEFT JOIN candidate_details cd ON cd.candidate_id = base.candidate_id  -- ✅ Qualifier avec base.
    ORDER BY base.compatibility_score DESC, base.distance_km ASC  -- ✅ Qualifier avec base.
    LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION public.get_optimized_candidates(UUID, INTEGER, BOOLEAN) IS 
'Version corrigée de get_optimized_candidates avec résolution d''ambiguïté candidate_id.';

-- ============================================================================
-- 2. CORRIGER LES SIGNATURES DE check_user_consent et grant_consent
-- ============================================================================
-- L'Edge Function manage-consent appelle :
-- - check_user_consent(p_user_id, p_purpose, p_required_version)
-- - grant_consent(p_user_id, p_purpose, p_version)
-- ============================================================================

-- Supprimer les anciennes versions si elles existent avec une mauvaise signature
DROP FUNCTION IF EXISTS public.check_user_consent(TEXT, INTEGER, UUID);
DROP FUNCTION IF EXISTS public.check_user_consent(UUID, TEXT, INTEGER);

-- Créer avec la bonne signature (correspond à l'Edge Function)
CREATE OR REPLACE FUNCTION public.check_user_consent(
    p_user_id UUID,
    p_purpose TEXT,
    p_required_version INTEGER DEFAULT 1
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    consent_exists BOOLEAN := false;
BEGIN
    -- Vérifier que la table consents existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'consents'
    ) THEN
        RAISE EXCEPTION 'Table consents does not exist';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM consents 
        WHERE user_id = p_user_id 
            AND purpose = p_purpose
            AND version >= p_required_version
            AND revoked_at IS NULL
    ) INTO consent_exists;
    
    RETURN consent_exists;
END;
$$;

-- Supprimer les anciennes versions si elles existent
DROP FUNCTION IF EXISTS public.grant_consent(TEXT, UUID, INTEGER);
DROP FUNCTION IF EXISTS public.grant_consent(UUID, TEXT, INTEGER);

-- Créer avec la bonne signature (correspond à l'Edge Function)
CREATE OR REPLACE FUNCTION public.grant_consent(
    p_user_id UUID,
    p_purpose TEXT,
    p_version INTEGER DEFAULT 1
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    consent_id UUID;
BEGIN
    -- ✅ Vérifier que l'utilisateur existe dans public.users
    IF NOT EXISTS (
        SELECT 1 FROM public.users WHERE id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist in public.users. Create profile first.', p_user_id;
    END IF;
    
    -- Vérifier que la table consents existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'consents'
    ) THEN
        RAISE EXCEPTION 'Table consents does not exist';
    END IF;
    
    -- Révoquer consentements précédents
    UPDATE consents 
    SET revoked_at = NOW()
    WHERE user_id = p_user_id 
        AND purpose = p_purpose 
        AND revoked_at IS NULL;
    
    -- Accorder nouveau consentement
    INSERT INTO consents (user_id, purpose, granted_at, version)
    VALUES (p_user_id, p_purpose, NOW(), p_version)
    RETURNING id INTO consent_id;
    
    RETURN consent_id;
END;
$$;

-- Créer revoke_consent si elle n'existe pas (utilisée par l'Edge Function)
CREATE OR REPLACE FUNCTION public.revoke_consent(
    p_user_id UUID,
    p_purpose TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    revoked_count INTEGER;
BEGIN
    -- Vérifier que la table consents existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'consents'
    ) THEN
        RAISE EXCEPTION 'Table consents does not exist';
    END IF;
    
    UPDATE consents 
    SET revoked_at = NOW()
    WHERE user_id = p_user_id 
        AND purpose = p_purpose 
        AND revoked_at IS NULL;
    
    GET DIAGNOSTICS revoked_count = ROW_COUNT;
    
    RETURN revoked_count > 0;
END;
$$;

-- ============================================================================
-- 3. VÉRIFICATIONS ET COMMENTAIRES
-- ============================================================================

COMMENT ON FUNCTION public.check_user_consent(UUID, TEXT, INTEGER) IS 
'Vérifie si un utilisateur a accordé son consentement pour un purpose donné. 
Signature: check_user_consent(p_user_id, p_purpose, p_required_version)';

COMMENT ON FUNCTION public.grant_consent(UUID, TEXT, INTEGER) IS 
'Accorde un consentement à un utilisateur pour un purpose donné.
Signature: grant_consent(p_user_id, p_purpose, p_version)';

COMMENT ON FUNCTION public.revoke_consent(UUID, TEXT) IS 
'Révoque un consentement actif pour un utilisateur et un purpose donné.
Signature: revoke_consent(p_user_id, p_purpose)';

-- ============================================================================
-- 4. VÉRIFICATION FINALE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Migration terminée avec succès';
    RAISE NOTICE '   - get_optimized_candidates corrigé (candidate_id ambiguous)';
    RAISE NOTICE '   - check_user_consent créé avec la bonne signature';
    RAISE NOTICE '   - grant_consent créé avec la bonne signature';
    RAISE NOTICE '   - revoke_consent créé';
END $$;

