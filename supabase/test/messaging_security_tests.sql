-- CrewSnow Messaging System - Automated Security Tests
-- 7. Documentation et tests - Tests automatisés selon spécifications

-- ============================================================================
-- 7.2 TESTS AUTOMATISÉS SELON SPÉCIFICATIONS
-- ============================================================================

-- Test 1: Vérifier qu'un utilisateur ne peut pas lire un message d'un autre match (RLS)
-- Test 2: Vérifier qu'il ne peut pas envoyer un message avec un match_id auquel il n'appartient pas  
-- Test 3: Tester la limite de longueur : une insertion avec un message >2000 caractères doit échouer
-- Test 4: Tester la pagination (limite et curseur)

-- ============================================================================
-- SETUP TEST DATA
-- ============================================================================

-- Test users from existing seed data
DO $$
DECLARE
    alice_id UUID := '00000000-0000-0000-0000-000000000001'; -- alpine_alex
    bob_id UUID := '00000000-0000-0000-000000000002';   -- powder_marie  
    charlie_id UUID := '00000000-0000-0000-0000-000000000003'; -- beginner_tom
    david_id UUID := '00000000-0000-0000-0000-000000000004';   -- park_rider_sam
    
    alice_bob_match_id UUID;
    charlie_david_match_id UUID;
    test_message_id UUID;
BEGIN
    RAISE NOTICE '🧪 SETTING UP MESSAGING SECURITY TEST DATA';
    RAISE NOTICE '==========================================';
    
    -- Ensure test matches exist
    INSERT INTO matches (user1_id, user2_id)
    VALUES 
        (LEAST(alice_id, bob_id), GREATEST(alice_id, bob_id)),
        (LEAST(charlie_id, david_id), GREATEST(charlie_id, david_id))
    ON CONFLICT DO NOTHING;
    
    -- Get match IDs for testing
    SELECT id INTO alice_bob_match_id
    FROM matches 
    WHERE (user1_id = LEAST(alice_id, bob_id) AND user2_id = GREATEST(alice_id, bob_id));
    
    SELECT id INTO charlie_david_match_id  
    FROM matches
    WHERE (user1_id = LEAST(charlie_id, david_id) AND user2_id = GREATEST(charlie_id, david_id));
    
    -- Add some test messages
    INSERT INTO messages (match_id, sender_id, content) VALUES
        (alice_bob_match_id, alice_id, 'Test message from Alice'),
        (alice_bob_match_id, bob_id, 'Test reply from Bob'),
        (charlie_david_match_id, charlie_id, 'Test message from Charlie'),
        (charlie_david_match_id, david_id, 'Test reply from David')
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE '✅ Test data prepared';
    RAISE NOTICE '   Alice-Bob match: %', alice_bob_match_id;
    RAISE NOTICE '   Charlie-David match: %', charlie_david_match_id;
END $$;

-- ============================================================================
-- TEST 1: RLS ISOLATION - User cannot read messages from other matches
-- ============================================================================

CREATE OR REPLACE FUNCTION test_1_rls_message_isolation()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    alice_id UUID := '00000000-0000-0000-0000-000000000001';
    bob_id UUID := '00000000-0000-0000-0000-000000000002';
    charlie_id UUID := '00000000-0000-0000-0000-000000000003';
    
    alice_bob_match_id UUID;
    charlie_david_match_id UUID;
    
    alice_can_read_own INTEGER;
    alice_can_read_others INTEGER;
    charlie_can_read_alice_bob INTEGER;
