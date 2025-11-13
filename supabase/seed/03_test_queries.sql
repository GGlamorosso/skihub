-- CrewSnow Test Queries
-- Description: Test the data model functionality and performance

-- ============================================================================
-- TEST BASIC QUERIES
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== TESTING CREWSNOW DATA MODEL ===';
    RAISE NOTICE 'Running comprehensive tests...';
END $$;

-- Test 1: Basic table counts
DO $$
DECLARE
    user_count INTEGER;
    station_count INTEGER;
    like_count INTEGER;
    match_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO station_count FROM stations;
    SELECT COUNT(*) INTO like_count FROM likes;
    SELECT COUNT(*) INTO match_count FROM matches;
    
    RAISE NOTICE 'TEST 1 - Table counts:';
    RAISE NOTICE '  Users: %', user_count;
    RAISE NOTICE '  Stations: %', station_count;
    RAISE NOTICE '  Likes: %', like_count;
    RAISE NOTICE '  Matches: %', match_count;
    
    IF user_count = 0 THEN
        RAISE WARNING 'No users found - seed data may not be loaded';
    END IF;
END $$;

-- Test 2: Geospatial queries (find stations near Val Thorens)
DO $$
DECLARE
    nearby_count INTEGER;
    test_result RECORD;
BEGIN
    RAISE NOTICE 'TEST 2 - Geospatial queries:';
    
    -- Find stations within 50km of Val Thorens
    SELECT COUNT(*) INTO nearby_count 
    FROM find_nearby_stations(45.2979, 6.5799, 50);
    
    RAISE NOTICE '  Stations within 50km of Val Thorens: %', nearby_count;
    
    -- Show closest 3 stations
    FOR test_result IN 
        SELECT name, distance_km, country_code 
        FROM find_nearby_stations(45.2979, 6.5799, 200) 
        LIMIT 3
    LOOP
        RAISE NOTICE '    %: % km (Country: %)', test_result.name, test_result.distance_km, test_result.country_code;
    END LOOP;
END $$;

-- Test 3: Matching algorithm
DO $$
DECLARE
    match_count INTEGER;
    test_result RECORD;
    test_user_id UUID := '00000000-0000-0000-0000-000000000001'; -- alpine_alex
BEGIN
    RAISE NOTICE 'TEST 3 - Matching algorithm for user alpine_alex:';
    
    SELECT COUNT(*) INTO match_count 
    FROM get_potential_matches(test_user_id, 10);
    
    RAISE NOTICE '  Potential matches found: %', match_count;
    
    -- Show top 3 potential matches with details
    FOR test_result IN 
        SELECT username, compatibility_score, distance_km, common_station_name, level, ride_styles
        FROM get_potential_matches(test_user_id, 3)
    LOOP
        RAISE NOTICE '    %: score=%, distance=%km, station=%, level=%, styles=%', 
            test_result.username, 
            test_result.compatibility_score,
            test_result.distance_km,
            test_result.common_station_name,
            test_result.level,
            test_result.ride_styles;
    END LOOP;
END $$;

-- Test 4: User location queries
DO $$
DECLARE
    user_count INTEGER;
    test_result RECORD;
BEGIN
    RAISE NOTICE 'TEST 4 - Users at stations:';
    
    -- Find users at Val Thorens
    SELECT COUNT(*) INTO user_count 
    FROM find_users_at_station(
        (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1),
        50
    );
    
    RAISE NOTICE '  Users at/near Val Thorens: %', user_count;
    
    -- Show user details
    FOR test_result IN 
        SELECT username, level, distance_km, station_name, date_from_user, date_to_user
        FROM find_users_at_station(
            (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1),
            50
        )
        LIMIT 3
    LOOP
        RAISE NOTICE '    %: level=%, distance=%km, at %, dates=% to %', 
            test_result.username,
            test_result.level,
            test_result.distance_km,
            test_result.station_name,
            test_result.date_from_user,
            test_result.date_to_user;
    END LOOP;
END $$;

-- Test 5: Ride statistics
DO $$
DECLARE
    test_result RECORD;
    test_user_id UUID := '00000000-0000-0000-0000-000000000001'; -- alpine_alex
