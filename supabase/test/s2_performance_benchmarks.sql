-- CrewSnow S2 - Performance Benchmarks
-- These tests validate that critical queries meet performance targets (< 100ms)

-- ========================================
-- SETUP: Performance Test Environment
-- ========================================

-- Function to measure query execution time
CREATE OR REPLACE FUNCTION measure_query_time(query_text text)
RETURNS TABLE (
  execution_time_ms numeric,
  rows_returned bigint,
  query_plan text
) AS $$
DECLARE
  start_time timestamp;
  end_time timestamp;
  result_count bigint;
  plan_text text;
BEGIN
  -- Get execution plan first
  EXECUTE 'EXPLAIN (FORMAT TEXT) ' || query_text INTO plan_text;
  
  -- Measure execution time
  start_time := clock_timestamp();
  EXECUTE 'SELECT COUNT(*) FROM (' || query_text || ') AS subquery' INTO result_count;
  end_time := clock_timestamp();
  
  RETURN QUERY SELECT 
    EXTRACT(MILLISECONDS FROM (end_time - start_time))::numeric,
    result_count,
    plan_text;
END;
$$ LANGUAGE plpgsql;

-- Function to run performance benchmark for likes queries
CREATE OR REPLACE FUNCTION benchmark_likes_performance()
RETURNS text AS $$
DECLARE
  result text := '';
  test_user_id UUID := '00000000-0000-0000-0000-000000000001';
  exec_time numeric;
  row_count bigint;
  plan_text text;
  target_time numeric := 100; -- Target: < 100ms
BEGIN
  result := result || E'=== LIKES PERFORMANCE BENCHMARKS ===\n\n';
  
  -- Test 1: "Who liked me" query (should use likes_liked_id_idx)
  result := result || E'Test 1: "Who liked me" query\n';
  result := result || format('Query: SELECT * FROM likes WHERE liked_id = ''%s''\n', test_user_id);
  
  SELECT execution_time_ms, rows_returned, query_plan 
  INTO exec_time, row_count, plan_text
  FROM measure_query_time(
    format('SELECT * FROM likes WHERE liked_id = ''%s''', test_user_id)
  );
  
  result := result || format('Execution time: %.2f ms\n', exec_time);
  result := result || format('Rows returned: %s\n', row_count);
  
  IF exec_time < target_time THEN
    result := result || format('✅ PASS: Query under target (%s ms)\n', target_time);
  ELSE
    result := result || format('❌ FAIL: Query over target (%s ms)\n', target_time);
  END IF;
  
  -- Check if index is being used
  IF plan_text LIKE '%likes_liked_id_idx%' OR plan_text LIKE '%Index Scan%' THEN
    result := result || E'✅ PASS: Using index scan\n';
  ELSE
    result := result || E'❌ FAIL: Not using expected index\n';
    result := result || format('Plan: %s\n', plan_text);
  END IF;
  
  result := result || E'\n';
  
  -- Test 2: "My sent likes" query (should use likes_liker_id_idx)
  result := result || E'Test 2: "My sent likes" query\n';
  result := result || format('Query: SELECT * FROM likes WHERE liker_id = ''%s''\n', test_user_id);
  
  SELECT execution_time_ms, rows_returned, query_plan 
  INTO exec_time, row_count, plan_text
  FROM measure_query_time(
    format('SELECT * FROM likes WHERE liker_id = ''%s''', test_user_id)
  );
  
  result := result || format('Execution time: %.2f ms\n', exec_time);
  result := result || format('Rows returned: %s\n', row_count);
  
  IF exec_time < target_time THEN
    result := result || format('✅ PASS: Query under target (%s ms)\n', target_time);
  ELSE
    result := result || format('❌ FAIL: Query over target (%s ms)\n', target_time);
  END IF;
  
  -- Check if index is being used
  IF plan_text LIKE '%likes_liker_id_idx%' OR plan_text LIKE '%Index Scan%' THEN
    result := result || E'✅ PASS: Using index scan\n';
  ELSE
    result := result || E'❌ FAIL: Not using expected index\n';
    result := result || format('Plan: %s\n', plan_text);
  END IF;
  
  result := result || E'\n';
  
  -- Test 3: Combined likes query (likes given and received)
  result := result || E'Test 3: Combined likes query (given + received)\n';
  result := result || format('Query: SELECT * FROM likes WHERE liker_id = ''%s'' OR liked_id = ''%s''\n', 
    test_user_id, test_user_id);
  
  SELECT execution_time_ms, rows_returned, query_plan 
  INTO exec_time, row_count, plan_text
  FROM measure_query_time(
    format('SELECT * FROM likes WHERE liker_id = ''%s'' OR liked_id = ''%s''', 
      test_user_id, test_user_id)
  );
  
  result := result || format('Execution time: %.2f ms\n', exec_time);
  result := result || format('Rows returned: %s\n', row_count);
  
  IF exec_time < target_time THEN
    result := result || format('✅ PASS: Query under target (%s ms)\n', target_time);
  ELSE
    result := result || format('❌ FAIL: Query over target (%s ms)\n', target_time);
  END IF;
  
  result := result || E'\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to run performance benchmark for messages queries