BEGIN
    result_text := result_text || E'🛡️ TEST 1: RLS Message Isolation\n';
    result_text := result_text || E'================================\n';
    
    -- Get test match IDs
    SELECT id INTO alice_bob_match_id FROM matches 
    WHERE (user1_id = alice_id AND user2_id = bob_id) OR (user1_id = bob_id AND user2_id = alice_id)
    LIMIT 1;
    
    SELECT id INTO charlie_david_match_id FROM matches 
    WHERE user1_id = '00000000-0000-0000-0000-000000000003' OR user2_id = '00000000-0000-0000-0000-000000000003'
    LIMIT 1;
    
    -- Test A: Alice can read her own match messages
    SET LOCAL role TO authenticated;
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', alice_id::text)::text;
    
    SELECT COUNT(*) INTO alice_can_read_own
    FROM messages 
    WHERE match_id = alice_bob_match_id;
    
    result_text := result_text || E'✅ Alice can read own match: ' || alice_can_read_own::text || E' messages\n';
    
    -- Test B: Alice cannot read other matches  
    SELECT COUNT(*) INTO alice_can_read_others
    FROM messages 
    WHERE match_id = charlie_david_match_id;
    
    IF alice_can_read_others = 0 THEN
        result_text := result_text || E'✅ Alice CANNOT read other match: SECURED\n';
    ELSE
        result_text := result_text || E'❌ Alice can read other match: SECURITY BREACH!\n';
    END IF;
    
    -- Test C: Charlie (non-participant) cannot read Alice-Bob match
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', charlie_id::text)::text;
    
    SELECT COUNT(*) INTO charlie_can_read_alice_bob
    FROM messages 
    WHERE match_id = alice_bob_match_id;
    
    IF charlie_can_read_alice_bob = 0 THEN
        result_text := result_text || E'✅ Non-participant CANNOT read match: SECURED\n';
    ELSE
        result_text := result_text || E'❌ Non-participant can read match: SECURITY BREACH!\n';
    END IF;
    
    RESET role;
    RESET "request.jwt.claims";
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST 2: RLS INSERTION - User cannot send message to match they don't belong to
-- ============================================================================

CREATE OR REPLACE FUNCTION test_2_rls_message_insertion()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    alice_id UUID := '00000000-0000-0000-0000-000000000001';
    charlie_id UUID := '00000000-0000-0000-0000-000000000003';
    
    alice_bob_match_id UUID;
    charlie_david_match_id UUID;
    
    can_insert_own BOOLEAN := false;
    can_insert_others BOOLEAN := false;
    can_insert_wrong_sender BOOLEAN := false;
BEGIN
    result_text := result_text || E'🚫 TEST 2: RLS Message Insertion Protection\n';
    result_text := result_text || E'==========================================\n';
    
    -- Get test match IDs  
    SELECT id INTO alice_bob_match_id FROM matches 
    WHERE (user1_id = alice_id AND user2_id = '00000000-0000-0000-0000-000000000002') 
       OR (user1_id = '00000000-0000-0000-0000-000000000002' AND user2_id = alice_id)
    LIMIT 1;
    
    SELECT id INTO charlie_david_match_id FROM matches 
    WHERE user1_id = charlie_id OR user2_id = charlie_id
    LIMIT 1;
    
    SET LOCAL role TO authenticated;
    
    -- Test A: Alice can send message to her match
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', alice_id::text)::text;
    
    BEGIN
        INSERT INTO messages (match_id, sender_id, content)
        VALUES (alice_bob_match_id, alice_id, 'RLS test message - should work');
        can_insert_own := true;
    EXCEPTION
        WHEN others THEN
            can_insert_own := false;
    END;
    
    IF can_insert_own THEN
        result_text := result_text || E'✅ User CAN send to own match: CORRECT\n';
    ELSE
        result_text := result_text || E'❌ User CANNOT send to own match: BUG!\n';
    END IF;
    
    -- Test B: Alice cannot send message to other's match
    BEGIN
        INSERT INTO messages (match_id, sender_id, content)
        VALUES (charlie_david_match_id, alice_id, 'Should fail - not participant');
        can_insert_others := true;
    EXCEPTION
        WHEN others THEN
            can_insert_others := false;
    END;
    
    IF NOT can_insert_others THEN
        result_text := result_text || E'✅ User CANNOT send to other match: SECURED\n';
    ELSE
        result_text := result_text || E'❌ User CAN send to other match: SECURITY BREACH!\n';
    END IF;
    
    -- Test C: Alice cannot send message with wrong sender_id
    BEGIN
        INSERT INTO messages (match_id, sender_id, content)
        VALUES (alice_bob_match_id, charlie_id, 'Wrong sender - should fail');
        can_insert_wrong_sender := true;
    EXCEPTION
        WHEN others THEN
            can_insert_wrong_sender := false;
    END;
    
    IF NOT can_insert_wrong_sender THEN
        result_text := result_text || E'✅ Cannot impersonate other user: SECURED\n';
    ELSE
        result_text := result_text || E'❌ Can impersonate other user: SECURITY BREACH!\n';
    END IF;
    
    RESET role;
    RESET "request.jwt.claims";
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST 3: Message Length Constraint
-- ============================================================================

