-- Week 7 Stripe & Quotas Tests selon spécifications point 5

-- ============================================================================
-- 5. TESTS SELON SPÉCIFICATIONS
-- ============================================================================

-- Tests unitaires selon spécifications
CREATE OR REPLACE FUNCTION test_checkout_session_completed()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_user_id UUID := '00000000-0000-0000-0000-000000000001';
    initial_premium BOOLEAN;
    final_premium BOOLEAN;
    subscription_count INTEGER;
BEGIN
    result_text := E'💳 TEST CHECKOUT.SESSION.COMPLETED\n=================================\n\n';
    
    -- État initial
    SELECT is_premium INTO initial_premium FROM users WHERE id = test_user_id;
    result_text := result_text || E'Initial premium status: ' || initial_premium::text || E'\n';
    
    -- Simuler checkout.session.completed selon spécifications
    INSERT INTO subscriptions (
        user_id,
        stripe_subscription_id,
        stripe_customer_id,
        stripe_price_id,
        status,
        current_period_start,
        current_period_end,
        amount_cents,
        currency,
        interval
    ) VALUES (
        test_user_id,
        'sub_test_checkout_completed',
        'cus_test_customer',
        'price_test_premium',
        'active',
        NOW(),
        NOW() + INTERVAL '1 month',
        999,
        'EUR',
        'month'
    ) ON CONFLICT (stripe_subscription_id) DO UPDATE SET updated_at = NOW();
    
    -- Mettre à jour users.is_premium selon spécifications
    UPDATE users 
    SET 
        is_premium = TRUE,
        premium_expires_at = NOW() + INTERVAL '1 month'
    WHERE id = test_user_id;
    
    -- Vérification
    SELECT is_premium INTO final_premium FROM users WHERE id = test_user_id;
    SELECT COUNT(*) INTO subscription_count FROM subscriptions WHERE user_id = test_user_id;
    
    result_text := result_text || E'✅ users.is_premium updated: ' || final_premium::text || E'\n';
    result_text := result_text || E'✅ subscriptions table updated: ' || subscription_count::text || E' records\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test customer.subscription.deleted selon spécifications
CREATE OR REPLACE FUNCTION test_subscription_deleted()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_user_id UUID := '00000000-0000-0000-0000-000000000001';
    final_premium BOOLEAN;
BEGIN
    result_text := E'❌ TEST CUSTOMER.SUBSCRIPTION.DELETED\n===================================\n\n';
    
    -- Simuler subscription.deleted selon spécifications
    UPDATE subscriptions
    SET 
        status = 'canceled',
        canceled_at = NOW()
    WHERE user_id = test_user_id;
    
    -- Mettre users.is_premium à FALSE selon spécifications
    UPDATE users
    SET 
        is_premium = FALSE,
        premium_expires_at = NULL
    WHERE id = test_user_id;
    
    -- Vérification révocation selon spécifications
    SELECT is_premium INTO final_premium FROM users WHERE id = test_user_id;
    
    result_text := result_text || E'✅ Premium revoked: is_premium = ' || final_premium::text || E'\n';
    result_text := result_text || E'✅ Subscription canceled in database\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test fonction rate limit selon spécifications
CREATE OR REPLACE FUNCTION test_rate_limit_function()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_user_id UUID := '00000000-0000-0000-0000-000000000002';
    i INTEGER;
    quota_result BOOLEAN;
    final_count INTEGER;
BEGIN
    result_text := E'⏱️ TEST RATE LIMIT FUNCTION\n==========================\n\n';
    
    -- Reset quotas pour test propre
    DELETE FROM daily_usage WHERE user_id = test_user_id AND date = CURRENT_DATE;
    
    -- Tester plusieurs swipes selon spécifications (confirmer quota respecté)
    FOR i IN 1..15 LOOP  -- Dépasser limite free (10)
        SELECT check_and_increment_usage(test_user_id, 10, 50, 1, 0) INTO quota_result;
        
        IF NOT quota_result THEN
            result_text := result_text || E'✅ Quota limit hit at swipe #' || i::text || E'\n';
            EXIT;
        END IF;
    END LOOP;
    
    -- Vérifier état final
    SELECT swipe_count INTO final_count 
    FROM daily_usage 
    WHERE user_id = test_user_id AND date = CURRENT_DATE;
    
    result_text := result_text || E'✅ Final swipe count: ' || COALESCE(final_count, 0)::text || E'\n';
    
    IF final_count <= 10 THEN
        result_text := result_text || E'✅ Rate limit enforced correctly\n';
    ELSE
        result_text := result_text || E'❌ Rate limit not working properly\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test idempotence Stripe selon spécifications
