-- CrewSnow Photo Moderation Webhook System  
-- Description: Sets up Supabase → n8n webhook trigger for automatic photo moderation
-- Date: January 10, 2025
--
-- 1. Mettre en place le déclencheur Supabase → n8n
-- 1.1 Configurer un webhook de base de données qui surveille les inserts dans profile_photos

-- ============================================================================
-- WEBHOOK LOGGING TABLE
-- ============================================================================

-- Create table to log webhook attempts for debugging and monitoring
CREATE TABLE IF NOT EXISTS webhook_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(50) NOT NULL,
    record_id UUID NOT NULL,
    webhook_type VARCHAR(50) NOT NULL,
    webhook_url TEXT,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    response_status INTEGER,
    response_body TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT webhook_logs_table_valid CHECK (table_name IN ('profile_photos', 'messages')),
    CONSTRAINT webhook_logs_type_valid CHECK (webhook_type IN ('n8n_moderation', 'notification', 'analytics'))
);

-- Index for efficient querying
CREATE INDEX IF NOT EXISTS idx_webhook_logs_timestamp ON webhook_logs (timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_table_record ON webhook_logs (table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_success ON webhook_logs (success, timestamp DESC) WHERE success = false;

-- ============================================================================
-- EDGE FUNCTION CALLER (PostgreSQL HTTP Extension Alternative)
-- ============================================================================

-- Function to call Edge Function from database trigger
-- This uses the http extension if available, or pg_net for newer Supabase instances
CREATE OR REPLACE FUNCTION call_n8n_webhook_edge_function(
    photo_id UUID,
    user_id UUID,
    storage_path TEXT,
    file_size_bytes INTEGER,
    mime_type TEXT
)
RETURNS void AS $$
DECLARE
    edge_function_url TEXT;
    payload JSON;
    response_status INTEGER;
    response_body TEXT;
BEGIN
    -- Get Edge Function URL
    edge_function_url := current_setting('app.edge_function_url', true) || '/functions/v1/webhook-n8n';
    
    -- If no custom URL set, use default Supabase project URL
    IF edge_function_url = '/functions/v1/webhook-n8n' OR edge_function_url IS NULL THEN
        edge_function_url := current_setting('app.supabase_url', true) || 
                             'http://localhost:54321' || 
                             '/functions/v1/webhook-n8n';
    END IF;
    
    -- Prepare payload
    payload := json_build_object(
        'record', json_build_object(
            'id', photo_id,
            'user_id', user_id,
            'storage_path', storage_path,
            'file_size_bytes', file_size_bytes,
            'mime_type', mime_type,
            'moderation_status', 'pending',
            'created_at', NOW()
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
        'profile_photos',
        photo_id,
        'n8n_moderation',
        edge_function_url,
        true, -- We'll assume success; Edge Function will handle its own error logging
        NOW()
    );
    
    -- Use pg_net to call Edge Function (if available)
    BEGIN
        -- Try to use pg_net (newer Supabase instances)
        SELECT net.http_post(
            url := edge_function_url,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || current_setting('app.service_role_key', true)
            ),
            body := payload::jsonb
        ) INTO response_status;
        
        RAISE NOTICE 'Webhook sent via pg_net to %', edge_function_url;
        
    EXCEPTION
        WHEN undefined_function THEN
            -- pg_net not available, log for manual processing or use alternative method
            RAISE NOTICE 'pg_net not available - webhook logged for Edge Function processing';
            
            -- Update webhook log with note about manual processing needed
            UPDATE webhook_logs 
            SET 
                success = false,
                error_message = 'pg_net not available - requires Edge Function processing'
            WHERE record_id = photo_id 
              AND webhook_type = 'n8n_moderation'
              AND timestamp = (SELECT MAX(timestamp) FROM webhook_logs WHERE record_id = photo_id);
              
        WHEN others THEN
            RAISE WARNING 'Webhook call failed: %', SQLERRM;
            
            -- Log the error
            UPDATE webhook_logs 
            SET 
                success = false,
                error_message = SQLERRM
            WHERE record_id = photo_id 
              AND webhook_type = 'n8n_moderation'
              AND timestamp = (SELECT MAX(timestamp) FROM webhook_logs WHERE record_id = photo_id);
    END;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGER FUNCTION FOR PROFILE_PHOTOS
-- ============================================================================

-- Trigger function that fires on INSERT into profile_photos with status='pending'
CREATE OR REPLACE FUNCTION trigger_photo_moderation_webhook()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger webhook for pending photos
    IF NEW.moderation_status = 'pending' THEN
        
        -- Log trigger execution
        RAISE NOTICE 'Photo moderation webhook triggered for photo ID: %', NEW.id;
        
        -- Call the webhook function asynchronously
        -- This will either call the Edge Function directly or log for processing
        PERFORM call_n8n_webhook_edge_function(
            NEW.id,
            NEW.user_id,
            NEW.storage_path,
            NEW.file_size_bytes,
            NEW.mime_type
        );
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- CREATE TRIGGER ON PROFILE_PHOTOS
-- ============================================================================

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_photo_moderation_webhook ON profile_photos;

-- Create trigger that fires AFTER INSERT for pending photos
CREATE TRIGGER trigger_photo_moderation_webhook
    AFTER INSERT ON profile_photos
    FOR EACH ROW
    WHEN (NEW.moderation_status = 'pending')
    EXECUTE FUNCTION trigger_photo_moderation_webhook();

-- ============================================================================
-- EDGE FUNCTION CONFIGURATION HELPER
-- ============================================================================

-- Function to set configuration for Edge Function URLs
CREATE OR REPLACE FUNCTION configure_webhook_settings(
    supabase_project_url TEXT,
    service_role_key TEXT
)
RETURNS void AS $$
BEGIN
    -- Set configuration for Edge Function calls
    -- These will be used by the webhook function
    
    PERFORM set_config('app.supabase_url', supabase_project_url, false);
    PERFORM set_config('app.service_role_key', service_role_key, false);
    
    RAISE NOTICE 'Webhook configuration updated:';
    RAISE NOTICE '  Supabase URL: %', supabase_project_url;
    RAISE NOTICE '  Service role configured: %', CASE WHEN service_role_key IS NOT NULL THEN 'Yes' ELSE 'No' END;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- WEBHOOK MONITORING AND UTILITIES
-- ============================================================================

-- Function to check webhook health and recent activity
CREATE OR REPLACE FUNCTION check_webhook_health()
RETURNS TABLE (
    status TEXT,
    total_webhooks_24h INTEGER,
    successful_webhooks_24h INTEGER,
    failed_webhooks_24h INTEGER,
    success_rate_percentage DECIMAL,
    last_successful_webhook TIMESTAMPTZ,
    last_failed_webhook TIMESTAMPTZ,
    pending_photos_count INTEGER
) AS $$
DECLARE
    total_24h INTEGER;
    successful_24h INTEGER;
    failed_24h INTEGER;
    success_rate DECIMAL;
    last_success TIMESTAMPTZ;
    last_failure TIMESTAMPTZ;
    pending_count INTEGER;
BEGIN
    -- Get webhook statistics for last 24 hours
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE success = true),
        COUNT(*) FILTER (WHERE success = false)
    INTO total_24h, successful_24h, failed_24h
    FROM webhook_logs 
    WHERE timestamp > NOW() - INTERVAL '24 hours'
      AND webhook_type = 'n8n_moderation';
    
    -- Calculate success rate
    success_rate := CASE 
        WHEN total_24h > 0 THEN (successful_24h::DECIMAL / total_24h::DECIMAL) * 100 
        ELSE 0 
    END;
    
    -- Get last successful and failed webhook timestamps
    SELECT MAX(timestamp) INTO last_success
    FROM webhook_logs 
    WHERE success = true AND webhook_type = 'n8n_moderation';
    
    SELECT MAX(timestamp) INTO last_failure  
    FROM webhook_logs 
    WHERE success = false AND webhook_type = 'n8n_moderation';
    
    -- Count photos pending moderation
    SELECT COUNT(*) INTO pending_count
    FROM profile_photos 
    WHERE moderation_status = 'pending';
    
    -- Determine overall status
    RETURN QUERY SELECT
        CASE 
            WHEN success_rate >= 95 THEN 'HEALTHY'
            WHEN success_rate >= 80 THEN 'DEGRADED' 
            ELSE 'UNHEALTHY'
        END,
        total_24h,
        successful_24h, 
        failed_24h,
        success_rate,
        last_success,
        last_failure,
        pending_count;
END;
$$ LANGUAGE plpgsql;

-- Function to retry failed webhook attempts
CREATE OR REPLACE FUNCTION retry_failed_webhooks(
    max_retries INTEGER DEFAULT 5,
    hours_back INTEGER DEFAULT 24
)
RETURNS INTEGER AS $$
DECLARE
    failed_webhook RECORD;
    retry_count INTEGER := 0;
BEGIN
    -- Find failed webhooks to retry
    FOR failed_webhook IN 
        SELECT DISTINCT wl.record_id, pp.*
        FROM webhook_logs wl
        JOIN profile_photos pp ON wl.record_id = pp.id
        WHERE wl.success = false
          AND wl.webhook_type = 'n8n_moderation'
          AND wl.timestamp > NOW() - INTERVAL '1 hour' * hours_back
          AND pp.moderation_status = 'pending'
        ORDER BY wl.timestamp DESC
        LIMIT max_retries
    LOOP
        -- Retry the webhook
        PERFORM call_n8n_webhook_edge_function(
            failed_webhook.id,
            failed_webhook.user_id,
            failed_webhook.storage_path,
            failed_webhook.file_size_bytes,
            failed_webhook.mime_type
        );
        
        retry_count := retry_count + 1;
        
        RAISE NOTICE 'Retried webhook for photo %', failed_webhook.id;
    END LOOP;
    
    RETURN retry_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- WEBHOOK PAYLOAD VALIDATION
-- ============================================================================

-- Function to validate webhook payload before sending
CREATE OR REPLACE FUNCTION validate_photo_webhook_payload(
    p_photo_id UUID,
    p_user_id UUID,
    p_storage_path TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    photo_exists BOOLEAN;
    user_exists BOOLEAN;
    storage_path_valid BOOLEAN;
BEGIN
    -- Check if photo exists and is pending
    SELECT EXISTS (
        SELECT 1 FROM profile_photos 
        WHERE id = p_photo_id 
          AND user_id = p_user_id
          AND moderation_status = 'pending'
    ) INTO photo_exists;
    
    -- Check if user exists and is active
    SELECT EXISTS (
        SELECT 1 FROM users 
        WHERE id = p_user_id 
          AND is_active = true 
          AND is_banned = false
    ) INTO user_exists;
    
    -- Validate storage path format
    storage_path_valid := p_storage_path IS NOT NULL 
                         AND length(p_storage_path) > 0
                         AND p_storage_path LIKE '%/%'; -- Should contain folder structure
    
    RETURN photo_exists AND user_exists AND storage_path_valid;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- CONFIGURATION AND SECURITY
-- ============================================================================

-- Enable RLS on webhook_logs
ALTER TABLE webhook_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Only service role and admin users can read webhook logs
CREATE POLICY "webhook_logs_admin_only" ON webhook_logs
FOR SELECT TO authenticated
USING (
    -- Only allow access to users with admin role or service role
    auth.jwt() ->> 'role' = 'admin' 
    OR auth.jwt() ->> 'role' = 'service_role'
    OR auth.uid()::text IN (
        SELECT id::text FROM users WHERE email LIKE '%@crewsnow.com' -- Admin emails
    )
);

-- Policy: Service role can insert webhook logs
CREATE POLICY "webhook_logs_service_insert" ON webhook_logs
FOR INSERT TO service_role
WITH CHECK (true);

-- ============================================================================
-- COMMENTS AND DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE webhook_logs IS 'Tracks webhook attempts for debugging and monitoring moderation workflow';

COMMENT ON FUNCTION call_n8n_webhook_edge_function(UUID, UUID, TEXT, INTEGER, TEXT) IS 
'Calls Edge Function webhook-n8n to trigger photo moderation workflow in n8n';

COMMENT ON FUNCTION trigger_photo_moderation_webhook() IS 
'Trigger function that fires when photos with pending status are inserted';

COMMENT ON TRIGGER trigger_photo_moderation_webhook ON profile_photos IS 
'Automatically sends photos to n8n for moderation when uploaded with pending status';

COMMENT ON FUNCTION check_webhook_health() IS 
'Monitors webhook health and provides status dashboard for moderation system';

COMMENT ON FUNCTION retry_failed_webhooks(INTEGER, INTEGER) IS 
'Retries failed webhook attempts for photos that are still pending moderation';

-- ============================================================================
-- INITIAL CONFIGURATION
-- ============================================================================

-- Set up initial configuration (customize these values)
DO $$
BEGIN
    -- Example configuration - update with your actual values
    PERFORM configure_webhook_settings(
        'https://your-project.supabase.co', -- Replace with actual Supabase URL
        'your-service-role-key'              -- Replace with actual service role key
    );
    
    RAISE NOTICE '🎯 Photo Moderation Webhook System Configured!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Next steps:';
    RAISE NOTICE '  1. Deploy Edge Function: supabase functions deploy webhook-n8n';
    RAISE NOTICE '  2. Configure n8n webhook URL in environment variables';
    RAISE NOTICE '  3. Set up n8n workflow to receive webhooks';
    RAISE NOTICE '  4. Test with: INSERT INTO profile_photos (...) VALUES (...);';
    RAISE NOTICE '';
    RAISE NOTICE '🔍 Monitoring:';
    RAISE NOTICE '  • Health check: SELECT * FROM check_webhook_health();';
    RAISE NOTICE '  • View logs: SELECT * FROM webhook_logs ORDER BY timestamp DESC;';
    RAISE NOTICE '  • Retry failed: SELECT retry_failed_webhooks(5, 24);';
    RAISE NOTICE '';
    RAISE NOTICE '🔐 Environment variables needed:';
    RAISE NOTICE '  • N8N_WEBHOOK_URL=https://your-n8n.app/webhook/photo-moderation';
    RAISE NOTICE '  • N8N_WEBHOOK_SECRET=your-secret-key';
    RAISE NOTICE '  • SUPABASE_SERVICE_ROLE_KEY=your-service-role-key';
    
EXCEPTION
    WHEN others THEN
        RAISE WARNING 'Could not set initial configuration: %', SQLERRM;
        RAISE NOTICE 'Please run configure_webhook_settings() manually with your values';
END $$;

-- ============================================================================
-- ENABLE WEBHOOK SYSTEM
-- ============================================================================

-- The trigger is already created above and will fire on INSERT
-- Test the system with:
-- INSERT INTO profile_photos (user_id, storage_path, file_size_bytes, mime_type, moderation_status)
-- VALUES ('user-uuid', 'path/to/photo.jpg', 123456, 'image/jpeg', 'pending');

RAISE NOTICE '✅ Photo moderation webhook system is now active!';
RAISE NOTICE 'Trigger will fire on: INSERT profile_photos WHERE moderation_status = ''pending''';
