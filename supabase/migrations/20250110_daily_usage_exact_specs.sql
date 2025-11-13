-- CrewSnow Daily Usage - Exact Specifications Week 7
-- 3.1 Table daily_usage selon spécifications exactes

-- ============================================================================
-- 3.1 TABLE DAILY_USAGE SELON SPÉCIFICATIONS
-- ============================================================================

-- Drop existing if different structure
DROP TABLE IF EXISTS daily_usage CASCADE;

-- Créer selon spécifications exactes
CREATE TABLE daily_usage (
  user_id UUID NOT NULL REFERENCES users(id),
  date DATE NOT NULL,
  swipe_count INT NOT NULL DEFAULT 0,
  message_count INT NOT NULL DEFAULT 0,
  -- Ajout autres compteurs
  boost_count INT NOT NULL DEFAULT 0,
  photo_upload_count INT NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, date)
);

-- Index performance
CREATE INDEX IF NOT EXISTS idx_daily_usage_date ON daily_usage (date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_usage_user_date ON daily_usage (user_id, date DESC);

-- ============================================================================
-- 3.2 FONCTION SQL VÉRIFICATION QUOTAS SELON SPÉCIFICATIONS
-- ============================================================================

-- Fonction selon spécifications exactes avec advisory lock
CREATE OR REPLACE FUNCTION check_and_increment_usage(
    p_user UUID, 
    p_limit_swipe INT, 
    p_limit_message INT, 
    p_count_swipe INT, 
    p_count_message INT
) RETURNS BOOLEAN AS $$
DECLARE
    current_swipe_count INT := 0;
    current_message_count INT := 0;
    new_swipe_count INT;
    new_message_count INT;
    today DATE := CURRENT_DATE;
BEGIN
    -- Advisory lock pour éviter courses critiques selon guide Neon
    PERFORM pg_advisory_xact_lock(hashtext(p_user::text || today::text));
    
    -- INSERT ... ON CONFLICT pour créer ou mettre à jour selon spécifications
    INSERT INTO daily_usage (user_id, date, swipe_count, message_count)
    VALUES (p_user, today, 0, 0)
    ON CONFLICT (user_id, date) DO NOTHING;
    
    -- Récupérer compteurs actuels
    SELECT swipe_count, message_count 
    INTO current_swipe_count, current_message_count
    FROM daily_usage 
    WHERE user_id = p_user AND date = today;
    
    -- Calculer nouveaux compteurs
    new_swipe_count := current_swipe_count + p_count_swipe;
    new_message_count := current_message_count + p_count_message;
    
    -- Vérifier limites selon spécifications
    IF new_swipe_count > p_limit_swipe OR new_message_count > p_limit_message THEN
        -- Limites dépassées - ne pas incrémenter
        RETURN false;
    END IF;
    
    -- Incrémenter compteurs selon spécifications
    UPDATE daily_usage 
    SET 
        swipe_count = new_swipe_count,
        message_count = new_message_count
    WHERE user_id = p_user AND date = today;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3.3 EDGE FUNCTION GATEKEEPER SELON SPÉCIFICATIONS
-- ============================================================================

-- Fonction helper pour Edge Function gatekeeper
CREATE OR REPLACE FUNCTION get_user_limits_and_check(
    p_user_id UUID,
    p_action VARCHAR(20), -- 'swipe' or 'message'
    p_increment INTEGER DEFAULT 1
) RETURNS TABLE (
    can_perform BOOLEAN,
    current_count INTEGER,
    daily_limit INTEGER,
    is_premium BOOLEAN,
    reason TEXT
) AS $$
DECLARE
    user_premium BOOLEAN := false;
    swipe_limit INTEGER;
    message_limit INTEGER;
    current_usage RECORD;
    check_result BOOLEAN;
BEGIN
    -- Vérifier statut premium selon spécifications
    SELECT u.is_premium INTO user_premium
    FROM users u 
    WHERE u.id = p_user_id 
        AND (u.premium_expires_at IS NULL OR u.premium_expires_at > NOW());
    
    -- Définir limites selon spécifications
    IF user_premium THEN
        swipe_limit := 100;    -- Premium: 100 swipes/jour
        message_limit := 500;  -- Premium: 500 messages/jour
    ELSE
        swipe_limit := 10;     -- Gratuit: 10 swipes/jour  
        message_limit := 50;   -- Gratuit: 50 messages/jour
    END IF;
    
    -- Récupérer usage actuel
    SELECT swipe_count, message_count INTO current_usage
    FROM daily_usage 
    WHERE user_id = p_user_id AND date = CURRENT_DATE;
    
    IF current_usage IS NULL THEN
        current_usage.swipe_count := 0;
        current_usage.message_count := 0;
    END IF;
    
    -- Appeler fonction check_and_increment selon spécifications
    IF p_action = 'swipe' THEN
        check_result := check_and_increment_usage(
            p_user_id, swipe_limit, message_limit, p_increment, 0
        );
        
        RETURN QUERY SELECT 
            check_result,
            current_usage.swipe_count,
            swipe_limit,
            user_premium,
            CASE WHEN check_result THEN 'Quota available' 
                 ELSE 'Daily swipe limit exceeded' END;
                 
    ELSIF p_action = 'message' THEN
        check_result := check_and_increment_usage(
            p_user_id, swipe_limit, message_limit, 0, p_increment
        );
        
        RETURN QUERY SELECT 
            check_result,
            current_usage.message_count,
            message_limit,
            user_premium,
            CASE WHEN check_result THEN 'Quota available'
                 ELSE 'Daily message limit exceeded' END;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 4. GESTION DES BOOSTS SELON SPÉCIFICATIONS
-- ============================================================================

-- Compléter table boosts si nécessaire
DO $$
BEGIN
    -- Ajouter stripe_checkout_session_id si pas présent
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'boosts' AND column_name = 'stripe_checkout_session_id'
    ) THEN
        ALTER TABLE boosts ADD COLUMN stripe_checkout_session_id VARCHAR(255);
        CREATE INDEX IF NOT EXISTS idx_boosts_stripe_session ON boosts(stripe_checkout_session_id);
    END IF;