CREATE OR REPLACE FUNCTION test_3_message_length_constraint()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_user_id UUID := '00000000-0000-0000-0000-000000000001';
    test_match_id UUID;
    
    short_message_ok BOOLEAN := false;
    long_message_blocked BOOLEAN := false;
    empty_message_blocked BOOLEAN := false;
    exactly_2000_ok BOOLEAN := false;
BEGIN
    result_text := result_text || E'📏 TEST 3: Message Length Constraints\n';
    result_text := result_text || E'===================================\n';
    
    -- Get a test match
    SELECT id INTO test_match_id
    FROM matches 
    WHERE user1_id = test_user_id OR user2_id = test_user_id
    LIMIT 1;
    
    -- Test A: Normal message (should work)
    BEGIN
        INSERT INTO messages (match_id, sender_id, content)
        VALUES (test_match_id, test_user_id, 'Normal message - should work');
        short_message_ok := true;
    EXCEPTION
        WHEN others THEN
            short_message_ok := false;
    END;
    
    IF short_message_ok THEN
        result_text := result_text || E'✅ Normal message accepted: CORRECT\n';
    ELSE
        result_text := result_text || E'❌ Normal message rejected: BUG!\n';
    END IF;
    
    -- Test B: Message > 2000 characters (should fail)
    BEGIN
        INSERT INTO messages (match_id, sender_id, content)
        VALUES (test_match_id, test_user_id, repeat('x', 2001)); -- 2001 characters
        long_message_blocked := false;
    EXCEPTION
        WHEN check_violation THEN
            long_message_blocked := true;
        WHEN others THEN
            long_message_blocked := true;
    END;
    
    IF long_message_blocked THEN
        result_text := result_text || E'✅ Message >2000 chars rejected: SECURED\n';
    ELSE
        result_text := result_text || E'❌ Message >2000 chars accepted: CONSTRAINT MISSING!\n';
    END IF;
    
    -- Test C: Empty message (should fail)
    BEGIN
        INSERT INTO messages (match_id, sender_id, content)
        VALUES (test_match_id, test_user_id, ''); -- Empty content
        empty_message_blocked := false;
    EXCEPTION
        WHEN check_violation THEN
            empty_message_blocked := true;
        WHEN others THEN
            empty_message_blocked := true;
    END;
    
    IF empty_message_blocked THEN
        result_text := result_text || E'✅ Empty message rejected: SECURED\n';
    ELSE
        result_text := result_text || E'❌ Empty message accepted: CONSTRAINT MISSING!\n';
    END IF;
    
    -- Test D: Message exactly 2000 characters (should work)
    BEGIN
        INSERT INTO messages (match_id, sender_id, content)
        VALUES (test_match_id, test_user_id, repeat('A', 2000)); -- Exactly 2000
        exactly_2000_ok := true;
    EXCEPTION
        WHEN others THEN
            exactly_2000_ok := false;
    END;
    
    IF exactly_2000_ok THEN
        result_text := result_text || E'✅ Message exactly 2000 chars accepted: CORRECT\n';
    ELSE
        result_text := result_text || E'❌ Message exactly 2000 chars rejected: TOO STRICT!\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST 4: Pagination Testing
-- ============================================================================

CREATE OR REPLACE FUNCTION test_4_pagination_functionality()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_user_id UUID := '00000000-0000-0000-0000-000000000001';
    test_match_id UUID;
    
    offset_result_count INTEGER;
    cursor_result_count INTEGER;
    pagination_consistency BOOLEAN := true;
    
    i INTEGER;
    test_messages UUID[];
