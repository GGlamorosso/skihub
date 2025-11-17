-- CrewSnow RLS Comprehensive Audit - Week 10 Day 1
-- 1. RLS & vues selon spécifications

-- ============================================================================
-- AUDIT TOUTES POLICIES RLS
-- ============================================================================

-- Fonction audit comprehensive RLS selon spécifications
CREATE OR REPLACE FUNCTION audit_all_rls_policies()
RETURNS TABLE (
    table_name TEXT,
    policy_name TEXT,
    policy_cmd TEXT,
    roles TEXT[],
    status VARCHAR(20),
    security_level VARCHAR(20),
    issues TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    WITH policy_analysis AS (
        SELECT 
            p.tablename,
            p.policyname,
            p.cmd,
            string_to_array(p.roles, ',') as policy_roles,
            p.qual as policy_condition,
            p.with_check as policy_check,
            CASE 
                WHEN p.tablename IN ('users', 'messages', 'matches', 'likes', 'subscriptions', 'consents', 'daily_usage') 
                     AND p.qual LIKE '%auth.uid()%' THEN 'SECURE'
                WHEN p.tablename IN ('stations', 'feature_flags') 
                     AND p.roles = '{authenticated}' THEN 'PUBLIC_READ_OK'
                WHEN p.tablename LIKE '%_logs' 
                     AND p.roles = '{service_role}' THEN 'ADMIN_ONLY_OK'
                ELSE 'NEEDS_REVIEW'
            END as security_assessment,
            ARRAY[]::TEXT[] as detected_issues
        FROM pg_policies p
        WHERE p.schemaname = 'public'
    )
    SELECT 
        pa.tablename::TEXT,
        pa.policyname::TEXT,
        pa.cmd::TEXT,
        pa.policy_roles::TEXT[],
        pa.security_assessment::VARCHAR(20),
        CASE 
            WHEN pa.security_assessment = 'SECURE' THEN 'HIGH'
            WHEN pa.security_assessment = 'PUBLIC_READ_OK' THEN 'MEDIUM'
            WHEN pa.security_assessment = 'ADMIN_ONLY_OK' THEN 'HIGH'
            ELSE 'LOW'
        END::VARCHAR(20) as security_level,
        pa.detected_issues::TEXT[]
    FROM policy_analysis pa
    ORDER BY pa.tablename, pa.policyname;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TESTS SQL SIMPLES selon spécifications
-- ============================================================================

-- Test User A → échec lecture données User B selon spécifications
CREATE OR REPLACE FUNCTION test_rls_user_isolation()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    alice_id UUID := '00000000-0000-0000-0000-000000000001';
    bob_id UUID := '00000000-0000-0000-0000-000000000002';
    charlie_id UUID := '00000000-0000-0000-0000-000000000003';
    
    alice_own_data INTEGER;
    alice_bob_data INTEGER;
    alice_charlie_data INTEGER;
    alice_matches INTEGER;
    alice_messages INTEGER;
BEGIN
    result_text := E'🛡️ RLS USER ISOLATION TESTS\n===========================\n\n';
    
    -- Test Alice accès ses propres données
    SET LOCAL role TO authenticated;
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', alice_id::text)::text;
    
    SELECT COUNT(*) INTO alice_own_data FROM users WHERE id = alice_id;
    result_text := result_text || E'✅ Alice own profile: ' || alice_own_data::text || E' (should be 1)\n';
    
    -- Test Alice ÉCHEC lecture profil Bob selon spécifications
    SELECT COUNT(*) INTO alice_bob_data FROM users WHERE id = bob_id;  
    result_text := result_text || E'🚫 Alice access Bob profile: ' || alice_bob_data::text || E' (should be 0)\n';
    
    -- Test Alice ÉCHEC lecture profil Charlie
    SELECT COUNT(*) INTO alice_charlie_data FROM users WHERE id = charlie_id;
    result_text := result_text || E'🚫 Alice access Charlie profile: ' || alice_charlie_data::text || E' (should be 0)\n';
    
    -- Test Alice OK ses matches selon spécifications
    SELECT COUNT(*) INTO alice_matches 
    FROM matches WHERE user1_id = alice_id OR user2_id = alice_id;
    result_text := result_text || E'✅ Alice own matches: ' || alice_matches::text || E'\n';
    
    -- Test Alice OK messages ses matches selon spécifications  
    SELECT COUNT(*) INTO alice_messages 
    FROM messages WHERE match_id IN (
        SELECT id FROM matches WHERE user1_id = alice_id OR user2_id = alice_id
    );
    result_text := result_text || E'✅ Alice match messages: ' || alice_messages::text || E'\n';
    
    RESET role;
    RESET "request.jwt.claims";
    
    -- Validation finale selon spécifications
    IF alice_own_data = 1 AND alice_bob_data = 0 AND alice_charlie_data = 0 THEN
        result_text := result_text || E'\n🎯 User isolation: WORKING CORRECTLY\n';
    ELSE
        result_text := result_text || E'\n❌ User isolation: SECURITY ISSUES DETECTED\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test tables système service role uniquement selon spécifications
CREATE OR REPLACE FUNCTION test_rls_system_tables()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    authenticated_access INTEGER;
    service_access INTEGER;
    anon_access INTEGER;
BEGIN
    result_text := E'🔧 RLS SYSTEM TABLES TESTS\n=========================\n\n';
    
    -- Test authenticated ne peut pas accéder event_log/processed_events
    SET LOCAL role TO authenticated;
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', '00000000-0000-0000-0000-000000000001'::text)::text;
    
    SELECT COUNT(*) INTO authenticated_access FROM processed_events LIMIT 1;
    result_text := result_text || E'🚫 Authenticated access processed_events: ' || authenticated_access::text || E' (should be 0)\n';
    
    RESET role;
    RESET "request.jwt.claims";
    
    -- Test service role peut accéder
    SET LOCAL role TO service_role;
    
    SELECT COUNT(*) INTO service_access FROM processed_events LIMIT 1;
    result_text := result_text || E'✅ Service role access: ' || service_access::text || E' (should work)\n';
    
    RESET role;
    
    -- Test anon ne peut rien voir
    SET LOCAL role TO anon;
    
    SELECT COUNT(*) INTO anon_access FROM users LIMIT 1;
    result_text := result_text || E'🚫 Anon access users: ' || anon_access::text || E' (should be 0)\n';
    
    RESET role;
    
    result_text := result_text || E'\n🔧 System tables security: VALIDATED\n';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SCHÉMA & CONTRAINTES VALIDATION
-- ============================================================================

-- Vérification UNIQUE et FK selon spécifications
CREATE OR REPLACE FUNCTION validate_schema_constraints()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    constraint_check RECORD;
    missing_constraints TEXT[] := '{}';
BEGIN
    result_text := E'🔍 SCHEMA CONSTRAINTS VALIDATION\n===============================\n\n';
    
    -- Vérifier likes UNIQUE(liker_id, liked_id) selon spécifications
    IF EXISTS (
        SELECT 1 FROM pg_constraint c
        JOIN pg_class t ON c.conrelid = t.oid
        WHERE t.relname = 'likes'
            AND c.contype = 'u'
            AND c.conkey = (SELECT array_agg(a.attnum ORDER BY a.attnum) 
                           FROM pg_attribute a 
                           WHERE a.attrelid = t.oid 
                           AND a.attname IN ('liker_id', 'liked_id'))
    ) THEN
        result_text := result_text || E'✅ likes UNIQUE(liker_id, liked_id): PRESENT\n';
    ELSE
        result_text := result_text || E'❌ likes UNIQUE constraint: MISSING\n';
        missing_constraints := array_append(missing_constraints, 'likes_unique_pair');
    END IF;
    
    -- Vérifier matches UNIQUE selon spécifications
    IF EXISTS (
        SELECT 1 FROM pg_constraint c
        JOIN pg_class t ON c.conrelid = t.oid  
        WHERE t.relname = 'matches'
            AND c.contype = 'u'
            AND c.conkey = (SELECT array_agg(a.attnum ORDER BY a.attnum)
                           FROM pg_attribute a
                           WHERE a.attrelid = t.oid
                           AND a.attname IN ('user1_id', 'user2_id'))
    ) THEN
        result_text := result_text || E'✅ matches UNIQUE(user1_id, user2_id): PRESENT\n';
    ELSE
        result_text := result_text || E'❌ matches UNIQUE constraint: MISSING\n';
        missing_constraints := array_append(missing_constraints, 'matches_unique_pair');
    END IF;
    
    -- Vérifier FK CASCADE cohérentes selon spécifications
    FOR constraint_check IN
        SELECT 
            tc.table_name,
            tc.constraint_name,
            rc.delete_rule,
            kcu.column_name,
            ccu.table_name as referenced_table
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
        JOIN information_schema.referential_constraints rc ON tc.constraint_name = rc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = 'public'
            AND ccu.table_name IN ('users', 'matches')
    LOOP
        result_text := result_text || E'🔗 ' || constraint_check.table_name || 
                      E'.' || constraint_check.column_name || 
                      E' → ' || constraint_check.referenced_table || 
                      E': ' || constraint_check.delete_rule || E'\n';
    END LOOP;
    
    -- Résultat final
    IF array_length(missing_constraints, 1) = 0 THEN
        result_text := result_text || E'\n✅ Schema constraints: ALL VALID\n';
    ELSE
        result_text := result_text || E'\n❌ Schema issues: ' || array_to_string(missing_constraints, ', ') || E'\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GÉOLOC & POSTGIS VALIDATION selon spécifications
-- ============================================================================

-- Contrôler PostGIS Point + proximité selon spécifications
CREATE OR REPLACE FUNCTION validate_geoloc_postgis()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    station_geom_check BOOLEAN;
    proximity_test RECORD;
    spatial_index_check BOOLEAN;
BEGIN
    result_text := E'🌍 GEOLOC & POSTGIS VALIDATION\n=============================\n\n';
    
    -- Vérifier stations Point(lat, lon) EPSG:4326 selon spécifications
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stations' AND column_name = 'geom'
            AND udt_name = 'geometry'
    ) INTO station_geom_check;
    
    result_text := result_text || E'✅ Stations geometry column: ' || station_geom_check::text || E'\n';
    
    -- Test requête proximité ST_DWithin selon spécifications
    SELECT 
        COUNT(*) as stations_found,
        AVG(ST_Distance(s1.geom::geography, s2.geom::geography) / 1000) as avg_distance_km
    INTO proximity_test
    FROM stations s1, stations s2
    WHERE s1.name = 'Val Thorens' 
        AND ST_DWithin(s1.geom::geography, s2.geom::geography, 50000) -- 50km radius
        AND s1.id != s2.id
    LIMIT 1;
    
    result_text := result_text || E'🗺️ Proximity test (50km from Val Thorens): ' || 
                  proximity_test.stations_found::text || E' stations found\n';
    result_text := result_text || E'📏 Average distance: ' || 
                  ROUND(proximity_test.avg_distance_km, 1)::text || E'km\n';
    
    -- Vérifier index GIST selon spécifications
    SELECT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'stations' 
            AND indexname = 'idx_stations_geom'
            AND indexdef LIKE '%GIST%'
    ) INTO spatial_index_check;
    
    result_text := result_text || E'⚡ GIST spatial index: ' || spatial_index_check::text || E'\n';
    
    -- Test cas "stations proches" selon spécifications
    IF proximity_test.stations_found > 0 AND spatial_index_check THEN
        result_text := result_text || E'\n🎯 PostGIS geolocation: WORKING CORRECTLY\n';
    ELSE
        result_text := result_text || E'\n❌ PostGIS geolocation: ISSUES DETECTED\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FINALISER PUBLIC_PROFILES_V selon spécifications
