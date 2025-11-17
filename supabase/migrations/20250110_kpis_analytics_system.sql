-- CrewSnow KPIs and Analytics System - Week 8
-- 1. Définir et calculer les KPIs selon spécifications

-- ============================================================================
-- ACTIVATION KPIs
-- ============================================================================

-- Vue matérialisée activation selon spécifications
CREATE MATERIALIZED VIEW IF NOT EXISTS kpi_activation_mv AS
SELECT 
    DATE_TRUNC('day', created_at) as date,
    COUNT(*) as total_signups,
    COUNT(*) FILTER (WHERE 
        bio IS NOT NULL 
        AND level IS NOT NULL 
        AND cardinality(ride_styles) > 0 
        AND cardinality(languages) > 0
        AND EXISTS (
            SELECT 1 FROM profile_photos pp 
            WHERE pp.user_id = users.id 
            AND pp.moderation_status = 'approved'
        )
    ) as complete_profiles,
    ROUND(
        COUNT(*) FILTER (WHERE 
            bio IS NOT NULL AND level IS NOT NULL 
            AND cardinality(ride_styles) > 0 AND cardinality(languages) > 0
            AND EXISTS (SELECT 1 FROM profile_photos pp WHERE pp.user_id = users.id AND pp.moderation_status = 'approved')
        )::DECIMAL / NULLIF(COUNT(*), 0) * 100, 2
    ) as activation_rate_pct
FROM users 
WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY date DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_kpi_activation_date ON kpi_activation_mv (date);

-- ============================================================================
-- RÉTENTION KPIs
-- ============================================================================

-- Vue daily active users selon spécifications
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_active_users_mv AS
WITH user_activities AS (
    SELECT user_id, DATE(created_at) as activity_date, 'like' as activity_type FROM likes
    UNION ALL
    SELECT sender_id as user_id, DATE(created_at) as activity_date, 'message' as activity_type FROM messages
    UNION ALL  
    SELECT user_id, DATE(created_at) as activity_date, 'boost' as activity_type FROM boosts
    UNION ALL
    SELECT user_id, DATE(updated_at) as activity_date, 'profile_update' as activity_type FROM users WHERE updated_at > created_at
    UNION ALL
    SELECT user_id, DATE(updated_at) as activity_date, 'location_update' as activity_type FROM user_station_status WHERE updated_at > created_at
)
SELECT 
    activity_date as date,
    COUNT(DISTINCT user_id) as daily_active_users,
    COUNT(DISTINCT user_id) FILTER (WHERE activity_type = 'like') as daily_swipers,
    COUNT(DISTINCT user_id) FILTER (WHERE activity_type = 'message') as daily_messagers,
    COUNT(DISTINCT user_id) FILTER (WHERE activity_type = 'boost') as daily_boosters,
    COUNT(*) as total_activities
FROM user_activities 
WHERE activity_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY activity_date
ORDER BY activity_date DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_active_users_date ON daily_active_users_mv (date);

-- Vue retention par cohorte
CREATE MATERIALIZED VIEW IF NOT EXISTS kpi_retention_mv AS
WITH cohorts AS (
    SELECT 
        u.id as user_id,
        DATE_TRUNC('week', u.created_at) as cohort_week,
        u.created_at
    FROM users u
    WHERE u.created_at >= CURRENT_DATE - INTERVAL '12 weeks'
),
retention_data AS (
    SELECT 
        c.cohort_week,
        COUNT(DISTINCT c.user_id) as cohort_size,
        COUNT(DISTINCT c.user_id) FILTER (WHERE 
            EXISTS (
                SELECT 1 FROM daily_active_users_mv dau 
                WHERE dau.date >= c.cohort_week + INTERVAL '1 week'
                AND dau.date <= c.cohort_week + INTERVAL '2 weeks'
                AND c.user_id IN (
                    SELECT user_id FROM likes WHERE DATE(created_at) BETWEEN dau.date AND dau.date + INTERVAL '1 day'
                    UNION
                    SELECT sender_id FROM messages WHERE DATE(created_at) BETWEEN dau.date AND dau.date + INTERVAL '1 day'
                )
            )
        ) as week1_retained,
        COUNT(DISTINCT c.user_id) FILTER (WHERE 
            EXISTS (
                SELECT 1 FROM daily_active_users_mv dau 
                WHERE dau.date >= c.cohort_week + INTERVAL '4 weeks'
                AND dau.date <= c.cohort_week + INTERVAL '5 weeks'
                AND c.user_id IN (
                    SELECT user_id FROM likes WHERE DATE(created_at) BETWEEN dau.date AND dau.date + INTERVAL '1 day'
                    UNION
                    SELECT sender_id FROM messages WHERE DATE(created_at) BETWEEN dau.date AND dau.date + INTERVAL '1 day'
                )
            )
        ) as week4_retained
    FROM cohorts c
    GROUP BY c.cohort_week
)
SELECT 
    cohort_week,
    cohort_size,
    week1_retained,
    week4_retained,
    ROUND(week1_retained::DECIMAL / NULLIF(cohort_size, 0) * 100, 2) as week1_retention_pct,
    ROUND(week4_retained::DECIMAL / NULLIF(cohort_size, 0) * 100, 2) as week4_retention_pct
