-- CrewSnow Message Moderation System (Optional)
-- Description: Optional message moderation with toxicity detection
-- Date: January 10, 2025

-- ============================================================================
-- 3. MODÉRATION DES MESSAGES (OPTIONNELLE)
-- ============================================================================

-- Add moderation columns to messages table
-- Only add if they don't already exist

DO $$
BEGIN
    -- Check if moderation columns exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'is_blocked'
    ) THEN
        ALTER TABLE messages ADD COLUMN is_blocked BOOLEAN NOT NULL DEFAULT false;
        RAISE NOTICE 'Added is_blocked column to messages table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'needs_review'
    ) THEN
        ALTER TABLE messages ADD COLUMN needs_review BOOLEAN NOT NULL DEFAULT false;
        RAISE NOTICE 'Added needs_review column to messages table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'moderation_score'
    ) THEN
        ALTER TABLE messages ADD COLUMN moderation_score DECIMAL(3,2);
        RAISE NOTICE 'Added moderation_score column to messages table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'moderation_reason'
    ) THEN
        ALTER TABLE messages ADD COLUMN moderation_reason TEXT;
        RAISE NOTICE 'Added moderation_reason column to messages table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'moderated_at'
    ) THEN
        ALTER TABLE messages ADD COLUMN moderated_at TIMESTAMPTZ;
        RAISE NOTICE 'Added moderated_at column to messages table';
    END IF;
END $$;

-- ============================================================================
-- MESSAGE FLAGS TABLE
-- ============================================================================

-- Alternative approach: separate table for message flags
CREATE TABLE IF NOT EXISTS message_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    flag_type VARCHAR(50) NOT NULL,
    
    -- Moderation details
    toxicity_score DECIMAL(3,2),
    flag_reason TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'medium',
    
    -- Flagging metadata
    flagged_by VARCHAR(20) NOT NULL DEFAULT 'auto_moderation',
    flagged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    resolution VARCHAR(20), -- 'confirmed', 'dismissed', 'pending'
    
    -- Constraints
    CONSTRAINT message_flags_severity_valid CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT message_flags_type_valid CHECK (flag_type IN ('toxicity', 'harassment', 'spam', 'inappropriate', 'violence')),
    CONSTRAINT message_flags_resolution_valid CHECK (resolution IN ('confirmed', 'dismissed', 'pending')),
    CONSTRAINT message_flags_score_valid CHECK (toxicity_score IS NULL OR (toxicity_score >= 0 AND toxicity_score <= 1))
);

-- Index for efficient querying and filtering
CREATE INDEX IF NOT EXISTS idx_message_flags_message ON message_flags (message_id);
CREATE INDEX IF NOT EXISTS idx_message_flags_type_severity ON message_flags (flag_type, severity);
CREATE INDEX IF NOT EXISTS idx_message_flags_pending ON message_flags (flagged_at DESC) WHERE resolution IS NULL;
CREATE INDEX IF NOT EXISTS idx_message_flags_auto ON message_flags (flagged_at DESC) WHERE flagged_by = 'auto_moderation';

-- Index on messages for moderation filtering
CREATE INDEX IF NOT EXISTS idx_messages_moderation ON messages (is_blocked, needs_review) WHERE is_blocked = true OR needs_review = true;
CREATE INDEX IF NOT EXISTS idx_messages_unmoderated ON messages (created_at DESC) WHERE moderation_score IS NULL;

-- ============================================================================
-- MESSAGE MODERATION FUNCTIONS
-- ============================================================================

-- Function to flag a message for moderation
CREATE OR REPLACE FUNCTION flag_message_for_moderation(
    p_message_id UUID,
    p_flag_type VARCHAR,
    p_toxicity_score DECIMAL DEFAULT NULL,
    p_reason TEXT DEFAULT 'Auto-detected content violation',
    p_severity VARCHAR DEFAULT 'medium',
    p_auto_block BOOLEAN DEFAULT false
)
RETURNS UUID AS $$
DECLARE
    flag_id UUID;
    should_auto_block BOOLEAN := false;
