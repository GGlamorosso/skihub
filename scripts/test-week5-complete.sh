#!/bin/bash
# CrewSnow Week 5 Complete Integration Tests

set -e

echo "🧪 CrewSnow Week 5 - Complete Moderation Tests"
echo "============================================="

# Test photo moderation trigger
echo "📸 Testing photo moderation..."
psql "$DATABASE_URL" -c "SELECT test_photo_moderation_complete();"

# Test signed URLs
echo "🔗 Testing signed URL generation..."
psql "$DATABASE_URL" -c "SELECT test_signed_urls();"

# Test message moderation
echo "💬 Testing message moderation..."
psql "$DATABASE_URL" -c "SELECT test_message_moderation();"

# Test complete integration
echo "🔗 Testing complete integration..."
psql "$DATABASE_URL" -c "SELECT test_moderation_integration();"

# Run master test suite
echo "🔒 Running master test suite..."
psql "$DATABASE_URL" -c "SELECT run_moderation_integration_tests();" > week5_test_results.txt

# Check results
if grep -q "❌\|FAILED\|ERROR" week5_test_results.txt; then
    echo "❌ Some tests failed!"
    cat week5_test_results.txt
    exit 1
else
    echo "✅ All Week 5 tests passed!"
fi

echo "📊 Dashboard stats:"
psql "$DATABASE_URL" -c "SELECT * FROM moderation_dashboard;"

echo "🔍 Webhook health:"
psql "$DATABASE_URL" -c "SELECT * FROM check_webhook_health();"

echo "✅ Week 5 validation complete!"