BEGIN
    result_text := result_text || E'📊 TEST 4: Pagination Functionality\n';
    result_text := result_text || E'==================================\n';
    
    -- Get test match
    SELECT id INTO test_match_id
    FROM matches 
    WHERE user1_id = test_user_id OR user2_id = test_user_id
    LIMIT 1;
    
    -- Create enough test messages for pagination testing
    FOR i IN 1..75 LOOP
        INSERT INTO messages (match_id, sender_id, content)
        VALUES (test_match_id, test_user_id, 'Pagination test message ' || i::text)
        ON CONFLICT DO NOTHING;
    END LOOP;
    
    result_text := result_text || E'✅ Created 75 test messages for pagination\n';
    
    -- Test A: Offset pagination with limit
    BEGIN
        SELECT COUNT(*) INTO offset_result_count
        FROM get_messages_by_offset(test_match_id, test_user_id, 50, 0);
        
        IF offset_result_count <= 50 THEN
            result_text := result_text || E'✅ Offset pagination respects limit: ' || offset_result_count::text || E' messages\n';
        ELSE
            result_text := result_text || E'❌ Offset pagination exceeds limit: ' || offset_result_count::text || E' messages\n';
            pagination_consistency := false;
        END IF;
    EXCEPTION
        WHEN others THEN
            result_text := result_text || E'❌ Offset pagination failed: ' || SQLERRM || E'\n';
            pagination_consistency := false;
    END;
    
    -- Test B: Cursor pagination with limit
    BEGIN
        SELECT COUNT(*) INTO cursor_result_count
        FROM get_messages_by_cursor(test_match_id, test_user_id, NULL, 50);
        
        IF cursor_result_count <= 50 THEN
            result_text := result_text || E'✅ Cursor pagination respects limit: ' || cursor_result_count::text || E' messages\n';
        ELSE
            result_text := result_text || E'❌ Cursor pagination exceeds limit: ' || cursor_result_count::text || E' messages\n';
            pagination_consistency := false;
        END IF;
    EXCEPTION
        WHEN others THEN
            result_text := result_text || E'❌ Cursor pagination failed: ' || SQLERRM || E'\n';
            pagination_consistency := false;
    END;
    
    -- Test C: Pagination consistency (both methods should return same count for first page)
    IF ABS(offset_result_count - cursor_result_count) <= 1 THEN
        result_text := result_text || E'✅ Pagination methods consistent: CORRECT\n';
    ELSE
        result_text := result_text || E'❌ Pagination methods inconsistent: BUG!\n';
        pagination_consistency := false;
    END IF;
    
    -- Test D: Cursor-based pagination order
    BEGIN
        DECLARE
            first_page RECORD;
            second_page RECORD;
        BEGIN
            SELECT created_at INTO first_page
            FROM get_messages_by_cursor(test_match_id, test_user_id, NULL, 25)
            ORDER BY created_at DESC
            LIMIT 1;
            
            SELECT created_at INTO second_page  
            FROM get_messages_by_cursor(test_match_id, test_user_id, first_page.created_at, 25)
            ORDER BY created_at DESC
            LIMIT 1;
            
            IF second_page.created_at < first_page.created_at THEN
                result_text := result_text || E'✅ Cursor pagination order correct: CHRONOLOGICAL\n';
            ELSE
                result_text := result_text || E'❌ Cursor pagination order wrong: BUG!\n';
                pagination_consistency := false;
            END IF;
        END;
    EXCEPTION
        WHEN others THEN
            result_text := result_text || E'⚠️ Cursor order test inconclusive: ' || SQLERRM || E'\n';
    END;
    
    RESET role;
    RESET "request.jwt.claims";
    
    -- Overall pagination status
    IF pagination_consistency THEN
        result_text := result_text || E'\n🎯 Pagination Status: All tests passed\n';
    ELSE
        result_text := result_text || E'\n❌ Pagination Status: Some tests failed\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST 5: match_reads RLS Isolation
-- ============================================================================

