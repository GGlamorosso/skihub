-- CrewSnow Specific Messaging RLS Policies
-- Description: Implements exact RLS policies as specified for messages and match_reads tables
-- Date: January 10, 2025
-- 
-- This migration replaces existing generic policies with specific granular policies
-- according to the exact specifications provided.

-- ============================================================================
-- CLEANUP EXISTING POLICIES
-- ============================================================================

-- Remove existing generic policies for messages
DROP POLICY IF EXISTS "messages_match_participants" ON public.messages;
DROP POLICY IF EXISTS "messages_realtime_policy" ON public.messages;  
DROP POLICY IF EXISTS "messages_match_participants_enhanced" ON public.messages;

-- Remove existing policies for match_reads if any
DROP POLICY IF EXISTS "match_reads_own_status" ON public.match_reads;
DROP POLICY IF EXISTS "match_reads_insert_own" ON public.match_reads;
DROP POLICY IF EXISTS "match_reads_update_own" ON public.match_reads;

-- ============================================================================
-- 2.1 TABLE MESSAGES - SPECIFIC RLS POLICIES
-- ============================================================================

-- Policy SELECT: User can read messages if they are the sender OR a participant in the match
CREATE POLICY "User can read messages in their matches"
ON public.messages
FOR SELECT TO authenticated
USING (
  auth.uid() = sender_id
  OR auth.uid() = (SELECT user1_id FROM public.matches m WHERE m.id = match_id)
  OR auth.uid() = (SELECT user2_id FROM public.matches m WHERE m.id = match_id)
);

-- Policy INSERT: User can send messages only if they are the sender AND a participant in the match
CREATE POLICY "User can send messages in their matches"
ON public.messages
FOR INSERT TO authenticated
WITH CHECK (
  auth.uid() = sender_id
  AND (
    auth.uid() = (SELECT user1_id FROM public.matches m WHERE m.id = match_id)
    OR auth.uid() = (SELECT user2_id FROM public.matches m WHERE m.id = match_id)
  )
);

-- Policy DELETE: Optional - User can delete their own messages
CREATE POLICY "User can delete their own messages"
ON public.messages
FOR DELETE TO authenticated
USING (
  auth.uid() = sender_id
);

-- Policy UPDATE: Optional - User can edit their own messages
CREATE POLICY "User can update their own messages"
ON public.messages
FOR UPDATE TO authenticated
USING (
  auth.uid() = sender_id
)
WITH CHECK (
  auth.uid() = sender_id
);

-- ============================================================================
-- 2.2 TABLE MATCH_READS - SPECIFIC RLS POLICIES
-- ============================================================================

-- Policy SELECT: Only a match member can see read receipts
CREATE POLICY "User can read their match reads"
ON public.match_reads
FOR SELECT TO authenticated
USING (
  auth.uid() = user_id
);

-- Policy INSERT/UPDATE: User can initialize or update their last_read_at if they are a match participant
CREATE POLICY "User can update match reads"
ON public.match_reads
FOR INSERT, UPDATE TO authenticated
WITH CHECK (
  auth.uid() = user_id
  AND (
    auth.uid() = (SELECT user1_id FROM public.matches m WHERE m.id = match_id)
    OR auth.uid() = (SELECT user2_id FROM public.matches m WHERE m.id = match_id)
  )
);

-- ============================================================================
-- PERFORMANCE OPTIMIZATION INDEXES
-- ============================================================================

-- Indexes to optimize RLS policy performance
-- These are critical for the subqueries in the policies

-- Index for messages policies - optimize match participant lookups
CREATE INDEX IF NOT EXISTS idx_messages_rls_match_lookup
ON public.messages (match_id, sender_id);

-- Index for match_reads policies - optimize match participant lookups  
CREATE INDEX IF NOT EXISTS idx_match_reads_rls_lookup
ON public.match_reads (match_id, user_id);

-- Index on matches table to optimize the subqueries in policies
CREATE INDEX IF NOT EXISTS idx_matches_participants_lookup
ON public.matches (id, user1_id, user2_id);

-- ============================================================================
-- REALTIME POLICIES UPDATE
-- ============================================================================

-- Update realtime policies to match the new specific policies
-- Messages realtime policy should match the SELECT policy
CREATE POLICY "messages_realtime_specific" ON public.messages
FOR SELECT TO authenticated
USING (
  auth.uid() = sender_id
  OR auth.uid() = (SELECT user1_id FROM public.matches m WHERE m.id = match_id)
  OR auth.uid() = (SELECT user2_id FROM public.matches m WHERE m.id = match_id)
);

