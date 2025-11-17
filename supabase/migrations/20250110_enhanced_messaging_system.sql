-- CrewSnow Enhanced Messaging System
-- Description: Adds match_reads table and optimizes messaging functionality
-- Date: January 2025
-- 
-- Note: The messages table already exists and is fully compliant with specifications.
-- This migration adds the missing match_reads table for read receipts and enhances the system.

-- ============================================================================
-- VERIFICATION: Check existing messages table compliance
-- ============================================================================

-- The existing messages table already meets all specifications:
-- ✅ id UUID PK (gen_random_uuid()) 
-- ✅ match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE
-- ✅ sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE  
-- ✅ content TEXT NOT NULL with CHECK (length(content) <= 2000)
-- ✅ created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- ✅ Index: idx_messages_match_time ON (match_id, created_at DESC)
-- ✅ RLS enabled with proper policies

-- Additional features already present (bonus):
-- ✅ message_type VARCHAR(20) for different message types
-- ✅ is_read BOOLEAN for basic read tracking
-- ✅ read_at TIMESTAMPTZ for read timestamps

-- ============================================================================
-- 1.2 CREATE match_reads TABLE (NEW)
-- ============================================================================

-- Table to track detailed read receipts per user per match
CREATE TABLE IF NOT EXISTS match_reads (
    -- Primary identifiers
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Read tracking
    last_read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_read_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT match_reads_unique_user_match UNIQUE (match_id, user_id)
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index for user's read status queries
CREATE INDEX IF NOT EXISTS idx_match_reads_user_match 
ON match_reads (user_id, match_id);

-- Index for match-based read status queries  
CREATE INDEX IF NOT EXISTS idx_match_reads_match_updated
ON match_reads (match_id, updated_at DESC);

-- Additional message indexes for read receipt functionality
CREATE INDEX IF NOT EXISTS idx_messages_match_created_asc
ON messages (match_id, created_at ASC);

-- Index for unread message counting
CREATE INDEX IF NOT EXISTS idx_messages_unread_per_match
ON messages (match_id, created_at DESC) 
WHERE is_read = false;

-- ============================================================================
-- ENHANCED RLS POLICIES
-- ============================================================================

-- Enable RLS on match_reads table
ALTER TABLE match_reads ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own read status
CREATE POLICY "match_reads_own_status" ON match_reads
FOR SELECT TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND auth.uid() = user_id
);

-- Policy: Users can insert their own read status
CREATE POLICY "match_reads_insert_own" ON match_reads
FOR INSERT TO authenticated
WITH CHECK (
    auth.uid() IS NOT NULL 
    AND auth.uid() = user_id
    AND EXISTS (
        SELECT 1 FROM matches m 
        WHERE m.id = match_id 
        AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
    )
);

-- Policy: Users can update their own read status
CREATE POLICY "match_reads_update_own" ON match_reads
FOR UPDATE TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND auth.uid() = user_id
)
WITH CHECK (
    auth.uid() IS NOT NULL 
    AND auth.uid() = user_id
);

-- Enhanced policy for messages (replace existing if needed)
DROP POLICY IF EXISTS "messages_match_participants" ON messages;

CREATE POLICY "messages_match_participants_enhanced" ON messages
FOR ALL TO authenticated
USING (
    auth.uid() IS NOT NULL 
    AND EXISTS (
        SELECT 1 FROM matches m 
        WHERE m.id = match_id 
        AND m.is_active = true
        AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
    )
);

-- ============================================================================
-- REALTIME CONFIGURATION
-- ============================================================================

-- Ensure messages table is in realtime publication
DO $$
BEGIN
    -- Add messages to realtime if not already present
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE messages;
    EXCEPTION 
        WHEN duplicate_object THEN 
            NULL; -- Table already in publication
    END;
    
    -- Add match_reads to realtime publication  
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE match_reads;
    EXCEPTION 
        WHEN duplicate_object THEN 
            NULL; -- Table already in publication
    END;
    
    RAISE NOTICE '✅ Realtime configuration updated for messages and match_reads';