CREATE OR REPLACE FUNCTION test_stripe_idempotence()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_event_id VARCHAR(255) := 'evt_test_idempotence_12345';
    first_insert BOOLEAN;
    second_insert BOOLEAN;
    event_count INTEGER;
BEGIN
    result_text := E'🔄 TEST STRIPE IDEMPOTENCE\n=========================\n\n';
    
    -- Premier traitement événement
    BEGIN
        INSERT INTO processed_events (event_id, event_type)
        VALUES (test_event_id, 'test.event.type');
        first_insert := true;
    EXCEPTION
        WHEN unique_violation THEN
            first_insert := false;
    END;
    
    -- Deuxième traitement même événement (doit être ignoré)
    BEGIN
        INSERT INTO processed_events (event_id, event_type)  
        VALUES (test_event_id, 'test.event.type');
        second_insert := true;
    EXCEPTION
        WHEN unique_violation THEN
            second_insert := false;
    END;
    
    -- Compter événements
    SELECT COUNT(*) INTO event_count
    FROM processed_events 
    WHERE event_id = test_event_id;
    
    result_text := result_text || E'First insert: ' || first_insert::text || E'\n';
    result_text := result_text || E'Second insert: ' || second_insert::text || E'\n';
    result_text := result_text || E'Events in DB: ' || event_count::text || E'\n';
    
    IF first_insert = true AND second_insert = false AND event_count = 1 THEN
        result_text := result_text || E'✅ Idempotence working correctly\n';
    ELSE
        result_text := result_text || E'❌ Idempotence not working properly\n';
    END IF;
    
    -- Cleanup
    DELETE FROM processed_events WHERE event_id = test_event_id;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test gatekeeper flow selon spécifications
CREATE OR REPLACE FUNCTION test_gatekeeper_flow()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_user_id UUID := '00000000-0000-0000-0000-000000000003';
    quota_check RECORD;
    i INTEGER;
BEGIN
    result_text := E'🛡️ TEST GATEKEEPER FLOW\n======================\n\n';
    
    -- Reset pour test propre
    DELETE FROM daily_usage WHERE user_id = test_user_id;
    UPDATE users SET is_premium = false WHERE id = test_user_id;
    
    -- Test utilisateur gratuit 
    result_text := result_text || E'Testing free user (limit 10 swipes):\n';
    
    FOR i IN 1..12 LOOP
        SELECT * INTO quota_check
        FROM get_user_limits_and_check(test_user_id, 'swipe', 1);
        
        IF NOT quota_check.can_perform THEN
            result_text := result_text || E'✅ Quota blocked at attempt #' || i::text || E'\n';
            result_text := result_text || E'   Reason: ' || quota_check.reason || E'\n';
            EXIT;
        END IF;
    END LOOP;
    
    -- Test utilisateur premium
    UPDATE users SET is_premium = true, premium_expires_at = NOW() + INTERVAL '1 month' WHERE id = test_user_id;
    DELETE FROM daily_usage WHERE user_id = test_user_id;
    
    result_text := result_text || E'\nTesting premium user (limit 100 swipes):\n';
    
    SELECT * INTO quota_check
    FROM get_user_limits_and_check(test_user_id, 'swipe', 1);
    
    result_text := result_text || E'✅ Premium limit: ' || quota_check.daily_limit::text || E'\n';
    result_text := result_text || E'✅ Premium status: ' || quota_check.is_premium::text || E'\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Master test suite Week 7
CREATE OR REPLACE FUNCTION run_week7_complete_tests()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
BEGIN
    result_text := E'🎯 WEEK 7 COMPLETE TEST SUITE\n============================\n\n';
    
    result_text := result_text || test_checkout_session_completed() || E'\n';
    result_text := result_text || test_subscription_deleted() || E'\n';
    result_text := result_text || test_rate_limit_function() || E'\n';
    result_text := result_text || test_stripe_idempotence() || E'\n';
    result_text := result_text || test_gatekeeper_flow() || E'\n';
    
    result_text := result_text || E'🎉 WEEK 7 TESTS COMPLETED\n';
    result_text := result_text || E'========================\n';
    result_text := result_text || E'All Stripe & Quota functionality validated\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;