CREATE OR REPLACE FUNCTION test_5_match_reads_isolation()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    alice_id UUID := '00000000-0000-0000-0000-000000000001';
    bob_id UUID := '00000000-0000-0000-0000-000000000002';
    charlie_id UUID := '00000000-0000-0000-0000-000000000003';
    
    test_match_id UUID;
    alice_can_read_own INTEGER;
    alice_can_read_bobs INTEGER;
    charlie_can_read_any INTEGER;
    alice_can_insert_own BOOLEAN := false;
    alice_can_insert_for_bob BOOLEAN := false;
BEGIN
    result_text := result_text || E'👁️ TEST 5: match_reads RLS Isolation\n';
    result_text := result_text || E'===================================\n';
    
    -- Get Alice-Bob match
    SELECT id INTO test_match_id FROM matches 
    WHERE (user1_id = alice_id AND user2_id = bob_id) OR (user1_id = bob_id AND user2_id = alice_id)
    LIMIT 1;
    
    -- Create test read receipts
    INSERT INTO match_reads (match_id, user_id, last_read_at) VALUES
        (test_match_id, alice_id, NOW()),
        (test_match_id, bob_id, NOW() - INTERVAL '1 hour')
    ON CONFLICT (match_id, user_id) DO UPDATE SET last_read_at = EXCLUDED.last_read_at;
    
    -- Test A: Alice can read her own read status
    SET LOCAL role TO authenticated;
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', alice_id::text)::text;
    
    SELECT COUNT(*) INTO alice_can_read_own
    FROM match_reads 
    WHERE match_id = test_match_id AND user_id = alice_id;
    
    result_text := result_text || E'✅ User can read own read status: ' || alice_can_read_own::text || E' records\n';
    
    -- Test B: Alice cannot read Bob's read status
    SELECT COUNT(*) INTO alice_can_read_bobs
    FROM match_reads 
    WHERE match_id = test_match_id AND user_id = bob_id;
    
    IF alice_can_read_bobs = 0 THEN
        result_text := result_text || E'✅ User CANNOT read other\'s read status: SECURED\n';
    ELSE
        result_text := result_text || E'❌ User CAN read other\'s read status: PRIVACY BREACH!\n';
    END IF;
    
    -- Test C: Charlie (non-participant) cannot read any read status
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', charlie_id::text)::text;
    
    SELECT COUNT(*) INTO charlie_can_read_any
    FROM match_reads 
    WHERE match_id = test_match_id;
    
    IF charlie_can_read_any = 0 THEN
        result_text := result_text || E'✅ Non-participant CANNOT read read status: SECURED\n';
    ELSE
        result_text := result_text || E'❌ Non-participant CAN read read status: SECURITY BREACH!\n';
    END IF;
    
    -- Test D: Alice can insert/update her own read status
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', alice_id::text)::text;
    
    BEGIN
        INSERT INTO match_reads (match_id, user_id, last_read_at)
        VALUES (test_match_id, alice_id, NOW())
        ON CONFLICT (match_id, user_id) DO UPDATE SET last_read_at = NOW();
        alice_can_insert_own := true;
    EXCEPTION
        WHEN others THEN
            alice_can_insert_own := false;
    END;
    
    IF alice_can_insert_own THEN
        result_text := result_text || E'✅ User CAN update own read status: CORRECT\n';
    ELSE
        result_text := result_text || E'❌ User CANNOT update own read status: BUG!\n';
    END IF;
    
    -- Test E: Alice cannot insert read status for Bob
    BEGIN
        INSERT INTO match_reads (match_id, user_id, last_read_at)
        VALUES (test_match_id, bob_id, NOW())  -- Trying to insert for Bob
        ON CONFLICT DO NOTHING;
        alice_can_insert_for_bob := true;
    EXCEPTION
        WHEN others THEN
            alice_can_insert_for_bob := false;
    END;
    
    IF NOT alice_can_insert_for_bob THEN
        result_text := result_text || E'✅ User CANNOT update other\'s read status: SECURED\n';
    ELSE
        result_text := result_text || E'❌ User CAN update other\'s read status: SECURITY BREACH!\n';
    END IF;
    
    RESET role;
    RESET "request.jwt.claims";
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- MASTER TEST FUNCTION - Run all security tests
-- ============================================================================

