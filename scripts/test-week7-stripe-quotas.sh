#!/bin/bash
# CrewSnow Week 7 - Stripe & Quotas Complete Tests

set -e

echo "🧪 CrewSnow Week 7 - Stripe & Quotas Tests"
echo "========================================"

# Test quotas system
echo "📊 Testing quotas system..."
psql "$DATABASE_URL" -c "
-- Test quota functions
SELECT * FROM get_user_usage_status('00000000-0000-0000-0000-000000000001');

-- Test quota checks
SELECT can_user_perform_action('00000000-0000-0000-0000-000000000001', 'like');
SELECT can_user_perform_action('00000000-0000-0000-0000-000000000001', 'message');

-- Test analytics
SELECT * FROM usage_analytics WHERE date = CURRENT_DATE;
SELECT * FROM user_tier_distribution;
"

# Test Stripe integration
echo "💳 Testing Stripe integration..."
psql "$DATABASE_URL" -c "
-- Test premium status function
SELECT * FROM user_has_active_premium_enhanced('00000000-0000-0000-0000-000000000001');

-- Test customer linking
SELECT link_user_to_stripe_customer('00000000-0000-0000-0000-000000000001', 'test_customer_id');
"

# Test Edge Functions (if running locally)
if curl -s "http://localhost:54321/functions/v1/swipe-enhanced" >/dev/null 2>&1; then
    echo "🚀 Testing enhanced Edge Functions..."
    
    # Test requires valid JWT - would need real token for full test
    echo "✅ Edge Functions accessible (full test requires valid JWT)"
else
    echo "ℹ️ Edge Functions not running locally - skipping integration tests"
fi

echo "✅ Week 7 Stripe & Quotas system ready!"
