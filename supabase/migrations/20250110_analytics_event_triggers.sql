-- CrewSnow Analytics Event Triggers - Week 8
-- Auto-tracking des événements clés selon spécifications

-- ============================================================================
-- TRIGGERS ÉVÉNEMENTS ANALYTICS
-- ============================================================================

-- Trigger user signup
CREATE OR REPLACE FUNCTION trigger_analytics_user_signup()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM track_analytics_event(
        'user_signed_up',
        NEW.id,
        jsonb_build_object(
            'email', NEW.email,
            'username', NEW.username,
            'signup_method', 'direct'
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER analytics_user_signup
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_analytics_user_signup();

-- Trigger profile completion
CREATE OR REPLACE FUNCTION trigger_analytics_profile_completed()
RETURNS TRIGGER AS $$
DECLARE
    is_complete BOOLEAN;
BEGIN
    -- Check if profile is now complete selon spécifications
    is_complete := (
        NEW.bio IS NOT NULL 
        AND NEW.level IS NOT NULL 
        AND cardinality(NEW.ride_styles) > 0 
        AND cardinality(NEW.languages) > 0
        AND EXISTS (
            SELECT 1 FROM profile_photos pp 
            WHERE pp.user_id = NEW.id 
            AND pp.moderation_status = 'approved'
        )
    );
    
    -- Only trigger if profile wasn't complete before but is now
    IF is_complete AND (
        OLD.bio IS NULL OR OLD.level IS NULL OR 
        cardinality(OLD.ride_styles) = 0 OR cardinality(OLD.languages) = 0
    ) THEN
        PERFORM track_analytics_event(
            'profile_completed',
            NEW.id,
            jsonb_build_object(
                'level', NEW.level,
                'ride_styles_count', cardinality(NEW.ride_styles),
                'languages_count', cardinality(NEW.languages),
                'has_bio', NEW.bio IS NOT NULL,
                'completion_time_hours', EXTRACT(epoch FROM (NOW() - NEW.created_at)) / 3600
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER analytics_profile_completed
    AFTER UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_analytics_profile_completed();

-- Trigger photo events
CREATE OR REPLACE FUNCTION trigger_analytics_photo_events()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM track_analytics_event(
            'photo_uploaded',
            NEW.user_id,
            jsonb_build_object(
                'photo_id', NEW.id,
                'file_size_mb', ROUND(NEW.file_size_bytes / 1024.0 / 1024.0, 2),
                'mime_type', NEW.mime_type,
                'is_main', NEW.is_main
            )
        );
    ELSIF TG_OP = 'UPDATE' AND OLD.moderation_status != NEW.moderation_status THEN
        IF NEW.moderation_status = 'approved' THEN
            PERFORM track_analytics_event(
                'photo_approved',
                NEW.user_id,
                jsonb_build_object(
                    'photo_id', NEW.id,
                    'moderation_time_hours', EXTRACT(epoch FROM (NEW.moderated_at - NEW.created_at)) / 3600
                )
            );
        ELSIF NEW.moderation_status = 'rejected' THEN
            PERFORM track_analytics_event(
                'photo_rejected',
                NEW.user_id,
                jsonb_build_object(
                    'photo_id', NEW.id,
                    'rejection_reason', NEW.moderation_reason
                )
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER analytics_photo_events
    AFTER INSERT OR UPDATE ON profile_photos
    FOR EACH ROW
    EXECUTE FUNCTION trigger_analytics_photo_events();

-- Trigger swipe events
CREATE OR REPLACE FUNCTION trigger_analytics_swipe_sent()
RETURNS TRIGGER AS $$
DECLARE
    swiper_data RECORD;
    target_data RECORD;
BEGIN
    -- Get user data for enriched analytics
    SELECT level, ride_styles, languages, is_premium INTO swiper_data
    FROM users WHERE id = NEW.liker_id;
    
    SELECT level, ride_styles, languages INTO target_data  
    FROM users WHERE id = NEW.liked_id;
    
    PERFORM track_analytics_event(
        'swipe_sent',
        NEW.liker_id,
        jsonb_build_object(
            'target_user_id', NEW.liked_id,
            'swiper_level', swiper_data.level,
            'target_level', target_data.level,
            'swiper_is_premium', swiper_data.is_premium,
            'common_styles', cardinality(swiper_data.ride_styles && target_data.ride_styles),
            'common_languages', cardinality(swiper_data.languages && target_data.languages)
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER analytics_swipe_sent
    AFTER INSERT ON likes
    FOR EACH ROW
    EXECUTE FUNCTION trigger_analytics_swipe_sent();

-- Trigger match creation
CREATE OR REPLACE FUNCTION trigger_analytics_match_created()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM track_analytics_event(
        'match_created',
        NEW.user1_id,
        jsonb_build_object(
            'match_id', NEW.id,
            'matched_user_id', NEW.user2_id,
            'matched_at_station', NEW.matched_at_station_id
        )
    );
    
    PERFORM track_analytics_event(
        'match_created',
        NEW.user2_id,
        jsonb_build_object(
            'match_id', NEW.id,
            'matched_user_id', NEW.user1_id,
            'matched_at_station', NEW.matched_at_station_id
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER analytics_match_created
    AFTER INSERT ON matches
    FOR EACH ROW
    EXECUTE FUNCTION trigger_analytics_match_created();

-- Trigger message events
CREATE OR REPLACE FUNCTION trigger_analytics_message_sent()
RETURNS TRIGGER AS $$
DECLARE
    is_first_message BOOLEAN;
    conversation_length INTEGER;
BEGIN
    -- Check if this is first message in conversation
    SELECT COUNT(*) = 0 INTO is_first_message
    FROM messages 
    WHERE match_id = NEW.match_id AND created_at < NEW.created_at;
    
    -- Get conversation length
    SELECT COUNT(*) INTO conversation_length
    FROM messages 
    WHERE match_id = NEW.match_id;
    
    IF is_first_message THEN
        PERFORM track_analytics_event(
            'conversation_started',
            NEW.sender_id,
            jsonb_build_object(
                'match_id', NEW.match_id,
                'message_id', NEW.id,
                'message_type', NEW.message_type,
                'time_to_first_message_hours', EXTRACT(epoch FROM (
                    NEW.created_at - (SELECT created_at FROM matches WHERE id = NEW.match_id)
                )) / 3600
            )
        );
    END IF;
    
    PERFORM track_analytics_event(
        'message_sent',
        NEW.sender_id,
        jsonb_build_object(
            'match_id', NEW.match_id,
            'message_id', NEW.id,
            'message_type', NEW.message_type,
            'content_length', length(NEW.content),
            'conversation_length', conversation_length,
            'is_first_message', is_first_message
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER analytics_message_sent
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION trigger_analytics_message_sent();

-- Trigger purchase events
CREATE OR REPLACE FUNCTION trigger_analytics_purchase_events()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.status = 'active' THEN
            PERFORM track_analytics_event(
                'subscription_created',
                NEW.user_id,
                jsonb_build_object(
                    'subscription_id', NEW.stripe_subscription_id,
                    'price_id', NEW.stripe_price_id,
                    'amount_cents', NEW.amount_cents,
                    'currency', NEW.currency,
                    'interval', NEW.interval
                )
            );
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != 'active' AND NEW.status = 'active' THEN
            PERFORM track_analytics_event(
                'purchase_completed',
                NEW.user_id,
                jsonb_build_object(
                    'subscription_id', NEW.stripe_subscription_id,
                    'amount_cents', NEW.amount_cents,
                    'upgrade_from_free', true
                )
            );
        ELSIF OLD.status = 'active' AND NEW.status IN ('canceled', 'past_due') THEN
            PERFORM track_analytics_event(
                'subscription_canceled',
                NEW.user_id,
                jsonb_build_object(
                    'subscription_id', NEW.stripe_subscription_id,
                    'cancellation_reason', NEW.status,
                    'lifetime_value_cents', NEW.amount_cents
                )
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER analytics_purchase_events
    AFTER INSERT OR UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION trigger_analytics_purchase_events();

-- Trigger boost events
CREATE OR REPLACE FUNCTION trigger_analytics_boost_purchased()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM track_analytics_event(
        'boost_purchased',
        NEW.user_id,
        jsonb_build_object(
            'boost_id', NEW.id,
            'station_id', NEW.station_id,
            'boost_multiplier', NEW.boost_multiplier,
            'duration_hours', EXTRACT(epoch FROM (NEW.ends_at - NEW.starts_at)) / 3600,
            'amount_cents', NEW.amount_paid_cents,
            'currency', NEW.currency
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER analytics_boost_purchased
    AFTER INSERT ON boosts
    FOR EACH ROW
    EXECUTE FUNCTION trigger_analytics_boost_purchased();

-- ============================================================================
-- BATCH PROCESSING FUNCTION
-- ============================================================================

-- Fonction processing batch pour PostHog
CREATE OR REPLACE FUNCTION process_analytics_batch()
RETURNS TEXT AS $$
DECLARE
    batch_size INTEGER := 100;
    processed_count INTEGER := 0;
    total_pending INTEGER;
    result_text TEXT;
BEGIN
    -- Count pending events
    SELECT COUNT(*) INTO total_pending
    FROM analytics_events 
    WHERE posthog_sent = false;
    
    -- Process if events pending
    IF total_pending > 0 THEN
        -- Call Edge Function for batch processing
        PERFORM net.http_post(
            url := current_setting('app.supabase_url') || '/functions/v1/analytics-posthog',
            headers := jsonb_build_object(
                'Authorization', 'Bearer ' || current_setting('app.service_role_key'),
                'Content-Type', 'application/json'
            ),
            body := '{}'::jsonb
        );
        
        processed_count := LEAST(total_pending, batch_size);
    END IF;
    
    result_text := 'Processed ' || processed_count::text || ' analytics events of ' || total_pending::text || ' pending';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Planifier processing PostHog toutes les 5 minutes
SELECT cron.schedule('process-analytics', '*/5 * * * *', 'SELECT process_analytics_batch();');

-- ============================================================================
-- FUNNELS ET COHORTS HELPERS
-- ============================================================================

-- Fonction création cohorts selon spécifications PostHog
CREATE OR REPLACE FUNCTION create_user_cohorts()
RETURNS TABLE (
    cohort_name TEXT,
    cohort_query TEXT,
    user_count INTEGER,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY VALUES
    ('Active Swipers', 'SELECT user_id FROM analytics_events WHERE event_name = ''swipe_sent'' AND timestamp > NOW() - INTERVAL ''7 days''', 
     (SELECT COUNT(DISTINCT user_id) FROM analytics_events WHERE event_name = 'swipe_sent' AND timestamp > NOW() - INTERVAL '7 days'),
     'Users who swiped in last 7 days'),
    
    ('Premium Users', 'SELECT id FROM users WHERE is_premium = true',
     (SELECT COUNT(*) FROM users WHERE is_premium = true),
     'Currently premium users'),
    
    ('Frequent Messagers', 'SELECT sender_id FROM messages WHERE created_at > NOW() - INTERVAL ''7 days'' GROUP BY sender_id HAVING COUNT(*) >= 5',
     (SELECT COUNT(*) FROM (SELECT sender_id FROM messages WHERE created_at > NOW() - INTERVAL '7 days' GROUP BY sender_id HAVING COUNT(*) >= 5) t),
     'Users with 5+ messages in last 7 days'),
    
    ('New Users This Week', 'SELECT id FROM users WHERE created_at > NOW() - INTERVAL ''7 days''',
     (SELECT COUNT(*) FROM users WHERE created_at > NOW() - INTERVAL '7 days'),
     'Users who signed up in last 7 days');
END;
$$ LANGUAGE plpgsql;

-- Fonction configuration funnels selon spécifications PostHog
CREATE OR REPLACE FUNCTION create_analytics_funnels()
RETURNS TABLE (
    funnel_name TEXT,
    steps JSONB,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY VALUES
    ('User Activation Funnel', 
     jsonb_build_array(
         jsonb_build_object('event', 'user_signed_up', 'name', 'Sign Up'),
         jsonb_build_object('event', 'photo_uploaded', 'name', 'Upload Photo'),
         jsonb_build_object('event', 'photo_approved', 'name', 'Photo Approved'),
         jsonb_build_object('event', 'profile_completed', 'name', 'Profile Complete')
     ), 
     'Inscription → Profil Complété'),
    
    ('Matching Funnel',
     jsonb_build_array(
         jsonb_build_object('event', 'profile_completed', 'name', 'Profile Complete'),
         jsonb_build_object('event', 'swipe_sent', 'name', 'First Swipe'),
         jsonb_build_object('event', 'match_created', 'name', 'First Match'),
         jsonb_build_object('event', 'conversation_started', 'name', 'First Message')
     ),
     'Profil Complet → Premier Message'),
    
    ('Monetization Funnel',
     jsonb_build_array(
         jsonb_build_object('event', 'swipe_sent', 'name', 'Active User'),
         jsonb_build_object('event', 'purchase_initiated', 'name', 'Purchase Intent'),
         jsonb_build_object('event', 'purchase_completed', 'name', 'Premium Conversion')
     ),
     'Utilisateur Actif → Premium');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- REAL-TIME KPI FUNCTIONS
-- ============================================================================

-- Fonction KPI temps réel pour dashboard
CREATE OR REPLACE FUNCTION get_realtime_kpis()
RETURNS TABLE (
    kpi_name TEXT,
    current_value DECIMAL,
    previous_value DECIMAL,
    change_pct DECIMAL,
    trend VARCHAR(10),
    last_updated TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    -- Daily Active Users
    SELECT 
        'Daily Active Users' as kpi_name,
        (SELECT daily_active_users FROM daily_active_users_mv WHERE date = CURRENT_DATE)::DECIMAL as current_value,
        (SELECT daily_active_users FROM daily_active_users_mv WHERE date = CURRENT_DATE - 1)::DECIMAL as previous_value,
        ROUND(
            ((SELECT daily_active_users FROM daily_active_users_mv WHERE date = CURRENT_DATE)::DECIMAL - 
             (SELECT daily_active_users FROM daily_active_users_mv WHERE date = CURRENT_DATE - 1)::DECIMAL) / 
            NULLIF((SELECT daily_active_users FROM daily_active_users_mv WHERE date = CURRENT_DATE - 1), 0) * 100, 2
        ) as change_pct,
        CASE 
            WHEN (SELECT daily_active_users FROM daily_active_users_mv WHERE date = CURRENT_DATE) > 
                 (SELECT daily_active_users FROM daily_active_users_mv WHERE date = CURRENT_DATE - 1) THEN 'UP'
            WHEN (SELECT daily_active_users FROM daily_active_users_mv WHERE date = CURRENT_DATE) < 
                 (SELECT daily_active_users FROM daily_active_users_mv WHERE date = CURRENT_DATE - 1) THEN 'DOWN'
            ELSE 'STABLE'
        END as trend,
        NOW() as last_updated
    
    UNION ALL
    
    -- Activation Rate
    SELECT 
        'Activation Rate' as kpi_name,
        (SELECT activation_rate_pct FROM kpi_activation_mv WHERE date = CURRENT_DATE)::DECIMAL,
        (SELECT activation_rate_pct FROM kpi_activation_mv WHERE date = CURRENT_DATE - 1)::DECIMAL,
        (SELECT activation_rate_pct FROM kpi_activation_mv WHERE date = CURRENT_DATE)::DECIMAL - 
        (SELECT activation_rate_pct FROM kpi_activation_mv WHERE date = CURRENT_DATE - 1)::DECIMAL,
        CASE 
            WHEN (SELECT activation_rate_pct FROM kpi_activation_mv WHERE date = CURRENT_DATE) > 
                 (SELECT activation_rate_pct FROM kpi_activation_mv WHERE date = CURRENT_DATE - 1) THEN 'UP'
            ELSE 'DOWN'
        END,
        NOW()
    
    UNION ALL
    
    -- Match Rate
    SELECT 
        'Match Rate per 100 Swipes' as kpi_name,
        (SELECT match_rate_per_100_swipes FROM kpi_quality_mv WHERE date = CURRENT_DATE)::DECIMAL,
        (SELECT match_rate_per_100_swipes FROM kpi_quality_mv WHERE date = CURRENT_DATE - 1)::DECIMAL,
        (SELECT match_rate_per_100_swipes FROM kpi_quality_mv WHERE date = CURRENT_DATE)::DECIMAL -
        (SELECT match_rate_per_100_swipes FROM kpi_quality_mv WHERE date = CURRENT_DATE - 1)::DECIMAL,
        CASE 
            WHEN (SELECT match_rate_per_100_swipes FROM kpi_quality_mv WHERE date = CURRENT_DATE) > 
                 (SELECT match_rate_per_100_swipes FROM kpi_quality_mv WHERE date = CURRENT_DATE - 1) THEN 'UP'
            ELSE 'DOWN'
        END,
        NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE analytics_events IS 'Event tracking for PostHog integration with automatic triggers on key user actions';
COMMENT ON FUNCTION process_analytics_batch() IS 'Processes pending analytics events and sends them to PostHog via Edge Function';
COMMENT ON FUNCTION create_user_cohorts() IS 'Generates cohort definitions for PostHog integration';
COMMENT ON FUNCTION create_analytics_funnels() IS 'Defines funnel analysis configurations for user journey tracking';
COMMENT ON FUNCTION get_realtime_kpis() IS 'Returns real-time KPI values with trends for dashboard display';

DO $$
BEGIN
    RAISE NOTICE '📡 Analytics Event Triggers & PostHog Integration Complete!';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Auto-tracking enabled for:';
    RAISE NOTICE '  ✅ user_signed_up - New registrations';
    RAISE NOTICE '  ✅ profile_completed - Complete profiles';
    RAISE NOTICE '  ✅ photo_uploaded/approved/rejected - Photo workflow';
    RAISE NOTICE '  ✅ swipe_sent - All swipe actions with context';
    RAISE NOTICE '  ✅ match_created - Successful matches';
    RAISE NOTICE '  ✅ message_sent/conversation_started - Messaging';
    RAISE NOTICE '  ✅ subscription_created/purchase_completed - Revenue';
    RAISE NOTICE '  ✅ boost_purchased - Boost transactions';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 PostHog Integration:';
    RAISE NOTICE '  ✅ Batch processing every 5 minutes via pg_cron';
    RAISE NOTICE '  ✅ Event enrichment with user properties';
    RAISE NOTICE '  ✅ Funnel and cohort definitions ready';
    RAISE NOTICE '';
    RAISE NOTICE '📈 Real-time KPIs:';
    RAISE NOTICE '  • Current metrics: SELECT * FROM get_realtime_kpis();';
    RAISE NOTICE '  • Dashboard view: SELECT * FROM kpi_dashboard WHERE date >= CURRENT_DATE - 7;';
    RAISE NOTICE '  • Cohorts: SELECT * FROM create_user_cohorts();';
END $$;