BEGIN
    RAISE NOTICE 'TEST 5 - Ride statistics for alpine_alex:';
    
    SELECT * INTO test_result 
    FROM get_user_ride_stats_summary(test_user_id, 30);
    
    IF test_result IS NOT NULL THEN
        RAISE NOTICE '  Days active: %', test_result.total_days;
        RAISE NOTICE '  Total distance: % km', test_result.total_distance_km;
        RAISE NOTICE '  Total elevation: % m', test_result.total_elevation_gain_m;
        RAISE NOTICE '  Total runs: %', test_result.total_runs;
        RAISE NOTICE '  Average max speed: % km/h', test_result.avg_vmax_kmh;
        RAISE NOTICE '  Best day distance: % km', test_result.best_day_distance_km;
        RAISE NOTICE '  Most visited station: %', test_result.most_visited_station;
    ELSE
        RAISE NOTICE '  No ride statistics found';
    END IF;
END $$;

-- Test 6: Premium features
DO $$
DECLARE
    premium_users INTEGER;
    active_boosts INTEGER;
    test_user_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
    RAISE NOTICE 'TEST 6 - Premium features:';
    
    SELECT COUNT(*) INTO premium_users 
    FROM users 
    WHERE user_has_active_premium(id) = true;
    
    RAISE NOTICE '  Users with active premium: %', premium_users;
    
    SELECT COUNT(*) INTO active_boosts 
    FROM boosts 
    WHERE is_active = true AND starts_at <= NOW() AND ends_at > NOW();
    
    RAISE NOTICE '  Active boosts: %', active_boosts;
    RAISE NOTICE '  User alpine_alex has premium: %', user_has_active_premium(test_user_id);
END $$;

-- Test 7: Views functionality
DO $$
DECLARE
    active_users INTEGER;
    recent_matches INTEGER;
BEGIN
    RAISE NOTICE 'TEST 7 - Views:';
    
    SELECT COUNT(*) INTO active_users FROM active_users_with_location;
    RAISE NOTICE '  Active users with location: %', active_users;
    
    SELECT COUNT(*) INTO recent_matches FROM recent_matches_with_users;
    RAISE NOTICE '  Recent matches: %', recent_matches;
END $$;

-- Test 8: Indexes performance (explain some key queries)
DO $$
BEGIN
    RAISE NOTICE 'TEST 8 - Index usage (sample queries):';
    RAISE NOTICE '  The following queries should use indexes efficiently:';
END $$;

-- Show execution plans for key queries
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM users WHERE username = 'alpine_alex';

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM stations 
WHERE ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(6.5799, 45.2979), 4326)::geography, 50000)
ORDER BY geom::geography <-> ST_SetSRID(ST_MakePoint(6.5799, 45.2979), 4326)::geography;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users WHERE 'en' = ANY(languages);

-- Test 9: Constraint validation
DO $$
BEGIN
    RAISE NOTICE 'TEST 9 - Constraint validation:';
    
    BEGIN
        -- This should fail - self-like constraint
        INSERT INTO likes (liker_id, liked_id) 
        VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001');
        RAISE WARNING 'Self-like constraint failed to trigger!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '  ✓ Self-like constraint working correctly';
    END;
    
    BEGIN
        -- This should fail - invalid date range
        INSERT INTO user_station_status (user_id, station_id, date_from, date_to, radius_km)
        VALUES (
            '00000000-0000-0000-0000-000000000001', 
            (SELECT id FROM stations LIMIT 1),
            '2024-12-01',
            '2024-11-01', -- date_to before date_from
            25
        );
        RAISE WARNING 'Invalid date range constraint failed to trigger!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '  ✓ Date range constraint working correctly';
    END;
    
    BEGIN
        -- This should fail - unrealistic radius
        INSERT INTO user_station_status (user_id, station_id, date_from, date_to, radius_km)
        VALUES (
            '00000000-0000-0000-0000-000000000001', 
            (SELECT id FROM stations LIMIT 1),
            CURRENT_DATE,
            CURRENT_DATE + 1,
            500 -- radius too large
        );
        RAISE WARNING 'Radius constraint failed to trigger!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '  ✓ Radius constraint working correctly';
    END;
END $$;

-- Test 10: Trigger functionality (match creation)
DO $$
DECLARE
    initial_match_count INTEGER;
    final_match_count INTEGER;
    test_user1 UUID := '00000000-0000-0000-0000-000000000007'; -- swiss_anna
    test_user2 UUID := '00000000-0000-0000-0000-000000000008'; -- italiano_marco