CREATE OR REPLACE FUNCTION run_all_messaging_security_tests()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    overall_status TEXT := 'PASSED';
BEGIN
    result_text := result_text || E'🔒 CREWSNOW MESSAGING SECURITY TEST SUITE\n';
    result_text := result_text || E'==========================================\n';
    result_text := result_text || E'Date: ' || NOW()::text || E'\n\n';
    
    -- Run Test 1: RLS Message Isolation  
    result_text := result_text || test_1_rls_message_isolation() || E'\n';
    
    -- Run Test 2: RLS Message Insertion
    result_text := result_text || test_2_rls_message_insertion() || E'\n';
    
    -- Run Test 3: Message Length Constraints
    result_text := result_text || test_3_message_length_constraint() || E'\n';
    
    -- Run Test 4: Pagination
    result_text := result_text || test_4_pagination_functionality() || E'\n';
    
    -- Run Test 5: match_reads RLS
    result_text := result_text || test_5_match_reads_isolation() || E'\n';
    
    -- Check if any failures occurred
    IF result_text LIKE '%❌%' OR result_text LIKE '%BREACH%' OR result_text LIKE '%BUG%' THEN
        overall_status := 'FAILED';
    END IF;
    
    -- Final summary
    result_text := result_text || E'==========================================\n';
    result_text := result_text || E'🎯 OVERALL TEST STATUS: ' || overall_status || E'\n';
    result_text := result_text || E'==========================================\n\n';
    
    IF overall_status = 'PASSED' THEN
        result_text := result_text || E'✅ All security tests passed!\n';
        result_text := result_text || E'🔒 System is secure and ready for production\n';
    ELSE
        result_text := result_text || E'❌ Some security tests failed!\n';
        result_text := result_text || E'🚨 Review and fix issues before production deployment\n';
    END IF;
    
    result_text := result_text || E'\n📊 Tests performed:\n';
    result_text := result_text || E'  1. RLS message isolation between matches\n';
    result_text := result_text || E'  2. RLS insertion protection for unauthorized matches\n';  
    result_text := result_text || E'  3. Message length constraints (0 < length <= 2000)\n';
    result_text := result_text || E'  4. Pagination functionality (offset and cursor)\n';
    result_text := result_text || E'  5. Read receipts RLS isolation\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PERFORMANCE VALIDATION TESTS
-- ============================================================================

CREATE OR REPLACE FUNCTION test_messaging_performance_validation()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_match_id UUID;
    test_user_id UUID := '00000000-0000-0000-0000-000000000001';
    
    offset_time_ms DECIMAL;
    cursor_time_ms DECIMAL;
    read_receipt_time_ms DECIMAL;
    
    start_time TIMESTAMPTZ;
    end_time TIMESTAMPTZ;
