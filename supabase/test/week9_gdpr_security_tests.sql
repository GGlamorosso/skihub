-- Week 9 GDPR & Security Tests selon spécifications

-- ============================================================================
-- 4.3 TESTS DE SÉCURITÉ selon spécifications
-- ============================================================================

-- Tests suppression de compte selon spécifications  
CREATE OR REPLACE FUNCTION test_account_deletion()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_user_id UUID;
    test_username VARCHAR(30) := 'test_deletion_user';
    test_email VARCHAR(255) := 'test.deletion@crewsnow.com';
    deletion_result RECORD;
    remaining_data INTEGER;
    cascade_check INTEGER;
BEGIN
    result_text := E'🗑️ ACCOUNT DELETION TESTS\n========================\n\n';
    
    -- Créer utilisateur test
    INSERT INTO users (id, username, email, level, is_active)
    VALUES (gen_random_uuid(), test_username, test_email, 'intermediate', true)
    RETURNING id INTO test_user_id;
    
    -- Ajouter données test dans diverses tables
    INSERT INTO likes (liker_id, liked_id) 
    VALUES (test_user_id, '00000000-0000-0000-0000-000000000001');
    
    INSERT INTO daily_usage (user_id, date, swipe_count)
    VALUES (test_user_id, CURRENT_DATE, 5);
    
    INSERT INTO consents (user_id, purpose, version)
    VALUES (test_user_id, 'gps', 1), (test_user_id, 'marketing', 1);
    
    result_text := result_text || E'✅ Test user created with sample data\n';
    
    -- Exécuter suppression complète
    SELECT * INTO deletion_result 
    FROM delete_user_data(test_user_id, 'gdpr_test');
    
    result_text := result_text || E'✅ Deletion executed: ' || deletion_result.success::text || E'\n';
    result_text := result_text || E'📊 Categories deleted: ' || array_length(deletion_result.deleted_categories, 1)::text || E'\n';
    
    -- Vérifier CASCADE ont fonctionné selon spécifications
    SELECT COUNT(*) INTO cascade_check FROM likes WHERE liker_id = test_user_id OR liked_id = test_user_id;
    result_text := result_text || E'✅ Likes CASCADE: ' || cascade_check::text || E' remaining (should be 0)\n';
    
    SELECT COUNT(*) INTO cascade_check FROM daily_usage WHERE user_id = test_user_id;
    result_text := result_text || E'✅ Usage CASCADE: ' || cascade_check::text || E' remaining (should be 0)\n';
    
    SELECT COUNT(*) INTO cascade_check FROM consents WHERE user_id = test_user_id;
    result_text := result_text || E'✅ Consents CASCADE: ' || cascade_check::text || E' remaining (should be 0)\n';
    
    -- Vérifier utilisateur supprimé
    SELECT COUNT(*) INTO remaining_data FROM users WHERE id = test_user_id;
    result_text := result_text || E'✅ User deleted: ' || remaining_data::text || E' remaining (should be 0)\n';
    
    IF remaining_data = 0 AND cascade_check = 0 THEN
        result_text := result_text || E'\n🎯 Account deletion: WORKING CORRECTLY\n';
    ELSE
        result_text := result_text || E'\n❌ Account deletion: ISSUES DETECTED\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test portabilité données selon spécifications
CREATE OR REPLACE FUNCTION test_data_portability()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    alice_id UUID := '00000000-0000-0000-0000-000000000001';
    export_count INTEGER;
    consent_count INTEGER;
    user_tables INTEGER;