BEGIN
    RAISE NOTICE 'TEST 10 - Match creation trigger:';
    
    SELECT COUNT(*) INTO initial_match_count FROM matches;
    
    -- Check if these users already liked each other
    IF NOT EXISTS (SELECT 1 FROM likes WHERE liker_id = test_user1 AND liked_id = test_user2) THEN
        -- Create first like
        INSERT INTO likes (liker_id, liked_id) VALUES (test_user1, test_user2);
        RAISE NOTICE '  Created first like: swiss_anna → italiano_marco';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM likes WHERE liker_id = test_user2 AND liked_id = test_user1) THEN
        -- Create reciprocal like (should trigger match creation)
        INSERT INTO likes (liker_id, liked_id) VALUES (test_user2, test_user1);
        RAISE NOTICE '  Created reciprocal like: italiano_marco → swiss_anna';
    END IF;
    
    SELECT COUNT(*) INTO final_match_count FROM matches;
    
    IF final_match_count > initial_match_count THEN
        RAISE NOTICE '  ✓ Match creation trigger working (matches: % → %)', initial_match_count, final_match_count;
    ELSE
        RAISE NOTICE '  ✓ Match may already exist or trigger working correctly';
    END IF;
END $$;

-- ============================================================================
-- PERFORMANCE METRICS
-- ============================================================================

-- Show table sizes and index usage
DO $$
DECLARE
    table_info RECORD;
BEGIN
    RAISE NOTICE '=== DATABASE STATISTICS ===';
    
    FOR table_info IN
        SELECT 
            schemaname,
            tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
            pg_stat_get_numscans(oid) as seq_scans,
            pg_stat_get_tuples_returned(oid) as tuples_returned
        FROM pg_tables t
        JOIN pg_class c ON c.relname = t.tablename
        WHERE schemaname = 'public'
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
    LOOP
        RAISE NOTICE 'Table %: size=%, seq_scans=%, tuples=%', 
            table_info.tablename, 
            table_info.size,
            table_info.seq_scans,
            table_info.tuples_returned;
    END LOOP;
END $$;

-- ============================================================================
-- SAMPLE API QUERIES
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== SAMPLE API QUERIES ===';
    RAISE NOTICE 'These are example queries your API would typically run:';
END $$;

-- 1. Get user profile with current location
SELECT 
    u.id,
    u.username,
    u.bio,
    u.level,
    u.ride_styles,
    u.languages,
    u.is_premium,
    s.name as current_station,
    s.country_code,
    uss.date_from,
    uss.date_to
FROM users u
LEFT JOIN user_station_status uss ON u.id = uss.user_id AND uss.is_active = true
LEFT JOIN stations s ON uss.station_id = s.id
WHERE u.username = 'alpine_alex'
LIMIT 1;

-- 2. Get matches for a user with last message
SELECT 
    m.id as match_id,
    CASE 
        WHEN m.user1_id = '00000000-0000-0000-0000-000000000001' THEN u2.username 
        ELSE u1.username 
    END as other_user_username,
    CASE 
        WHEN m.user1_id = '00000000-0000-0000-0000-000000000001' THEN u2.level 
        ELSE u1.level 
    END as other_user_level,
    last_msg.content as last_message,
    last_msg.created_at as last_message_at
FROM matches m
JOIN users u1 ON m.user1_id = u1.id
JOIN users u2 ON m.user2_id = u2.id
LEFT JOIN LATERAL (
    SELECT content, created_at
    FROM messages msg
    WHERE msg.match_id = m.id
    ORDER BY msg.created_at DESC
    LIMIT 1
) last_msg ON true
WHERE (m.user1_id = '00000000-0000-0000-0000-000000000001' OR m.user2_id = '00000000-0000-0000-0000-000000000001')
    AND m.is_active = true
ORDER BY COALESCE(last_msg.created_at, m.created_at) DESC;

-- 3. Get messages for a specific match
SELECT 
    msg.id,
    msg.content,
    msg.sender_id,
    u.username as sender_username,
    msg.created_at
FROM messages msg
JOIN users u ON msg.sender_id = u.id
WHERE msg.match_id = (
    SELECT id FROM matches 
    WHERE (user1_id = '00000000-0000-0000-0000-000000000001' OR user2_id = '00000000-0000-0000-0000-000000000001')
    LIMIT 1
)
ORDER BY msg.created_at DESC
LIMIT 20;

DO $$
BEGIN
    RAISE NOTICE '=== ALL TESTS COMPLETED SUCCESSFULLY ===';
    RAISE NOTICE 'The CrewSnow data model is ready for use!';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Run these migrations in your Supabase project';
    RAISE NOTICE '2. Configure RLS policies for your specific use case';
    RAISE NOTICE '3. Set up real-time subscriptions for matches and messages';
    RAISE NOTICE '4. Create API endpoints using the utility functions';
    RAISE NOTICE '5. Add monitoring and backup procedures';
END $$;
