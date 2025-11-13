-- CrewSnow Usage Limits and Quotas System - Week 7
-- Description: Implements daily quotas for likes and messages with premium/free tiers

-- ============================================================================
-- USAGE LIMITS TABLES
-- ============================================================================

-- Daily usage tracking table
CREATE TABLE IF NOT EXISTS daily_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Like quotas
    likes_used INTEGER NOT NULL DEFAULT 0,
    likes_limit INTEGER NOT NULL DEFAULT 20, -- Free tier default
    
    -- Message quotas
    messages_used INTEGER NOT NULL DEFAULT 0,
    messages_limit INTEGER NOT NULL DEFAULT 50, -- Free tier default
    
    -- Boost usage
    boosts_used INTEGER NOT NULL DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT daily_usage_unique_user_date UNIQUE (user_id, date),
    CONSTRAINT daily_usage_likes_positive CHECK (likes_used >= 0 AND likes_limit >= 0),
    CONSTRAINT daily_usage_messages_positive CHECK (messages_used >= 0 AND messages_limit >= 0),
    CONSTRAINT daily_usage_usage_within_limit CHECK (likes_used <= likes_limit * 2), -- Allow some overflow for grace
    CONSTRAINT daily_usage_date_reasonable CHECK (date >= CURRENT_DATE - INTERVAL '1 year' AND date <= CURRENT_DATE + INTERVAL '1 day')
);

-- Usage limits configuration table
CREATE TABLE IF NOT EXISTS usage_limits_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tier VARCHAR(20) NOT NULL UNIQUE,
    
    -- Daily limits
    daily_likes_limit INTEGER NOT NULL,
    daily_messages_limit INTEGER NOT NULL,
    
    -- Feature access
    unlimited_likes BOOLEAN NOT NULL DEFAULT false,
    unlimited_messages BOOLEAN NOT NULL DEFAULT false,
    advanced_filters BOOLEAN NOT NULL DEFAULT false,
    priority_matching BOOLEAN NOT NULL DEFAULT false,
    
    -- Metadata
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT usage_limits_tier_valid CHECK (tier IN ('free', 'premium', 'boost_active')),
    CONSTRAINT usage_limits_positive CHECK (daily_likes_limit > 0 AND daily_messages_limit > 0)
);