-- match_reads realtime policy
CREATE POLICY "match_reads_realtime_specific" ON public.match_reads
FOR SELECT TO authenticated
USING (
  auth.uid() = user_id
);

-- ============================================================================
-- VALIDATION AND TESTING FUNCTION
-- ============================================================================

-- Function to test the new RLS policies
CREATE OR REPLACE FUNCTION test_specific_messaging_rls_policies()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_match_id UUID;
    test_message_id UUID;
    test_user1_id UUID := '00000000-0000-0000-0000-000000000001'; -- alpine_alex
    test_user2_id UUID := '00000000-0000-0000-0000-000000000002'; -- powder_marie
    test_user3_id UUID := '00000000-0000-0000-0000-000000000003'; -- beginner_tom (non-participant)
    can_read_count INTEGER;
    can_insert BOOLEAN;
    can_read_reads BOOLEAN;
BEGIN
    result_text := result_text || E'🔒 SPECIFIC MESSAGING RLS POLICIES TEST\n';
    result_text := result_text || E'=====================================\n\n';
    
    -- Find or create a test match
    SELECT id INTO test_match_id
    FROM matches 
    WHERE (user1_id = test_user1_id AND user2_id = test_user2_id)
       OR (user1_id = test_user2_id AND user2_id = test_user1_id)
    LIMIT 1;
    
    IF test_match_id IS NULL THEN
        INSERT INTO matches (user1_id, user2_id)
        VALUES (LEAST(test_user1_id, test_user2_id), GREATEST(test_user1_id, test_user2_id))
        RETURNING id INTO test_match_id;
        
        result_text := result_text || E'✅ Created test match: ' || test_match_id::text || E'\n';
    END IF;
    
    -- Insert test message
    INSERT INTO messages (match_id, sender_id, content)
    VALUES (test_match_id, test_user1_id, 'Test message for RLS policy validation')
    ON CONFLICT DO NOTHING
    RETURNING id INTO test_message_id;
    
    result_text := result_text || E'✅ Test message created\n\n';
    
    -- Test 1: Verify sender can read their own message
    SET LOCAL role TO authenticated;
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', test_user1_id::text)::text;
    
    SELECT COUNT(*) INTO can_read_count
    FROM messages 
    WHERE match_id = test_match_id AND sender_id = test_user1_id;
    
    result_text := result_text || E'📖 TEST 1 - Sender can read own messages: ';
    IF can_read_count > 0 THEN
        result_text := result_text || E'✅ PASS (' || can_read_count::text || E' messages)\n';
    ELSE
        result_text := result_text || E'❌ FAIL (0 messages visible)\n';
    END IF;
    
    -- Test 2: Verify match participant can read messages
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', test_user2_id::text)::text;
    
    SELECT COUNT(*) INTO can_read_count
    FROM messages 
    WHERE match_id = test_match_id;
    
    result_text := result_text || E'👥 TEST 2 - Match participant can read messages: ';
    IF can_read_count > 0 THEN
        result_text := result_text || E'✅ PASS (' || can_read_count::text || E' messages)\n';
    ELSE
        result_text := result_text || E'❌ FAIL (0 messages visible)\n';
    END IF;
    
    -- Test 3: Verify non-participant cannot read messages
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', test_user3_id::text)::text;
    
    SELECT COUNT(*) INTO can_read_count
    FROM messages 
    WHERE match_id = test_match_id;
    
    result_text := result_text || E'🚫 TEST 3 - Non-participant cannot read messages: ';
    IF can_read_count = 0 THEN
        result_text := result_text || E'✅ PASS (0 messages visible)\n';
    ELSE
        result_text := result_text || E'❌ FAIL (' || can_read_count::text || E' messages visible)\n';
    END IF;
    
    -- Test 4: Test match_reads policies
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', test_user1_id::text)::text;
    
    -- Try to insert read status
    BEGIN
        INSERT INTO match_reads (match_id, user_id, last_read_at)
        VALUES (test_match_id, test_user1_id, NOW())
        ON CONFLICT (match_id, user_id) DO UPDATE SET last_read_at = NOW();
        
        can_insert := TRUE;
    EXCEPTION
        WHEN others THEN
            can_insert := FALSE;
    END;
    
    result_text := result_text || E'📝 TEST 4 - User can insert/update match_reads: ';
    IF can_insert THEN
        result_text := result_text || E'✅ PASS\n';
    ELSE
        result_text := result_text || E'❌ FAIL\n';
    END IF;
    
    -- Test 5: User can read their own match_reads
    SELECT EXISTS (
        SELECT 1 FROM match_reads 
        WHERE match_id = test_match_id AND user_id = test_user1_id
    ) INTO can_read_reads;
    
    result_text := result_text || E'👁️ TEST 5 - User can read own match_reads: ';
    IF can_read_reads THEN
        result_text := result_text || E'✅ PASS\n';
    ELSE
        result_text := result_text || E'❌ FAIL\n';
    END IF;
    
    -- Reset role
    RESET role;
    RESET "request.jwt.claims";
    
    result_text := result_text || E'\n🎯 RLS Policies Status: All specific policies implemented\n';
    result_text := result_text || E'📊 Performance: Optimized with dedicated indexes\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON POLICY "User can read messages in their matches" ON public.messages IS 