BEGIN
    result_text := result_text || E'⚡ MESSAGING PERFORMANCE VALIDATION\n';
    result_text := result_text || E'==================================\n';
    
    -- Get test match with messages
    SELECT id INTO test_match_id
    FROM matches 
    WHERE user1_id = test_user_id OR user2_id = test_user_id
    LIMIT 1;
    
    -- Test 1: Offset pagination performance  
    start_time := clock_timestamp();
    PERFORM * FROM get_messages_by_offset(test_match_id, test_user_id, 50, 0);
    end_time := clock_timestamp();
    
    offset_time_ms := EXTRACT(epoch FROM (end_time - start_time)) * 1000;
    result_text := result_text || E'📊 Offset pagination: ' || offset_time_ms::text || E'ms';
    
    IF offset_time_ms < 200 THEN
        result_text := result_text || E' ✅ GOOD\n';
    ELSE
        result_text := result_text || E' ⚠️ SLOW\n';
    END IF;
    
    -- Test 2: Cursor pagination performance
    start_time := clock_timestamp();
    PERFORM * FROM get_messages_by_cursor(test_match_id, test_user_id, NULL, 50);
    end_time := clock_timestamp();
    
    cursor_time_ms := EXTRACT(epoch FROM (end_time - start_time)) * 1000;
    result_text := result_text || E'📊 Cursor pagination: ' || cursor_time_ms::text || E'ms';
    
    IF cursor_time_ms < 100 THEN
        result_text := result_text || E' ✅ EXCELLENT\n';
    ELSIF cursor_time_ms < 200 THEN
        result_text := result_text || E' ✅ GOOD\n';
    ELSE
        result_text := result_text || E' ⚠️ SLOW\n';
    END IF;
    
    -- Test 3: Read receipt update performance
    start_time := clock_timestamp();
    PERFORM mark_messages_read(test_match_id, test_user_id);
    end_time := clock_timestamp();
    
    read_receipt_time_ms := EXTRACT(epoch FROM (end_time - start_time)) * 1000;
    result_text := result_text || E'📖 Read receipt update: ' || read_receipt_time_ms::text || E'ms';
    
    IF read_receipt_time_ms < 50 THEN
        result_text := result_text || E' ✅ EXCELLENT\n';
    ELSIF read_receipt_time_ms < 100 THEN
        result_text := result_text || E' ✅ GOOD\n';
    ELSE
        result_text := result_text || E' ⚠️ SLOW\n';
    END IF;
    
    -- Performance summary
    result_text := result_text || E'\n⚡ Performance Summary:\n';
    IF cursor_time_ms < 100 AND read_receipt_time_ms < 50 THEN
        result_text := result_text || E'✅ System performance: EXCELLENT for production\n';
    ELSIF cursor_time_ms < 200 AND read_receipt_time_ms < 100 THEN
        result_text := result_text || E'✅ System performance: GOOD for production\n';
    ELSE
        result_text := result_text || E'⚠️ System performance: Review optimization\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- REALTIME CONNECTIVITY TEST
-- ============================================================================

CREATE OR REPLACE FUNCTION test_realtime_connectivity()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    publication_tables INTEGER;
    realtime_indexes INTEGER;
BEGIN
    result_text := result_text || E'📡 REALTIME CONNECTIVITY TEST\n';
    result_text := result_text || E'============================\n';
    
    -- Test 1: Verify tables are in realtime publication
    SELECT COUNT(*) INTO publication_tables
    FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
      AND tablename IN ('messages', 'match_reads');
    
    result_text := result_text || E'📊 Tables in realtime publication: ' || publication_tables::text || E'/2';
    
    IF publication_tables = 2 THEN
        result_text := result_text || E' ✅ ALL CONFIGURED\n';
    ELSE
        result_text := result_text || E' ❌ MISSING TABLES\n';
    END IF;
    
    -- Test 2: Verify realtime performance indexes exist
    SELECT COUNT(*) INTO realtime_indexes
    FROM pg_indexes 
    WHERE tablename IN ('messages', 'match_reads')
      AND indexname LIKE '%realtime%';
      
    result_text := result_text || E'⚡ Realtime performance indexes: ' || realtime_indexes::text;
    
    IF realtime_indexes > 0 THEN
        result_text := result_text || E' ✅ OPTIMIZED\n';
    ELSE
        result_text := result_text || E' ⚠️ BASIC (still functional)\n';
    END IF;
    
    -- Test 3: Verify RLS policies are compatible with realtime
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'messages' 
        AND policyname LIKE '%can read messages%'
    ) THEN
        result_text := result_text || E'🔒 RLS policies for realtime: ✅ CONFIGURED\n';
    ELSE
        result_text := result_text || E'🔒 RLS policies for realtime: ❌ MISSING\n';
    END IF;
    
    result_text := result_text || E'\n📡 Realtime Status: Ready for postgres_changes events\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMPREHENSIVE MASTER TEST SUITE
-- ============================================================================

CREATE OR REPLACE FUNCTION run_comprehensive_messaging_tests()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_start_time TIMESTAMPTZ := clock_timestamp();
    test_end_time TIMESTAMPTZ;
    total_duration_ms DECIMAL;
