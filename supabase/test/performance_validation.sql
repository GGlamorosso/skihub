-- CrewSnow - Performance Validation Tests
-- These tests validate index usage and query performance with EXPLAIN ANALYZE

-- ========================================
-- SETUP: Create test data if needed
-- ========================================

-- Ensure we have test data for performance tests
DO $$
BEGIN
  -- Check if we have enough test data
  IF (SELECT COUNT(*) FROM users) < 5 THEN
    RAISE NOTICE 'Warning: Limited test data. Run seed migrations first for accurate performance tests.';
  END IF;
END $$;

-- ========================================
-- TEST 1: LIKES PERFORMANCE
-- ========================================

-- Test "who liked me" query (should use likes_liked_id_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT l.*, u.username as liker_username
FROM likes l
JOIN users u ON u.id = l.liker_id
WHERE l.liked_id = '00000000-0000-0000-0000-000000000001'
ORDER BY l.created_at DESC;

-- Expected: Index Scan using likes_liked_id_idx
-- Target: < 50ms for 1000+ likes

-- Test "my sent likes" query (should use likes_liker_id_idx)  
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT l.*, u.username as liked_username
FROM likes l
JOIN users u ON u.id = l.liked_id
WHERE l.liker_id = '00000000-0000-0000-0000-000000000001'
ORDER BY l.created_at DESC;

-- Expected: Index Scan using likes_liker_id_idx
-- Target: < 50ms for user's sent likes

-- ========================================
-- TEST 2: MESSAGES PAGINATION PERFORMANCE
-- ========================================

-- Test message pagination (should use messages_match_created_desc_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT m.*, u.username as sender_username
FROM messages m
JOIN users u ON u.id = m.sender_id
WHERE m.match_id = (SELECT id FROM matches LIMIT 1)
ORDER BY m.created_at DESC
LIMIT 50;

-- Expected: Index Scan using messages_match_created_desc_idx
-- Target: < 100ms for chat pagination

-- Test message count per match
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT match_id, COUNT(*) as message_count
FROM messages
WHERE match_id IN (SELECT id FROM matches LIMIT 10)
GROUP BY match_id;

-- Expected: Index usage for efficient counting
-- Target: < 200ms for multiple match stats

-- ========================================
-- TEST 3: MODERATION QUEUE PERFORMANCE
-- ========================================

-- Test pending photos queue (should use profile_photos_pending_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT pp.*, u.username
FROM profile_photos pp
JOIN users u ON u.id = pp.user_id
WHERE pp.moderation_status = 'pending'
ORDER BY pp.created_at
LIMIT 50;

-- Expected: Index Scan using profile_photos_pending_idx
-- Target: < 100ms for moderation queue

-- Test rejected photos review (should use profile_photos_rejected_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT pp.*, u.username, pp.moderation_reason
FROM profile_photos pp
JOIN users u ON u.id = pp.user_id
WHERE pp.moderation_status = 'rejected'
ORDER BY pp.updated_at DESC
LIMIT 20;

-- Expected: Index Scan using profile_photos_rejected_idx
-- Target: < 100ms for admin review

-- ========================================
-- TEST 4: USER MATCHING ALGORITHM PERFORMANCE
-- ========================================

-- Test active users lookup (should use users_last_active_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id, username, last_active_at, is_premium
FROM users
WHERE is_active = true 
  AND is_banned = false
  AND last_active_at > NOW() - INTERVAL '7 days'
ORDER BY last_active_at DESC
LIMIT 100;

-- Expected: Index Scan using users_last_active_idx
-- Target: < 200ms for active user discovery

-- Test ride style matching (should use users_ride_styles_gin_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id, username, ride_styles
FROM users
WHERE ride_styles @> ARRAY['alpine']::ride_style[]
  AND is_active = true 
  AND is_banned = false
LIMIT 50;

-- Expected: Bitmap Index Scan using users_ride_styles_gin_idx
-- Target: < 300ms for ride style filtering

-- Test language matching (should use users_languages_gin_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id, username, languages
FROM users
WHERE languages @> ARRAY['en']::language_code[]
  AND is_active = true 
  AND is_banned = false
LIMIT 50;

-- Expected: Bitmap Index Scan using users_languages_gin_idx
-- Target: < 300ms for language filtering

-- ========================================
-- TEST 5: STATION-BASED MATCHING PERFORMANCE
-- ========================================

-- Test station matching with date overlap (should use user_station_status_matching_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT uss.*, u.username, s.name as station_name
FROM user_station_status uss
JOIN users u ON u.id = uss.user_id
JOIN stations s ON s.id = uss.station_id
WHERE uss.station_id = (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1)
  AND uss.date_from <= CURRENT_DATE + 7
  AND uss.date_to >= CURRENT_DATE
ORDER BY uss.date_from;

-- Expected: Index Scan using user_station_status_matching_idx
-- Target: < 300ms for geo-temporal matching

-- Test multi-station radius search
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT uss.*, u.username, s.name as station_name
FROM user_station_status uss
JOIN users u ON u.id = uss.user_id
JOIN stations s ON s.id = uss.station_id
WHERE uss.station_id IN (
  SELECT id FROM stations 
  WHERE country_code = 'FR' 
  LIMIT 10
)
  AND uss.date_to >= CURRENT_DATE
ORDER BY uss.date_from
LIMIT 100;

-- Expected: Efficient index usage for multi-station queries
-- Target: < 500ms for complex geo queries

-- ========================================
-- TEST 6: CHAT LIST PERFORMANCE
-- ========================================

-- Test recent matches for chat list (should use matches_recent_activity_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
  m.*,
  u1.username as user1_name,
  u2.username as user2_name,
  (SELECT content FROM messages msg WHERE msg.match_id = m.id ORDER BY msg.created_at DESC LIMIT 1) as last_message
FROM matches m
JOIN users u1 ON u1.id = m.user1_id
JOIN users u2 ON u2.id = m.user2_id
ORDER BY m.created_at DESC
LIMIT 50;

-- Expected: Index Scan using matches_recent_activity_idx
-- Target: < 400ms for chat list with last messages

-- Test user's matches (should use matches_user1_created_idx or matches_user2_created_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT m.*, 
  CASE 
    WHEN m.user1_id = '00000000-0000-0000-0000-000000000001' THEN u2.username
    ELSE u1.username 
  END as other_user_name
FROM matches m
JOIN users u1 ON u1.id = m.user1_id
JOIN users u2 ON u2.id = m.user2_id
WHERE m.user1_id = '00000000-0000-0000-0000-000000000001' 
   OR m.user2_id = '00000000-0000-0000-0000-000000000001'
ORDER BY m.created_at DESC;

-- Expected: Index usage for user-specific match lookup
-- Target: < 200ms for user's match list

-- ========================================
-- TEST 7: ANALYTICS QUERIES PERFORMANCE
-- ========================================

-- Test daily stats aggregation (should use ride_stats_date_user_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
  date,
  COUNT(*) as active_users,
  AVG(distance_km) as avg_distance,
  AVG(vmax_kmh) as avg_max_speed
FROM ride_stats_daily
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY date
ORDER BY date DESC;

-- Expected: Index Scan using ride_stats_date_user_idx
-- Target: < 500ms for monthly analytics

-- Test station popularity (should use ride_stats_station_date_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
  s.name as station_name,
  COUNT(*) as total_rides,
  AVG(rs.distance_km) as avg_distance
FROM ride_stats_daily rs
JOIN stations s ON s.id = rs.station_id
WHERE rs.date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY s.id, s.name
ORDER BY total_rides DESC
LIMIT 20;

-- Expected: Index usage for station-based aggregation
-- Target: < 800ms for station popularity analysis

-- ========================================
-- TEST 8: PREMIUM USER QUERIES
-- ========================================

-- Test premium expiration tracking (should use users_premium_expiry_idx)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id, username, premium_expires_at
FROM users
WHERE is_premium = true
  AND premium_expires_at IS NOT NULL
  AND premium_expires_at < NOW() + INTERVAL '7 days'
ORDER BY premium_expires_at;

-- Expected: Index Scan using users_premium_expiry_idx
-- Target: < 100ms for expiration notifications

-- ========================================
-- PERFORMANCE BENCHMARKS SUMMARY
-- ========================================

/*
EXPECTED PERFORMANCE TARGETS:

CRITICAL QUERIES (< 100ms):
- Who liked me: likes_liked_id_idx
- My sent likes: likes_liker_id_idx  
- Message pagination: messages_match_created_desc_idx
- Moderation queue: profile_photos_pending_idx
- Premium expiration: users_premium_expiry_idx

IMPORTANT QUERIES (< 300ms):
- Active users: users_last_active_idx
- Ride style matching: users_ride_styles_gin_idx
- Language matching: users_languages_gin_idx
- Station matching: user_station_status_matching_idx
- User's matches: matches_user1/user2_created_idx

ANALYTICS QUERIES (< 800ms):
- Daily stats: ride_stats_date_user_idx
- Station popularity: ride_stats_station_date_idx
- Chat list with messages: matches_recent_activity_idx

INDEX USAGE VALIDATION:
- All queries should show "Index Scan" or "Bitmap Index Scan"
- No "Seq Scan" on large tables (users, messages, likes)
- Buffer hits should be high (> 95% for frequently accessed data)
- Query planning time should be minimal (< 5ms)
*/