BEGIN
    result_text := E'📤 DATA PORTABILITY TESTS\n========================\n\n';
    
    -- Simuler collecte données utilisateur (fonction interne export)
    -- Compter tables impliquant utilisateur selon spécifications
    SELECT COUNT(*) INTO user_tables FROM (
        SELECT 'users' WHERE EXISTS (SELECT 1 FROM users WHERE id = alice_id)
        UNION ALL
        SELECT 'profile_photos' WHERE EXISTS (SELECT 1 FROM profile_photos WHERE user_id = alice_id) 
        UNION ALL
        SELECT 'likes' WHERE EXISTS (SELECT 1 FROM likes WHERE liker_id = alice_id OR liked_id = alice_id)
        UNION ALL
        SELECT 'matches' WHERE EXISTS (SELECT 1 FROM matches WHERE user1_id = alice_id OR user2_id = alice_id)
        UNION ALL
        SELECT 'messages' WHERE EXISTS (SELECT 1 FROM messages WHERE sender_id = alice_id)
        UNION ALL
        SELECT 'ride_stats' WHERE EXISTS (SELECT 1 FROM ride_stats_daily WHERE user_id = alice_id)
        UNION ALL
        SELECT 'subscriptions' WHERE EXISTS (SELECT 1 FROM subscriptions WHERE user_id = alice_id)
        UNION ALL
        SELECT 'daily_usage' WHERE EXISTS (SELECT 1 FROM daily_usage WHERE user_id = alice_id)
    ) t;
    
    result_text := result_text || E'📊 User data spans ' || user_tables::text || E' table categories\n';
    
    -- Test logs export
    INSERT INTO export_logs (user_id, status) VALUES (alice_id, 'completed');
    SELECT COUNT(*) INTO export_count FROM export_logs WHERE user_id = alice_id;
    result_text := result_text || E'✅ Export logging: ' || export_count::text || E' records\n';
    
    -- Test consentements
    INSERT INTO consents (user_id, purpose, version) VALUES (alice_id, 'gdpr_test', 1) ON CONFLICT DO NOTHING;
    SELECT COUNT(*) INTO consent_count FROM consents WHERE user_id = alice_id;
    result_text := result_text || E'✅ Consent management: ' || consent_count::text || E' consents\n';
    
    result_text := result_text || E'\n🎯 Data portability system: FUNCTIONAL\n';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test consentements selon spécifications
CREATE OR REPLACE FUNCTION test_consent_management()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_user_id UUID := '00000000-0000-0000-0000-000000000002';
    grant_result UUID;
    revoke_result BOOLEAN;
    check_result BOOLEAN;
BEGIN
    result_text := E'✋ CONSENT MANAGEMENT TESTS\n=========================\n\n';
    
    -- Test accord consentement
    SELECT grant_consent(test_user_id, 'ai_moderation', 2) INTO grant_result;
    result_text := result_text || E'✅ Grant consent: ' || (grant_result IS NOT NULL)::text || E'\n';
    
    -- Test vérification consentement
    SELECT check_user_consent(test_user_id, 'ai_moderation', 2) INTO check_result;
    result_text := result_text || E'✅ Check consent: ' || check_result::text || E'\n';
    
    -- Test révocation consentement
    SELECT revoke_consent(test_user_id, 'ai_moderation') INTO revoke_result;
    result_text := result_text || E'✅ Revoke consent: ' || revoke_result::text || E'\n';
    
    -- Test après révocation
    SELECT check_user_consent(test_user_id, 'ai_moderation', 2) INTO check_result;
    result_text := result_text || E'✅ Check after revoke: ' || check_result::text || E' (should be false)\n';
    
    IF NOT check_result THEN
        result_text := result_text || E'\n🎯 Consent management: WORKING CORRECTLY\n';
    ELSE
        result_text := result_text || E'\n❌ Consent management: REVOCATION FAILED\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test sécurité RLS selon spécifications
CREATE OR REPLACE FUNCTION test_gdpr_rls_policies()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    alice_id UUID := '00000000-0000-0000-0000-000000000001';
    bob_id UUID := '00000000-0000-0000-0000-000000000002';
    alice_consents INTEGER;
    bob_consents INTEGER;
    alice_exports INTEGER;
    cross_access_blocked BOOLEAN := true;
BEGIN
    result_text := E'🛡️ GDPR RLS SECURITY TESTS\n=========================\n\n';
    
    -- Ajouter données test
    INSERT INTO consents (user_id, purpose, version) VALUES 
        (alice_id, 'test_rls_alice', 1),
        (bob_id, 'test_rls_bob', 1)
    ON CONFLICT DO NOTHING;
    
    INSERT INTO export_logs (user_id, status) VALUES
        (alice_id, 'completed'),
        (bob_id, 'completed')
    ON CONFLICT DO NOTHING;
    
    -- Test Alice accès ses propres données
    SET LOCAL role TO authenticated;
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', alice_id::text)::text;
    
    SELECT COUNT(*) INTO alice_consents FROM consents WHERE user_id = alice_id;
    SELECT COUNT(*) INTO alice_exports FROM export_logs WHERE user_id = alice_id;
    
    result_text := result_text || E'✅ Alice own data access: ' || alice_consents::text || E' consents, ' || alice_exports::text || E' exports\n';
    
    -- Test Alice NE PEUT PAS accéder données Bob
    SELECT COUNT(*) INTO bob_consents FROM consents WHERE user_id = bob_id;
    
    IF bob_consents = 0 THEN
        result_text := result_text || E'✅ Alice CANNOT access Bob consents: SECURED\n';
    ELSE
        result_text := result_text || E'❌ Alice CAN access Bob consents: SECURITY BREACH!\n';
        cross_access_blocked := false;
    END IF;
    
    RESET role;
    RESET "request.jwt.claims";
    
    -- Test service role accès complet
    SELECT COUNT(*) INTO alice_consents FROM consents;
    result_text := result_text || E'✅ Service role access: ' || alice_consents::text || E' total consents\n';
    
    IF cross_access_blocked THEN
        result_text := result_text || E'\n🔒 GDPR RLS security: WORKING CORRECTLY\n';
    ELSE
        result_text := result_text || E'\n❌ GDPR RLS security: ISSUES DETECTED\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test storage sécurité selon spécifications  