FROM retention_data
WHERE cohort_size > 0
ORDER BY cohort_week DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_kpi_retention_cohort ON kpi_retention_mv (cohort_week);

-- ============================================================================
-- QUALITÉ KPIs
-- ============================================================================

-- Vue qualité matches et conversations selon spécifications
CREATE MATERIALIZED VIEW IF NOT EXISTS kpi_quality_mv AS
WITH swipe_stats AS (
    SELECT 
        DATE(created_at) as date,
        COUNT(*) as total_swipes,
        COUNT(DISTINCT liker_id) as unique_swipers
    FROM likes 
    WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(created_at)
),
match_stats AS (
    SELECT 
        DATE(created_at) as date,
        COUNT(*) as total_matches,
        COUNT(DISTINCT user1_id) + COUNT(DISTINCT user2_id) as unique_matchers
    FROM matches
    WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(created_at)
),
conversation_stats AS (
    SELECT 
        DATE(m.created_at) as date,
        COUNT(m.id) as total_conversations,
        COUNT(m.id) FILTER (WHERE (
            SELECT COUNT(*) FROM messages msg 
            WHERE msg.match_id = m.id
        ) >= 3) as quality_conversations
    FROM matches m
    WHERE m.created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(m.created_at)
),
tracker_adoption AS (
    SELECT 
        DATE(created_at) as date,
        COUNT(DISTINCT user_id) as users_with_stats
    FROM ride_stats_daily
    WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(created_at)
)
SELECT 
    COALESCE(ss.date, ms.date, cs.date, ta.date) as date,
    COALESCE(ss.total_swipes, 0) as total_swipes,
    COALESCE(ms.total_matches, 0) as total_matches,
    COALESCE(cs.total_conversations, 0) as total_conversations,
    COALESCE(cs.quality_conversations, 0) as quality_conversations,
    COALESCE(ta.users_with_stats, 0) as users_with_ride_stats,
    -- Ratio matches/swipes selon spécifications
    ROUND(COALESCE(ms.total_matches, 0)::DECIMAL / NULLIF(ss.total_swipes, 0) * 100, 2) as match_rate_per_100_swipes,
    -- Proportion conversations > 3 messages selon spécifications  
    ROUND(COALESCE(cs.quality_conversations, 0)::DECIMAL / NULLIF(cs.total_conversations, 0) * 100, 2) as quality_conversation_rate_pct
FROM swipe_stats ss
FULL OUTER JOIN match_stats ms ON ss.date = ms.date
FULL OUTER JOIN conversation_stats cs ON COALESCE(ss.date, ms.date) = cs.date
FULL OUTER JOIN tracker_adoption ta ON COALESCE(ss.date, ms.date, cs.date) = ta.date
ORDER BY date DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_kpi_quality_date ON kpi_quality_mv (date);

-- ============================================================================
-- MONÉTISATION KPIs
-- ============================================================================

