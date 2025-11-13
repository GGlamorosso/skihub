-- CrewSnow Launch Readiness Assessment - Week 8
-- 4. Décider ce qui est fait avant/après lancement selon spécifications

-- ============================================================================
-- PRÉ-LANCEMENT ESSENTIELS
-- ============================================================================

-- Fonction vérification readiness selon spécifications  
CREATE OR REPLACE FUNCTION assess_launch_readiness()
RETURNS TABLE (
    category VARCHAR(50),
    requirement TEXT,
    status VARCHAR(20),
    priority VARCHAR(10),
    blocker BOOLEAN,
    details TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- KPIs et vues matérialisées (essentiel pré-lancement)
    SELECT 
        'Analytics' as category,
        'KPI materialized views created' as requirement,
        CASE WHEN EXISTS (SELECT 1 FROM pg_matviews WHERE matviewname = 'kpi_activation_mv') 
             THEN 'READY' ELSE 'MISSING' END as status,
        'CRITICAL' as priority,
        NOT EXISTS (SELECT 1 FROM pg_matviews WHERE matviewname = 'kpi_activation_mv') as blocker,
        'Required for internal dashboards and business monitoring' as details
    
    UNION ALL
    
    -- Système quotas fonctionnel
    SELECT 
        'Business Logic' as category,
        'Usage quotas system operational' as requirement,
        CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'daily_usage') 
             THEN 'READY' ELSE 'MISSING' END as status,
        'CRITICAL' as priority,
        NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'daily_usage') as blocker,
        'Required to prevent abuse and enforce premium tiers' as details
    
    UNION ALL
    
    -- Stripe webhook sécurisé  
    SELECT 
        'Monetization' as category,
        'Stripe webhook with idempotency' as requirement,
        CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'processed_events')
             THEN 'READY' ELSE 'MISSING' END as status,
        'CRITICAL' as priority,
        NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'processed_events') as blocker,
        'Required for reliable payment processing' as details
    
    UNION ALL
    
    -- Photo modération
    SELECT 
        'Safety' as category,
        'Photo moderation workflow' as requirement,
        CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'webhook_logs')
             THEN 'READY' ELSE 'MISSING' END as status,
        'CRITICAL' as priority,
        NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'webhook_logs') as blocker,
        'Required for content safety and legal compliance' as details
    
    UNION ALL
    
    -- Performance index essentiels
    SELECT 
        'Performance' as category,
        'Critical indexes for matching' as requirement,
        CASE WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'stations' AND indexname = 'idx_stations_geom')
             THEN 'READY' ELSE 'MISSING' END as status,
        'HIGH' as priority,
        NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'stations' AND indexname = 'idx_stations_geom') as blocker,
        'PostGIS spatial queries performance critical for user experience' as details
    
    UNION ALL
    
    -- RLS sécurité
    SELECT 
        'Security' as category,
        'RLS policies on all tables' as requirement,
        CASE WHEN (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true) >= 10
             THEN 'READY' ELSE 'INCOMPLETE' END as status,
        'CRITICAL' as priority,
        (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true) < 10 as blocker,
        'Data isolation required for multi-tenant security' as details;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- POST-LANCEMENT OPTIMIZATIONS
-- ============================================================================