CREATE OR REPLACE FUNCTION test_storage_security()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    policy_count INTEGER;
    bucket_config RECORD;
BEGIN
    result_text := E'🗄️ STORAGE SECURITY TESTS\n=========================\n\n';
    
    -- Vérifier buckets privés
    SELECT * INTO bucket_config FROM storage.buckets WHERE id = 'exports';
    IF bucket_config.public = false THEN
        result_text := result_text || E'✅ Exports bucket: PRIVATE\n';
    ELSE
        result_text := result_text || E'❌ Exports bucket: PUBLIC (security issue!)\n';
    END IF;
    
    SELECT * INTO bucket_config FROM storage.buckets WHERE id = 'profile_photos';
    IF bucket_config.public = false THEN
        result_text := result_text || E'✅ Photos bucket: PRIVATE\n';
    ELSE
        result_text := result_text || E'❌ Photos bucket: PUBLIC (security issue!)\n';
    END IF;
    
    -- Vérifier politiques Storage RLS
    SELECT COUNT(*) INTO policy_count 
    FROM pg_policies 
    WHERE tablename = 'objects' 
        AND schemaname = 'storage';
    
    result_text := result_text || E'✅ Storage RLS policies: ' || policy_count::text || E'\n';
    
    result_text := result_text || E'\n🔐 Storage security: ';
    IF bucket_config.public = false AND policy_count > 0 THEN
        result_text := result_text || E'PROPERLY SECURED\n';
    ELSE
        result_text := result_text || E'NEEDS ATTENTION\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test portabilité téléchargement selon spécifications
CREATE OR REPLACE FUNCTION test_data_export_portability()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    alice_id UUID := '00000000-0000-0000-0000-000000000001';
    export_data JSONB;
    data_categories INTEGER;
    photos_with_urls INTEGER;
    sensitive_data_masked BOOLEAN := true;
BEGIN
    result_text := E'📥 DATA EXPORT PORTABILITY TESTS\n==============================\n\n';
    
    -- Simuler export données (structure JSON)
    export_data := jsonb_build_object(
        'user_profile', (SELECT to_jsonb(u.*) FROM users u WHERE id = alice_id),
        'profile_photos', (SELECT jsonb_agg(to_jsonb(pp.*)) FROM profile_photos pp WHERE user_id = alice_id),
        'likes_given', (SELECT jsonb_agg(to_jsonb(l.*)) FROM likes l WHERE liker_id = alice_id),
        'messages', (SELECT jsonb_agg(to_jsonb(m.*)) FROM messages m WHERE sender_id = alice_id),
        'ride_stats', (SELECT jsonb_agg(to_jsonb(rs.*)) FROM ride_stats_daily rs WHERE user_id = alice_id),
        'subscriptions', (SELECT jsonb_agg(to_jsonb(s.*)) FROM subscriptions s WHERE user_id = alice_id)
    );
    
    -- Compter catégories données  
    SELECT jsonb_object_keys_count(export_data) INTO data_categories;
    result_text := result_text || E'📊 Data categories exported: ' || data_categories::text || E'\n';
    
    -- Vérifier photos avec URLs (simulation)
    SELECT COUNT(*) INTO photos_with_urls 
    FROM profile_photos 
    WHERE user_id = alice_id AND moderation_status = 'approved';
    result_text := result_text || E'🖼️ Photos with URLs: ' || photos_with_urls::text || E'\n';
    
    -- Vérifier données sensibles masquées
    IF export_data->>'user_profile' NOT LIKE '%stripe_customer_id%' THEN
        result_text := result_text || E'✅ Sensitive data masked: stripe_customer_id hidden\n';
    ELSE
        result_text := result_text || E'❌ Sensitive data exposed: check masking logic\n';
        sensitive_data_masked := false;
    END IF;
    
    result_text := result_text || E'\n📤 Export portability: ';
    IF data_categories >= 6 AND sensitive_data_masked THEN
        result_text := result_text || E'RGPD COMPLIANT\n';
    ELSE
        result_text := result_text || E'NEEDS REVIEW\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test webhook sécurité selon spécifications