CREATE OR REPLACE FUNCTION benchmark_messages_performance()
RETURNS text AS $$
DECLARE
  result text := '';
  test_match_id UUID;
  exec_time numeric;
  row_count bigint;
  plan_text text;
  target_time numeric := 100; -- Target: < 100ms
BEGIN
  result := result || E'=== MESSAGES PERFORMANCE BENCHMARKS ===\n\n';
  
  -- Get a test match ID
  SELECT id INTO test_match_id FROM matches LIMIT 1;
  
  IF test_match_id IS NULL THEN
    result := result || E'❌ SKIP: No matches found for testing\n\n';
    RETURN result;
  END IF;
  
  -- Test 1: Message pagination query (should use messages_match_created_desc_idx)
  result := result || E'Test 1: Message pagination (newest first)\n';
  result := result || format('Query: SELECT * FROM messages WHERE match_id = ''%s'' ORDER BY created_at DESC LIMIT 50\n', test_match_id);
  
  SELECT execution_time_ms, rows_returned, query_plan 
  INTO exec_time, row_count, plan_text
  FROM measure_query_time(
    format('SELECT * FROM messages WHERE match_id = ''%s'' ORDER BY created_at DESC LIMIT 50', test_match_id)
  );
  
  result := result || format('Execution time: %.2f ms\n', exec_time);
  result := result || format('Rows returned: %s\n', row_count);
  
  IF exec_time < target_time THEN
    result := result || format('✅ PASS: Query under target (%s ms)\n', target_time);
  ELSE
    result := result || format('❌ FAIL: Query over target (%s ms)\n', target_time);
  END IF;
  
  -- Check if correct index is being used
  IF plan_text LIKE '%messages_match_created_desc_idx%' OR 
     (plan_text LIKE '%Index Scan%' AND plan_text LIKE '%created_at%') THEN
    result := result || E'✅ PASS: Using optimized index for DESC ordering\n';
  ELSE
    result := result || E'❌ FAIL: Not using expected DESC index\n';
    result := result || format('Plan: %s\n', plan_text);
  END IF;
  
  result := result || E'\n';
  
  -- Test 2: Message count per match
  result := result || E'Test 2: Message count per match\n';
  result := result || format('Query: SELECT COUNT(*) FROM messages WHERE match_id = ''%s''\n', test_match_id);
  
  SELECT execution_time_ms, rows_returned, query_plan 
  INTO exec_time, row_count, plan_text
  FROM measure_query_time(
    format('SELECT COUNT(*) FROM messages WHERE match_id = ''%s''', test_match_id)
  );
  
  result := result || format('Execution time: %.2f ms\n', exec_time);
  result := result || format('Count result: %s\n', row_count);
  
  IF exec_time < target_time THEN
    result := result || format('✅ PASS: Count query under target (%s ms)\n', target_time);
  ELSE
    result := result || format('❌ FAIL: Count query over target (%s ms)\n', target_time);
  END IF;
  
  result := result || E'\n';
  
  -- Test 3: Recent messages across all matches (chat list)
  result := result || E'Test 3: Recent messages for chat list\n';
  result := result || E'Query: SELECT DISTINCT ON (match_id) * FROM messages ORDER BY match_id, created_at DESC LIMIT 20\n';
  
  SELECT execution_time_ms, rows_returned, query_plan 
  INTO exec_time, row_count, plan_text
  FROM measure_query_time(
    'SELECT DISTINCT ON (match_id) match_id, created_at, content FROM messages ORDER BY match_id, created_at DESC LIMIT 20'
  );
  
  result := result || format('Execution time: %.2f ms\n', exec_time);
  result := result || format('Rows returned: %s\n', row_count);
  
  IF exec_time < target_time THEN
    result := result || format('✅ PASS: Chat list query under target (%s ms)\n', target_time);
  ELSE
    result := result || format('❌ FAIL: Chat list query over target (%s ms)\n', target_time);
  END IF;
  
  result := result || E'\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to benchmark matching algorithm queries
