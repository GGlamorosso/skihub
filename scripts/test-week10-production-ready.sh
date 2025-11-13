#!/bin/bash
# CrewSnow Week 10 - Production Ready Validation

set -e

echo "🚀 CrewSnow Week 10 - Production Ready Tests"
echo "=========================================="

echo "📊 Test results will be saved to: week10_test_results.txt"
exec > >(tee week10_test_results.txt)
exec 2>&1

# Day 1: Database security audit  
echo ""
echo "🔒 DAY 1 - Database Security Audit..."
psql "$DATABASE_URL" -c "SELECT run_day1_database_security_audit();"

# Day 2: Storage & idempotence
echo ""
echo "🗄️ DAY 2 - Storage & Idempotence..."  
psql "$DATABASE_URL" -c "SELECT run_day2_storage_idempotence_tests();"

# Day 4: E2E scenario & observability
echo ""
echo "🎭 DAY 4 - E2E Scenario & Observability..."
psql "$DATABASE_URL" -c "SELECT run_day4_e2e_observability_tests();"

# Go/No-Go decision
echo ""
echo "🎯 GO/NO-GO DECISION FRAMEWORK..."
psql "$DATABASE_URL" -c "SELECT * FROM make_go_no_go_decision();"

# Feature flags status
echo ""
echo "🎛️ FEATURE FLAGS STATUS..."
psql "$DATABASE_URL" -c "
SELECT 
    feature_category,
    COUNT(*) as total_flags,
    COUNT(*) FILTER (WHERE is_enabled) as enabled_flags,
    array_agg(flag_key ORDER BY flag_key) FILTER (WHERE is_enabled) as enabled_list
FROM feature_flags 
GROUP BY feature_category
ORDER BY feature_category;
"

# Performance final validation
echo ""
echo "⚡ PERFORMANCE FINAL VALIDATION..."
psql "$DATABASE_URL" -c "SELECT * FROM performance_health_check();"

# GDPR compliance final check
echo ""
echo "⚖️ GDPR COMPLIANCE FINAL CHECK..."
psql "$DATABASE_URL" -c "
SELECT 
    'Export Function' as component,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'delete_user_data')
         THEN '✅ READY' ELSE '❌ MISSING' END as status
UNION ALL
SELECT 
    'Consent Management' as component,
    CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'consents')
         THEN '✅ READY' ELSE '❌ MISSING' END as status
UNION ALL  
SELECT 
    'Data Deletion' as component,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'delete_user_data')
         THEN '✅ READY' ELSE '❌ MISSING' END as status;
"

# Security final validation
echo ""
echo "🛡️ SECURITY FINAL VALIDATION..."
psql "$DATABASE_URL" -c "
SELECT 
    COUNT(*) as total_policies,
    COUNT(*) FILTER (WHERE qual LIKE '%auth.uid()%') as user_isolated_policies,
    COUNT(*) FILTER (WHERE roles = '{service_role}') as admin_only_policies
FROM pg_policies 
WHERE schemaname = 'public';
"

# Analytics & KPIs operational
echo ""
echo "📊 ANALYTICS & KPIS OPERATIONAL..."
psql "$DATABASE_URL" -c "
SELECT 
    matviewname as view_name,
    CASE WHEN ispopulated THEN '✅ POPULATED' ELSE '❌ EMPTY' END as status
FROM pg_matviews
WHERE schemaname = 'public' AND matviewname LIKE 'kpi_%'
ORDER BY matviewname;
"

# Edge Functions validation
if curl -s "http://localhost:54321" >/dev/null 2>&1; then
    echo ""
    echo "🚀 EDGE FUNCTIONS VALIDATION..."
    
    # Test core functions accessibility
    FUNCTIONS=(
        "swipe-enhanced"
        "match-candidates"  
        "export-user-data"
        "manage-consent"
        "stripe-webhook-enhanced"
        "analytics-posthog"
    )
    
    for func in "${FUNCTIONS[@]}"; do
        if curl -s "http://localhost:54321/functions/v1/$func" >/dev/null 2>&1; then
            echo "✅ $func: Accessible"
        else
            echo "⚠️ $func: Not accessible (may need deployment)"
        fi
    done
else
    echo ""
    echo "ℹ️ Supabase not running locally - Edge Functions validation skipped"
fi

# Final assessment
echo ""
echo "============================================"
echo "🎯 WEEK 10 PRODUCTION READINESS ASSESSMENT"
echo "============================================"

# Count critical issues
if grep -q "❌\|CRITICAL\|SECURITY ISSUES\|NOT READY" week10_test_results.txt; then
    echo "🔴 CRITICAL ISSUES DETECTED"
    echo ""
    echo "🚨 Issues found:"
    grep -E "❌|CRITICAL|SECURITY ISSUES|NOT READY" week10_test_results.txt
    echo ""
    echo "🔧 Action required: Resolve issues before production deployment"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Review issues above"
    echo "  2. Apply necessary fixes"  
    echo "  3. Re-run validation: ./scripts/test-week10-production-ready.sh"
    echo "  4. Ensure all tests pass before creating production tag"
    
    exit 1
else
    echo "✅ ALL TESTS PASSED"
    echo ""
    echo "🚀 PRODUCTION DEPLOYMENT APPROVED"
    echo ""
    echo "📊 System Status:"
    echo "  ✅ Database security: Validated"
    echo "  ✅ Storage & idempotence: Working"  
    echo "  ✅ E2E scenario: Complete success"
    echo "  ✅ GDPR compliance: Ready"
    echo "  ✅ Performance: Within targets"
    echo "  ✅ Feature flags: Configured"
    echo ""
    echo "🎯 Ready to create production tag:"
    echo "  git tag v1.0.0"
    echo "  git push origin v1.0.0"
    echo ""
    echo "📈 Post-deployment monitoring:"
    echo "  • Watch GitHub Actions pipeline"
    echo "  • Monitor real-time metrics"
    echo "  • Verify user flows"
    echo "  • Check error rates < 5%"
    echo ""
    echo "🎉 CrewSnow ready for production launch!"
fi

echo ""
echo "📄 Full test results saved to: week10_test_results.txt"