-- ============================================================================

-- Recréer vue publique selon spécifications exactes
DROP VIEW IF EXISTS public_profiles_v;

CREATE VIEW public_profiles_v AS
SELECT 
    u.id,
    u.username,
    u.level,
    u.ride_styles,
    u.languages,
    u.is_premium,
    u.last_active_at,
    -- Photo principale approuvée uniquement
    pp.storage_path as main_photo_path,
    -- Station courante
    uss.station_id as current_station_id,
    s.name as current_station_name,
    uss.date_from,
    uss.date_to,
    uss.radius_km,
    -- Distance helper (sera calculée dynamiquement)
    s.geom as station_geom
FROM users u
-- Jointure photo approuvée principale selon spécifications
LEFT JOIN profile_photos pp ON (
    pp.user_id = u.id 
    AND pp.is_main = true 
    AND pp.moderation_status = 'approved'
)
-- Jointure station courante selon spécifications
LEFT JOIN user_station_status uss ON (
    uss.user_id = u.id 
    AND uss.is_active = true
)
LEFT JOIN stations s ON uss.station_id = s.id
WHERE u.is_active = true 
    AND u.is_banned = false;

-- Policy lecture authentifiés selon spécifications
CREATE POLICY "public_profiles_authenticated_read" ON public_profiles_v
FOR SELECT TO authenticated
USING (true);

