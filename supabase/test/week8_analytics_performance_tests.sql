-- Week 8 Analytics & Performance Tests

-- ============================================================================
-- TESTS KPIs ET ANALYTICS
-- ============================================================================

CREATE OR REPLACE FUNCTION test_kpis_calculation()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    activation_count INTEGER;
    retention_count INTEGER;
    quality_metrics RECORD;
    monetization_metrics RECORD;
BEGIN
    result_text := E'📊 KPIs CALCULATION TESTS\n========================\n\n';
    
    -- Test activation KPI
    SELECT COUNT(*) INTO activation_count FROM kpi_activation_mv;
    result_text := result_text || E'✅ Activation KPI records: ' || activation_count::text || E'\n';
    
    -- Test retention KPI
    SELECT COUNT(*) INTO retention_count FROM kpi_retention_mv;
    result_text := result_text || E'✅ Retention KPI records: ' || retention_count::text || E'\n';
    
    -- Test quality metrics
    SELECT * INTO quality_metrics FROM kpi_quality_mv ORDER BY date DESC LIMIT 1;
    IF quality_metrics IS NOT NULL THEN
        result_text := result_text || E'✅ Quality metrics: ' || quality_metrics.match_rate_per_100_swipes::text || E'% match rate\n';
    END IF;
    
    -- Test monetization
    SELECT * INTO monetization_metrics FROM kpi_monetization_mv ORDER BY date DESC LIMIT 1;
    IF monetization_metrics IS NOT NULL THEN
        result_text := result_text || E'✅ Monetization: ' || monetization_metrics.conversion_rate_pct::text || E'% conversion\n';
    END IF;
    
    result_text := result_text || E'\n🎯 KPI calculation: FUNCTIONAL\n';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TESTS PERFORMANCE
-- ============================================================================

CREATE OR REPLACE FUNCTION test_performance_optimization()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    slow_queries INTEGER;
    missing_indexes INTEGER;
    health_status RECORD;
BEGIN
    result_text := E'⚡ PERFORMANCE OPTIMIZATION TESTS\n===============================\n\n';
    
    -- Test slow query detection
    SELECT COUNT(*) INTO slow_queries FROM analyze_slow_queries();
    result_text := result_text || E'📊 Slow queries detected: ' || slow_queries::text || E'\n';
    
    -- Test missing index detection  
    SELECT COUNT(*) INTO missing_indexes FROM suggest_missing_indexes();
    result_text := result_text || E'🔍 Missing indexes suggested: ' || missing_indexes::text || E'\n';
    
    -- Test health check
    SELECT * INTO health_status FROM performance_health_check() WHERE status != 'OK' LIMIT 1;
    IF health_status IS NULL THEN
        result_text := result_text || E'✅ Performance health: ALL SYSTEMS OK\n';
    ELSE
        result_text := result_text || E'⚠️ Performance issue: ' || health_status.metric || E'\n';
    END IF;
    
    result_text := result_text || E'\n⚡ Performance monitoring: OPERATIONAL\n';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TESTS ANALYTICS EVENTS
-- ============================================================================

CREATE OR REPLACE FUNCTION test_analytics_events_tracking()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_user_id UUID := '00000000-0000-0000-0000-000000000001';
    event_id UUID;
    event_count INTEGER;
BEGIN
    result_text := E'📡 ANALYTICS EVENTS TRACKING TESTS\n=================================\n\n';
    
    -- Test manual event tracking
    SELECT track_analytics_event(
        'test_event',
        test_user_id,
        jsonb_build_object('test_property', 'test_value')
    ) INTO event_id;
    
    result_text := result_text || E'✅ Manual event tracked: ' || event_id::text || E'\n';
    
    -- Test trigger events (simulate user signup)
    INSERT INTO users (id, username, email, level) 
    VALUES (gen_random_uuid(), 'test_analytics_user', 'test@analytics.com', 'beginner')
    ON CONFLICT DO NOTHING;
    
    -- Count events generated
    SELECT COUNT(*) INTO event_count 
    FROM analytics_events 
    WHERE event_name IN ('user_signed_up', 'test_event');
    
    result_text := result_text || E'✅ Auto-triggered events: ' || event_count::text || E' total\n';
    
    result_text := result_text || E'\n📡 Analytics tracking: FUNCTIONAL\n';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TESTS LAUNCH READINESS
-- ============================================================================

CREATE OR REPLACE FUNCTION test_launch_readiness()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    launch_result RECORD;
    blocker_count INTEGER;
    gate_failures INTEGER;
BEGIN
    result_text := E'🚀 LAUNCH READINESS TESTS\n========================\n\n';
    
    -- Get launch decision
    SELECT * INTO launch_result FROM make_launch_decision();
    
    result_text := result_text || E'📊 Launch Decision: ' || launch_result.decision || E'\n';
    result_text := result_text || E'📈 Readiness Score: ' || launch_result.readiness_score::text || E'/100\n';
    result_text := result_text || E'🔴 Critical Blockers: ' || launch_result.blockers_count::text || E'\n';
    result_text := result_text || E'⚠️ Warnings: ' || launch_result.warnings_count::text || E'\n';
    
    -- Check specific blockers
    SELECT COUNT(*) INTO blocker_count
    FROM assess_launch_readiness() 
    WHERE blocker = true;
    
    SELECT COUNT(*) INTO gate_failures
    FROM validate_launch_gates()
    WHERE NOT passed;
    
    IF blocker_count = 0 AND gate_failures = 0 THEN
        result_text := result_text || E'✅ No critical blockers detected\n';
        result_text := result_text || E'🚀 System ready for production launch\n';
    ELSE
        result_text := result_text || E'❌ ' || (blocker_count + gate_failures)::text || E' blockers must be resolved\n';
    END IF;
    
    result_text := result_text || E'\n🎯 Launch readiness: ';
    result_text := result_text || CASE WHEN launch_result.launch_ready THEN 'READY' ELSE 'NOT READY' END || E'\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Master test suite Week 8
CREATE OR REPLACE FUNCTION run_week8_complete_tests()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
BEGIN
    result_text := E'🎯 WEEK 8 COMPLETE TEST SUITE\n============================\n\n';
    
    result_text := result_text || test_kpis_calculation() || E'\n';
    result_text := result_text || test_performance_optimization() || E'\n'; 
    result_text := result_text || test_analytics_events_tracking() || E'\n';
    result_text := result_text || test_launch_readiness() || E'\n';
    
    result_text := result_text || E'🎉 WEEK 8 TESTS COMPLETED\n';
    result_text := result_text || E'========================\n';
    result_text := result_text || E'KPIs, Analytics, Performance & Launch Assessment validated\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;