CREATE OR REPLACE FUNCTION benchmark_matching_performance()
RETURNS text AS $$
DECLARE
  result text := '';
  test_station_id UUID;
  exec_time numeric;
  row_count bigint;
  plan_text text;
  target_time numeric := 300; -- Target: < 300ms for complex matching
BEGIN
  result := result || E'=== MATCHING ALGORITHM BENCHMARKS ===\n\n';
  
  -- Get a test station ID
  SELECT id INTO test_station_id FROM stations WHERE name = 'Val Thorens' LIMIT 1;
  
  IF test_station_id IS NULL THEN
    SELECT id INTO test_station_id FROM stations LIMIT 1;
  END IF;
  
  IF test_station_id IS NULL THEN
    result := result || E'❌ SKIP: No stations found for testing\n\n';
    RETURN result;
  END IF;
  
  -- Test 1: Users by ride style (should use GIN index)
  result := result || E'Test 1: Users by ride style (array search)\n';
  result := result || E'Query: SELECT * FROM users WHERE ride_styles @> ARRAY[''alpine''] AND is_active = true\n';
  
  SELECT execution_time_ms, rows_returned, query_plan 
  INTO exec_time, row_count, plan_text
  FROM measure_query_time(
    'SELECT * FROM users WHERE ride_styles @> ARRAY[''alpine'']::ride_style[] AND is_active = true AND is_banned = false'
  );
  
  result := result || format('Execution time: %.2f ms\n', exec_time);
  result := result || format('Rows returned: %s\n', row_count);
  
  IF exec_time < target_time THEN
    result := result || format('✅ PASS: Ride style query under target (%s ms)\n', target_time);
  ELSE
    result := result || format('❌ FAIL: Ride style query over target (%s ms)\n', target_time);
  END IF;
  
  -- Check for GIN index usage
  IF plan_text LIKE '%users_ride_styles_gin_idx%' OR plan_text LIKE '%Bitmap Index Scan%' THEN
    result := result || E'✅ PASS: Using GIN index for array search\n';
  ELSE
    result := result || E'❌ FAIL: Not using expected GIN index\n';
  END IF;
  
  result := result || E'\n';
  
  -- Test 2: Users by language (should use GIN index)
  result := result || E'Test 2: Users by language (array search)\n';
  result := result || E'Query: SELECT * FROM users WHERE languages @> ARRAY[''en''] AND is_active = true\n';
  
  SELECT execution_time_ms, rows_returned, query_plan 
  INTO exec_time, row_count, plan_text
  FROM measure_query_time(
    'SELECT * FROM users WHERE languages @> ARRAY[''en'']::language_code[] AND is_active = true AND is_banned = false'
  );
  
  result := result || format('Execution time: %.2f ms\n', exec_time);
  result := result || format('Rows returned: %s\n', row_count);
  
  IF exec_time < target_time THEN
    result := result || format('✅ PASS: Language query under target (%s ms)\n', target_time);
  ELSE
    result := result || format('❌ FAIL: Language query over target (%s ms)\n', target_time);
  END IF;
  
  result := result || E'\n';
  
  -- Test 3: Station-based matching
  result := result || E'Test 3: Station-based user matching\n';
  result := result || format('Query: Users at station with date overlap\n');
  
  SELECT execution_time_ms, rows_returned, query_plan 
  INTO exec_time, row_count, plan_text
  FROM measure_query_time(
    format('SELECT * FROM user_station_status WHERE station_id = ''%s'' AND date_from <= CURRENT_DATE + 7 AND date_to >= CURRENT_DATE', test_station_id)
  );
  
  result := result || format('Execution time: %.2f ms\n', exec_time);
  result := result || format('Rows returned: %s\n', row_count);
  
  IF exec_time < target_time THEN
    result := result || format('✅ PASS: Station matching under target (%s ms)\n', target_time);
  ELSE
    result := result || format('❌ FAIL: Station matching over target (%s ms)\n', target_time);
  END IF;
  
  result := result || E'\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to benchmark moderation queue performance
CREATE OR REPLACE FUNCTION benchmark_moderation_performance()
RETURNS text AS $$
DECLARE
  result text := '';
  exec_time numeric;
  row_count bigint;
  plan_text text;
  target_time numeric := 100; -- Target: < 100ms for admin interface
