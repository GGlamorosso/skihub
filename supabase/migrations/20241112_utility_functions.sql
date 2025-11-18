-- CrewSnow Utility Functions
-- Description: Core functions for matching, geo queries, and business logic

-- ============================================================================
-- MATCHING FUNCTIONS
-- ============================================================================

-- Function to create a match when mutual likes exist
CREATE OR REPLACE FUNCTION create_match_from_likes()
RETURNS TRIGGER AS $$
DECLARE
    existing_like_id UUID;
    match_exists BOOLEAN;
    user1_id UUID;
    user2_id UUID;
BEGIN
    -- Check if the reverse like exists (mutual like)
    SELECT id INTO existing_like_id 
    FROM likes 
    WHERE liker_id = NEW.liked_id AND liked_id = NEW.liker_id;
    
    IF existing_like_id IS NOT NULL THEN
        -- Ensure proper ordering for match table (smaller UUID first)
        IF NEW.liker_id < NEW.liked_id THEN
            user1_id := NEW.liker_id;
            user2_id := NEW.liked_id;
        ELSE
            user1_id := NEW.liked_id;
            user2_id := NEW.liker_id;
        END IF;
        
        -- Check if match already exists
        SELECT EXISTS(
            SELECT 1 FROM matches 
            WHERE user1_id = user1_id AND user2_id = user2_id
        ) INTO match_exists;
        
        -- Create match if it doesn't exist
        IF NOT match_exists THEN
            INSERT INTO matches (user1_id, user2_id, matched_at_station_id, created_at)
            SELECT 
                user1_id, 
                user2_id, 
                -- Try to find a common station where both users are/were
                COALESCE(
                    (SELECT uss1.station_id 
                     FROM user_station_status uss1 
                     JOIN user_station_status uss2 ON uss1.station_id = uss2.station_id
                     WHERE uss1.user_id = user1_id 
                       AND uss2.user_id = user2_id
                       AND uss1.is_active = true 
                       AND uss2.is_active = true
                       AND uss1.date_from <= uss2.date_to 
                       AND uss2.date_from <= uss1.date_to
                     ORDER BY uss1.created_at DESC
                     LIMIT 1),
                    NULL
                ),
                NOW();
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically create matches on mutual likes
-- ✅ Idempotent : supprime le trigger s'il existe déjà avant de le créer
DROP TRIGGER IF EXISTS trigger_create_match_on_like ON likes;
CREATE TRIGGER trigger_create_match_on_like
    AFTER INSERT ON likes
    FOR EACH ROW
    EXECUTE FUNCTION create_match_from_likes();

-- ============================================================================
-- GEOSPATIAL UTILITY FUNCTIONS
-- ============================================================================

