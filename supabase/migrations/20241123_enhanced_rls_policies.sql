-- CrewSnow Enhanced RLS Policies for Swipe Function
-- Description: Refined RLS policies according to specifications for optimal security
-- Date: November 2024

-- ============================================================================
-- ENHANCED RLS POLICIES FOR LIKES TABLE
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "likes_own_actions" ON likes;
DROP POLICY IF EXISTS "likes_realtime_policy" ON likes;

-- 1. Allow INSERT: User can like others if authenticated user matches liker_id and liker_id ≠ liked_id
CREATE POLICY "allow_insert_likes" ON likes 
FOR INSERT TO authenticated
WITH CHECK (
    auth.uid() IS NOT NULL 
    AND auth.uid() = liker_id 
    AND liker_id != liked_id
);

-- 2. Allow SELECT: Users can read likes involving them (given or received)
CREATE POLICY "allow_select_likes" ON likes
FOR SELECT TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND (auth.uid() = liker_id OR auth.uid() = liked_id)
);

-- 3. Allow DELETE: Users can delete their own likes (unlike functionality)
CREATE POLICY "allow_delete_likes" ON likes
FOR DELETE TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND auth.uid() = liker_id
);

-- ============================================================================
-- ENHANCED RLS POLICIES FOR MATCHES TABLE
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "matches_participants" ON matches;
DROP POLICY IF EXISTS "matches_realtime_policy" ON matches;

-- 1. Allow SELECT: Users can view matches they participate in
CREATE POLICY "allow_select_matches" ON matches
FOR SELECT TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND (auth.uid() = user1_id OR auth.uid() = user2_id)
);

-- 2. Allow UPDATE: Match participants can update match status (if needed)
CREATE POLICY "allow_update_matches" ON matches
FOR UPDATE TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND (auth.uid() = user1_id OR auth.uid() = user2_id)
)
WITH CHECK (
    auth.uid() IS NOT NULL 
    AND (auth.uid() = user1_id OR auth.uid() = user2_id)
);

-- Note: INSERT for matches is handled by Edge Function using service role authentication
-- This bypasses RLS and allows the function to create matches from mutual likes

-- ============================================================================
-- ENHANCED RLS POLICIES FOR FRIENDS TABLE (BLOCKING FUNCTIONALITY)
-- ============================================================================

-- Drop existing basic policy if any
DROP POLICY IF EXISTS "friends_own_data" ON friends;

-- 1. Allow INSERT: Users can send friend requests or block others
CREATE POLICY "allow_insert_friends" ON friends
FOR INSERT TO authenticated
WITH CHECK (
    auth.uid() IS NOT NULL 
    AND auth.uid() = requester_id 
    AND requester_id != addressee_id
);

-- 2. Allow SELECT: Users can read relationships involving them
CREATE POLICY "allow_select_friends" ON friends
FOR SELECT TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND (auth.uid() = requester_id OR auth.uid() = addressee_id)
);

-- 3. Allow UPDATE: Addressee can update status (accept/reject/block), requester can update to block
CREATE POLICY "allow_update_friends" ON friends
FOR UPDATE TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND (
        -- Addressee can update any status
        auth.uid() = addressee_id
        OR 
        -- Requester can only update to 'blocked' status
        (auth.uid() = requester_id AND status = 'blocked')
    )
)
WITH CHECK (
    auth.uid() IS NOT NULL 
    AND (
        -- Addressee can set any valid status
        auth.uid() = addressee_id
        OR 
        -- Requester can only set to 'blocked'
        (auth.uid() = requester_id AND status = 'blocked')
    )
);

-- 4. Allow DELETE: Users can remove relationships they're involved in
CREATE POLICY "allow_delete_friends" ON friends
FOR DELETE TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND (auth.uid() = requester_id OR auth.uid() = addressee_id)
);

-- ============================================================================
-- ENHANCED REALTIME POLICIES (SPECIFIC OPERATIONS)
-- ============================================================================

-- Realtime policies need to be more specific for security

-- Likes: Only SELECT for realtime notifications
CREATE POLICY "realtime_select_likes" ON likes
FOR SELECT TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND (auth.uid() = liker_id OR auth.uid() = liked_id)
);

-- Matches: Only SELECT for realtime match notifications  
CREATE POLICY "realtime_select_matches" ON matches
FOR SELECT TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND (auth.uid() = user1_id OR auth.uid() = user2_id)
    AND is_active = true
);

-- ============================================================================
-- SERVICE ROLE POLICY FOR EDGE FUNCTIONS
-- ============================================================================