BEGIN
  result := result || E'=== MODERATION QUEUE BENCHMARKS ===\n\n';
  
  -- Test 1: Pending photos queue (should use partial index)
  result := result || E'Test 1: Pending photos moderation queue\n';
  result := result || E'Query: SELECT * FROM profile_photos WHERE moderation_status = ''pending'' ORDER BY created_at LIMIT 50\n';
  
  SELECT execution_time_ms, rows_returned, query_plan 
  INTO exec_time, row_count, plan_text
  FROM measure_query_time(
    'SELECT * FROM profile_photos WHERE moderation_status = ''pending'' ORDER BY created_at LIMIT 50'
  );
  
  result := result || format('Execution time: %.2f ms\n', exec_time);
  result := result || format('Rows returned: %s\n', row_count);
  
  IF exec_time < target_time THEN
    result := result || format('✅ PASS: Moderation queue under target (%s ms)\n', target_time);
  ELSE
    result := result || format('❌ FAIL: Moderation queue over target (%s ms)\n', target_time);
  END IF;
  
  -- Check for partial index usage
  IF plan_text LIKE '%profile_photos_pending_idx%' OR plan_text LIKE '%Index Scan%' THEN
    result := result || E'✅ PASS: Using partial index for pending photos\n';
  ELSE
    result := result || E'❌ FAIL: Not using expected partial index\n';
  END IF;
  
  result := result || E'\n';
  
  -- Test 2: Rejected photos review
  result := result || E'Test 2: Rejected photos review queue\n';
  result := result || E'Query: SELECT * FROM profile_photos WHERE moderation_status = ''rejected'' ORDER BY updated_at DESC LIMIT 20\n';
  
  SELECT execution_time_ms, rows_returned, query_plan 
  INTO exec_time, row_count, plan_text
  FROM measure_query_time(
    'SELECT * FROM profile_photos WHERE moderation_status = ''rejected'' ORDER BY updated_at DESC LIMIT 20'
  );
  
  result := result || format('Execution time: %.2f ms\n', exec_time);
  result := result || format('Rows returned: %s\n', row_count);
  
  IF exec_time < target_time THEN
    result := result || format('✅ PASS: Rejected review under target (%s ms)\n', target_time);
  ELSE
    result := result || format('❌ FAIL: Rejected review over target (%s ms)\n', target_time);
  END IF;
  
  result := result || E'\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- MAIN PERFORMANCE TEST RUNNER
-- ========================================

-- Function to run all performance benchmarks
CREATE OR REPLACE FUNCTION run_performance_benchmarks()
RETURNS text AS $$
DECLARE
  result text := '';
  total_start_time timestamp;
  total_end_time timestamp;
  total_duration numeric;
BEGIN
  total_start_time := clock_timestamp();
  
  result := result || E'CREWSNOW S2 - PERFORMANCE BENCHMARK SUITE\n';
  result := result || E'==========================================\n\n';
  
  result := result || format('Test started at: %s\n\n', total_start_time);
  
  -- Run likes performance tests
  result := result || benchmark_likes_performance();
  
  -- Run messages performance tests
  result := result || benchmark_messages_performance();
  
  -- Run matching algorithm tests
  result := result || benchmark_matching_performance();
  
  -- Run moderation queue tests
  result := result || benchmark_moderation_performance();
  
  total_end_time := clock_timestamp();
  total_duration := EXTRACT(MILLISECONDS FROM (total_end_time - total_start_time));
  
  result := result || E'=== BENCHMARK SUMMARY ===\n';
  result := result || format('Total test duration: %.2f ms\n', total_duration);
  result := result || format('Test completed at: %s\n\n', total_end_time);
  
  result := result || E'=== PERFORMANCE TARGETS ===\n';
  result := result || E'✅ Critical queries: < 100ms (likes, messages, moderation)\n';
  result := result || E'✅ Complex queries: < 300ms (matching algorithms)\n';
  result := result || E'✅ Index usage: Should show Index Scan or Bitmap Index Scan\n';
  result := result || E'❌ Sequential scans: Should be avoided on large tables\n\n';
  
  result := result || E'=== OPTIMIZATION NOTES ===\n';
  result := result || E'- If queries exceed targets, check index usage in query plans\n';
  result := result || E'- Monitor with: SELECT * FROM check_index_effectiveness()\n';
  result := result || E'- Consider ANALYZE TABLE if statistics are stale\n';
  result := result || E'- Use EXPLAIN (ANALYZE, BUFFERS) for detailed analysis\n\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- QUICK TEST EXECUTION
-- ========================================

-- Run the performance benchmark suite
SELECT run_performance_benchmarks();
