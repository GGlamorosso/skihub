-- CrewSnow Feature Flags & Production Readiness - Week 10 Day 5

-- ============================================================================
-- 1. FEATURE FLAGS selon spécifications
-- ============================================================================

-- Table feature_flags selon spécifications
CREATE TABLE IF NOT EXISTS feature_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flag_key VARCHAR(100) NOT NULL UNIQUE,
    flag_name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Flag configuration
    is_enabled BOOLEAN NOT NULL DEFAULT false,
    rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage BETWEEN 0 AND 100),
    
    -- Targeting
    target_user_ids UUID[] DEFAULT '{}',
    target_premium_only BOOLEAN DEFAULT false,
    target_regions TEXT[] DEFAULT '{}',
    
    -- Module association
    module_name VARCHAR(100), -- 'tracker_pro', 'boost_station', 'multi_station_pass'
    feature_category VARCHAR(50), -- 'core', 'premium', 'experimental'
    
    -- Metadata
    created_by VARCHAR(100) DEFAULT 'system',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_checked_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT feature_flags_category_valid CHECK (feature_category IN ('core', 'premium', 'experimental', 'beta')),
    CONSTRAINT feature_flags_module_valid CHECK (module_name IN (
        'tracker_pro', 'boost_station', 'multi_station_pass', 'ai_moderation', 
        'collaborative_filtering', 'advanced_matching', 'real_time_chat',
        'premium_features', 'analytics_enhanced'
    ))
);

CREATE INDEX IF NOT EXISTS idx_feature_flags_enabled ON feature_flags (is_enabled, rollout_percentage);
CREATE INDEX IF NOT EXISTS idx_feature_flags_module ON feature_flags (module_name, is_enabled);
CREATE INDEX IF NOT EXISTS idx_feature_flags_category ON feature_flags (feature_category, is_enabled);

-- Initialiser feature flags selon spécifications
INSERT INTO feature_flags (flag_key, flag_name, description, is_enabled, module_name, feature_category) VALUES

-- Core features (activées par défaut)
('user_registration', 'User Registration', 'Allow new user signups', true, 'core', 'core'),
('photo_upload', 'Photo Upload', 'Allow profile photo uploads', true, 'core', 'core'),
('basic_matching', 'Basic Matching', 'Core matching algorithm', true, 'core', 'core'),
('messaging', 'Real-time Messaging', 'Chat functionality between matches', true, 'real_time_chat', 'core'),

-- Premium features (activées)
('premium_subscriptions', 'Premium Subscriptions', 'Stripe-based premium subscriptions', true, 'premium_features', 'premium'),
('unlimited_likes', 'Unlimited Likes', 'Remove daily like limits for premium users', true, 'premium_features', 'premium'),
('advanced_filters', 'Advanced Filters', 'Enhanced matching filters', true, 'advanced_matching', 'premium'),

-- Tracker features (activées progressivement) 
('tracker_pro', 'Tracker Pro', 'Advanced ski tracking with GPS and stats', false, 'tracker_pro', 'premium'),
('ride_stats_analytics', 'Ride Stats Analytics', 'Detailed ride analytics and insights', true, 'tracker_pro', 'premium'),

-- Boost features (activées)
('boost_station', 'Station Boost', 'Profile boost in specific stations', true, 'boost_station', 'premium'),
('multi_station_pass', 'Multi-Station Pass', 'Profile boost across multiple stations', true, 'multi_station_pass', 'premium'),

-- Experimental features (désactivées par défaut)
('ai_moderation_auto', 'AI Auto-Moderation', 'Fully automated AI photo moderation', false, 'ai_moderation', 'experimental'),
('collaborative_filtering_v2', 'Collaborative Filtering v2', 'ML-based recommendation system', false, 'collaborative_filtering', 'experimental'),
('voice_messages', 'Voice Messages', 'Voice message support in chat', false, 'real_time_chat', 'beta'),
('group_matching', 'Group Matching', 'Match groups of friends together', false, 'advanced_matching', 'beta'),

-- Analytics features (activées)
('analytics_enhanced', 'Enhanced Analytics', 'PostHog integration with advanced funnels', true, 'analytics_enhanced', 'core'),
('performance_monitoring', 'Performance Monitoring', 'Real-time performance and health monitoring', true, 'analytics_enhanced', 'core')

ON CONFLICT (flag_key) DO UPDATE SET 
    updated_at = NOW(),
    description = EXCLUDED.description;

-- ============================================================================
-- FONCTIONS FEATURE FLAGS
-- ============================================================================