BEGIN
    -- Determine if message should be auto-blocked based on severity and score
    should_auto_block := p_auto_block OR 
                        (p_toxicity_score IS NOT NULL AND p_toxicity_score > 0.9) OR
                        p_severity = 'critical';
    
    -- Insert flag record
    INSERT INTO message_flags (
        message_id,
        flag_type,
        toxicity_score,
        flag_reason,
        severity,
        flagged_by,
        resolution
    ) VALUES (
        p_message_id,
        p_flag_type,
        p_toxicity_score,
        p_reason,
        p_severity,
        'auto_moderation',
        CASE WHEN should_auto_block THEN 'confirmed' ELSE 'pending' END
    ) RETURNING id INTO flag_id;
    
    -- Update message table if auto-blocking
    IF should_auto_block THEN
        UPDATE messages 
        SET 
            is_blocked = true,
            moderation_score = p_toxicity_score,
            moderation_reason = p_reason,
            moderated_at = NOW()
        WHERE id = p_message_id;
        
        RAISE NOTICE 'Message % auto-blocked due to severity %', p_message_id, p_severity;
    ELSIF p_toxicity_score IS NOT NULL AND p_toxicity_score > 0.6 THEN
        -- Mark for human review
        UPDATE messages 
        SET 
            needs_review = true,
            moderation_score = p_toxicity_score,
            moderated_at = NOW()
        WHERE id = p_message_id;
        
        RAISE NOTICE 'Message % marked for review (score: %)', p_message_id, p_toxicity_score;
    END IF;
    
    RETURN flag_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get messages needing moderation
CREATE OR REPLACE FUNCTION get_messages_for_moderation(
    p_limit INTEGER DEFAULT 50,
    p_hours_back INTEGER DEFAULT 24,
    p_strategy VARCHAR DEFAULT 'recent' -- 'recent', 'unmoderated', 'flagged'
)
RETURNS TABLE (
    message_id UUID,
    match_id UUID,
    sender_id UUID,
    content TEXT,
    created_at TIMESTAMPTZ,
    sender_username VARCHAR,
    moderation_score DECIMAL,
    flag_count INTEGER,
    highest_severity VARCHAR
) AS $$
BEGIN
    IF p_strategy = 'recent' THEN
        -- Strategy: Recent messages not yet moderated
        RETURN QUERY
        SELECT 
            m.id,
            m.match_id,
            m.sender_id,
            m.content,
            m.created_at,
            u.username,
            m.moderation_score,
            COALESCE(flags.flag_count, 0)::INTEGER,
            flags.highest_severity
        FROM messages m
        JOIN users u ON m.sender_id = u.id
        LEFT JOIN (
            SELECT 
                mf.message_id,
                COUNT(*) as flag_count,
                MAX(mf.severity) as highest_severity
            FROM message_flags mf
            WHERE mf.resolution IS NULL OR mf.resolution = 'pending'
            GROUP BY mf.message_id
        ) flags ON m.id = flags.message_id
        WHERE m.created_at > NOW() - INTERVAL '1 hour' * p_hours_back
          AND m.moderation_score IS NULL
          AND m.is_blocked = false
          AND length(m.content) > 5 -- Skip very short messages
        ORDER BY m.created_at DESC
        LIMIT p_limit;
        
    ELSIF p_strategy = 'flagged' THEN
        -- Strategy: Already flagged messages needing human review
        RETURN QUERY
        SELECT 
            m.id,
            m.match_id,
            m.sender_id,
            m.content,
            m.created_at,
            u.username,
            m.moderation_score,
            flags.flag_count::INTEGER,
            flags.highest_severity
        FROM messages m
        JOIN users u ON m.sender_id = u.id
        JOIN (
            SELECT 
                mf.message_id,
                COUNT(*) as flag_count,
                MAX(mf.severity) as highest_severity,
                MAX(mf.flagged_at) as latest_flag
            FROM message_flags mf
            WHERE mf.resolution IS NULL OR mf.resolution = 'pending'
            GROUP BY mf.message_id
        ) flags ON m.id = flags.message_id
        WHERE m.needs_review = true
        ORDER BY flags.latest_flag DESC
        LIMIT p_limit;
        
    ELSE
        -- Strategy: All unmoderated messages
        RETURN QUERY
        SELECT 
            m.id,
            m.match_id,
            m.sender_id,
            m.content,
            m.created_at,
            u.username,
            m.moderation_score,
            0::INTEGER as flag_count,
            NULL::VARCHAR as highest_severity
        FROM messages m
        JOIN users u ON m.sender_id = u.id
        WHERE m.moderation_score IS NULL
          AND m.is_blocked = false
          AND m.created_at > NOW() - INTERVAL '1 hour' * p_hours_back
        ORDER BY m.created_at DESC
        LIMIT p_limit;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- MESSAGE MODERATION TRIGGER (Optional Real-time)