-- Default usage limits
INSERT INTO usage_limits_config (tier, daily_likes_limit, daily_messages_limit, unlimited_likes, unlimited_messages, advanced_filters, priority_matching, description) VALUES
('free', 20, 50, false, false, false, false, 'Free tier with basic limits'),
('premium', 999999, 999999, true, true, true, true, 'Premium tier with unlimited usage'),
('boost_active', 50, 100, false, false, true, false, 'Boosted visibility with increased limits')
ON CONFLICT (tier) DO UPDATE SET updated_at = NOW();

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_daily_usage_user_date ON daily_usage (user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_usage_date ON daily_usage (date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_usage_limits_exceeded ON daily_usage (user_id, date) 
    WHERE likes_used >= likes_limit OR messages_used >= messages_limit;

-- ============================================================================
-- USAGE TRACKING FUNCTIONS
-- ============================================================================

-- Get or create daily usage record
CREATE OR REPLACE FUNCTION get_or_create_daily_usage(p_user_id UUID, p_date DATE DEFAULT CURRENT_DATE)
RETURNS UUID AS $$
DECLARE
    usage_record_id UUID;
    user_tier VARCHAR(20);
    tier_config RECORD;
BEGIN
    -- Determine user tier
    SELECT 
        CASE 
            WHEN u.is_premium AND u.premium_expires_at > NOW() THEN 'premium'
            WHEN EXISTS (
                SELECT 1 FROM boosts b 
                WHERE b.user_id = u.id 
                AND b.is_active = true 
                AND b.ends_at > NOW()
            ) THEN 'boost_active'
            ELSE 'free'
        END INTO user_tier
    FROM users u 
    WHERE u.id = p_user_id;
    
    -- Get tier configuration
    SELECT * INTO tier_config
    FROM usage_limits_config 
    WHERE tier = user_tier;
    
    -- Get or create daily usage record
    INSERT INTO daily_usage (
        user_id, 
        date, 
        likes_limit, 
        messages_limit
    ) VALUES (
        p_user_id, 
        p_date, 
        tier_config.daily_likes_limit,
        tier_config.daily_messages_limit
    )
    ON CONFLICT (user_id, date) 
    DO UPDATE SET 
        likes_limit = EXCLUDED.likes_limit,
        messages_limit = EXCLUDED.messages_limit,
        updated_at = NOW()
    RETURNING id INTO usage_record_id;
    
    RETURN usage_record_id;
END;
$$ LANGUAGE plpgsql;

-- Check if user can perform action (like/message)
CREATE OR REPLACE FUNCTION can_user_perform_action(
    p_user_id UUID,
    p_action VARCHAR(20), -- 'like' or 'message'
    p_date DATE DEFAULT CURRENT_DATE
) RETURNS BOOLEAN AS $$
DECLARE
    usage_record RECORD;
    user_tier VARCHAR(20);
    can_perform BOOLEAN := false;
BEGIN
    -- Ensure usage record exists
    PERFORM get_or_create_daily_usage(p_user_id, p_date);
    
    -- Get current usage
    SELECT * INTO usage_record
    FROM daily_usage 
    WHERE user_id = p_user_id AND date = p_date;
    
    -- Determine user tier for unlimited checks
    SELECT 
        CASE 
            WHEN u.is_premium AND u.premium_expires_at > NOW() THEN 'premium'
            WHEN EXISTS (
                SELECT 1 FROM boosts b 
                WHERE b.user_id = u.id 
                AND b.is_active = true 
                AND b.ends_at > NOW()
            ) THEN 'boost_active'
            ELSE 'free'
        END INTO user_tier
    FROM users u 
    WHERE u.id = p_user_id;
    
    -- Check limits based on action and tier
    IF p_action = 'like' THEN
        can_perform := (
            user_tier = 'premium' OR 
            usage_record.likes_used < usage_record.likes_limit
        );
    ELSIF p_action = 'message' THEN
        can_perform := (
            user_tier = 'premium' OR
            usage_record.messages_used < usage_record.messages_limit
        );
    END IF;
    
    RETURN can_perform;
END;
$$ LANGUAGE plpgsql;

-- Increment usage counter
CREATE OR REPLACE FUNCTION increment_usage_counter(
    p_user_id UUID,
    p_action VARCHAR(20),
    p_date DATE DEFAULT CURRENT_DATE
) RETURNS BOOLEAN AS $$
DECLARE
    rows_updated INTEGER;
BEGIN
    -- Ensure usage record exists
    PERFORM get_or_create_daily_usage(p_user_id, p_date);
    
    -- Increment appropriate counter
    IF p_action = 'like' THEN
        UPDATE daily_usage 
        SET 
            likes_used = likes_used + 1,
            updated_at = NOW()
        WHERE user_id = p_user_id AND date = p_date;
    ELSIF p_action = 'message' THEN
        UPDATE daily_usage 
        SET 
            messages_used = messages_used + 1,
            updated_at = NOW()
        WHERE user_id = p_user_id AND date = p_date;
    ELSE
        RETURN false;
    END IF;
    
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    RETURN rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

-- Get user's current usage status
CREATE OR REPLACE FUNCTION get_user_usage_status(p_user_id UUID)
RETURNS TABLE (
    date DATE,
    likes_used INTEGER,
    likes_limit INTEGER,
    likes_remaining INTEGER,
    messages_used INTEGER,
    messages_limit INTEGER,
    messages_remaining INTEGER,
    tier VARCHAR(20),
    unlimited_likes BOOLEAN,
    unlimited_messages BOOLEAN,
    reset_time TIMESTAMPTZ
) AS $$
DECLARE
    user_tier VARCHAR(20);
BEGIN
    -- Ensure today's record exists
    PERFORM get_or_create_daily_usage(p_user_id, CURRENT_DATE);
    
    -- Determine current tier
    SELECT 
        CASE 
            WHEN u.is_premium AND u.premium_expires_at > NOW() THEN 'premium'
            WHEN EXISTS (
                SELECT 1 FROM boosts b 
                WHERE b.user_id = u.id 
                AND b.is_active = true 
                AND b.ends_at > NOW()
            ) THEN 'boost_active'
            ELSE 'free'
        END INTO user_tier
    FROM users u 
    WHERE u.id = p_user_id;
    
    RETURN QUERY
    SELECT 
        du.date,
        du.likes_used,
        du.likes_limit,
        GREATEST(0, du.likes_limit - du.likes_used) as likes_remaining,
        du.messages_used,
        du.messages_limit,
        GREATEST(0, du.messages_limit - du.messages_used) as messages_remaining,
        user_tier,
        CASE WHEN user_tier = 'premium' THEN true ELSE false END as unlimited_likes,
        CASE WHEN user_tier = 'premium' THEN true ELSE false END as unlimited_messages,
        (CURRENT_DATE + INTERVAL '1 day')::TIMESTAMPTZ as reset_time
    FROM daily_usage du
    WHERE du.user_id = p_user_id AND du.date = CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- INTEGRATION WITH EXISTING FUNCTIONS
-- ============================================================================

-- Enhanced swipe function with quota checking
CREATE OR REPLACE FUNCTION check_and_increment_like_quota(p_user_id UUID)
RETURNS TABLE (
    can_like BOOLEAN,
    reason TEXT,
    likes_remaining INTEGER,
    tier VARCHAR(20)
) AS $$
DECLARE
    can_perform BOOLEAN;
    usage_status RECORD;
    increment_success BOOLEAN;
BEGIN
    -- Check if user can like
    can_perform := can_user_perform_action(p_user_id, 'like');
    
    IF can_perform THEN
        -- Increment usage counter
        increment_success := increment_usage_counter(p_user_id, 'like');
        
        -- Get updated status
        SELECT * INTO usage_status
        FROM get_user_usage_status(p_user_id);
        
        RETURN QUERY SELECT 
            true,
            'Like quota available'::TEXT,
            usage_status.likes_remaining,
            usage_status.tier;
    ELSE
        -- Get current status for error message
        SELECT * INTO usage_status
        FROM get_user_usage_status(p_user_id);
        
        RETURN QUERY SELECT 
            false,
            CASE 
                WHEN usage_status.tier = 'free' 
                THEN 'Daily like limit reached. Upgrade to premium for unlimited likes!'
                ELSE 'Like quota temporarily unavailable'
            END::TEXT,
            usage_status.likes_remaining,
            usage_status.tier;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Enhanced message function with quota checking
CREATE OR REPLACE FUNCTION check_and_increment_message_quota(p_user_id UUID)
RETURNS TABLE (
    can_message BOOLEAN,
    reason TEXT,
    messages_remaining INTEGER,
    tier VARCHAR(20)
) AS $$
DECLARE
    can_perform BOOLEAN;
    usage_status RECORD;
    increment_success BOOLEAN;
BEGIN
    -- Check if user can message
    can_perform := can_user_perform_action(p_user_id, 'message');
    
    IF can_perform THEN
        -- Increment usage counter
        increment_success := increment_usage_counter(p_user_id, 'message');
        
        -- Get updated status
        SELECT * INTO usage_status
        FROM get_user_usage_status(p_user_id);
        
        RETURN QUERY SELECT 
            true,
            'Message quota available'::TEXT,
            usage_status.messages_remaining,
            usage_status.tier;
    ELSE
        -- Get current status for error message
        SELECT * INTO usage_status
        FROM get_user_usage_status(p_user_id);
        
        RETURN QUERY SELECT 
            false,
            CASE 
                WHEN usage_status.tier = 'free' 
                THEN 'Daily message limit reached. Upgrade to premium for unlimited messaging!'
                ELSE 'Message quota temporarily unavailable'
            END::TEXT,
            usage_status.messages_remaining,
            usage_status.tier;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STRIPE CUSTOMER MANAGEMENT
-- ============================================================================

-- Function to link user to Stripe customer (called when first payment)
CREATE OR REPLACE FUNCTION link_user_to_stripe_customer(
    p_user_id UUID,
    p_stripe_customer_id VARCHAR(255)
) RETURNS BOOLEAN AS $$
DECLARE
    updated_rows INTEGER;
BEGIN
    UPDATE users 
    SET 
        stripe_customer_id = p_stripe_customer_id,
        updated_at = NOW()
    WHERE id = p_user_id 
        AND (stripe_customer_id IS NULL OR stripe_customer_id = '');
    
    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    
    IF updated_rows > 0 THEN
        RAISE NOTICE 'User % linked to Stripe customer %', p_user_id, p_stripe_customer_id;
        RETURN true;
    ELSE
        RAISE WARNING 'User % already has Stripe customer or not found', p_user_id;
        RETURN false;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- QUOTA ENFORCEMENT TRIGGERS
-- ============================================================================

-- Trigger to update daily usage on likes
CREATE OR REPLACE FUNCTION trigger_like_quota_check()
RETURNS TRIGGER AS $$
DECLARE
    quota_check RECORD;
BEGIN
    -- Check quota before allowing like
    SELECT * INTO quota_check
    FROM check_and_increment_like_quota(NEW.liker_id);
    
    IF NOT quota_check.can_like THEN
        RAISE EXCEPTION 'Like quota exceeded: %', quota_check.reason
            USING ERRCODE = 'QUOTA_EXCEEDED',
                  HINT = 'Upgrade to premium for unlimited likes';
    END IF;
    
    -- Note: Usage already incremented by check_and_increment_like_quota
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update daily usage on messages
CREATE OR REPLACE FUNCTION trigger_message_quota_check()
RETURNS TRIGGER AS $$
DECLARE
    quota_check RECORD;
BEGIN
    -- Check quota before allowing message
    SELECT * INTO quota_check
    FROM check_and_increment_message_quota(NEW.sender_id);
    
    IF NOT quota_check.can_message THEN
        RAISE EXCEPTION 'Message quota exceeded: %', quota_check.reason
            USING ERRCODE = 'QUOTA_EXCEEDED',
                  HINT = 'Upgrade to premium for unlimited messaging';
    END IF;
    
    -- Note: Usage already incremented by check_and_increment_message_quota
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers (can be enabled/disabled based on requirements)
-- DROP TRIGGER IF EXISTS trigger_like_quota_enforcement ON likes;
-- CREATE TRIGGER trigger_like_quota_enforcement
--     BEFORE INSERT ON likes
--     FOR EACH ROW
--     EXECUTE FUNCTION trigger_like_quota_check();

-- DROP TRIGGER IF EXISTS trigger_message_quota_enforcement ON messages;  
-- CREATE TRIGGER trigger_message_quota_enforcement
--     BEFORE INSERT ON messages
--     FOR EACH ROW
--     EXECUTE FUNCTION trigger_message_quota_check();

-- ============================================================================
-- PREMIUM STATUS MANAGEMENT
-- ============================================================================

-- Enhanced function to check active premium (with subscription sync)
CREATE OR REPLACE FUNCTION user_has_active_premium_enhanced(p_user_id UUID)
RETURNS TABLE (
    has_premium BOOLEAN,
    premium_source VARCHAR(50),
    expires_at TIMESTAMPTZ,
    subscription_status VARCHAR(50),
    tier VARCHAR(20)
) AS $$
DECLARE
    user_record RECORD;
    subscription_record RECORD;
    boost_record RECORD;
BEGIN
    -- Get user data
    SELECT * INTO user_record FROM users WHERE id = p_user_id;
    
    -- Get active subscription
    SELECT * INTO subscription_record
    FROM subscriptions 
    WHERE user_id = p_user_id 
        AND status IN ('active', 'trialing')
        AND current_period_end > NOW()
    ORDER BY current_period_end DESC
    LIMIT 1;
    
    -- Get active boost
    SELECT * INTO boost_record
    FROM boosts 
    WHERE user_id = p_user_id 
        AND is_active = true 
        AND ends_at > NOW()
    ORDER BY ends_at DESC
    LIMIT 1;
    
    -- Determine premium status and source
    IF subscription_record.id IS NOT NULL THEN
        RETURN QUERY SELECT 
            true,
            'subscription'::VARCHAR(50),
            subscription_record.current_period_end,
            subscription_record.status::VARCHAR(50),
            'premium'::VARCHAR(20);
    ELSIF user_record.is_premium AND user_record.premium_expires_at > NOW() THEN
        RETURN QUERY SELECT 
            true,
            'direct_premium'::VARCHAR(50),
            user_record.premium_expires_at,
            'active'::VARCHAR(50),
            'premium'::VARCHAR(20);
    ELSIF boost_record.id IS NOT NULL THEN
        RETURN QUERY SELECT 
            false, -- Boost doesn't grant premium, just enhanced limits
            'boost'::VARCHAR(50),
            boost_record.ends_at,
            'active'::VARCHAR(50),
            'boost_active'::VARCHAR(20);
    ELSE
        RETURN QUERY SELECT 
            false,
            'none'::VARCHAR(50),
            NULL::TIMESTAMPTZ,
            'inactive'::VARCHAR(50),
            'free'::VARCHAR(20);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ANALYTICS AND MONITORING
-- ============================================================================

-- Daily usage analytics view
CREATE OR REPLACE VIEW usage_analytics AS
SELECT 
    date,
    COUNT(*) as total_users,
    AVG(likes_used) as avg_likes_used,
    AVG(messages_used) as avg_messages_used,
    COUNT(*) FILTER (WHERE likes_used >= likes_limit) as users_hit_like_limit,
    COUNT(*) FILTER (WHERE messages_used >= messages_limit) as users_hit_message_limit,
    COUNT(*) FILTER (WHERE likes_limit > 50) as premium_users,
    ROUND(AVG(likes_used::DECIMAL / likes_limit * 100), 2) as avg_like_quota_usage_pct,
    ROUND(AVG(messages_used::DECIMAL / messages_limit * 100), 2) as avg_message_quota_usage_pct
FROM daily_usage 
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY date
ORDER BY date DESC;

-- User tier distribution
CREATE OR REPLACE VIEW user_tier_distribution AS
SELECT 
    tier,
    COUNT(*) as user_count,
    AVG(daily_likes_limit) as avg_likes_limit,
    AVG(daily_messages_limit) as avg_messages_limit
FROM usage_limits_config ulc
JOIN daily_usage du ON (
    CASE 
        WHEN (SELECT is_premium FROM users WHERE id = du.user_id) = true THEN 'premium'
        WHEN EXISTS (SELECT 1 FROM boosts WHERE user_id = du.user_id AND is_active = true AND ends_at > NOW()) THEN 'boost_active'
        ELSE 'free'
    END
) = ulc.tier
WHERE du.date = CURRENT_DATE
GROUP BY tier, ulc.daily_likes_limit, ulc.daily_messages_limit;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Enable RLS on usage tables
ALTER TABLE daily_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_limits_config ENABLE ROW LEVEL SECURITY;

-- Users can only see their own usage
CREATE POLICY "users_own_usage" ON daily_usage
FOR ALL TO authenticated
USING (auth.uid() = user_id);

-- Config is readable by all authenticated users
CREATE POLICY "config_readable" ON usage_limits_config
FOR SELECT TO authenticated
USING (true);

-- Service role can manage all usage data
CREATE POLICY "service_manage_usage" ON daily_usage
FOR ALL TO service_role
WITH CHECK (true);

CREATE POLICY "service_manage_config" ON usage_limits_config
FOR ALL TO service_role
WITH CHECK (true);

-- ============================================================================
-- MAINTENANCE FUNCTIONS
-- ============================================================================

-- Cleanup old usage records
CREATE OR REPLACE FUNCTION cleanup_old_usage_records()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM daily_usage 
    WHERE date < CURRENT_DATE - INTERVAL '90 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Daily reset function (can be called by cron)
CREATE OR REPLACE FUNCTION reset_daily_quotas()
RETURNS INTEGER AS $$
DECLARE
    reset_count INTEGER := 0;
    active_user RECORD;
BEGIN
    -- Reset quotas for active users (create new day records)
    FOR active_user IN 
        SELECT DISTINCT u.id
        FROM users u
        JOIN user_station_status uss ON u.id = uss.user_id
        WHERE u.is_active = true
            AND uss.is_active = true
            AND u.last_active_at > NOW() - INTERVAL '7 days'
    LOOP
        PERFORM get_or_create_daily_usage(active_user.id, CURRENT_DATE);
        reset_count := reset_count + 1;
    END LOOP;
    
    RETURN reset_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE daily_usage IS 'Tracks daily usage quotas for likes and messages per user';
COMMENT ON TABLE usage_limits_config IS 'Configuration for usage limits by user tier (free/premium/boost)';
COMMENT ON FUNCTION can_user_perform_action(UUID, VARCHAR, DATE) IS 'Checks if user can perform action without exceeding quota';
COMMENT ON FUNCTION increment_usage_counter(UUID, VARCHAR, DATE) IS 'Increments usage counter for likes or messages';
COMMENT ON FUNCTION get_user_usage_status(UUID) IS 'Returns complete usage status for user dashboard';
COMMENT ON VIEW usage_analytics IS 'Daily analytics view for usage patterns and quota utilization';

-- ============================================================================
-- COMPLETION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🎯 Usage Limits and Quotas System Implemented!';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Features:';
    RAISE NOTICE '  ✅ Daily usage tracking with tier-based limits';
    RAISE NOTICE '  ✅ Free tier: 20 likes/50 messages per day';
    RAISE NOTICE '  ✅ Premium tier: Unlimited likes and messages';
    RAISE NOTICE '  ✅ Boost tier: Enhanced limits (50 likes/100 messages)';
    RAISE NOTICE '  ✅ Quota enforcement functions ready for integration';
    RAISE NOTICE '  ✅ Analytics views for monitoring usage patterns';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Integration functions:';
    RAISE NOTICE '  • Check quota: SELECT can_user_perform_action(user_id, ''like'');';
    RAISE NOTICE '  • User status: SELECT * FROM get_user_usage_status(user_id);';
    RAISE NOTICE '  • Analytics: SELECT * FROM usage_analytics;';
    RAISE NOTICE '';
    RAISE NOTICE '⚡ Triggers available (disabled by default):';
    RAISE NOTICE '  • Enable like quota: CREATE TRIGGER trigger_like_quota_enforcement...';
    RAISE NOTICE '  • Enable message quota: CREATE TRIGGER trigger_message_quota_enforcement...';
END $$;