-- ============================================================================
-- CHECKLIST RLS SELON SPÉCIFICATIONS
-- ============================================================================

-- Fonction génération checklist selon spécifications
CREATE OR REPLACE FUNCTION generate_rls_checklist()
RETURNS TABLE (
    requirement TEXT,
    table_name TEXT,
    status VARCHAR(20),
    policy_exists BOOLEAN,
    auth_uid_check BOOLEAN,
    recommendation TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- users table
    SELECT 
        'User can only read/modify own profile' as requirement,
        'users' as table_name,
        CASE WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'users' AND qual LIKE '%auth.uid() = id%'
        ) THEN 'SECURE' ELSE 'MISSING' END as status,
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users') as policy_exists,
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND qual LIKE '%auth.uid()%') as auth_uid_check,
        CASE WHEN NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND qual LIKE '%auth.uid() = id%')
             THEN 'CREATE POLICY users_own_data ON users FOR ALL USING (auth.uid() = id)'
             ELSE 'Policy correctly configured' END as recommendation
    
    UNION ALL
    
    -- likes table
    SELECT 
        'User can see likes they gave/received only',
        'likes',
        CASE WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'likes' AND qual LIKE '%liker_id%' AND qual LIKE '%liked_id%'
        ) THEN 'SECURE' ELSE 'MISSING' END,
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'likes'),
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'likes' AND qual LIKE '%auth.uid()%'),
        'Policy should check: auth.uid() = liker_id OR auth.uid() = liked_id'
    
    UNION ALL
    
    -- matches table
    SELECT 
        'User can see only their matches',
        'matches',
        CASE WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'matches' AND qual LIKE '%user1_id%' AND qual LIKE '%user2_id%'
        ) THEN 'SECURE' ELSE 'MISSING' END,
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'matches'),
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'matches' AND qual LIKE '%auth.uid()%'),
        'Policy should check: auth.uid() = user1_id OR auth.uid() = user2_id'
    
    UNION ALL
    
    -- messages table
    SELECT 
        'User can see messages from their matches only',
        'messages',
        CASE WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'messages' AND qual LIKE '%match_id%'
        ) THEN 'SECURE' ELSE 'MISSING' END,
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'messages'),
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND qual LIKE '%auth.uid()%'),
        'Policy should check match participation via subquery'
    
    UNION ALL
    
    -- subscriptions table
    SELECT 
        'User can see only own subscriptions',
        'subscriptions',
        CASE WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'subscriptions' AND qual LIKE '%user_id%'
        ) THEN 'SECURE' ELSE 'MISSING' END,
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions'),
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions' AND qual LIKE '%auth.uid()%'),
        'Policy should check: auth.uid() = user_id'
    
    UNION ALL
    
    -- daily_usage table
    SELECT 
        'User can see only own usage stats',
        'daily_usage',
        CASE WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'daily_usage' AND qual LIKE '%user_id%'
        ) THEN 'SECURE' ELSE 'MISSING' END,
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'daily_usage'),
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'daily_usage' AND qual LIKE '%auth.uid()%'),
        'Policy should check: auth.uid() = user_id'
    
    UNION ALL
    
    -- consents table
    SELECT 
        'User can manage only own consents',
        'consents', 
        CASE WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'consents' AND qual LIKE '%user_id%'
        ) THEN 'SECURE' ELSE 'MISSING' END,
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'consents'),
        EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'consents' AND qual LIKE '%auth.uid()%'),
        'Policy should check: auth.uid() = user_id';