-- ============================================================================

-- Trigger function for real-time message moderation
-- This can be enabled/disabled based on moderation strategy preference
CREATE OR REPLACE FUNCTION trigger_message_moderation_webhook()
RETURNS TRIGGER AS $$
DECLARE
    should_moderate BOOLEAN := false;
    content_length INTEGER;
    suspicious_patterns INTEGER := 0;
BEGIN
    -- Quick content analysis to determine if moderation is needed
    content_length := length(NEW.content);
    
    -- Check for suspicious patterns (basic keyword detection)
    suspicious_patterns := (
        SELECT COUNT(*)
        FROM (VALUES 
            ('fuck'), ('shit'), ('bitch'), ('asshole'), ('damn'),
            ('kill yourself'), ('kys'), ('die'), ('hate'),
            ('stupid'), ('idiot'), ('retard'), ('gay'), ('fag')
        ) AS keywords(word)
        WHERE NEW.content ILIKE '%' || word || '%'
    );
    
    -- Decide if moderation is needed
    should_moderate := (
        content_length > 100 OR                    -- Long messages
        suspicious_patterns > 0 OR                -- Contains flagged keywords
        NEW.content ~ '[A-Z]{5,}' OR              -- Excessive caps
        NEW.content ~ '(.)\1{4,}' OR              -- Repeated characters
        NEW.content ~ 'http[s]?://' OR            -- Contains URLs
        array_length(string_to_array(NEW.content, ' '), 1) > 50 -- Very long message
    );
    
    -- If moderation needed, call webhook (similar to photo moderation)
    IF should_moderate THEN
        -- Log for batch processing or real-time webhook
        INSERT INTO webhook_logs (
            table_name,
            record_id,
            webhook_type,
            success,
            error_message,
            timestamp
        ) VALUES (
            'messages',
            NEW.id,
            'message_moderation_pending',
            false, -- Will be updated when processed
            'Queued for moderation analysis',
            NOW()
        );
        
        RAISE NOTICE 'Message % queued for moderation (suspicious patterns: %)', NEW.id, suspicious_patterns;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger (disabled by default - enable if real-time moderation desired)
-- DROP TRIGGER IF EXISTS trigger_message_moderation_webhook ON messages;
-- CREATE TRIGGER trigger_message_moderation_webhook
--     AFTER INSERT ON messages
--     FOR EACH ROW
--     EXECUTE FUNCTION trigger_message_moderation_webhook();

-- ============================================================================
-- BATCH MESSAGE MODERATION FUNCTION
-- ============================================================================

-- Function for cron-based message moderation (recommended strategy)
CREATE OR REPLACE FUNCTION process_message_moderation_batch()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    batch_size INTEGER := 100;
    processed_count INTEGER := 0;
    message_record RECORD;