-- Vue monétisation selon spécifications
CREATE MATERIALIZED VIEW IF NOT EXISTS kpi_monetization_mv AS
WITH conversion_stats AS (
    SELECT 
        DATE_TRUNC('day', s.created_at) as date,
        COUNT(DISTINCT s.user_id) as new_premium_users,
        COUNT(DISTINCT u.id) FILTER (WHERE u.created_at >= DATE_TRUNC('day', s.created_at) - INTERVAL '30 days') as eligible_for_conversion,
        SUM(s.amount_cents) as revenue_cents,
        AVG(s.amount_cents) as avg_revenue_per_user_cents
    FROM subscriptions s
    JOIN users u ON s.user_id = u.id
    WHERE s.created_at >= CURRENT_DATE - INTERVAL '90 days'
        AND s.status IN ('active', 'trialing')
    GROUP BY DATE_TRUNC('day', s.created_at)
),
boost_revenue AS (
    SELECT 
        DATE(created_at) as date,
        COUNT(*) as boost_purchases,
        SUM(amount_paid_cents) as boost_revenue_cents,
        COUNT(DISTINCT user_id) as unique_boost_buyers
    FROM boosts
    WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(created_at)
),
user_base AS (
    SELECT 
        DATE(created_at) as date,
        COUNT(*) as new_signups,
        COUNT(*) FILTER (WHERE is_active = true) as active_signups
    FROM users
    WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE(created_at)
)
SELECT 
    COALESCE(cs.date, br.date, ub.date) as date,
    COALESCE(cs.new_premium_users, 0) as new_premium_users,
    COALESCE(br.boost_purchases, 0) as boost_purchases,
    COALESCE(cs.revenue_cents, 0) + COALESCE(br.boost_revenue_cents, 0) as total_revenue_cents,
    COALESCE(cs.avg_revenue_per_user_cents, 0) as arppu_subscription_cents,
    COALESCE(ub.new_signups, 0) as new_signups,
    -- Conversion Free→Premium selon spécifications
    ROUND(
        COALESCE(cs.new_premium_users, 0)::DECIMAL / 
        NULLIF(COALESCE(cs.eligible_for_conversion, ub.new_signups, 0), 0) * 100, 2
    ) as conversion_rate_pct,
    COALESCE(br.unique_boost_buyers, 0) as unique_boost_buyers
FROM conversion_stats cs
FULL OUTER JOIN boost_revenue br ON cs.date = br.date
FULL OUTER JOIN user_base ub ON COALESCE(cs.date, br.date) = ub.date
ORDER BY date DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_kpi_monetization_date ON kpi_monetization_mv (date);

-- ============================================================================
-- ÉVÉNEMENTS ANALYTICS TABLE
-- ============================================================================

-- Table pour tracking événements selon spécifications point 2
CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_name VARCHAR(100) NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR(255),
    
    -- Propriétés événement
    properties JSONB DEFAULT '{}',
    user_properties JSONB DEFAULT '{}',
    
    -- Metadata
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    platform VARCHAR(50), -- web, ios, android
    app_version VARCHAR(20),
    
    -- PostHog integration
    distinct_id VARCHAR(255),
    posthog_sent BOOLEAN DEFAULT false,
    posthog_sent_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT analytics_events_name_valid CHECK (event_name IN (
        'user_signed_up', 'profile_completed', 'photo_uploaded', 'photo_approved',
        'swipe_sent', 'match_created', 'message_sent', 'conversation_started',
        'purchase_initiated', 'purchase_completed', 'subscription_created',
        'boost_purchased', 'app_opened', 'app_backgrounded'
    ))
);

