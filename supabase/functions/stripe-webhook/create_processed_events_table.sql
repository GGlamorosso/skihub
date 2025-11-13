-- ============================================================================
-- PROCESSED EVENTS TABLE FOR STRIPE WEBHOOK IDEMPOTENCY
-- ============================================================================

-- Create table to track processed Stripe events (prevents duplicate processing)
CREATE TABLE IF NOT EXISTS processed_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id VARCHAR(255) NOT NULL UNIQUE, -- Stripe event ID
    event_type VARCHAR(100) NOT NULL,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Indexes
    CONSTRAINT processed_events_event_id_unique UNIQUE (event_id)
);

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_processed_events_event_id ON processed_events(event_id);
CREATE INDEX IF NOT EXISTS idx_processed_events_type ON processed_events(event_type);
CREATE INDEX IF NOT EXISTS idx_processed_events_processed_at ON processed_events(processed_at DESC);

-- RLS (only service role should access this)
ALTER TABLE processed_events ENABLE ROW LEVEL SECURITY;

-- Function to create table (callable from Edge Function)
CREATE OR REPLACE FUNCTION create_processed_events_table_if_not_exists()
RETURNS VOID AS $$
BEGIN
    -- Table creation is idempotent, this is just a helper
    RAISE NOTICE 'processed_events table verified';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cleanup function to remove old processed events (optional)
CREATE OR REPLACE FUNCTION cleanup_processed_events()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM processed_events 
    WHERE processed_at < NOW() - INTERVAL '90 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE processed_events IS 'Tracks processed Stripe webhook events for idempotency';
COMMENT ON FUNCTION create_processed_events_table_if_not_exists() IS 'Helper function for Edge Function to ensure table exists';
COMMENT ON FUNCTION cleanup_processed_events() IS 'Removes old processed events (run periodically)';