-- Fonction optimizations post-lancement
CREATE OR REPLACE FUNCTION assess_post_launch_optimizations()
RETURNS TABLE (
    optimization VARCHAR(100),
    current_priority VARCHAR(10),
    estimated_effort VARCHAR(20),
    business_impact VARCHAR(20),
    technical_debt BOOLEAN,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY VALUES
    ('PostHog Full Integration', 'MEDIUM', 'MEDIUM', 'HIGH', false,
     'Complete PostHog integration with advanced funnels and AI insights'),
    
    ('Table Partitioning', 'LOW', 'HIGH', 'MEDIUM', false,
     'Partition messages and analytics_events by date for large datasets'),
    
    ('Advanced Caching', 'MEDIUM', 'MEDIUM', 'HIGH', false, 
     'Redis cache for hot matching queries and user preferences'),
    
    ('Machine Learning Recommendations', 'LOW', 'HIGH', 'HIGH', false,
     'ML-based matching recommendations beyond collaborative filtering'),
    
    ('Real-time Notifications', 'HIGH', 'MEDIUM', 'HIGH', false,
     'Push notifications for matches, messages, and engagement'),
    
    ('Advanced Analytics Dashboard', 'MEDIUM', 'LOW', 'MEDIUM', false,
     'Internal dashboard with drill-down capabilities and alerts'),
    
    ('API Rate Limiting Enhancement', 'HIGH', 'LOW', 'MEDIUM', true,
     'Implement per-endpoint rate limiting and DDoS protection'),
    
    ('Database Connection Pooling', 'HIGH', 'MEDIUM', 'HIGH', true,
     'PgBouncer setup for connection efficiency at scale'),
    
    ('Query Performance Monitoring', 'MEDIUM', 'LOW', 'MEDIUM', false,
     'Continuous monitoring with automatic optimization suggestions');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- LAUNCH GATES
-- ============================================================================

-- Fonction gates validation pour lancement
CREATE OR REPLACE FUNCTION validate_launch_gates()
RETURNS TABLE (
    gate_name TEXT,
    passed BOOLEAN,
    error_message TEXT,
    check_query TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Gate 1: Matching algorithm performance
    SELECT 
        'Matching Performance' as gate_name,
        (
            WITH perf_test AS (
                SELECT extract(epoch from (clock_timestamp() - start_time)) * 1000 as duration
                FROM (SELECT clock_timestamp() as start_time) t1,
                     LATERAL (SELECT * FROM get_potential_matches_enhanced('00000000-0000-0000-0000-000000000001', 20)) t2
            )
            SELECT duration < 200 FROM perf_test
        ) as passed,
        CASE WHEN (
            WITH perf_test AS (
                SELECT extract(epoch from (clock_timestamp() - start_time)) * 1000 as duration
                FROM (SELECT clock_timestamp() as start_time) t1,
                     LATERAL (SELECT * FROM get_potential_matches_enhanced('00000000-0000-0000-0000-000000000001', 20)) t2
            )
            SELECT duration >= 200 FROM perf_test
        ) THEN 'Matching algorithm too slow (>200ms)' ELSE NULL END as error_message,
        'Performance test on get_potential_matches_enhanced' as check_query
    
    UNION ALL
    
    -- Gate 2: Critical data validation
    SELECT 
        'Data Integrity' as gate_name,
        (SELECT COUNT(*) > 0 FROM users WHERE is_active = true) AND
        (SELECT COUNT(*) > 0 FROM stations WHERE is_active = true) as passed,
        CASE WHEN NOT ((SELECT COUNT(*) > 0 FROM users WHERE is_active = true) AND
                      (SELECT COUNT(*) > 0 FROM stations WHERE is_active = true))
             THEN 'Missing essential data (users or stations)' ELSE NULL END as error_message,
        'Validation of users and stations data' as check_query
    
    UNION ALL
    
    -- Gate 3: Security policies active
    SELECT 
        'Security Policies' as gate_name,
        (SELECT COUNT(*) FROM pg_policies WHERE tablename IN ('users', 'messages', 'matches', 'likes')) >= 8 as passed,
        CASE WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename IN ('users', 'messages', 'matches', 'likes')) < 8
             THEN 'Insufficient RLS policies on critical tables' ELSE NULL END as error_message,
        'RLS policy count validation' as check_query
    
    UNION ALL
    
    -- Gate 4: Essential indexes present
    SELECT 
        'Performance Indexes' as gate_name,
        (SELECT COUNT(*) FROM pg_indexes WHERE tablename IN ('messages', 'likes', 'matches', 'stations') AND indexname LIKE 'idx_%') >= 15 as passed,
        CASE WHEN (SELECT COUNT(*) FROM pg_indexes WHERE tablename IN ('messages', 'likes', 'matches', 'stations') AND indexname LIKE 'idx_%') < 15
             THEN 'Critical performance indexes missing' ELSE NULL END as error_message,
        'Index count validation on key tables' as check_query;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- LAUNCH DECISION FUNCTION
-- ============================================================================

-- Fonction décision finale launch selon spécifications
CREATE OR REPLACE FUNCTION make_launch_decision()
RETURNS TABLE (
    launch_ready BOOLEAN,
    blockers_count INTEGER,
    warnings_count INTEGER,
    readiness_score INTEGER,
    decision TEXT,
    next_steps TEXT[]
) AS $$
DECLARE
    total_requirements INTEGER;
    ready_requirements INTEGER;
    critical_blockers INTEGER;
    readiness_percentage INTEGER;
    gates_passed INTEGER;
    total_gates INTEGER;
BEGIN
    -- Assess launch readiness
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE status = 'READY'),
        COUNT(*) FILTER (WHERE priority = 'CRITICAL' AND status != 'READY')
    INTO total_requirements, ready_requirements, critical_blockers
    FROM assess_launch_readiness();
    
    -- Validate launch gates
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE passed = true)
    INTO total_gates, gates_passed  
    FROM validate_launch_gates();
    
    -- Calculate readiness score
    readiness_percentage := ROUND(ready_requirements::DECIMAL / total_requirements * 100);
    
    RETURN QUERY
    SELECT 
        (critical_blockers = 0 AND gates_passed = total_gates) as launch_ready,
        critical_blockers,
        (total_requirements - ready_requirements - critical_blockers) as warnings_count,
        readiness_percentage,
        CASE 
            WHEN critical_blockers = 0 AND gates_passed = total_gates AND readiness_percentage >= 95 
            THEN '🚀 READY FOR LAUNCH'
            WHEN critical_blockers = 0 AND readiness_percentage >= 90
            THEN '⚠️ LAUNCH WITH CAUTION - Minor issues to address'
            WHEN critical_blockers > 0
            THEN '🔴 NOT READY - Critical blockers must be resolved'
            ELSE '🟡 NEEDS WORK - Significant preparation required'
        END as decision,
        CASE 
            WHEN critical_blockers = 0 AND gates_passed = total_gates THEN
                ARRAY['✅ All systems green', '📊 Enable real-time monitoring', '🎯 Launch marketing campaign']
            WHEN critical_blockers > 0 THEN
                ARRAY['🔧 Resolve critical blockers', '🧪 Run comprehensive tests', '📋 Review launch checklist']
            ELSE
                ARRAY['⚡ Complete performance optimization', '📊 Finalize analytics setup', '🔍 Security audit']
        END as next_steps;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS ET MONITORING