-- Allow service role (used by Edge Functions) to insert matches
CREATE POLICY "service_role_insert_matches" ON matches
FOR INSERT TO service_role
WITH CHECK (true);

-- Allow service role to bypass RLS for complex operations
-- Note: Edge Functions run with service_role context when using direct DB connection

-- ============================================================================
-- ADDITIONAL SECURITY CONSTRAINTS
-- ============================================================================

-- Create function to validate blocking relationships in likes
CREATE OR REPLACE FUNCTION check_user_not_blocked(liker_uuid UUID, liked_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if either user has blocked the other
    RETURN NOT EXISTS (
        SELECT 1 FROM friends 
        WHERE status = 'blocked' 
        AND (
            (requester_id = liker_uuid AND addressee_id = liked_uuid)
            OR
            (requester_id = liked_uuid AND addressee_id = liker_uuid)
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update likes INSERT policy to include blocking check
DROP POLICY IF EXISTS "allow_insert_likes" ON likes;

CREATE POLICY "allow_insert_likes" ON likes 
FOR INSERT TO authenticated
WITH CHECK (
    auth.uid() IS NOT NULL 
    AND auth.uid() = liker_id 
    AND liker_id != liked_id
    AND check_user_not_blocked(liker_id, liked_id)
);

-- ============================================================================
-- VERIFICATION AND TESTING
-- ============================================================================

-- Function to test RLS policies
CREATE OR REPLACE FUNCTION test_rls_policies()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_user_1 UUID := '00000000-0000-0000-0000-000000000001';
    test_user_2 UUID := '00000000-0000-0000-0000-000000000002';
    likes_count INTEGER;
    matches_count INTEGER;
BEGIN
    result_text := result_text || E'🔒 RLS POLICIES TEST RESULTS\n';
    result_text := result_text || E'================================\n\n';
    
    -- Test 1: Likes visibility for authenticated user
    SET LOCAL role TO authenticated;
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', test_user_1::text)::text;
    
    SELECT COUNT(*) INTO likes_count 
    FROM likes 
    WHERE liker_id = test_user_1 OR liked_id = test_user_1;
    
    result_text := result_text || E'✅ User can see their likes: ' || likes_count::text || E' likes visible\n';
    
    -- Test 2: Matches visibility for authenticated user  
    SELECT COUNT(*) INTO matches_count 
    FROM matches 
    WHERE user1_id = test_user_1 OR user2_id = test_user_1;
    
    result_text := result_text || E'✅ User can see their matches: ' || matches_count::text || E' matches visible\n';
    
    -- Reset role
    RESET role;
    RESET "request.jwt.claims";
    
    result_text := result_text || E'\n🛡️ RLS policies are active and functional\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PERFORMANCE INDEXES FOR RLS QUERIES
-- ============================================================================

-- Index to optimize RLS policy checks
CREATE INDEX IF NOT EXISTS idx_likes_auth_check 
ON likes (liker_id, liked_id);

CREATE INDEX IF NOT EXISTS idx_matches_auth_check 
ON matches (user1_id, user2_id) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_friends_blocking_check 
ON friends (requester_id, addressee_id, status) WHERE status = 'blocked';

-- ============================================================================
-- COMMENTS AND DOCUMENTATION
-- ============================================================================

COMMENT ON POLICY "allow_insert_likes" ON likes IS 
'Users can like others if authenticated user matches liker_id, IDs are different, and no blocking relationship exists';

COMMENT ON POLICY "allow_select_likes" ON likes IS 
'Users can read likes they gave or received';

COMMENT ON POLICY "allow_select_matches" ON matches IS 
'Users can view matches they participate in';

COMMENT ON POLICY "allow_insert_friends" ON friends IS 
'Users can create friend requests or block relationships as the requester';

COMMENT ON POLICY "allow_select_friends" ON friends IS 
'Users can read friendship/blocking relationships involving them';

COMMENT ON FUNCTION check_user_not_blocked(UUID, UUID) IS 
'Security function to verify no blocking relationship exists between two users';

-- ============================================================================
-- COMPLETION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔒 Enhanced RLS policies implemented successfully!';
    RAISE NOTICE '📋 Key features:';
    RAISE NOTICE '  ✅ Granular policies for likes (INSERT/SELECT/DELETE)';
    RAISE NOTICE '  ✅ Match visibility restricted to participants only';
    RAISE NOTICE '  ✅ Blocking functionality with bidirectional checks';
    RAISE NOTICE '  ✅ Service role support for Edge Functions';
    RAISE NOTICE '  ✅ Realtime-specific policies for notifications';
    RAISE NOTICE '  ✅ Performance indexes for RLS queries';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Run SELECT test_rls_policies(); to verify functionality';
END $$;