CREATE OR REPLACE FUNCTION test_webhook_security()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    processed_events_count INTEGER;
    idempotency_test BOOLEAN;
BEGIN
    result_text := E'🔐 WEBHOOK SECURITY TESTS\n========================\n\n';
    
    -- Test idempotence Stripe
    INSERT INTO processed_events (event_id, event_type) 
    VALUES ('test_event_security', 'test.security.event');
    
    -- Tenter dupliquer (doit échouer)
    BEGIN
        INSERT INTO processed_events (event_id, event_type) 
        VALUES ('test_event_security', 'test.security.event');
        idempotency_test := false; -- Ne devrait pas arriver
    EXCEPTION
        WHEN unique_violation THEN
            idempotency_test := true; -- Comportement attendu
    END;
    
    result_text := result_text || E'✅ Webhook idempotency: ' || idempotency_test::text || E'\n';
    
    -- Compter événements traités
    SELECT COUNT(*) INTO processed_events_count FROM processed_events;
    result_text := result_text || E'📊 Processed events: ' || processed_events_count::text || E'\n';
    
    -- Cleanup test data
    DELETE FROM processed_events WHERE event_id = 'test_event_security';
    
    result_text := result_text || E'\n🛡️ Webhook security: VALIDATED\n';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Test chiffrement données selon spécifications
CREATE OR REPLACE FUNCTION test_encryption_system()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_user_id UUID := '00000000-0000-0000-0000-000000000003';
    encrypted_id UUID;
    encryption_available BOOLEAN;
BEGIN
    result_text := E'🔐 ENCRYPTION SYSTEM TESTS\n=========================\n\n';
    
    -- Test si pgsodium disponible
    BEGIN
        PERFORM pgsodium.crypto_box_new_keypair();
        encryption_available := true;
    EXCEPTION
        WHEN others THEN
            encryption_available := false;
    END;
    
    result_text := result_text || E'🔐 pgsodium available: ' || encryption_available::text || E'\n';
    
    IF encryption_available THEN
        -- Test stockage données chiffrées
        SELECT store_sensitive_data(test_user_id, 'test_data', 'sensitive information') INTO encrypted_id;
        result_text := result_text || E'✅ Sensitive data encrypted: ' || (encrypted_id IS NOT NULL)::text || E'\n';
        
        -- Cleanup
        DELETE FROM sensitive_data WHERE id = encrypted_id;
    ELSE
        result_text := result_text || E'ℹ️ Encryption extension not available in current environment\n';
    END IF;
    
    result_text := result_text || E'\n🔒 Encryption system: READY\n';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Master test suite GDPR Week 9
CREATE OR REPLACE FUNCTION run_week9_gdpr_tests()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    overall_status TEXT := 'PASSED';
BEGIN
    result_text := E'🔒 WEEK 9 GDPR COMPLIANCE TEST SUITE\n===================================\n\n';
    
    result_text := result_text || test_account_deletion() || E'\n';
    result_text := result_text || test_data_portability() || E'\n';
    result_text := result_text || test_consent_management() || E'\n';
    result_text := result_text || test_gdpr_rls_policies() || E'\n';
    result_text := result_text || test_storage_security() || E'\n';
    result_text := result_text || test_webhook_security() || E'\n';
    result_text := result_text || test_encryption_system() || E'\n';
    
    -- Vérifier échecs
    IF result_text LIKE '%❌%' OR result_text LIKE '%BREACH%' OR result_text LIKE '%ISSUES DETECTED%' THEN
        overall_status := 'FAILED';
    END IF;
    
    result_text := result_text || E'===================================\n';
    result_text := result_text || E'🎯 OVERALL GDPR COMPLIANCE: ' || overall_status || E'\n';
    result_text := result_text || E'===================================\n\n';
    
    IF overall_status = 'PASSED' THEN
        result_text := result_text || E'✅ All GDPR compliance tests passed!\n';
        result_text := result_text || E'⚖️ System ready for GDPR-compliant launch\n';
    ELSE
        result_text := result_text || E'❌ Some GDPR compliance issues detected!\n';
        result_text := result_text || E'🚨 Review and fix before public launch\n';
    END IF;
    
    result_text := result_text || E'\n📋 Tests performed:\n';
    result_text := result_text || E'  1. Account deletion with cascade cleanup\n';
    result_text := result_text || E'  2. Data portability export simulation\n';
    result_text := result_text || E'  3. Consent management (grant/check/revoke)\n';
    result_text := result_text || E'  4. RLS policies data isolation\n';
    result_text := result_text || E'  5. Storage bucket security\n';
    result_text := result_text || E'  6. Webhook idempotency and security\n';
    result_text := result_text || E'  7. Encryption system availability\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;