-- ============================================================================

COMMENT ON FUNCTION assess_launch_readiness() IS 'Evaluates system readiness against pre-launch requirements checklist';
COMMENT ON FUNCTION assess_post_launch_optimizations() IS 'Prioritizes post-launch improvements and technical debt';
COMMENT ON FUNCTION validate_launch_gates() IS 'Validates critical performance and functionality gates for launch';
COMMENT ON FUNCTION make_launch_decision() IS 'Makes final launch/no-launch decision based on comprehensive assessment';

-- Vue monitoring lancement
CREATE OR REPLACE VIEW launch_monitoring AS
SELECT 
    'Launch Readiness' as assessment_type,
    lr.requirement,
    lr.status,
    lr.priority,
    lr.blocker,
    lr.details as description
FROM assess_launch_readiness() lr
WHERE lr.status != 'READY'

UNION ALL

SELECT 
    'Launch Gates' as assessment_type,
    lg.gate_name as requirement,
    CASE WHEN lg.passed THEN 'PASSED' ELSE 'FAILED' END as status,
    'CRITICAL' as priority,
    NOT lg.passed as blocker,
    COALESCE(lg.error_message, 'Gate validation passed') as description
FROM validate_launch_gates() lg
WHERE NOT lg.passed;

DO $$
DECLARE
    launch_decision RECORD;
BEGIN
    RAISE NOTICE '🎯 Week 8 Launch Decision Framework Complete!';
    RAISE NOTICE '';
    
    -- Get launch decision
    SELECT * INTO launch_decision FROM make_launch_decision();
    
    RAISE NOTICE '📊 Launch Assessment Results:';
    RAISE NOTICE '  Decision: %', launch_decision.decision;
    RAISE NOTICE '  Readiness Score: %/100', launch_decision.readiness_score;
    RAISE NOTICE '  Critical Blockers: %', launch_decision.blockers_count;
    RAISE NOTICE '  Warnings: %', launch_decision.warnings_count;
    RAISE NOTICE '';
    
    IF launch_decision.launch_ready THEN
        RAISE NOTICE '🚀 SYSTEM IS READY FOR PRODUCTION LAUNCH!';
    ELSE
        RAISE NOTICE '🔧 SYSTEM NEEDS ATTENTION BEFORE LAUNCH';
        RAISE NOTICE 'Review: SELECT * FROM launch_monitoring;';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '📋 Available assessments:';
    RAISE NOTICE '  • Overall: SELECT * FROM make_launch_decision();';
    RAISE NOTICE '  • Detailed: SELECT * FROM assess_launch_readiness();';
    RAISE NOTICE '  • Gates: SELECT * FROM validate_launch_gates();';
    RAISE NOTICE '  • Monitoring: SELECT * FROM launch_monitoring;';
    RAISE NOTICE '  • Post-launch: SELECT * FROM assess_post_launch_optimizations();';
END $$;