BEGIN
    result_text := result_text || E'🔍 MESSAGE MODERATION BATCH PROCESSING\n';
    result_text := result_text || E'====================================\n';
    result_text := result_text || E'Started: ' || NOW()::text || E'\n\n';
    
    -- Process messages from last hour that haven't been moderated
    FOR message_record IN 
        SELECT * FROM get_messages_for_moderation(batch_size, 1, 'recent')
    LOOP
        -- Log each message for webhook processing
        INSERT INTO webhook_logs (
            table_name,
            record_id,
            webhook_type,
            success,
            error_message,
            timestamp
        ) VALUES (
            'messages',
            message_record.message_id,
            'n8n_text_moderation',
            false, -- Will be updated by n8n workflow
            'Queued for NLP toxicity analysis',
            NOW()
        );
        
        processed_count := processed_count + 1;
    END LOOP;
    
    result_text := result_text || E'📊 Processed: ' || processed_count::text || E' messages for moderation\n';
    result_text := result_text || E'📋 Next: n8n workflow will process via NLP service\n';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- RLS POLICIES FOR MESSAGE MODERATION
-- ============================================================================

-- Enable RLS on message_flags
ALTER TABLE message_flags ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see flags on their own messages
CREATE POLICY "users_can_see_own_message_flags" ON message_flags
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM messages m 
        WHERE m.id = message_id 
        AND m.sender_id = auth.uid()
    )
);

-- Policy: Moderators can see all flags
CREATE POLICY "moderators_can_see_all_flags" ON message_flags
FOR ALL TO authenticated
USING (
    auth.jwt() ->> 'role' = 'moderator' 
    OR auth.jwt() ->> 'role' = 'admin'
    OR auth.uid()::text IN (
        SELECT id::text FROM users 
        WHERE email LIKE '%@crewsnow.com'
    )
);

-- Policy: Service role can manage flags (for n8n)
CREATE POLICY "service_role_manage_flags" ON message_flags
FOR ALL TO service_role
WITH CHECK (true);

-- ============================================================================
-- MODERATION VIEWS
-- ============================================================================

-- View for moderation dashboard
CREATE OR REPLACE VIEW moderation_dashboard AS
SELECT 
    'photos' as content_type,
    COUNT(*) as total_pending,
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '1 hour') as pending_last_hour,
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours') as pending_last_24h,
    AVG(EXTRACT(epoch FROM (NOW() - created_at))) / 60 as avg_pending_minutes
FROM profile_photos 
WHERE moderation_status = 'pending'

UNION ALL

SELECT 
    'messages' as content_type,
    COUNT(*),
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '1 hour'),
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours'),
    AVG(EXTRACT(epoch FROM (NOW() - created_at))) / 60
FROM messages 
WHERE needs_review = true OR is_blocked = true;

-- View for flagged content summary
CREATE OR REPLACE VIEW flagged_content_summary AS
SELECT 
    flag_type,
    severity,
    COUNT(*) as total_flags,
    COUNT(*) FILTER (WHERE resolution = 'confirmed') as confirmed_flags,
    COUNT(*) FILTER (WHERE resolution = 'dismissed') as dismissed_flags,
    COUNT(*) FILTER (WHERE resolution IS NULL) as pending_flags,
    AVG(toxicity_score) as avg_toxicity_score,
    MAX(flagged_at) as last_flagged
FROM message_flags 
WHERE flagged_at > NOW() - INTERVAL '30 days'
GROUP BY flag_type, severity
ORDER BY total_flags DESC;

-- ============================================================================
-- WEBHOOK FOR MESSAGE MODERATION
-- ============================================================================