-- Index pour analytics
CREATE INDEX IF NOT EXISTS idx_analytics_events_name_time ON analytics_events (event_name, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user_time ON analytics_events (user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_session ON analytics_events (session_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_analytics_events_posthog_pending ON analytics_events (posthog_sent, timestamp) WHERE posthog_sent = false;

-- ============================================================================
-- FUNNELS ANALYTICS
-- ============================================================================

-- Vue funnel principal selon spécifications
CREATE MATERIALIZED VIEW IF NOT EXISTS funnel_analysis_mv AS
WITH funnel_steps AS (
    SELECT 
        u.id as user_id,
        u.created_at as step_1_signup,
        (SELECT MIN(created_at) FROM profile_photos WHERE user_id = u.id AND moderation_status = 'approved') as step_2_photo_approved,
        (SELECT MIN(created_at) FROM user_station_status WHERE user_id = u.id) as step_3_location_set,
        (SELECT MIN(created_at) FROM likes WHERE liker_id = u.id) as step_4_first_swipe,
        (SELECT MIN(created_at) FROM matches WHERE user1_id = u.id OR user2_id = u.id) as step_5_first_match,
        (SELECT MIN(created_at) FROM messages WHERE sender_id = u.id) as step_6_first_message,
        (SELECT MIN(created_at) FROM subscriptions WHERE user_id = u.id AND status = 'active') as step_7_premium_conversion
    FROM users u
    WHERE u.created_at >= CURRENT_DATE - INTERVAL '90 days'
),
funnel_metrics AS (
    SELECT 
        DATE_TRUNC('week', step_1_signup) as cohort_week,
        COUNT(*) as signups,
        COUNT(step_2_photo_approved) as completed_photo,
        COUNT(step_3_location_set) as set_location, 
        COUNT(step_4_first_swipe) as first_swipe,
        COUNT(step_5_first_match) as first_match,
        COUNT(step_6_first_message) as first_message,
        COUNT(step_7_premium_conversion) as premium_conversion
    FROM funnel_steps
    GROUP BY DATE_TRUNC('week', step_1_signup)
)
SELECT 
    cohort_week,
    signups,
    completed_photo,
    set_location,
    first_swipe,
    first_match,
    first_message,
    premium_conversion,
    -- Conversion rates
    ROUND(completed_photo::DECIMAL / NULLIF(signups, 0) * 100, 2) as photo_completion_rate,
    ROUND(set_location::DECIMAL / NULLIF(signups, 0) * 100, 2) as location_completion_rate,
    ROUND(first_swipe::DECIMAL / NULLIF(signups, 0) * 100, 2) as swipe_activation_rate,
    ROUND(first_match::DECIMAL / NULLIF(signups, 0) * 100, 2) as match_conversion_rate,
    ROUND(first_message::DECIMAL / NULLIF(signups, 0) * 100, 2) as messaging_activation_rate,
    ROUND(premium_conversion::DECIMAL / NULLIF(signups, 0) * 100, 2) as premium_conversion_rate
FROM funnel_metrics
ORDER BY cohort_week DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_funnel_analysis_cohort ON funnel_analysis_mv (cohort_week);

-- ============================================================================
-- KPI DASHBOARD VIEW
-- ============================================================================

-- Vue consolidée pour dashboard
CREATE OR REPLACE VIEW kpi_dashboard AS
SELECT 
    'activation' as metric_category,
    a.date,
    a.total_signups as value,
    a.activation_rate_pct as percentage,
    'Total signups' as description
FROM kpi_activation_mv a
WHERE a.date >= CURRENT_DATE - INTERVAL '30 days'

UNION ALL

SELECT 
    'retention' as metric_category,
    dau.date,
    dau.daily_active_users as value,
    NULL as percentage,
    'Daily active users' as description  
FROM daily_active_users_mv dau
WHERE dau.date >= CURRENT_DATE - INTERVAL '30 days'

UNION ALL

SELECT 
    'quality' as metric_category,
    q.date,
    q.total_matches as value,
    q.match_rate_per_100_swipes as percentage,
    'Matches per 100 swipes' as description
FROM kpi_quality_mv q  
WHERE q.date >= CURRENT_DATE - INTERVAL '30 days'

UNION ALL

SELECT 
    'monetization' as metric_category,
    m.date,
    m.total_revenue_cents as value,
    m.conversion_rate_pct as percentage,
    'Revenue (cents)' as description
FROM kpi_monetization_mv m
WHERE m.date >= CURRENT_DATE - INTERVAL '30 days'

ORDER BY metric_category, date DESC;

-- ============================================================================
-- AUTO-REFRESH AVEC PG_CRON
-- ============================================================================

-- Installer pg_cron si pas disponible
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Fonction refresh toutes vues matérialisées
CREATE OR REPLACE FUNCTION refresh_all_kpi_views()
RETURNS TEXT AS $$
DECLARE
    start_time TIMESTAMPTZ := NOW();
    end_time TIMESTAMPTZ;
    result_text TEXT := '';
BEGIN
    -- Refresh vues matérialisées selon article epsio.io
    REFRESH MATERIALIZED VIEW CONCURRENTLY kpi_activation_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_active_users_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY kpi_retention_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY kpi_quality_mv;
    REFRESH MATERIALIZED VIEW CONCURRENTLY kpi_monetization_mv;
    
    end_time := NOW();
    result_text := 'KPI views refreshed in ' || EXTRACT(epoch FROM (end_time - start_time))::text || ' seconds';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Planifier refresh toutes les heures selon spécifications
SELECT cron.schedule('refresh-kpis', '0 * * * *', 'SELECT refresh_all_kpi_views();');

-- ============================================================================
-- FONCTIONS ANALYTICS
-- ============================================================================

-- Fonction pour enregistrer événement
CREATE OR REPLACE FUNCTION track_analytics_event(
    p_event_name VARCHAR(100),
    p_user_id UUID,
    p_properties JSONB DEFAULT '{}',
    p_session_id VARCHAR(255) DEFAULT NULL,
    p_platform VARCHAR(50) DEFAULT 'web'
) RETURNS UUID AS $$
DECLARE
    event_id UUID;
BEGIN
    INSERT INTO analytics_events (
        event_name,
        user_id,
        session_id,
        properties,
        user_properties,
        platform,
        distinct_id
    ) VALUES (
        p_event_name,
        p_user_id,
        p_session_id,
        p_properties,
        (SELECT jsonb_build_object(
            'is_premium', is_premium,
            'level', level,
            'languages', languages,
            'ride_styles', ride_styles,
            'created_at', created_at
        ) FROM users WHERE id = p_user_id),
        p_platform,
        p_user_id::text
    ) RETURNING id INTO event_id;
    
    RETURN event_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PERFORMANCE MONITORING
-- ============================================================================

-- Table monitoring requêtes lentes
CREATE TABLE IF NOT EXISTS slow_query_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_hash TEXT NOT NULL,
    query_text TEXT NOT NULL,
    execution_time_ms DECIMAL NOT NULL,
    rows_affected INTEGER,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id UUID,
    function_name VARCHAR(100),
    
    CONSTRAINT slow_query_min_time CHECK (execution_time_ms > 100) -- Only log queries > 100ms
);

CREATE INDEX IF NOT EXISTS idx_slow_query_time ON slow_query_log (timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_slow_query_hash ON slow_query_log (query_hash);
CREATE INDEX IF NOT EXISTS idx_slow_query_function ON slow_query_log (function_name, timestamp DESC);

-- Fonction pour logger requête lente
CREATE OR REPLACE FUNCTION log_slow_query(
    p_query_text TEXT,
    p_execution_time_ms DECIMAL,
    p_function_name VARCHAR(100) DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
) RETURNS void AS $$
BEGIN
    INSERT INTO slow_query_log (
        query_hash,
        query_text,
        execution_time_ms,
        function_name,
        user_id
    ) VALUES (
        md5(p_query_text),
        p_query_text,
        p_execution_time_ms,
        p_function_name,
        p_user_id
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Analytics events RLS
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_events" ON analytics_events
FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "service_manage_events" ON analytics_events
FOR ALL TO service_role
WITH CHECK (true);

-- Slow query log RLS (admin only)
ALTER TABLE slow_query_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_slow_queries" ON slow_query_log
FOR ALL TO authenticated
USING (
    auth.jwt() ->> 'role' = 'admin' 
    OR auth.uid()::text IN (SELECT id::text FROM users WHERE email LIKE '%@crewsnow.com')
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON MATERIALIZED VIEW kpi_activation_mv IS 'Activation KPI: percentage of users with complete profiles (photo, level, styles, languages)';
COMMENT ON MATERIALIZED VIEW daily_active_users_mv IS 'Daily active users based on swipes, messages, boosts, and profile updates';
COMMENT ON MATERIALIZED VIEW kpi_retention_mv IS 'Retention analysis by weekly cohorts with week1 and week4 retention rates';
COMMENT ON MATERIALIZED VIEW kpi_quality_mv IS 'Quality metrics: matches per 100 swipes and conversations exceeding 3 messages';
COMMENT ON MATERIALIZED VIEW kpi_monetization_mv IS 'Monetization KPIs: Free→Premium conversion rates and ARPPU calculations';

COMMENT ON TABLE analytics_events IS 'Event tracking for PostHog/Supabase Analytics integration';
COMMENT ON FUNCTION track_analytics_event(VARCHAR, UUID, JSONB, VARCHAR, VARCHAR) IS 'Records analytics events for funnel and behavior analysis';
COMMENT ON FUNCTION refresh_all_kpi_views() IS 'Refreshes all materialized KPI views - scheduled hourly via pg_cron';

DO $$
BEGIN
    RAISE NOTICE '📊 Week 8 KPIs & Analytics System Implemented!';
    RAISE NOTICE '';
    RAISE NOTICE '📈 KPI Views Created:';
    RAISE NOTICE '  ✅ kpi_activation_mv - Profile completion rates';
    RAISE NOTICE '  ✅ daily_active_users_mv - Daily retention tracking';  
    RAISE NOTICE '  ✅ kpi_retention_mv - Weekly cohort analysis';
    RAISE NOTICE '  ✅ kpi_quality_mv - Match rates and conversation quality';
    RAISE NOTICE '  ✅ kpi_monetization_mv - Revenue and conversion tracking';
    RAISE NOTICE '';
    RAISE NOTICE '📡 Analytics Features:';
    RAISE NOTICE '  ✅ analytics_events table for event tracking';
    RAISE NOTICE '  ✅ PostHog integration ready';
    RAISE NOTICE '  ✅ Auto-refresh scheduled hourly via pg_cron';
    RAISE NOTICE '  ✅ Performance monitoring with slow query log';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Test commands:';
    RAISE NOTICE '  • Dashboard: SELECT * FROM kpi_dashboard ORDER BY date DESC LIMIT 10;';
    RAISE NOTICE '  • Refresh: SELECT refresh_all_kpi_views();';
    RAISE NOTICE '  • Track event: SELECT track_analytics_event(''user_signed_up'', user_id);';
END $$;
