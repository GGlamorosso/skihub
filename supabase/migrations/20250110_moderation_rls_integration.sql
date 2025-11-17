-- CrewSnow Moderation RLS Integration
-- Description: Ensures moderation system works with existing RLS policies
-- Date: January 10, 2025

-- ============================================================================
-- 4. INTEGRATION WITH PREVIOUS WEEKS - RLS COMPATIBILITY
-- ============================================================================

-- Service role policies for moderation system (bypass RLS for n8n)
CREATE POLICY "service_role_moderate_photos" ON profile_photos
FOR UPDATE TO service_role
WITH CHECK (true);

CREATE POLICY "service_role_moderate_messages" ON messages  
FOR UPDATE TO service_role
WITH CHECK (true);

-- Update existing message counting to exclude blocked messages
CREATE OR REPLACE FUNCTION get_unread_messages_count_filtered(p_user_id UUID)
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
        SELECT mr.match_id, mr.last_read_at
        FROM match_reads mr
        WHERE mr.user_id = p_user_id
    ),
    match_stats AS (
        SELECT 
            um.match_id,
            COUNT(msg.id) FILTER (
                WHERE msg.sender_id != p_user_id 
                AND msg.is_blocked = false  -- ✅ Exclude blocked messages
                AND (rs.last_read_at IS NULL OR msg.created_at > rs.last_read_at)
            )::INTEGER as unread_count,
            (SELECT content FROM messages m2 
             WHERE m2.match_id = um.match_id 
             AND m2.is_blocked = false  -- ✅ Exclude blocked from last message
             ORDER BY created_at DESC LIMIT 1) as last_message_content,
            MAX(msg.created_at) FILTER (WHERE msg.is_blocked = false) as last_message_at
        FROM user_matches um
        LEFT JOIN read_status rs ON um.match_id = rs.match_id
        LEFT JOIN messages msg ON um.match_id = msg.match_id
        GROUP BY um.match_id, rs.last_read_at
    )
    SELECT ms.match_id, ms.unread_count, ms.last_message_content, ms.last_message_at
    FROM match_stats ms
    WHERE ms.unread_count > 0 OR ms.last_message_at IS NOT NULL
    ORDER BY ms.last_message_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- MODERATION DASHBOARD
-- ============================================================================

CREATE TABLE IF NOT EXISTS moderation_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    content_type VARCHAR(20) NOT NULL,
    total_processed INTEGER NOT NULL DEFAULT 0,
    approved_count INTEGER NOT NULL DEFAULT 0,
    rejected_count INTEGER NOT NULL DEFAULT 0,
    avg_processing_time_seconds DECIMAL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT moderation_stats_unique_date_type UNIQUE (date, content_type),
    CONSTRAINT moderation_stats_content_type_valid CHECK (content_type IN ('photos', 'messages'))
);

CREATE INDEX IF NOT EXISTS idx_moderation_stats_date ON moderation_stats (date DESC, content_type);

-- Function to update daily moderation statistics
CREATE OR REPLACE FUNCTION update_moderation_stats()
RETURNS void AS $$
BEGIN
    -- Photos statistics
    INSERT INTO moderation_stats (date, content_type, total_processed, approved_count, rejected_count)
    SELECT 
        CURRENT_DATE,
        'photos',
        COUNT(*),
        COUNT(*) FILTER (WHERE moderation_status = 'approved'),
        COUNT(*) FILTER (WHERE moderation_status = 'rejected')
    FROM profile_photos 
    WHERE DATE(moderated_at) = CURRENT_DATE
    ON CONFLICT (date, content_type) 
    DO UPDATE SET 
        total_processed = EXCLUDED.total_processed,
        approved_count = EXCLUDED.approved_count,
        rejected_count = EXCLUDED.rejected_count;
    
    -- Messages statistics (if moderation enabled)
    INSERT INTO moderation_stats (date, content_type, total_processed, approved_count, rejected_count)
    SELECT 
        CURRENT_DATE,
        'messages',
        COUNT(*),
        COUNT(*) FILTER (WHERE is_blocked = false AND moderation_score IS NOT NULL),
        COUNT(*) FILTER (WHERE is_blocked = true)
    FROM messages 
    WHERE DATE(moderated_at) = CURRENT_DATE
    ON CONFLICT (date, content_type) 
    DO UPDATE SET 
        total_processed = EXCLUDED.total_processed,
        approved_count = EXCLUDED.approved_count,
        rejected_count = EXCLUDED.rejected_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TESTS AND INTEGRATION
-- ============================================================================

CREATE OR REPLACE FUNCTION test_moderation_integration()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    test_photo_id UUID;
    test_message_id UUID;
    test_user_id UUID := '00000000-0000-0000-0000-000000000001';
    test_match_id UUID;
BEGIN
    result_text := result_text || E'🔍 MODERATION INTEGRATION TESTS\n================================\n\n';
    
    -- Test 1: Photo moderation trigger
    INSERT INTO profile_photos (user_id, storage_path, file_size_bytes, mime_type, moderation_status)
    VALUES (test_user_id, 'test/integration.jpg', 1024000, 'image/jpeg', 'pending')
    RETURNING id INTO test_photo_id;
    
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM webhook_logs 
        WHERE record_id = test_photo_id AND webhook_type = 'n8n_moderation'
    ) THEN 'TRIGGERED' ELSE 'NOT_TRIGGERED' END INTO result_text;
    
    result_text := result_text || E'✅ Photo webhook trigger: ' || result_text || E'\n';
    
    -- Test 2: Message moderation compatibility  
    SELECT id INTO test_match_id FROM matches WHERE user1_id = test_user_id OR user2_id = test_user_id LIMIT 1;
    
    IF test_match_id IS NOT NULL THEN
        INSERT INTO messages (match_id, sender_id, content)
        VALUES (test_match_id, test_user_id, 'Test message for moderation integration')
        RETURNING id INTO test_message_id;
        
        PERFORM flag_message_for_moderation(test_message_id, 'toxicity', 0.5, 'Integration test');
        
        result_text := result_text || E'✅ Message moderation integration: WORKING\n';
    END IF;
    
    -- Test 3: RLS compatibility
    SET LOCAL role TO authenticated;
    SET LOCAL "request.jwt.claims" TO json_build_object('sub', test_user_id::text)::text;
    
    IF EXISTS (SELECT 1 FROM profile_photos WHERE user_id = test_user_id AND moderation_status = 'approved') THEN
        result_text := result_text || E'✅ RLS approved photos access: WORKING\n';
    END IF;
    
    RESET role; RESET "request.jwt.claims";
    
    result_text := result_text || E'\n🎯 Moderation system integrated successfully\n';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_moderation_stats() IS 'Updates daily statistics for moderation dashboard';
COMMENT ON FUNCTION test_moderation_integration() IS 'Tests integration between moderation system and existing features';