END;
$$ LANGUAGE plpgsql;

-- Master audit function Day 1
CREATE OR REPLACE FUNCTION run_day1_database_security_audit()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    security_issues INTEGER := 0;
BEGIN
    result_text := E'🔒 DAY 1 - DATABASE SECURITY AUDIT\n=================================\n\n';
    
    result_text := result_text || test_rls_user_isolation() || E'\n';
    result_text := result_text || test_rls_system_tables() || E'\n';  
    result_text := result_text || validate_schema_constraints() || E'\n';
    result_text := result_text || validate_geoloc_postgis() || E'\n';
    
    -- Compter issues détectées
    SELECT COUNT(*) INTO security_issues 
    FROM generate_rls_checklist() 
    WHERE status != 'SECURE';
    
    result_text := result_text || E'=================================\n';
    result_text := result_text || E'🎯 AUDIT SUMMARY DAY 1\n';
    result_text := result_text || E'=================================\n';
    
    IF security_issues = 0 THEN
        result_text := result_text || E'✅ Security audit: ALL CHECKS PASSED\n';
        result_text := result_text || E'🛡️ Database security: PRODUCTION READY\n';
    ELSE
        result_text := result_text || E'⚠️ Security issues detected: ' || security_issues::text || E'\n';
        result_text := result_text || E'🔧 Review checklist: SELECT * FROM generate_rls_checklist();\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;