-- Vérifier si feature activée pour utilisateur
CREATE OR REPLACE FUNCTION is_feature_enabled_for_user(
    p_flag_key VARCHAR(100),
    p_user_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    flag_config RECORD;
    user_data RECORD;
    random_percentage INTEGER;
BEGIN
    -- Récupérer configuration flag
    SELECT * INTO flag_config FROM feature_flags WHERE flag_key = p_flag_key;
    
    IF flag_config IS NULL OR NOT flag_config.is_enabled THEN
        RETURN false;
    END IF;
    
    -- Si pas de rollout progressif → activée
    IF flag_config.rollout_percentage = 100 THEN
        RETURN true;
    END IF;
    
    -- Si utilisateur spécifique dans target_user_ids
    IF p_user_id IS NOT NULL AND p_user_id = ANY(flag_config.target_user_ids) THEN
        RETURN true;
    END IF;
    
    -- Si premium uniquement et user pas premium
    IF flag_config.target_premium_only AND p_user_id IS NOT NULL THEN
        SELECT is_premium INTO user_data FROM users WHERE id = p_user_id;
        IF NOT user_data.is_premium THEN
            RETURN false;
        END IF;
    END IF;
    
    -- Rollout progressif basé sur user_id hash
    IF p_user_id IS NOT NULL AND flag_config.rollout_percentage > 0 THEN
        random_percentage := ABS(hashtext(p_user_id::text)) % 100;
        RETURN random_percentage < flag_config.rollout_percentage;
    END IF;
    
    RETURN flag_config.rollout_percentage = 100;
END;
$$ LANGUAGE plpgsql;

-- Fonction mise à jour feature flag  
CREATE OR REPLACE FUNCTION update_feature_flag(
    p_flag_key VARCHAR(100),
    p_is_enabled BOOLEAN DEFAULT NULL,
    p_rollout_percentage INTEGER DEFAULT NULL,
    p_updated_by VARCHAR(100) DEFAULT 'system'
) RETURNS BOOLEAN AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE feature_flags 
    SET 
        is_enabled = COALESCE(p_is_enabled, is_enabled),
        rollout_percentage = COALESCE(p_rollout_percentage, rollout_percentage),
        updated_at = NOW(),
        last_checked_at = NOW()
    WHERE flag_key = p_flag_key;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Log changement
    IF updated_count > 0 THEN
        PERFORM log_system_event(
            'feature_flag_updated',
            NULL,
            jsonb_build_object(
                'flag_key', p_flag_key,
                'enabled', p_is_enabled,
                'rollout_pct', p_rollout_percentage,
                'updated_by', p_updated_by
            )
        );
    END IF;
    
    RETURN updated_count > 0;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GO/NO-GO DECISION FRAMEWORK selon spécifications
-- ============================================================================

-- Fonction Go/No-Go selon spécifications
CREATE OR REPLACE FUNCTION make_go_no_go_decision()
RETURNS TABLE (
    decision VARCHAR(20),
    readiness_score INTEGER,
    critical_blockers INTEGER,
    warnings INTEGER,
    go_criteria_met BOOLEAN,
    next_actions TEXT[],
    deployment_recommendation TEXT
) AS $$
DECLARE
    tests_e2e_ok BOOLEAN;
    rls_security_ok BOOLEAN;
    payments_test_ok BOOLEAN;
    monitoring_ok BOOLEAN;
    
    score INTEGER := 0;
    blockers INTEGER := 0;
    warns INTEGER := 0;
BEGIN
    -- Critère 1: Tests E2E OK selon spécifications
    BEGIN
        PERFORM run_complete_e2e_scenario();
        tests_e2e_ok := true;
        score := score + 25;
    EXCEPTION
        WHEN others THEN
            tests_e2e_ok := false;
            blockers := blockers + 1;
    END;
    
    -- Critère 2: Pas de fuite données RLS selon spécifications
    BEGIN
        PERFORM run_day1_database_security_audit();
        rls_security_ok := true;
        score := score + 30;
    EXCEPTION 
        WHEN others THEN
            rls_security_ok := false;
            blockers := blockers + 1;
    END;
    
    -- Critère 3: Paiements test mode live selon spécifications
    payments_test_ok := EXISTS (
        SELECT 1 FROM subscriptions 
        WHERE status = 'active'
    );
    
    IF payments_test_ok THEN
        score := score + 25;
    ELSE
        warns := warns + 1;
    END IF;
    
    -- Critère 4: Monitoring opérationnel selon spécifications
    monitoring_ok := EXISTS (
        SELECT 1 FROM information_schema.views 
        WHERE table_name IN ('edge_functions_monitoring', 'error_rate_monitoring')
    );
    
    IF monitoring_ok THEN
        score := score + 20;
    ELSE
        warns := warns + 1;
    END IF;
    
    -- Décision finale selon spécifications
    RETURN QUERY SELECT
        CASE 
            WHEN blockers = 0 AND score >= 90 THEN 'GO'
            WHEN blockers = 0 AND score >= 70 THEN 'GO_WITH_CAUTION'
            ELSE 'NO_GO'
        END,
        score,
        blockers,
        warns,
        (blockers = 0 AND score >= 90),
        CASE 
            WHEN blockers = 0 AND score >= 90 THEN 
                ARRAY['✅ All systems ready', '🚀 Proceed with deployment', '📊 Monitor post-launch metrics']
            WHEN blockers = 0 THEN
                ARRAY['⚠️ Deploy with enhanced monitoring', '🔍 Address warnings post-launch']
            ELSE
                ARRAY['🔧 Resolve critical blockers', '🧪 Re-run validation tests', '📋 Review deployment checklist']
        END,
        CASE 
            WHEN blockers = 0 AND score >= 90 THEN 'Recommended for immediate production deployment'
            WHEN blockers = 0 THEN 'Approved with caution - monitor closely'
            ELSE 'Not ready for production - resolve issues first'
        END;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- RLS pour tables système
-- ============================================================================

-- RLS feature_flags
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "feature_flags_read_all" ON feature_flags  
FOR SELECT TO authenticated
USING (true); -- Lecture publique des flags

CREATE POLICY "feature_flags_admin_manage" ON feature_flags
FOR ALL TO authenticated
USING (
    auth.jwt() ->> 'role' = 'admin'
    OR auth.uid()::text IN (SELECT id::text FROM users WHERE email LIKE '%@crewsnow.com')
);

-- RLS event_log (lecture restreinte)
ALTER TABLE event_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "event_log_own_events" ON event_log
FOR SELECT TO authenticated  
USING (auth.uid() = user_id);

CREATE POLICY "event_log_admin_all" ON event_log
FOR ALL TO authenticated
USING (
    auth.jwt() ->> 'role' = 'admin'
    OR auth.uid()::text IN (SELECT id::text FROM users WHERE email LIKE '%@crewsnow.com')
);

-- RLS backup_log (admin uniquement)
ALTER TABLE backup_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "backup_log_admin_only" ON backup_log
FOR ALL TO authenticated
USING (
    auth.jwt() ->> 'role' = 'admin'
    OR auth.uid()::text IN (SELECT id::text FROM users WHERE email LIKE '%@crewsnow.com')
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE feature_flags IS 'Feature flag system for production deployment control and progressive rollout';
COMMENT ON FUNCTION is_feature_enabled_for_user(VARCHAR, UUID) IS 'Checks if feature flag is enabled for specific user with targeting and rollout rules';
COMMENT ON FUNCTION update_feature_flag(VARCHAR, BOOLEAN, INTEGER, VARCHAR) IS 'Updates feature flag configuration with audit logging';
COMMENT ON FUNCTION make_go_no_go_decision() IS 'Go/No-Go decision framework for production deployment based on test results';

DO $$
BEGIN
    RAISE NOTICE '🚀 Day 5 - Production Readiness & Feature Flags Complete!';
    RAISE NOTICE '';
    RAISE NOTICE '🎛️ Feature flags configured:';
    RAISE NOTICE '  ✅ Core features: Enabled for launch';
    RAISE NOTICE '  ✅ Premium features: Ready for paid users';
    RAISE NOTICE '  ✅ Tracker features: Progressive rollout';
    RAISE NOTICE '  ✅ Experimental features: Disabled by default';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Management functions:';
    RAISE NOTICE '  • Check flag: SELECT is_feature_enabled_for_user(''tracker_pro'', user_id);';
    RAISE NOTICE '  • Update flag: SELECT update_feature_flag(''boost_station'', true, 100);';
    RAISE NOTICE '  • Go/No-Go: SELECT * FROM make_go_no_go_decision();';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Available flags for launch control:';
    
    -- Afficher flags disponibles
    FOR rec IN SELECT flag_key, is_enabled, feature_category FROM feature_flags ORDER BY feature_category, flag_key LOOP
        RAISE NOTICE '  • %: % (%)', rec.flag_key, 
                     CASE WHEN rec.is_enabled THEN 'ENABLED' ELSE 'DISABLED' END, 
                     rec.feature_category;
    END LOOP;
END $$;