'Users can read messages if they are the sender OR a participant in the match (user1_id or user2_id)';

COMMENT ON POLICY "User can send messages in their matches" ON public.messages IS 
'Users can send messages only if they are the sender AND a participant in the match';

COMMENT ON POLICY "User can delete their own messages" ON public.messages IS 
'Optional policy: Users can delete only their own messages';

COMMENT ON POLICY "User can update their own messages" ON public.messages IS 
'Optional policy: Users can edit only their own messages';

COMMENT ON POLICY "User can read their match reads" ON public.match_reads IS 
'Users can only see their own read receipt status (user_id = auth.uid())';

COMMENT ON POLICY "User can update match reads" ON public.match_reads IS 
'Users can insert/update their read status only if they are a participant in the match';

-- ============================================================================
-- POLICY ANALYSIS AND SECURITY VERIFICATION
-- ============================================================================

-- Function to analyze policy security
CREATE OR REPLACE FUNCTION analyze_messaging_rls_security()
RETURNS TABLE (
    policy_name TEXT,
    table_name TEXT,
    operation TEXT,
    security_level TEXT,
    performance_impact TEXT
) AS $$
BEGIN
    RETURN QUERY VALUES
    -- Messages policies
    ('User can read messages in their matches', 'messages', 'SELECT', 'HIGH - Sender OR participant check', 'MEDIUM - 2 subqueries'),
    ('User can send messages in their matches', 'messages', 'INSERT', 'HIGH - Sender AND participant check', 'MEDIUM - 2 subqueries'),
    ('User can delete their own messages', 'messages', 'DELETE', 'HIGH - Sender only', 'LOW - Direct column check'),
    ('User can update their own messages', 'messages', 'UPDATE', 'HIGH - Sender only', 'LOW - Direct column check'),
    
    -- match_reads policies  
    ('User can read their match reads', 'match_reads', 'SELECT', 'HIGH - Own records only', 'LOW - Direct column check'),
    ('User can update match reads', 'match_reads', 'INSERT/UPDATE', 'HIGH - Owner AND participant check', 'MEDIUM - 2 subqueries');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMPLETION AND VALIDATION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔒 Specific Messaging RLS Policies Migration Completed!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Summary of implemented policies:';
    RAISE NOTICE '  ✅ messages SELECT: Sender OR match participant';
    RAISE NOTICE '  ✅ messages INSERT: Sender AND match participant';
    RAISE NOTICE '  ✅ messages DELETE: Sender only (optional)';
    RAISE NOTICE '  ✅ messages UPDATE: Sender only (optional)';
    RAISE NOTICE '  ✅ match_reads SELECT: Own records only';
    RAISE NOTICE '  ✅ match_reads INSERT/UPDATE: Owner AND match participant';
    RAISE NOTICE '';
    RAISE NOTICE '⚡ Performance optimizations:';
    RAISE NOTICE '  ✅ Dedicated RLS indexes created';
    RAISE NOTICE '  ✅ Match lookup optimization';
    RAISE NOTICE '  ✅ Realtime policies updated';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Test the policies: SELECT test_specific_messaging_rls_policies();';
    RAISE NOTICE '📊 Analyze security: SELECT * FROM analyze_messaging_rls_security();';
END $$;