-- Function to find users within radius of a station
CREATE OR REPLACE FUNCTION find_users_at_station(
    target_station_id UUID,
    search_radius_km INTEGER DEFAULT 50,
    date_from DATE DEFAULT CURRENT_DATE,
    date_to DATE DEFAULT CURRENT_DATE + INTERVAL '30 days'
) RETURNS TABLE (
    user_id UUID,
    username VARCHAR,
    level user_level,
    ride_styles ride_style[],
    languages language_code[],
    is_premium BOOLEAN,
    distance_km DECIMAL,
    station_name VARCHAR,
    user_radius_km INTEGER,
    date_from_user DATE,
    date_to_user DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id as user_id,
        u.username,
        u.level,
        u.ride_styles,
        u.languages,
        u.is_premium,
        ROUND(
            ST_Distance(
                s_target.geom::geography, 
                s_user.geom::geography
            ) / 1000, 1
        ) as distance_km,
        s_user.name as station_name,
        uss.radius_km as user_radius_km,
        uss.date_from as date_from_user,
        uss.date_to as date_to_user
    FROM users u
    JOIN user_station_status uss ON u.id = uss.user_id
    JOIN stations s_user ON uss.station_id = s_user.id
    CROSS JOIN stations s_target
    WHERE s_target.id = target_station_id
        AND uss.is_active = true
        AND u.is_active = true
        AND u.is_banned = false
        -- Date overlap check
        AND uss.date_from <= date_to
        AND uss.date_to >= date_from
        -- Distance check (either within search radius or user's radius)
        AND (
            ST_DWithin(
                s_target.geom::geography,
                s_user.geom::geography,
                GREATEST(search_radius_km, uss.radius_km) * 1000
            )
        )
    ORDER BY distance_km ASC, u.last_active_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to find nearby stations from a point
CREATE OR REPLACE FUNCTION find_nearby_stations(
    latitude DECIMAL,
    longitude DECIMAL,
    radius_km INTEGER DEFAULT 100
) RETURNS TABLE (
    station_id UUID,
    name VARCHAR,
    country_code CHAR,
    distance_km DECIMAL,
    elevation_m INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id as station_id,
        s.name,
        s.country_code,
        ROUND(
            ST_Distance(
                ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
                s.geom::geography
            ) / 1000, 1
        ) as distance_km,
        s.elevation_m
    FROM stations s
    WHERE s.is_active = true
        AND ST_DWithin(
            ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
            s.geom::geography,
            radius_km * 1000
        )
    ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- MATCHING ALGORITHM FUNCTIONS
-- ============================================================================

-- Function to get potential matches for a user
CREATE OR REPLACE FUNCTION get_potential_matches(
    target_user_id UUID,
    limit_results INTEGER DEFAULT 20
) RETURNS TABLE (
    user_id UUID,
    username VARCHAR,
    bio TEXT,
    level user_level,
    ride_styles ride_style[],
    languages language_code[],
    is_premium BOOLEAN,
    last_active_at TIMESTAMPTZ,
    common_station_name VARCHAR,
    distance_km DECIMAL,
    compatibility_score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH target_user AS (
        SELECT u.*, uss.station_id, uss.date_from, uss.date_to, uss.radius_km
        FROM users u
        JOIN user_station_status uss ON u.id = uss.user_id
        WHERE u.id = target_user_id 
            AND uss.is_active = true
            AND u.is_active = true
    ),
    potential_users AS (
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
            ROUND(
                ST_Distance(
                    s_target.geom::geography,
                    s.geom::geography
                ) / 1000, 1
            ) as distance_km,
            -- Compatibility scoring
            (
                -- Language overlap (0-30 points)
                CASE 
                    WHEN tu.languages && u.languages THEN 30
                    ELSE 0
                END +
                -- Level compatibility (0-25 points)
                CASE 
                    WHEN tu.level = u.level THEN 25
                    WHEN (tu.level IN ('beginner', 'intermediate') AND u.level IN ('beginner', 'intermediate')) THEN 20
                    WHEN (tu.level IN ('intermediate', 'advanced') AND u.level IN ('intermediate', 'advanced')) THEN 20
                    WHEN (tu.level IN ('advanced', 'expert') AND u.level IN ('advanced', 'expert')) THEN 20
                    ELSE 10
                END +
                -- Ride style overlap (0-25 points)
                CASE 
                    WHEN tu.ride_styles && u.ride_styles THEN 25
                    ELSE 5
                END +
                -- Recent activity bonus (0-15 points)
                CASE 
                    WHEN u.last_active_at > NOW() - INTERVAL '1 hour' THEN 15
                    WHEN u.last_active_at > NOW() - INTERVAL '1 day' THEN 10
                    WHEN u.last_active_at > NOW() - INTERVAL '1 week' THEN 5
                    ELSE 0
                END +
                -- Premium user bonus (0-5 points)
                CASE WHEN u.is_premium THEN 5 ELSE 0 END
            ) as compatibility_score
        FROM target_user tu
        JOIN stations s_target ON tu.station_id = s_target.id
        JOIN user_station_status uss ON uss.station_id IN (
            -- Users at same station or nearby stations
            SELECT s2.id 
            FROM stations s2 
            WHERE ST_DWithin(
                s_target.geom::geography,
                s2.geom::geography,
                GREATEST(tu.radius_km, 50) * 1000
            )
        )
        JOIN users u ON uss.user_id = u.id
        JOIN stations s ON uss.station_id = s.id
        WHERE u.id != target_user_id
            AND u.is_active = true
            AND u.is_banned = false
            AND uss.is_active = true
            -- Date overlap
            AND uss.date_from <= tu.date_to
            AND uss.date_to >= tu.date_from
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
    )
    SELECT 
        pu.id,
        pu.username,
        pu.bio,
        pu.level,
        pu.ride_styles,
        pu.languages,
        pu.is_premium,
        pu.last_active_at,
        pu.station_name,
        pu.distance_km,
        pu.compatibility_score
    FROM potential_users pu
    ORDER BY pu.compatibility_score DESC, pu.distance_km ASC, pu.last_active_at DESC
    LIMIT limit_results;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- USER STATISTICS FUNCTIONS
-- ============================================================================

-- Function to get user's ride statistics summary
CREATE OR REPLACE FUNCTION get_user_ride_stats_summary(
    target_user_id UUID,
    days_back INTEGER DEFAULT 30
) RETURNS TABLE (
    total_days INTEGER,
    total_distance_km DECIMAL,
    total_elevation_gain_m BIGINT,
    total_runs INTEGER,
    avg_vmax_kmh DECIMAL,
    best_day_distance_km DECIMAL,
    best_day_vmax_kmh DECIMAL,
    most_visited_station VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    WITH stats AS (
        SELECT 
            COUNT(DISTINCT date) as total_days,
            SUM(distance_km) as total_distance_km,
            SUM(elevation_gain_m) as total_elevation_gain_m,
            SUM(runs_count) as total_runs,
            AVG(vmax_kmh) as avg_vmax_kmh,
            MAX(distance_km) as best_day_distance_km,
            MAX(vmax_kmh) as best_day_vmax_kmh
        FROM ride_stats_daily rsd
        WHERE rsd.user_id = target_user_id
            AND rsd.date >= CURRENT_DATE - INTERVAL '1 day' * days_back
    ),
    station_stats AS (
        SELECT s.name
        FROM ride_stats_daily rsd
        JOIN stations s ON rsd.station_id = s.id
        WHERE rsd.user_id = target_user_id
            AND rsd.date >= CURRENT_DATE - INTERVAL '1 day' * days_back
        GROUP BY s.name
        ORDER BY COUNT(*) DESC, SUM(rsd.distance_km) DESC
        LIMIT 1
    )
    SELECT 
        s.total_days,
        s.total_distance_km,
        s.total_elevation_gain_m,
        s.total_runs,
        ROUND(s.avg_vmax_kmh, 1),
        s.best_day_distance_km,
        s.best_day_vmax_kmh,
        ss.name
    FROM stats s
    LEFT JOIN station_stats ss ON true;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PREMIUM FEATURES FUNCTIONS
-- ============================================================================

-- Function to check if user has active premium
CREATE OR REPLACE FUNCTION user_has_active_premium(target_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    result BOOLEAN;
BEGIN
    SELECT 
        (u.is_premium = true AND u.premium_expires_at > NOW()) OR
        EXISTS (
            SELECT 1 FROM subscriptions s 
            WHERE s.user_id = target_user_id 
                AND s.status = 'active' 
                AND s.current_period_end > NOW()
        )
    INTO result
    FROM users u
    WHERE u.id = target_user_id;
    
    RETURN COALESCE(result, false);
END;
$$ LANGUAGE plpgsql;

-- Function to get active boosts for a user at a station
CREATE OR REPLACE FUNCTION get_active_boosts_at_station(
    target_station_id UUID,
    target_time TIMESTAMPTZ DEFAULT NOW()
) RETURNS TABLE (
    user_id UUID,
    username VARCHAR,
    boost_multiplier DECIMAL,
    ends_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.username,
        b.boost_multiplier,
        b.ends_at
    FROM boosts b
    JOIN users u ON b.user_id = u.id
    WHERE b.station_id = target_station_id
        AND b.is_active = true
        AND b.starts_at <= target_time
        AND b.ends_at > target_time
    ORDER BY b.boost_multiplier DESC, b.ends_at ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- CLEANUP AND MAINTENANCE FUNCTIONS
-- ============================================================================

-- Function to clean up expired data
CREATE OR REPLACE FUNCTION cleanup_expired_data()
RETURNS INTEGER AS $$
DECLARE
    rows_affected INTEGER := 0;
    temp_count INTEGER;
BEGIN
    -- Mark expired premium users
    UPDATE users 
    SET is_premium = false 
    WHERE is_premium = true 
        AND premium_expires_at < NOW();
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    rows_affected := rows_affected + temp_count;
    
    -- Deactivate old user station statuses
    UPDATE user_station_status 
    SET is_active = false 
    WHERE is_active = true 
        AND date_to < CURRENT_DATE - INTERVAL '7 days';
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    rows_affected := rows_affected + temp_count;
    
    -- Deactivate expired boosts
    UPDATE boosts 
    SET is_active = false 
    WHERE is_active = true 
        AND ends_at < NOW();
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    rows_affected := rows_affected + temp_count;
    
    RETURN rows_affected;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View for active users with current location
-- ✅ Idempotent : remplace la vue si elle existe déjà
DROP VIEW IF EXISTS active_users_with_location;
CREATE VIEW active_users_with_location AS
SELECT 
    u.id,
    u.username,
    u.level,
    u.ride_styles,
    u.languages,
    u.is_premium,
    u.last_active_at,
    s.name as current_station,
    s.country_code,
    uss.date_from,
    uss.date_to,
    uss.radius_km
FROM users u
JOIN user_station_status uss ON u.id = uss.user_id
JOIN stations s ON uss.station_id = s.id
WHERE u.is_active = true
    AND u.is_banned = false
    AND uss.is_active = true
    AND uss.date_from <= CURRENT_DATE + INTERVAL '7 days'
    AND uss.date_to >= CURRENT_DATE;

-- View for recent matches with user info
-- ✅ Idempotent : remplace la vue si elle existe déjà
DROP VIEW IF EXISTS recent_matches_with_users;
CREATE VIEW recent_matches_with_users AS
SELECT 
    m.id as match_id,
    m.created_at as matched_at,
    u1.id as user1_id,
    u1.username as user1_username,
    u1.level as user1_level,
    u2.id as user2_id,
    u2.username as user2_username,
    u2.level as user2_level,
    s.name as matched_at_station,
    s.country_code as station_country,
    -- Last message info
    last_msg.content as last_message,
    last_msg.created_at as last_message_at,
    last_msg.sender_id as last_message_sender_id
FROM matches m
JOIN users u1 ON m.user1_id = u1.id
JOIN users u2 ON m.user2_id = u2.id
LEFT JOIN stations s ON m.matched_at_station_id = s.id
LEFT JOIN LATERAL (
    SELECT content, created_at, sender_id
    FROM messages msg
    WHERE msg.match_id = m.id
    ORDER BY msg.created_at DESC
    LIMIT 1
) last_msg ON true
WHERE m.is_active = true
ORDER BY COALESCE(last_msg.created_at, m.created_at) DESC;

-- ============================================================================
-- COMPLETION
-- ============================================================================

-- Create some initial matches from existing test data
INSERT INTO matches (user1_id, user2_id, created_at)
SELECT 
    LEAST(l1.liker_id, l1.liked_id) as user1_id,
    GREATEST(l1.liker_id, l1.liked_id) as user2_id,
    GREATEST(l1.created_at, l2.created_at) as created_at
FROM likes l1
JOIN likes l2 ON l1.liker_id = l2.liked_id AND l1.liked_id = l2.liker_id
WHERE NOT EXISTS (
    SELECT 1 FROM matches m
    WHERE m.user1_id = LEAST(l1.liker_id, l1.liked_id)
        AND m.user2_id = GREATEST(l1.liker_id, l1.liked_id)
)
ON CONFLICT DO NOTHING;

DO $$
BEGIN
    RAISE NOTICE 'Utility functions created successfully!';
    RAISE NOTICE 'Available functions: matching, geospatial queries, user stats, premium checks';
    RAISE NOTICE 'Views created: active_users_with_location, recent_matches_with_users';
END $$;