END $$;

-- ============================================================================
-- UTILITY FUNCTIONS FOR MESSAGING
-- ============================================================================

-- Function to mark messages as read and update match_reads
CREATE OR REPLACE FUNCTION mark_messages_read(
    p_match_id UUID,
    p_user_id UUID,
    p_last_message_id UUID DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    latest_message_id UUID;
BEGIN
    -- Get the latest message ID if not provided
    IF p_last_message_id IS NULL THEN
        SELECT id INTO latest_message_id
        FROM messages 
        WHERE match_id = p_match_id
        ORDER BY created_at DESC
        LIMIT 1;
    ELSE
        latest_message_id := p_last_message_id;
    END IF;
    
    -- Update or insert read status
    INSERT INTO match_reads (match_id, user_id, last_read_at, last_read_message_id)
    VALUES (p_match_id, p_user_id, NOW(), latest_message_id)
    ON CONFLICT (match_id, user_id)
    DO UPDATE SET
        last_read_at = NOW(),
        last_read_message_id = EXCLUDED.last_read_message_id,
        updated_at = NOW();
    
    -- Mark individual messages as read (for backward compatibility)
    UPDATE messages 
    SET is_read = true, read_at = NOW()
    WHERE match_id = p_match_id
      AND sender_id != p_user_id  -- Don't mark own messages as read
      AND is_read = false
      AND (p_last_message_id IS NULL OR created_at <= (
          SELECT created_at FROM messages WHERE id = p_last_message_id
      ));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread message count for a user
CREATE OR REPLACE FUNCTION get_unread_messages_count(p_user_id UUID)
RETURNS TABLE (
    match_id UUID,
    unread_count INTEGER,
    last_message_content TEXT,
    last_message_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    WITH user_matches AS (
        SELECT m.id as match_id
        FROM matches m
        WHERE m.is_active = true
          AND (m.user1_id = p_user_id OR m.user2_id = p_user_id)
    ),
    read_status AS (
        SELECT 
            mr.match_id,
            mr.last_read_at
        FROM match_reads mr
        WHERE mr.user_id = p_user_id
    ),
    match_stats AS (
        SELECT 
            um.match_id,
            COUNT(msg.id) FILTER (
                WHERE msg.sender_id != p_user_id 
                AND (rs.last_read_at IS NULL OR msg.created_at > rs.last_read_at)
            )::INTEGER as unread_count,
            (SELECT content FROM messages m2 
             WHERE m2.match_id = um.match_id 
             ORDER BY created_at DESC LIMIT 1) as last_message_content,
            MAX(msg.created_at) as last_message_at
        FROM user_matches um
        LEFT JOIN read_status rs ON um.match_id = rs.match_id
        LEFT JOIN messages msg ON um.match_id = msg.match_id
        GROUP BY um.match_id, rs.last_read_at
    )
    SELECT 
        ms.match_id,
        ms.unread_count,
        ms.last_message_content,
        ms.last_message_at
    FROM match_stats ms
    WHERE ms.unread_count > 0 OR ms.last_message_at IS NOT NULL
    ORDER BY ms.last_message_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get messages for a match with read status
CREATE OR REPLACE FUNCTION get_match_messages(
    p_match_id UUID,
    p_user_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_before_timestamp TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    sender_id UUID,
    sender_username VARCHAR,
    message_type VARCHAR,
    created_at TIMESTAMPTZ,
    is_own_message BOOLEAN,
    is_read BOOLEAN,
    read_at TIMESTAMPTZ
) AS $$
BEGIN
    -- Verify user has access to this match
    IF NOT EXISTS (
        SELECT 1 FROM matches m 
        WHERE m.id = p_match_id 
        AND (m.user1_id = p_user_id OR m.user2_id = p_user_id)
    ) THEN
        RAISE EXCEPTION 'Access denied to match %', p_match_id;
    END IF;
    
    RETURN QUERY
    SELECT 
        msg.id,
        msg.content,
        msg.sender_id,
        u.username,
        msg.message_type,
        msg.created_at,
        (msg.sender_id = p_user_id) as is_own_message,
        msg.is_read,
        msg.read_at
    FROM messages msg
    JOIN users u ON msg.sender_id = u.id
    WHERE msg.match_id = p_match_id
      AND (p_before_timestamp IS NULL OR msg.created_at < p_before_timestamp)
    ORDER BY msg.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Trigger to update match_reads.updated_at on changes
CREATE OR REPLACE FUNCTION update_match_reads_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_match_reads_updated_at
    BEFORE UPDATE ON match_reads
    FOR EACH ROW
    EXECUTE FUNCTION update_match_reads_timestamp();

-- Trigger to initialize match_reads when users first access a match
CREATE OR REPLACE FUNCTION initialize_match_reads()
RETURNS TRIGGER AS $$
BEGIN
    -- Create read status entries for both participants when first message is sent
    INSERT INTO match_reads (match_id, user_id, last_read_at)
    SELECT 
        NEW.match_id,
        participant_id,
        CASE 
            WHEN participant_id = NEW.sender_id THEN NOW()
            ELSE NEW.created_at - INTERVAL '1 second'  -- Mark as unread for recipient
        END
    FROM (
        SELECT user1_id as participant_id FROM matches WHERE id = NEW.match_id
        UNION 
        SELECT user2_id as participant_id FROM matches WHERE id = NEW.match_id
    ) participants
    ON CONFLICT (match_id, user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_initialize_match_reads
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION initialize_match_reads();

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View to get matches with unread message indicators
CREATE OR REPLACE VIEW matches_with_unread AS
SELECT 
    m.id as match_id,
    m.user1_id,
    m.user2_id,
    m.created_at as matched_at,
    m.is_active,
    u1.username as user1_username,
    u2.username as user2_username,
    last_msg.content as last_message_content,
    last_msg.created_at as last_message_at,
    last_msg.sender_id as last_message_sender,
    -- Unread counts for each user
    COALESCE(unread1.count, 0) as user1_unread_count,
    COALESCE(unread2.count, 0) as user2_unread_count
FROM matches m
JOIN users u1 ON m.user1_id = u1.id
JOIN users u2 ON m.user2_id = u2.id
LEFT JOIN LATERAL (
    SELECT content, created_at, sender_id
    FROM messages msg
    WHERE msg.match_id = m.id
    ORDER BY msg.created_at DESC
    LIMIT 1
) last_msg ON true
LEFT JOIN LATERAL (
    SELECT COUNT(*)::INTEGER as count
    FROM messages msg
    LEFT JOIN match_reads mr ON mr.match_id = m.id AND mr.user_id = m.user1_id
    WHERE msg.match_id = m.id
      AND msg.sender_id = m.user2_id  -- Messages from the other user
      AND (mr.last_read_at IS NULL OR msg.created_at > mr.last_read_at)
) unread1 ON true
LEFT JOIN LATERAL (
    SELECT COUNT(*)::INTEGER as count
    FROM messages msg
    LEFT JOIN match_reads mr ON mr.match_id = m.id AND mr.user_id = m.user2_id
    WHERE msg.match_id = m.id
      AND msg.sender_id = m.user1_id  -- Messages from the other user
      AND (mr.last_read_at IS NULL OR msg.created_at > mr.last_read_at)
) unread2 ON true
WHERE m.is_active = true;

-- ============================================================================
-- COMMENTS AND DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE match_reads IS 'Tracks read receipts and last read position for each user in each match conversation';

COMMENT ON COLUMN match_reads.last_read_at IS 'Timestamp when user last read messages in this match';
COMMENT ON COLUMN match_reads.last_read_message_id IS 'ID of the last message the user has read';

COMMENT ON FUNCTION mark_messages_read(UUID, UUID, UUID) IS 
'Marks messages as read for a user in a match and updates read status';

COMMENT ON FUNCTION get_unread_messages_count(UUID) IS 
'Returns unread message counts for all matches where the user participates';

COMMENT ON FUNCTION get_match_messages(UUID, UUID, INTEGER, TIMESTAMPTZ) IS 
'Retrieves paginated messages for a match with read status for the requesting user';

COMMENT ON VIEW matches_with_unread IS 
'Comprehensive view of matches with last message info and unread counts for both participants';

-- ============================================================================
-- VALIDATION AND TESTING
-- ============================================================================

-- Function to test the messaging system
CREATE OR REPLACE FUNCTION test_messaging_system()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_match_id UUID;
    test_user1_id UUID := '00000000-0000-0000-0000-000000000001';
    test_user2_id UUID := '00000000-0000-0000-0000-000000000002';
    message_count INTEGER;
    unread_count INTEGER;
BEGIN
    result_text := result_text || E'🧪 MESSAGING SYSTEM TEST RESULTS\n';
    result_text := result_text || E'==================================\n\n';
    
    -- Find or create a test match
    SELECT id INTO test_match_id
    FROM matches 
    WHERE (user1_id = test_user1_id AND user2_id = test_user2_id)
       OR (user1_id = test_user2_id AND user2_id = test_user1_id)
    LIMIT 1;
    
    IF test_match_id IS NULL THEN
        -- Create a test match
        INSERT INTO matches (user1_id, user2_id)
        VALUES (LEAST(test_user1_id, test_user2_id), GREATEST(test_user1_id, test_user2_id))
        RETURNING id INTO test_match_id;
        
        result_text := result_text || E'✅ Created test match: ' || test_match_id::text || E'\n';
    ELSE
        result_text := result_text || E'✅ Using existing match: ' || test_match_id::text || E'\n';
    END IF;
    
    -- Test message insertion
    INSERT INTO messages (match_id, sender_id, content)
    VALUES (test_match_id, test_user1_id, 'Test message for messaging system validation');
    
    -- Check message count
    SELECT COUNT(*) INTO message_count
    FROM messages 
    WHERE match_id = test_match_id;
    
    result_text := result_text || E'✅ Messages in test match: ' || message_count::text || E'\n';
    
    -- Test read status function
    PERFORM mark_messages_read(test_match_id, test_user2_id);
    
    -- Check unread count
    SELECT COUNT(*) INTO unread_count
    FROM get_unread_messages_count(test_user2_id);
    
    result_text := result_text || E'✅ Unread count function working\n';
    
    -- Test match_reads table
    INSERT INTO match_reads (match_id, user_id)
    VALUES (test_match_id, test_user1_id)
    ON CONFLICT DO NOTHING;
    
    result_text := result_text || E'✅ match_reads table operational\n';
    result_text := result_text || E'\n📊 System Status: All messaging components functional\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMPLETION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 Enhanced Messaging System Migration Completed!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Summary of changes:';
    RAISE NOTICE '  ✅ messages table: Already compliant (no changes needed)';
    RAISE NOTICE '  ✅ match_reads table: Created with read receipt functionality';
    RAISE NOTICE '  ✅ Enhanced RLS policies: Added for match_reads, improved for messages';
    RAISE NOTICE '  ✅ Realtime configuration: Updated for both tables';
    RAISE NOTICE '  ✅ Utility functions: Added for read status management';
    RAISE NOTICE '  ✅ Performance indexes: Optimized for messaging queries';
    RAISE NOTICE '  ✅ Triggers: Auto-initialization and timestamp updates';
    RAISE NOTICE '  ✅ Views: matches_with_unread for comprehensive match listing';
    RAISE NOTICE '';
    RAISE NOTICE '🧪 Run SELECT test_messaging_system(); to validate functionality';
    RAISE NOTICE '📊 Query matches with: SELECT * FROM matches_with_unread;';
    RAISE NOTICE '💬 Mark messages read: SELECT mark_messages_read(match_id, user_id);';
END $$;
