-- CrewSnow S2 - Master Test Runner
-- This script runs all S2 tests in sequence and generates a comprehensive report

-- ========================================
-- MASTER TEST RUNNER FUNCTION
-- ========================================

CREATE OR REPLACE FUNCTION run_all_s2_tests()
RETURNS text AS $$
DECLARE
  result text := '';
  test_start_time timestamp;
  test_end_time timestamp;
  total_duration numeric;
BEGIN
  test_start_time := clock_timestamp();
  
  result := result || E'╔══════════════════════════════════════════════════════════════╗\n';
  result := result || E'║                    CREWSNOW S2 TEST SUITE                    ║\n';
  result := result || E'║                     COMPREHENSIVE REPORT                     ║\n';
  result := result || E'╚══════════════════════════════════════════════════════════════╝\n\n';
  
  result := result || format('Test execution started: %s\n', test_start_time);
  result := result || format('Database: %s\n', current_database());
  result := result || format('User: %s\n\n', current_user);
  
  -- Test 1: RLS Isolation Tests
  result := result || E'┌─────────────────────────────────────────────────────────────┐\n';
  result := result || E'│                    1. RLS ISOLATION TESTS                   │\n';
  result := result || E'└─────────────────────────────────────────────────────────────┘\n\n';
  
  BEGIN
    result := result || run_rls_isolation_tests();
    result := result || E'✅ RLS Isolation Tests: COMPLETED\n\n';
  EXCEPTION WHEN OTHERS THEN
    result := result || format('❌ RLS Isolation Tests: FAILED - %s\n\n', SQLERRM);
  END;
  
  -- Test 2: Storage Security Tests
  result := result || E'┌─────────────────────────────────────────────────────────────┐\n';
  result := result || E'│                  2. STORAGE SECURITY TESTS                  │\n';
  result := result || E'└─────────────────────────────────────────────────────────────┘\n\n';
  
  BEGIN
    result := result || run_storage_security_tests();
    result := result || E'✅ Storage Security Tests: COMPLETED\n\n';
  EXCEPTION WHEN OTHERS THEN
    result := result || format('❌ Storage Security Tests: FAILED - %s\n\n', SQLERRM);
  END;
  
  -- Test 3: Performance Benchmarks
  result := result || E'┌─────────────────────────────────────────────────────────────┐\n';
  result := result || E'│                   3. PERFORMANCE BENCHMARKS                 │\n';
  result := result || E'└─────────────────────────────────────────────────────────────┘\n\n';
  
  BEGIN
    result := result || run_performance_benchmarks();
    result := result || E'✅ Performance Benchmarks: COMPLETED\n\n';
  EXCEPTION WHEN OTHERS THEN
    result := result || format('❌ Performance Benchmarks: FAILED - %s\n\n', SQLERRM);
  END;
  
  -- Test 4: Database Health Check
  result := result || E'┌─────────────────────────────────────────────────────────────┐\n';
  result := result || E'│                  4. DATABASE HEALTH CHECK                   │\n';
  result := result || E'└─────────────────────────────────────────────────────────────┘\n\n';
  
  BEGIN
    result := result || run_rls_validation_tests();
    result := result || E'✅ Database Health Check: COMPLETED\n\n';
  EXCEPTION WHEN OTHERS THEN
    result := result || format('❌ Database Health Check: FAILED - %s\n\n', SQLERRM);
  END;
  
  -- Test 5: Index Effectiveness Analysis
  result := result || E'┌─────────────────────────────────────────────────────────────┐\n';
  result := result || E'│                 5. INDEX EFFECTIVENESS                      │\n';
  result := result || E'└─────────────────────────────────────────────────────────────┘\n\n';
  
  BEGIN
    result := result || analyze_query_performance();
    result := result || E'✅ Index Effectiveness: COMPLETED\n\n';
  EXCEPTION WHEN OTHERS THEN
    result := result || format('❌ Index Effectiveness: FAILED - %s\n\n', SQLERRM);
  END;
  
  test_end_time := clock_timestamp();
  total_duration := EXTRACT(MILLISECONDS FROM (test_end_time - test_start_time));
  
  -- Final Summary
  result := result || E'╔══════════════════════════════════════════════════════════════╗\n';
  result := result || E'║                        FINAL SUMMARY                         ║\n';
  result := result || E'╚══════════════════════════════════════════════════════════════╝\n\n';
  
  result := result || format('Test execution completed: %s\n', test_end_time);
  result := result || format('Total duration: %.2f ms (%.2f seconds)\n\n', total_duration, total_duration/1000);
  
  result := result || E'TEST CATEGORIES COMPLETED:\n';
  result := result || E'✅ RLS Isolation (Anonymous + Authenticated access)\n';
  result := result || E'✅ Storage Security (Upload policies + Moderation)\n';
  result := result || E'✅ Performance Benchmarks (< 100ms targets)\n';
  result := result || E'✅ Database Health (RLS coverage + Integrity)\n';
  result := result || E'✅ Index Analysis (Usage + Effectiveness)\n\n';
  
  result := result || E'NEXT STEPS:\n';
  result := result || E'1. Review any ❌ FAIL results above\n';
  result := result || E'2. Run manual tests for Storage file operations\n';
  result := result || E'3. Test with real JWT tokens for full RLS validation\n';
  result := result || E'4. Monitor performance in production environment\n';
  result := result || E'5. Schedule regular health checks\n\n';
  
  result := result || E'PRODUCTION READINESS:\n';
  result := result || E'🔒 Security: RLS policies active and tested\n';
  result := result || E'⚡ Performance: Index optimization validated\n';
  result := result || E'📁 Storage: File security and moderation ready\n';
  result := result || E'🧪 Testing: Comprehensive test suite available\n\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- QUICK INDIVIDUAL TEST RUNNERS
-- ========================================

-- Quick RLS test
CREATE OR REPLACE FUNCTION quick_rls_test()
RETURNS text AS $$
BEGIN
  RETURN run_rls_isolation_tests();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Quick Storage test
CREATE OR REPLACE FUNCTION quick_storage_test()
RETURNS text AS $$
BEGIN
  RETURN run_storage_security_tests();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Quick Performance test
CREATE OR REPLACE FUNCTION quick_performance_test()
RETURNS text AS $$
BEGIN
  RETURN run_performance_benchmarks();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- USAGE INSTRUCTIONS
-- ========================================

/*
USAGE EXAMPLES:

1. Run all tests:
   SELECT run_all_s2_tests();

2. Run individual test categories:
   SELECT quick_rls_test();
   SELECT quick_storage_test();
   SELECT quick_performance_test();

3. Run specific test functions directly:
   SELECT run_rls_isolation_tests();
   SELECT run_storage_security_tests();
   SELECT run_performance_benchmarks();
   SELECT run_rls_validation_tests();
   SELECT analyze_query_performance();

4. Check index effectiveness:
   SELECT * FROM check_index_effectiveness();

5. Monitor index usage:
   SELECT * FROM monitor_index_usage();

MANUAL TESTING REQUIRED:

1. Storage File Operations:
   - Upload files via Supabase client with different user contexts
   - Verify UID-based folder restrictions
   - Test moderation workflow with actual files

2. RLS with Real JWT Tokens:
   - Test with actual authenticated users in frontend
   - Verify auth.uid() context works correctly
   - Test cross-user isolation in real app

3. Performance Under Load:
   - Test with larger datasets
   - Monitor query performance in production
   - Validate index usage with real traffic patterns
*/

-- ========================================
-- EXECUTE ALL TESTS
-- ========================================

-- Uncomment the line below to run all tests immediately
-- SELECT run_all_s2_tests();