END $$;

-- Fonction pour boost purchase selon spécifications
CREATE OR REPLACE FUNCTION create_boost_from_checkout(
    p_user_id UUID,
    p_station_id UUID,
    p_stripe_session_id VARCHAR(255),
    p_boost_duration_days INTEGER DEFAULT 7,
    p_amount_cents INTEGER,
    p_currency VARCHAR(3) DEFAULT 'EUR'
) RETURNS UUID AS $$
DECLARE
    boost_id UUID;
    starts_at TIMESTAMPTZ := NOW();
    ends_at TIMESTAMPTZ := NOW() + INTERVAL '1 day' * p_boost_duration_days;
BEGIN
    -- Insérer boost selon spécifications
    INSERT INTO boosts (
        user_id,
        station_id, 
        starts_at,
        ends_at,
        stripe_checkout_session_id,
        amount_paid_cents,
        currency,
        is_active
    ) VALUES (
        p_user_id,
        p_station_id,
        starts_at,
        ends_at,
        p_stripe_session_id,
        p_amount_cents,
        p_currency,
        true
    ) RETURNING id INTO boost_id;
    
    RETURN boost_id;
END;
$$ LANGUAGE plpgsql;

-- Fonction filtering pour matching avec boosts actifs selon spécifications  
CREATE OR REPLACE FUNCTION get_boosted_users_at_station(
    p_station_id UUID,
    p_date TIMESTAMPTZ DEFAULT NOW()
) RETURNS TABLE (
    user_id UUID,
    username VARCHAR,
    boost_multiplier DECIMAL,
    boost_ends_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.user_id,
        u.username,
        b.boost_multiplier,
        b.ends_at
    FROM boosts b
    JOIN users u ON b.user_id = u.id
    WHERE b.station_id = p_station_id
        AND b.is_active = true
        AND p_date BETWEEN b.starts_at AND b.ends_at
        AND u.is_active = true
        AND u.is_banned = false
    ORDER BY b.boost_multiplier DESC, b.ends_at ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- RLS POLICIES SELON SPÉCIFICATIONS
-- ============================================================================

-- RLS sur daily_usage
ALTER TABLE daily_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_usage_only" ON daily_usage
FOR ALL TO authenticated
USING (auth.uid() = user_id);

-- RLS sur subscriptions selon spécifications (utilisateur ne voit que son abonnement)
-- Politique déjà existante, vérification
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'subscriptions' 
        AND policyname = 'users_own_subscriptions_only'
    ) THEN
        CREATE POLICY "users_own_subscriptions_only" ON subscriptions
        FOR SELECT TO authenticated
        USING (auth.uid() = user_id);
    END IF;
END $$;

-- Service role policies pour webhook updates
CREATE POLICY "service_role_manage_subscriptions" ON subscriptions
FOR ALL TO service_role
WITH CHECK (true);

CREATE POLICY "service_role_manage_usage" ON daily_usage
FOR ALL TO service_role  
WITH CHECK (true);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE daily_usage IS 'Daily usage tracking for swipes and messages per user with exact Week 7 specifications';
COMMENT ON FUNCTION check_and_increment_usage(UUID, INT, INT, INT, INT) IS 'Week 7 quota function with advisory lock and exact specifications';
COMMENT ON FUNCTION get_user_limits_and_check(UUID, VARCHAR, INTEGER) IS 'Helper for gatekeeper Edge Function - checks premium status and applies limits';
COMMENT ON FUNCTION create_boost_from_checkout(UUID, UUID, VARCHAR, INTEGER, INTEGER, VARCHAR) IS 'Creates boost from Stripe checkout session';
COMMENT ON FUNCTION get_boosted_users_at_station(UUID, TIMESTAMPTZ) IS 'Returns users with active boosts at station for priority matching';

DO $$
BEGIN
    RAISE NOTICE '🎯 Week 7 Exact Specifications Implementation Complete!';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Components:';
    RAISE NOTICE '  ✅ daily_usage table with exact structure (user_id, date, swipe_count, message_count)';
    RAISE NOTICE '  ✅ check_and_increment_usage() with advisory lock and rate limiting';
    RAISE NOTICE '  ✅ Premium limits: 100 swipes/500 messages vs Free: 10 swipes/50 messages';
    RAISE NOTICE '  ✅ Boost management with stripe_checkout_session_id tracking';
    RAISE NOTICE '  ✅ RLS policies: users see only own subscriptions and usage';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Test functions:';
    RAISE NOTICE '  • SELECT * FROM get_user_limits_and_check(user_id, ''swipe'', 1);';
    RAISE NOTICE '  • SELECT check_and_increment_usage(user_id, 10, 50, 1, 0);';
    RAISE NOTICE '  • SELECT * FROM get_boosted_users_at_station(station_id);';
END $$;