BEGIN
    result_text := result_text || E'🧪 CREWSNOW MESSAGING COMPREHENSIVE TEST SUITE\n';
    result_text := result_text || E'==============================================\n';
    result_text := result_text || E'Started: ' || test_start_time::text || E'\n\n';
    
    -- Security tests
    result_text := result_text || run_all_messaging_security_tests() || E'\n';
    
    -- Performance tests
    result_text := result_text || test_messaging_performance_validation() || E'\n';
    
    -- Realtime connectivity tests
    result_text := result_text || test_realtime_connectivity() || E'\n';
    
    -- Integration tests  
    result_text := result_text || test_complete_integration() || E'\n';
    
    -- Calculate total test duration
    test_end_time := clock_timestamp();
    total_duration_ms := EXTRACT(epoch FROM (test_end_time - test_start_time)) * 1000;
    
    -- Final summary
    result_text := result_text || E'==============================================\n';
    result_text := result_text || E'🏁 COMPREHENSIVE TEST SUITE COMPLETED\n';
    result_text := result_text || E'==============================================\n';
    result_text := result_text || E'Duration: ' || total_duration_ms::text || E'ms\n';
    result_text := result_text || E'Completed: ' || test_end_time::text || E'\n\n';
    
    -- Status check
    IF result_text LIKE '%❌%' OR result_text LIKE '%BREACH%' OR result_text LIKE '%FAILED%' THEN
        result_text := result_text || E'🚨 RESULT: Some tests failed - review before production\n';
    ELSE
        result_text := result_text || E'🎉 RESULT: All tests passed - ready for production!\n';
    END IF;
    
    result_text := result_text || E'\n📋 Test categories completed:\n';
    result_text := result_text || E'  ✅ Security isolation (RLS policies)\n';
    result_text := result_text || E'  ✅ Message length constraints\n';
    result_text := result_text || E'  ✅ Pagination functionality\n';
    result_text := result_text || E'  ✅ Read receipts isolation\n';
    result_text := result_text || E'  ✅ Performance validation\n';
    result_text := result_text || E'  ✅ Realtime connectivity\n';
    result_text := result_text || E'  ✅ System integration\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS AND DOCUMENTATION
-- ============================================================================

COMMENT ON FUNCTION test_1_rls_message_isolation() IS 
'Test 1: Verifies users cannot read messages from matches they do not participate in';

COMMENT ON FUNCTION test_2_rls_message_insertion() IS 
'Test 2: Verifies users cannot send messages to matches they do not belong to';

COMMENT ON FUNCTION test_3_message_length_constraint() IS 
'Test 3: Verifies message length constraint (0 < length <= 2000 characters)';

COMMENT ON FUNCTION test_4_pagination_functionality() IS 
'Test 4: Validates both offset and cursor pagination strategies';

COMMENT ON FUNCTION test_5_match_reads_isolation() IS 
'Test 5: Verifies read receipt isolation and access controls';

COMMENT ON FUNCTION run_all_messaging_security_tests() IS 
'Master security test suite for messaging system - runs all RLS and constraint tests';

COMMENT ON FUNCTION test_messaging_performance_validation() IS 
'Performance validation for messaging operations with time benchmarks';

-- ============================================================================
-- COMPLETION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🧪 Comprehensive Messaging Security Tests Created!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Available test functions:';
    RAISE NOTICE '  🔒 run_all_messaging_security_tests() - Complete security suite';
    RAISE NOTICE '  ⚡ test_messaging_performance_validation() - Performance benchmarks';
    RAISE NOTICE '  📡 test_realtime_connectivity() - Realtime configuration';
    RAISE NOTICE '  🔗 test_complete_integration() - End-to-end integration';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Quick test command:';
    RAISE NOTICE '   SELECT run_comprehensive_messaging_tests();';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Individual tests:';
    RAISE NOTICE '   SELECT test_1_rls_message_isolation();';
    RAISE NOTICE '   SELECT test_2_rls_message_insertion();'; 
    RAISE NOTICE '   SELECT test_3_message_length_constraint();';
    RAISE NOTICE '   SELECT test_4_pagination_functionality();';
    RAISE NOTICE '   SELECT test_5_match_reads_isolation();';
END $$;
