-- CrewSnow Migration - Final Index Optimizations
-- This migration adds the final performance indexes based on common query patterns

-- ========================================
-- 1. LIKES PERFORMANCE INDEXES
-- ========================================

-- Index for "my sent likes" queries (liker_id lookup)
CREATE INDEX IF NOT EXISTS likes_liker_id_idx
  ON public.likes (liker_id);

-- Note: likes_liked_id_idx already exists from previous migration for "who liked me" queries

-- ========================================
-- 2. MESSAGES PAGINATION OPTIMIZATION
-- ========================================

-- Drop existing index if it doesn't have DESC order
DROP INDEX IF EXISTS messages_match_created_idx;
DROP INDEX IF EXISTS idx_messages_match_id_created_at;

-- Create optimized index for message pagination (newest first)
CREATE INDEX messages_match_created_desc_idx
  ON public.messages (match_id, created_at DESC);

-- ========================================
-- 3. MODERATION QUEUE OPTIMIZATION
-- ========================================

-- Partial index for pending photos moderation queue
CREATE INDEX IF NOT EXISTS profile_photos_pending_idx
  ON public.profile_photos (moderation_status, created_at)
  WHERE moderation_status = 'pending';

-- Partial index for rejected photos (for admin review)
CREATE INDEX IF NOT EXISTS profile_photos_rejected_idx
  ON public.profile_photos (moderation_status, updated_at)
  WHERE moderation_status = 'rejected';

-- ========================================
-- 4. USER ACTIVITY OPTIMIZATION
-- ========================================

-- Index for active users lookup with last activity
CREATE INDEX IF NOT EXISTS users_last_active_idx
  ON public.users (last_active_at DESC)
  WHERE is_active = true AND is_banned = false;

-- Index for premium users by expiration date
CREATE INDEX IF NOT EXISTS users_premium_expiry_idx
  ON public.users (premium_expires_at)
  WHERE is_premium = true AND premium_expires_at IS NOT NULL;

-- ========================================
-- 5. MATCHING ALGORITHM OPTIMIZATION
-- ========================================

-- Composite index for station-based matching with date overlap
CREATE INDEX IF NOT EXISTS user_station_status_matching_idx
  ON public.user_station_status (station_id, date_from, date_to, user_id)
  WHERE date_to >= CURRENT_DATE;

-- Index for finding users by ride styles (GIN for array operations)
CREATE INDEX IF NOT EXISTS users_ride_styles_gin_idx
  ON public.users USING GIN (ride_styles)
  WHERE is_active = true AND is_banned = false;

-- Index for finding users by languages (GIN for array operations)
CREATE INDEX IF NOT EXISTS users_languages_gin_idx
  ON public.users USING GIN (languages)
  WHERE is_active = true AND is_banned = false;

-- ========================================
-- 6. CHAT PERFORMANCE OPTIMIZATION
-- ========================================

-- Index for finding recent matches (for chat list)
CREATE INDEX IF NOT EXISTS matches_recent_activity_idx
  ON public.matches (created_at DESC);

-- Composite index for match participants lookup
CREATE INDEX IF NOT EXISTS matches_user1_created_idx
  ON public.matches (user1_id, created_at DESC);

CREATE INDEX IF NOT EXISTS matches_user2_created_idx
  ON public.matches (user2_id, created_at DESC);

-- ========================================
-- 7. ANALYTICS & REPORTING OPTIMIZATION
-- ========================================

-- Index for daily stats aggregation
CREATE INDEX IF NOT EXISTS ride_stats_date_user_idx
  ON public.ride_stats_daily (date DESC, user_id);

-- Index for station popularity analysis
CREATE INDEX IF NOT EXISTS ride_stats_station_date_idx
  ON public.ride_stats_daily (station_id, date DESC);

-- ========================================
-- 8. PERFORMANCE TEST QUERIES
-- ========================================

-- Function to run performance tests on key queries
CREATE OR REPLACE FUNCTION run_performance_tests()
RETURNS text AS $$
DECLARE
  result text := '';
  query_plan text;
  test_user_id uuid := '00000000-0000-0000-0000-000000000001';
  test_match_id uuid;
BEGIN
  result := result || E'=== PERFORMANCE TEST RESULTS ===\n\n';
  
  -- Get a test match ID
  SELECT id INTO test_match_id FROM matches LIMIT 1;
  
  -- Test 1: "Who liked me" query
  result := result || E'TEST 1: Who liked me query\n';
  EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
    SELECT * FROM likes WHERE liked_id = test_user_id;
  GET DIAGNOSTICS query_plan = PG_CONTEXT;
  result := result || 'Expected: Index Scan using likes_liked_id_idx' || E'\n\n';
  
  -- Test 2: Message pagination
  result := result || E'TEST 2: Message pagination (newest first)\n';
  IF test_match_id IS NOT NULL THEN
    EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
      SELECT * FROM messages 
      WHERE match_id = test_match_id 
      ORDER BY created_at DESC 
      LIMIT 50;
    GET DIAGNOSTICS query_plan = PG_CONTEXT;
    result := result || 'Expected: Index Scan using messages_match_created_desc_idx' || E'\n\n';
  END IF;
  
  -- Test 3: Moderation queue
  result := result || E'TEST 3: Pending photos moderation queue\n';
  EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
    SELECT * FROM profile_photos 
    WHERE moderation_status = 'pending' 
    ORDER BY created_at 
    LIMIT 50;
  GET DIAGNOSTICS query_plan = PG_CONTEXT;
  result := result || 'Expected: Index Scan using profile_photos_pending_idx' || E'\n\n';
  
  -- Test 4: Active users by ride styles
  result := result || E'TEST 4: Users by ride styles (array search)\n';
  EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
    SELECT * FROM users 
    WHERE ride_styles @> ARRAY['alpine']::ride_style[]
      AND is_active = true 
      AND is_banned = false
    LIMIT 20;
  GET DIAGNOSTICS query_plan = PG_CONTEXT;
  result := result || 'Expected: Bitmap Index Scan using users_ride_styles_gin_idx' || E'\n\n';
  
  -- Test 5: Station matching
  result := result || E'TEST 5: Station-based matching\n';
  EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
    SELECT * FROM user_station_status 
    WHERE station_id = (SELECT id FROM stations LIMIT 1)
      AND date_from <= CURRENT_DATE + 7
      AND date_to >= CURRENT_DATE
    LIMIT 20;
  GET DIAGNOSTICS query_plan = PG_CONTEXT;
  result := result || 'Expected: Index Scan using user_station_status_matching_idx' || E'\n\n';
  
  result := result || E'=== PERFORMANCE TESTS COMPLETE ===\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 9. INDEX MONITORING FUNCTION
