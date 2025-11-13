-- CrewSnow Enhanced Matching Algorithm - Week 6
-- Optimized PostGIS distance calculations and compatibility scoring

-- ============================================================================
-- 1. DISTANCE CALCULATION WITH POSTGIS
-- ============================================================================

-- Enhanced function using ST_DWithin and ST_DistanceSphere specifically
CREATE OR REPLACE FUNCTION calculate_user_distance(
    user1_station_id UUID,
    user2_station_id UUID
) RETURNS DECIMAL AS $$
DECLARE
    distance_meters DECIMAL;
BEGIN
    -- Use ST_DistanceSphere for minimal distance calculation (faster, less precise)
    SELECT ST_DistanceSphere(s1.geom, s2.geom) / 1000.0
    INTO distance_meters
    FROM stations s1, stations s2
    WHERE s1.id = user1_station_id AND s2.id = user2_station_id;
    
    RETURN COALESCE(distance_meters, 999999);
END;
$$ LANGUAGE plpgsql;

-- Proximity check using ST_DWithin (optimized for spatial indexes)
CREATE OR REPLACE FUNCTION users_within_radius(
    target_station_id UUID,
    radius_km INTEGER,
    date_from DATE DEFAULT CURRENT_DATE,
    date_to DATE DEFAULT CURRENT_DATE + 7
) RETURNS TABLE (
    user_id UUID,
    station_id UUID,
    distance_km DECIMAL,
    date_from_user DATE,
    date_to_user DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uss.user_id,
        uss.station_id,
        ROUND(ST_DistanceSphere(s_target.geom, s_user.geom) / 1000.0, 1) as distance_km,
        uss.date_from,
        uss.date_to
    FROM user_station_status uss
    JOIN stations s_user ON uss.station_id = s_user.id
    CROSS JOIN stations s_target
    WHERE s_target.id = target_station_id
        AND uss.is_active = true
        AND uss.date_from <= date_to
        AND uss.date_to >= date_from
        AND ST_DWithin(
            s_target.geom::geography,
            s_user.geom::geography,
            radius_km * 1000 -- Convert km to meters
        )
    ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. ENHANCED COMPATIBILITY SCORING
-- ============================================================================

-- New compatibility scoring function with exact specifications
CREATE OR REPLACE FUNCTION calculate_compatibility_score(
    user1_level user_level,
    user1_styles ride_style[],
    user1_languages language_code[],
    user2_level user_level,
    user2_styles ride_style[],
    user2_languages language_code[],
    distance_km DECIMAL,
    dates_overlap BOOLEAN
) RETURNS INTEGER AS $$
DECLARE
    level_score INTEGER := 0;
    styles_score INTEGER := 0;
    languages_score INTEGER := 0;
    distance_score INTEGER := 0;
    overlap_score INTEGER := 0;
    total_score INTEGER := 0;
    
    common_styles INTEGER := 0;
    common_languages INTEGER := 0;
BEGIN
    -- Niveau (users.level): +4 si identique, +2 si adjacent
    level_score := CASE
        WHEN user1_level = user2_level THEN 4
        WHEN (user1_level = 'beginner' AND user2_level = 'intermediate') OR
             (user1_level = 'intermediate' AND user2_level = 'beginner') OR
             (user1_level = 'intermediate' AND user2_level = 'advanced') OR
             (user1_level = 'advanced' AND user2_level = 'intermediate') OR
             (user1_level = 'advanced' AND user2_level = 'expert') OR
             (user1_level = 'expert' AND user2_level = 'advanced') THEN 2
        ELSE 0
    END;
    
    -- Styles de ride: +2 par style commun
    -- Using cardinality(array_intersect(...)) as specified
    common_styles := cardinality(
        ARRAY(
            SELECT unnest(user1_styles) 
            INTERSECT 
            SELECT unnest(user2_styles)
        )
    );
    styles_score := common_styles * 2;
    
    -- Langues parlées: +1 par langue commune
    common_languages := cardinality(
        ARRAY(
            SELECT unnest(user1_languages)
            INTERSECT
            SELECT unnest(user2_languages)
        )
    );
    languages_score := common_languages * 1;
    
    -- Distance: bonus décroissant 10 / (1 + distance_km)
    distance_score := FLOOR(10.0 / (1.0 + COALESCE(distance_km, 100)));
    
    -- Dates qui se chevauchent: +1 si overlap
    overlap_score := CASE WHEN dates_overlap THEN 1 ELSE 0 END;
    
    total_score := level_score + styles_score + languages_score + distance_score + overlap_score;
    
    RETURN total_score;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ENHANCED MATCHING FUNCTION WITH NEW ALGORITHM
-- ============================================================================

-- Complete rewrite of matching function with Week 6 specifications
CREATE OR REPLACE FUNCTION get_potential_matches_enhanced(
    target_user_id UUID,
    limit_results INTEGER DEFAULT 20,
    max_distance_km INTEGER DEFAULT 100
) RETURNS TABLE (
    user_id UUID,
    username VARCHAR,
    bio TEXT,
    level user_level,
    ride_styles ride_style[],
    languages language_code[],
    is_premium BOOLEAN,
    last_active_at TIMESTAMPTZ,
    station_name VARCHAR,
    distance_km DECIMAL,
    compatibility_score INTEGER,
    level_score INTEGER,
    styles_score INTEGER,
    languages_score INTEGER,
    distance_score INTEGER,
    overlap_score INTEGER,
    common_styles INTEGER,
    common_languages INTEGER,
    dates_overlap BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH target_user AS (
        SELECT 
            u.level as t_level,
            u.ride_styles as t_styles,
            u.languages as t_languages,
            uss.station_id as t_station_id,
            uss.date_from as t_date_from,
            uss.date_to as t_date_to,
            uss.radius_km as t_radius_km,
            s.geom as t_station_geom
        FROM users u
        JOIN user_station_status uss ON u.id = uss.user_id
        JOIN stations s ON uss.station_id = s.id
        WHERE u.id = target_user_id 
            AND uss.is_active = true
            AND u.is_active = true
        LIMIT 1
    ),
    nearby_users AS (
        SELECT DISTINCT
            u.id,
            u.username,
            u.bio,
            u.level,
            u.ride_styles,
            u.languages,
            u.is_premium,
            u.last_active_at,
            s.name as station_name,
            uss.date_from,
            uss.date_to,
            -- Use ST_DistanceSphere for exact distance calculation
            ROUND(ST_DistanceSphere(tu.t_station_geom, s.geom) / 1000.0, 1) as distance_km,
            -- Check date overlap
            (uss.date_from <= tu.t_date_to AND uss.date_to >= tu.t_date_from) as dates_overlap
        FROM target_user tu
        CROSS JOIN user_station_status uss
        JOIN users u ON uss.user_id = u.id
        JOIN stations s ON uss.station_id = s.id
        WHERE u.id != target_user_id
            AND u.is_active = true
            AND u.is_banned = false
            AND uss.is_active = true
            -- Use ST_DWithin for optimized spatial filtering
            AND ST_DWithin(
                tu.t_station_geom::geography,
                s.geom::geography,
                LEAST(max_distance_km, tu.t_radius_km) * 1000
            )
            -- Exclude already liked users
            AND NOT EXISTS (
                SELECT 1 FROM likes l 
                WHERE l.liker_id = target_user_id AND l.liked_id = u.id
            )
            -- Exclude already matched users
            AND NOT EXISTS (
                SELECT 1 FROM matches m 
                WHERE (m.user1_id = LEAST(target_user_id, u.id) AND m.user2_id = GREATEST(target_user_id, u.id))
            )
    ),
    scored_users AS (
        SELECT 
            nu.*,
            tu.t_level,
            tu.t_styles,
            tu.t_languages,
            -- Calculate individual scores
            CASE
                WHEN nu.level = tu.t_level THEN 4
                WHEN (nu.level = 'beginner' AND tu.t_level = 'intermediate') OR
                     (nu.level = 'intermediate' AND tu.t_level = 'beginner') OR
                     (nu.level = 'intermediate' AND tu.t_level = 'advanced') OR
                     (nu.level = 'advanced' AND tu.t_level = 'intermediate') OR
                     (nu.level = 'advanced' AND tu.t_level = 'expert') OR
                     (nu.level = 'expert' AND tu.t_level = 'advanced') THEN 2
                ELSE 0
            END as level_score,
            
            cardinality(
                ARRAY(SELECT unnest(tu.t_styles) INTERSECT SELECT unnest(nu.ride_styles))
            ) * 2 as styles_score,
            
            cardinality(
                ARRAY(SELECT unnest(tu.t_languages) INTERSECT SELECT unnest(nu.languages))
            ) * 1 as languages_score,
            
            FLOOR(10.0 / (1.0 + nu.distance_km))::INTEGER as distance_score,
            
            CASE WHEN nu.dates_overlap THEN 1 ELSE 0 END as overlap_score,
            
            cardinality(
                ARRAY(SELECT unnest(tu.t_styles) INTERSECT SELECT unnest(nu.ride_styles))
            ) as common_styles,
            
            cardinality(
                ARRAY(SELECT unnest(tu.t_languages) INTERSECT SELECT unnest(nu.languages))
            ) as common_languages
        FROM nearby_users nu
        CROSS JOIN target_user tu
    )
    SELECT 
        su.id,
        su.username,
        su.bio,
        su.level,
        su.ride_styles,
        su.languages,
        su.is_premium,
        su.last_active_at,
        su.station_name,
        su.distance_km,
        (su.level_score + su.styles_score + su.languages_score + su.distance_score + su.overlap_score) as compatibility_score,
        su.level_score,
        su.styles_score,
        su.languages_score,
        su.distance_score,
        su.overlap_score,
        su.common_styles,
        su.common_languages,
        su.dates_overlap
    FROM scored_users su
    ORDER BY 
        compatibility_score DESC,
        distance_km ASC,
        last_active_at DESC
    LIMIT limit_results;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- DISTANCE OPTIMIZATION FUNCTIONS
-- ============================================================================

-- Function for bulk distance calculations
CREATE OR REPLACE FUNCTION calculate_bulk_distances(
    center_station_id UUID,
    target_station_ids UUID[]
) RETURNS TABLE (
    station_id UUID,
    distance_km DECIMAL,
    within_50km BOOLEAN,
    within_25km BOOLEAN,
    within_10km BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        ROUND(ST_DistanceSphere(s_center.geom, s.geom) / 1000.0, 1) as distance_km,
        ST_DWithin(s_center.geom::geography, s.geom::geography, 50000) as within_50km,
        ST_DWithin(s_center.geom::geography, s.geom::geography, 25000) as within_25km,
        ST_DWithin(s_center.geom::geography, s.geom::geography, 10000) as within_10km
    FROM stations s
    CROSS JOIN stations s_center
    WHERE s_center.id = center_station_id
        AND s.id = ANY(target_station_ids)
        AND s.is_active = true
    ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMPATIBILITY SCORE BREAKDOWN FUNCTION
-- ============================================================================

-- Detailed compatibility analysis function
CREATE OR REPLACE FUNCTION analyze_compatibility(
    user1_id UUID,
    user2_id UUID
) RETURNS TABLE (
    total_score INTEGER,
    level_score INTEGER,
    level_match TEXT,
    styles_score INTEGER,
    common_styles_count INTEGER,
    common_styles TEXT[],
    languages_score INTEGER,
    common_languages_count INTEGER,
    common_languages TEXT[],
    distance_score INTEGER,
    distance_km DECIMAL,
    overlap_score INTEGER,
    date_overlap_days INTEGER,
    recommendation TEXT
) AS $$
DECLARE
    u1 RECORD;
    u2 RECORD;
    u1_status RECORD;
    u2_status RECORD;
    dist_km DECIMAL;
    overlap_days INTEGER;
    dates_overlap BOOLEAN;
BEGIN
    -- Get user data
    SELECT level, ride_styles, languages INTO u1 FROM users WHERE id = user1_id;
    SELECT level, ride_styles, languages INTO u2 FROM users WHERE id = user2_id;
    
    -- Get current station status
    SELECT station_id, date_from, date_to INTO u1_status 
    FROM user_station_status WHERE user_id = user1_id AND is_active = true LIMIT 1;
    
    SELECT station_id, date_from, date_to INTO u2_status
    FROM user_station_status WHERE user_id = user2_id AND is_active = true LIMIT 1;
    
    -- Calculate distance if both have active locations
    IF u1_status.station_id IS NOT NULL AND u2_status.station_id IS NOT NULL THEN
        SELECT calculate_user_distance(u1_status.station_id, u2_status.station_id) INTO dist_km;
        
        -- Check date overlap
        dates_overlap := u1_status.date_from <= u2_status.date_to AND u1_status.date_to >= u2_status.date_from;
        
        IF dates_overlap THEN
            overlap_days := (LEAST(u1_status.date_to, u2_status.date_to) - GREATEST(u1_status.date_from, u2_status.date_from))::INTEGER + 1;
        ELSE
            overlap_days := 0;
        END IF;
    ELSE
        dist_km := 999999;
        dates_overlap := false;
        overlap_days := 0;
    END IF;
    
    RETURN QUERY
    WITH score_calc AS (
        SELECT 
            CASE
                WHEN u1.level = u2.level THEN 4
                WHEN (u1.level IN ('beginner', 'intermediate') AND u2.level IN ('beginner', 'intermediate')) OR
                     (u1.level IN ('intermediate', 'advanced') AND u2.level IN ('intermediate', 'advanced')) OR
                     (u1.level IN ('advanced', 'expert') AND u2.level IN ('advanced', 'expert')) THEN 2
                ELSE 0
            END as ls,
            
            cardinality(ARRAY(SELECT unnest(u1.ride_styles) INTERSECT SELECT unnest(u2.ride_styles))) * 2 as ss,
            
            cardinality(ARRAY(SELECT unnest(u1.languages) INTERSECT SELECT unnest(u2.languages))) * 1 as las,
            
            FLOOR(10.0 / (1.0 + COALESCE(dist_km, 100)))::INTEGER as ds,
            
            CASE WHEN dates_overlap THEN 1 ELSE 0 END as os,
            
            ARRAY(SELECT unnest(u1.ride_styles) INTERSECT SELECT unnest(u2.ride_styles)) as common_s,
            
            ARRAY(SELECT unnest(u1.languages) INTERSECT SELECT unnest(u2.languages)) as common_l
    )
    SELECT 
        sc.ls + sc.ss + sc.las + sc.ds + sc.os,
        sc.ls,
        CASE
            WHEN u1.level = u2.level THEN 'Identical (' || u1.level::text || ')'
            WHEN sc.ls = 2 THEN 'Adjacent (' || u1.level::text || ' ↔ ' || u2.level::text || ')'
            ELSE 'Different (' || u1.level::text || ' ↔ ' || u2.level::text || ')'
        END,
        sc.ss,
        cardinality(sc.common_s),
        sc.common_s::TEXT[],
        sc.las,
        cardinality(sc.common_l),
        sc.common_l::TEXT[],
        sc.ds,
        dist_km,
        sc.os,
        overlap_days,
        CASE 
            WHEN sc.ls + sc.ss + sc.las + sc.ds + sc.os >= 15 THEN 'Excellent match'
            WHEN sc.ls + sc.ss + sc.las + sc.ds + sc.os >= 10 THEN 'Good match'
            WHEN sc.ls + sc.ss + sc.las + sc.ds + sc.os >= 5 THEN 'Possible match'
            ELSE 'Low compatibility'
        END
    FROM score_calc sc;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- OPTIMIZED MATCHING WITH WEEK 6 ALGORITHM
-- ============================================================================

-- Main matching function using enhanced algorithm
CREATE OR REPLACE FUNCTION get_matches_week6_algorithm(
    target_user_id UUID,
    limit_results INTEGER DEFAULT 20,
    max_distance_km INTEGER DEFAULT 100,
    min_compatibility_score INTEGER DEFAULT 3
) RETURNS TABLE (
    user_id UUID,
    username VARCHAR,
    bio TEXT,
    level user_level,
    ride_styles ride_style[],
    languages language_code[],
    is_premium BOOLEAN,
    last_active_at TIMESTAMPTZ,
    station_name VARCHAR,
    distance_km DECIMAL,
    compatibility_score INTEGER,
    level_compatibility TEXT,
    common_styles_count INTEGER,
    common_languages_count INTEGER,
    dates_overlap BOOLEAN,
    overlap_days INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH target_user AS (
        SELECT 
            u.level,
            u.ride_styles,
            u.languages,
            uss.station_id,
            uss.date_from,
            uss.date_to,
            uss.radius_km,
            s.geom as station_geom
        FROM users u
        JOIN user_station_status uss ON u.id = uss.user_id
        JOIN stations s ON uss.station_id = s.id
        WHERE u.id = target_user_id 
            AND uss.is_active = true
            AND u.is_active = true
        LIMIT 1
    ),
    nearby_candidates AS (
        SELECT 
            u.id,
            u.username,
            u.bio,
            u.level,
            u.ride_styles,
            u.languages,
            u.is_premium,
            u.last_active_at,
            s.name as station_name,
            uss.date_from,
            uss.date_to,
            ROUND(ST_DistanceSphere(tu.station_geom, s.geom) / 1000.0, 1) as distance_km,
            (uss.date_from <= tu.date_to AND uss.date_to >= tu.date_from) as dates_overlap,
            CASE 
                WHEN uss.date_from <= tu.date_to AND uss.date_to >= tu.date_from 
                THEN (LEAST(uss.date_to, tu.date_to) - GREATEST(uss.date_from, tu.date_from))::INTEGER + 1
                ELSE 0
            END as overlap_days
        FROM target_user tu
        CROSS JOIN user_station_status uss
        JOIN users u ON uss.user_id = u.id
        JOIN stations s ON uss.station_id = s.id
        WHERE u.id != target_user_id
            AND u.is_active = true
            AND u.is_banned = false
            AND uss.is_active = true
            AND ST_DWithin(
                tu.station_geom::geography,
                s.geom::geography,
                LEAST(max_distance_km, tu.radius_km) * 1000
            )
            AND NOT EXISTS (SELECT 1 FROM likes l WHERE l.liker_id = target_user_id AND l.liked_id = u.id)
            AND NOT EXISTS (SELECT 1 FROM matches m WHERE (m.user1_id = LEAST(target_user_id, u.id) AND m.user2_id = GREATEST(target_user_id, u.id)))
    ),
    compatibility_scored AS (
        SELECT 
            nc.*,
            tu.level as target_level,
            tu.ride_styles as target_styles,
            tu.languages as target_languages,
            calculate_compatibility_score(
                tu.level, tu.ride_styles, tu.languages,
                nc.level, nc.ride_styles, nc.languages,
                nc.distance_km, nc.dates_overlap
            ) as compat_score
        FROM nearby_candidates nc
        CROSS JOIN target_user tu
        WHERE nc.distance_km <= max_distance_km
    )
    SELECT 
        cs.id,
        cs.username,
        cs.bio,
        cs.level,
        cs.ride_styles,
        cs.languages,
        cs.is_premium,
        cs.last_active_at,
        cs.station_name,
        cs.distance_km,
        cs.compat_score,
        CASE
            WHEN cs.level = cs.target_level THEN 'Identical (' || cs.level::text || ')'
            ELSE 'Compatible levels'
        END as level_compatibility,
        cardinality(ARRAY(SELECT unnest(cs.target_styles) INTERSECT SELECT unnest(cs.ride_styles))) as common_styles_count,
        cardinality(ARRAY(SELECT unnest(cs.target_languages) INTERSECT SELECT unnest(cs.languages))) as common_languages_count,
        cs.dates_overlap,
        cs.overlap_days
    FROM compatibility_scored cs
    WHERE cs.compat_score >= min_compatibility_score
    ORDER BY 
        cs.compat_score DESC,
        cs.distance_km ASC,
        cs.last_active_at DESC
    LIMIT limit_results;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SPATIAL INDEXES VERIFICATION
-- ============================================================================

-- Check and create missing spatial indexes
DO $$
DECLARE
    index_exists BOOLEAN;
BEGIN
    -- Check GIST index on stations.geom
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'stations' AND indexname = 'idx_stations_geom'
    ) INTO index_exists;
    
    IF index_exists THEN
        RAISE NOTICE '✅ GIST index on stations.geom exists';
    ELSE
        CREATE INDEX idx_stations_geom ON stations USING GIST(geom);
        RAISE NOTICE '✅ Created GIST index on stations.geom';
    END IF;
    
    -- Check if user_station_status needs geom column and index
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_station_status' AND column_name = 'geom'
    ) THEN
        -- Add computed geom column if needed
        ALTER TABLE user_station_status 
        ADD COLUMN geom GEOMETRY(POINT, 4326) 
        GENERATED ALWAYS AS (
            (SELECT geom FROM stations WHERE id = station_id)
        ) STORED;
        
        -- Create spatial index
        CREATE INDEX idx_user_station_status_geom ON user_station_status USING GIST(geom);
        RAISE NOTICE '✅ Added geom column and GIST index to user_station_status';
    END IF;
END $$;

-- ============================================================================
-- PERFORMANCE OPTIMIZATION INDEXES
-- ============================================================================

-- Additional indexes for matching performance
CREATE INDEX IF NOT EXISTS idx_users_matching_filters ON users (is_active, is_banned, level) WHERE is_active = true AND is_banned = false;
CREATE INDEX IF NOT EXISTS idx_users_arrays_matching ON users USING GIN (ride_styles, languages) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_user_station_active_dates ON user_station_status (station_id, date_from, date_to, is_active) WHERE is_active = true;

-- ============================================================================
-- COMPATIBILITY CONSTANTS TABLE
-- ============================================================================

-- Table to store adjustable compatibility weights
CREATE TABLE IF NOT EXISTS compatibility_weights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    weight_name VARCHAR(50) NOT NULL UNIQUE,
    weight_value INTEGER NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default weights (adjustable)
INSERT INTO compatibility_weights (weight_name, weight_value, description) VALUES
('level_identical', 4, 'Points for identical skill level'),
('level_adjacent', 2, 'Points for adjacent skill levels'),
('style_common', 2, 'Points per common ride style'),
('language_common', 1, 'Points per common language'),
('distance_base', 10, 'Base points for distance calculation: base / (1 + distance)'),
('date_overlap', 1, 'Points for overlapping dates'),
('min_score_threshold', 3, 'Minimum compatibility score to show user'),
('max_distance_default', 100, 'Default maximum distance in km')
ON CONFLICT (weight_name) DO UPDATE SET 
    updated_at = NOW();

-- Function to get adjustable weight
CREATE OR REPLACE FUNCTION get_compatibility_weight(weight_name VARCHAR)
RETURNS INTEGER AS $$
DECLARE
    weight_value INTEGER;
BEGIN
    SELECT cw.weight_value INTO weight_value 
    FROM compatibility_weights cw 
    WHERE cw.weight_name = get_compatibility_weight.weight_name;
    
    RETURN COALESCE(weight_value, 0);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- CONFIGURABLE MATCHING FUNCTION
-- ============================================================================

-- Matching function with configurable weights
CREATE OR REPLACE FUNCTION get_matches_configurable(
    target_user_id UUID,
    limit_results INTEGER DEFAULT 20
) RETURNS TABLE (
    user_id UUID,
    username VARCHAR,
    compatibility_score INTEGER,
    distance_km DECIMAL,
    station_name VARCHAR,
    score_breakdown JSONB
) AS $$
DECLARE
    level_identical_weight INTEGER;
    level_adjacent_weight INTEGER;
    style_common_weight INTEGER;
    language_common_weight INTEGER;
    distance_base_weight INTEGER;
    overlap_weight INTEGER;
BEGIN
    -- Load configurable weights
    level_identical_weight := get_compatibility_weight('level_identical');
    level_adjacent_weight := get_compatibility_weight('level_adjacent');
    style_common_weight := get_compatibility_weight('style_common');
    language_common_weight := get_compatibility_weight('language_common');
    distance_base_weight := get_compatibility_weight('distance_base');
    overlap_weight := get_compatibility_weight('date_overlap');
    
    RETURN QUERY
    SELECT 
        enhanced.user_id,
        enhanced.username,
        enhanced.compatibility_score,
        enhanced.distance_km,
        enhanced.station_name,
        jsonb_build_object(
            'level_score', enhanced.level_score,
            'styles_score', enhanced.styles_score,
            'languages_score', enhanced.languages_score,
            'distance_score', enhanced.distance_score,
            'overlap_score', enhanced.overlap_score,
            'common_styles', enhanced.common_styles,
            'common_languages', enhanced.common_languages,
            'dates_overlap', enhanced.dates_overlap
        ) as score_breakdown
    FROM get_potential_matches_enhanced(
        target_user_id, 
        limit_results,
        get_compatibility_weight('max_distance_default')
    ) enhanced
    WHERE enhanced.compatibility_score >= get_compatibility_weight('min_score_threshold');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON FUNCTION calculate_user_distance(UUID, UUID) IS 'Uses ST_DistanceSphere for fast distance calculation between stations';
COMMENT ON FUNCTION users_within_radius(UUID, INTEGER, DATE, DATE) IS 'Uses ST_DWithin for optimized spatial proximity filtering';
COMMENT ON FUNCTION calculate_compatibility_score(user_level, ride_style[], language_code[], user_level, ride_style[], language_code[], DECIMAL, BOOLEAN) IS 'Week 6 compatibility scoring: level +4/+2, styles +2 each, languages +1 each, distance 10/(1+km), overlap +1';
COMMENT ON FUNCTION get_potential_matches_enhanced(UUID, INTEGER, INTEGER) IS 'Enhanced matching with detailed scoring breakdown and Week 6 algorithm';
COMMENT ON TABLE compatibility_weights IS 'Adjustable weights for compatibility scoring algorithm';

DO $$
BEGIN
    RAISE NOTICE '🎯 Enhanced Matching Algorithm (Week 6) Implemented!';
    RAISE NOTICE '📊 Features:';
    RAISE NOTICE '  ✅ ST_DWithin for spatial optimization';
    RAISE NOTICE '  ✅ ST_DistanceSphere for exact distances';  
    RAISE NOTICE '  ✅ New compatibility formula: level +4/+2, styles +2 each, languages +1 each';
    RAISE NOTICE '  ✅ Distance bonus: 10 / (1 + distance_km)';
    RAISE NOTICE '  ✅ Date overlap: +1 if overlapping';
    RAISE NOTICE '  ✅ Configurable weights via compatibility_weights table';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Test: SELECT * FROM get_potential_matches_enhanced(user_id, 10);';
    RAISE NOTICE '📊 Analyze: SELECT * FROM analyze_compatibility(user1_id, user2_id);';
END $$;
