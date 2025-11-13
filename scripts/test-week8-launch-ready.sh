#!/bin/bash
# CrewSnow Week 8 - Launch Readiness Validation

set -e

echo "🎯 CrewSnow Week 8 - Launch Readiness Tests"
echo "========================================"

# Test KPI system
echo "📊 Testing KPI analytics system..."
psql "$DATABASE_URL" -c "SELECT test_kpis_calculation();"

# Test performance optimization
echo "⚡ Testing performance monitoring..."  
psql "$DATABASE_URL" -c "SELECT test_performance_optimization();"

# Test analytics event tracking
echo "📡 Testing analytics events..."
psql "$DATABASE_URL" -c "SELECT test_analytics_events_tracking();"

# Test launch readiness
echo "🚀 Assessing launch readiness..."
psql "$DATABASE_URL" -c "SELECT test_launch_readiness();"

# Run complete test suite
echo "🧪 Running complete Week 8 test suite..."
psql "$DATABASE_URL" -c "SELECT run_week8_complete_tests();" > week8_test_results.txt

# Launch decision
echo "🎯 Making launch decision..."
psql "$DATABASE_URL" -c "SELECT * FROM make_launch_decision();" > launch_decision.txt

# Check results
if grep -q "READY FOR LAUNCH" launch_decision.txt; then
    echo "🚀 LAUNCH APPROVED!"
    echo "✅ System ready for production"
    cat launch_decision.txt
else
    echo "⚠️ Launch assessment needed"
    echo "📋 Review requirements:"
    psql "$DATABASE_URL" -c "SELECT * FROM launch_monitoring;"
fi

echo ""
echo "📊 Real-time KPIs:"
psql "$DATABASE_URL" -c "SELECT * FROM get_realtime_kpis();"

echo ""  
echo "⚡ Performance health:"
psql "$DATABASE_URL" -c "SELECT * FROM performance_health_check();"

echo ""
echo "✅ Week 8 Analytics & Performance validation complete!"