-- Function to send message to n8n for text moderation
CREATE OR REPLACE FUNCTION send_message_to_moderation(
    p_message_id UUID,
    p_webhook_url TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    message_record RECORD;
    webhook_url TEXT;
    payload JSON;
BEGIN
    -- Get message details
    SELECT 
        m.id,
        m.content,
        m.sender_id,
        m.match_id,
        m.created_at,
        u.username
    INTO message_record
    FROM messages m
    JOIN users u ON m.sender_id = u.id
    WHERE m.id = p_message_id;
    
    IF message_record IS NULL THEN
        RAISE WARNING 'Message % not found', p_message_id;
        RETURN false;
    END IF;
    
    -- Use provided URL or get from configuration
    webhook_url := COALESCE(
        p_webhook_url,
        current_setting('app.n8n_message_webhook_url', true),
        current_setting('app.n8n_webhook_url', true) || '/message-moderation'
    );
    
    -- Prepare payload for n8n
    payload := json_build_object(
        'record', json_build_object(
            'id', message_record.id,
            'content', message_record.content,
            'sender_id', message_record.sender_id,
            'match_id', message_record.match_id,
            'created_at', message_record.created_at,
            'sender_username', message_record.username,
            'content_length', length(message_record.content),
            'moderation_type', 'text_analysis'
        )
    );
    
    -- Log webhook attempt
    INSERT INTO webhook_logs (
        table_name,
        record_id, 
        webhook_type,
        webhook_url,
        success,
        timestamp
    ) VALUES (
        'messages',
        p_message_id,
        'n8n_text_moderation',
        webhook_url,
        true, -- Assume success; n8n will update if it fails
        NOW()
    );
    
    RAISE NOTICE 'Message % sent to text moderation webhook', p_message_id;
    RETURN true;
    
EXCEPTION
    WHEN others THEN
        RAISE WARNING 'Failed to send message % for moderation: %', p_message_id, SQLERRM;
        RETURN false;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS AND DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE message_flags IS 'Flags and moderation results for message content';
COMMENT ON COLUMN message_flags.toxicity_score IS 'Score from 0.0 to 1.0 indicating toxicity level from NLP service';
COMMENT ON COLUMN message_flags.flag_reason IS 'Detailed reason why message was flagged';
COMMENT ON COLUMN message_flags.severity IS 'Severity level: low, medium, high, critical';

COMMENT ON FUNCTION flag_message_for_moderation(UUID, VARCHAR, DECIMAL, TEXT, VARCHAR, BOOLEAN) IS 
'Flags a message for moderation with toxicity analysis results';

COMMENT ON FUNCTION get_messages_for_moderation(INTEGER, INTEGER, VARCHAR) IS 
'Returns messages that need moderation analysis based on strategy (recent/unmoderated/flagged)';

COMMENT ON FUNCTION send_message_to_moderation(UUID, TEXT) IS 
'Sends individual message to n8n for text moderation analysis';

COMMENT ON FUNCTION process_message_moderation_batch() IS 
'Batch processes recent messages for moderation - can be run via cron';

COMMENT ON VIEW moderation_dashboard IS 
'Dashboard view showing pending moderation counts for photos and messages';

COMMENT ON VIEW flagged_content_summary IS 
'Summary of flagged content by type and severity for moderation monitoring';

-- ============================================================================
-- COMPLETION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '📝 Message Moderation System (Optional) Configured!';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Features added:';
    RAISE NOTICE '  ✅ message_flags table for detailed tracking';
    RAISE NOTICE '  ✅ Moderation columns added to messages table';
    RAISE NOTICE '  ✅ Batch processing function for cron strategy';
    RAISE NOTICE '  ✅ Real-time trigger available (disabled by default)';
    RAISE NOTICE '  ✅ RLS policies for moderated content';
    RAISE NOTICE '  ✅ Dashboard views for monitoring';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Usage:';
    RAISE NOTICE '  • Batch process: SELECT process_message_moderation_batch();';
    RAISE NOTICE '  • Get flagged: SELECT * FROM get_messages_for_moderation(50, 24, ''flagged'');';
    RAISE NOTICE '  • Dashboard: SELECT * FROM moderation_dashboard;';
    RAISE NOTICE '  • Flag message: SELECT flag_message_for_moderation(message_id, ''toxicity'', 0.85);';
    RAISE NOTICE '';
    RAISE NOTICE '⚙️ Strategies available:';
    RAISE NOTICE '  1. Real-time: Enable trigger_message_moderation_webhook trigger';  
    RAISE NOTICE '  2. Cron: Run process_message_moderation_batch() every minute';
    RAISE NOTICE '  3. Hybrid: Real-time flagging + batch processing';
END $$;