-- ========================================

-- Function to monitor index usage and size
CREATE OR REPLACE FUNCTION monitor_index_usage()
RETURNS TABLE (
  schemaname text,
  tablename text,
  indexname text,
  index_size text,
  index_scans bigint,
  rows_read bigint,
  rows_fetched bigint,
  usage_ratio numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.schemaname::text,
    s.tablename::text,
    s.indexname::text,
    pg_size_pretty(pg_relation_size(s.indexrelid))::text as index_size,
    s.idx_scan,
    s.idx_tup_read,
    s.idx_tup_fetch,
    CASE 
      WHEN s.idx_scan = 0 THEN 0
      ELSE ROUND((s.idx_tup_fetch::numeric / s.idx_tup_read::numeric) * 100, 2)
    END as usage_ratio
  FROM pg_stat_user_indexes s
  JOIN pg_indexes i ON i.indexname = s.indexname AND i.schemaname = s.schemaname
  WHERE s.schemaname = 'public'
  ORDER BY s.idx_scan DESC, pg_relation_size(s.indexrelid) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 10. QUERY OPTIMIZATION RECOMMENDATIONS
-- ========================================

-- Function to analyze slow queries and suggest optimizations
CREATE OR REPLACE FUNCTION analyze_query_performance()
RETURNS text AS $$
DECLARE
  result text := '';
  rec record;
BEGIN
  result := result || E'=== QUERY PERFORMANCE ANALYSIS ===\n\n';
  
  -- Check for unused indexes
  result := result || E'UNUSED INDEXES (0 scans):\n';
  FOR rec IN 
    SELECT indexname, pg_size_pretty(pg_relation_size(indexrelid)) as size
    FROM pg_stat_user_indexes 
    WHERE schemaname = 'public' AND idx_scan = 0
    ORDER BY pg_relation_size(indexrelid) DESC
  LOOP
    result := result || format('- %s (%s)%s', rec.indexname, rec.size, E'\n');
  END LOOP;
  
  result := result || E'\nMOST USED INDEXES:\n';
  FOR rec IN 
    SELECT indexname, idx_scan, pg_size_pretty(pg_relation_size(indexrelid)) as size
    FROM pg_stat_user_indexes 
    WHERE schemaname = 'public' AND idx_scan > 0
    ORDER BY idx_scan DESC
    LIMIT 10
  LOOP
    result := result || format('- %s: %s scans (%s)%s', rec.indexname, rec.idx_scan, rec.size, E'\n');
  END LOOP;
  
  result := result || E'\n=== ANALYSIS COMPLETE ===\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 11. INDEX DOCUMENTATION
-- ========================================

-- Add comments for all new indexes
COMMENT ON INDEX likes_liker_id_idx IS 'Optimizes "my sent likes" queries for user activity feeds';
COMMENT ON INDEX messages_match_created_desc_idx IS 'Optimizes message pagination in chat (newest first)';
COMMENT ON INDEX profile_photos_pending_idx IS 'Partial index for moderation queue - pending photos only';
COMMENT ON INDEX profile_photos_rejected_idx IS 'Partial index for admin review of rejected photos';
COMMENT ON INDEX users_last_active_idx IS 'Finds recently active users for matching algorithm';
COMMENT ON INDEX users_premium_expiry_idx IS 'Tracks premium subscription expiration for billing';
COMMENT ON INDEX user_station_status_matching_idx IS 'Optimizes station-based matching with date overlap';
COMMENT ON INDEX users_ride_styles_gin_idx IS 'GIN index for array-based ride style matching';
COMMENT ON INDEX users_languages_gin_idx IS 'GIN index for array-based language matching';
COMMENT ON INDEX matches_recent_activity_idx IS 'Sorts matches by creation date for chat list';
COMMENT ON INDEX matches_user1_created_idx IS 'Finds matches for user1 sorted by date';
COMMENT ON INDEX matches_user2_created_idx IS 'Finds matches for user2 sorted by date';
COMMENT ON INDEX ride_stats_date_user_idx IS 'Optimizes daily stats queries and user analytics';
COMMENT ON INDEX ride_stats_station_date_idx IS 'Enables station popularity analysis over time';

-- ========================================
-- MIGRATION COMPLETE
-- ========================================

-- Run performance test to validate indexes
SELECT run_performance_tests();

-- Add comment to track migration completion
COMMENT ON SCHEMA public IS 'CrewSnow schema with optimized indexes - Migration 20241120 completed';
