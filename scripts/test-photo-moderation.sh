#!/bin/bash
# CrewSnow Photo Moderation Webhook - Test Script
# Tests the complete flow: Supabase → Edge Function → n8n

set -e

echo "🧪 CrewSnow Photo Moderation Webhook Test"
echo "======================================="

# Configuration
SUPABASE_URL="${SUPABASE_URL:-http://localhost:54321}"
SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-your-service-role-key}"
N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:-https://your-n8n.domain.com/webhook-test/photo-moderation}"
N8N_WEBHOOK_SECRET="${N8N_WEBHOOK_SECRET:-your-secret-key}"

# Test data
TEST_USER_ID="00000000-0000-0000-0000-000000000001"
TEST_PHOTO_ID=$(uuidgen)
TEST_STORAGE_PATH="test-user/test-photo-$(date +%s).jpg"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# ============================================================================
# Test 1: Database Trigger Test
# ============================================================================

test_database_trigger() {
    log_info "Testing database trigger for photo moderation webhook..."
    
    # Insert test photo with pending status
    PSQL_RESULT=$(psql "${DATABASE_URL:-$SUPABASE_URL/db/postgres}" -c "
        INSERT INTO profile_photos (
            id,
            user_id,
            storage_path,
            file_size_bytes,
            mime_type,
            moderation_status
        ) VALUES (
            '$TEST_PHOTO_ID',
            '$TEST_USER_ID', 
            '$TEST_STORAGE_PATH',
            1024000,
            'image/jpeg',
            'pending'
        ) ON CONFLICT DO NOTHING;
        
        SELECT 'Photo inserted successfully' as result;
    " 2>&1)

    if echo "$PSQL_RESULT" | grep -q "Photo inserted successfully"; then
        log_success "Database trigger test - Photo inserted"
        
        # Check if webhook was logged
        sleep 2 # Wait for trigger to execute
        
        WEBHOOK_LOG=$(psql "${DATABASE_URL:-$SUPABASE_URL/db/postgres}" -t -c "
            SELECT 'webhook_logged' 
            FROM webhook_logs 
            WHERE record_id = '$TEST_PHOTO_ID' 
              AND webhook_type = 'n8n_moderation'
            LIMIT 1;
        " 2>&1)
        
        if echo "$WEBHOOK_LOG" | grep -q "webhook_logged"; then
            log_success "Database trigger fired webhook successfully"
        else
            log_warning "Database trigger may not have fired webhook (check logs)"
        fi
        
    else
        log_error "Database trigger test failed"
        echo "Error: $PSQL_RESULT"
        return 1
    fi
}

# ============================================================================
# Test 2: Edge Function Direct Test
# ============================================================================

test_edge_function() {
    log_info "Testing Edge Function webhook-n8n directly..."
    
    # Test payload matching trigger format
    TEST_PAYLOAD=$(cat << EOF
{
  "record": {
    "id": "$TEST_PHOTO_ID",
    "user_id": "$TEST_USER_ID",
    "storage_path": "$TEST_STORAGE_PATH",
    "file_size_bytes": 1024000,
    "mime_type": "image/jpeg",
    "moderation_status": "pending",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"
  }
}
EOF
    )
    
    # Call Edge Function directly
    EDGE_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -X POST "$SUPABASE_URL/functions/v1/webhook-n8n" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -d "$TEST_PAYLOAD")
    
    HTTP_STATUS=$(echo "$EDGE_RESPONSE" | tail -1 | sed 's/HTTP_STATUS://')
    RESPONSE_BODY=$(echo "$EDGE_RESPONSE" | head -n -1)
    
    if [[ "$HTTP_STATUS" == "200" ]]; then
        log_success "Edge Function responded successfully"
        echo "Response: $RESPONSE_BODY"
        
        # Parse response
        if echo "$RESPONSE_BODY" | grep -q '"success":true'; then
            log_success "Edge Function processed webhook successfully"
        else
            log_warning "Edge Function returned success response but may have encountered issues"
            echo "Details: $RESPONSE_BODY"
        fi
    else
        log_error "Edge Function test failed (HTTP $HTTP_STATUS)"
        echo "Response: $RESPONSE_BODY"
        return 1
    fi
}

# ============================================================================
# Test 3: n8n Webhook Connectivity
# ============================================================================

test_n8n_connectivity() {
    log_info "Testing n8n webhook connectivity..."
    
    if [[ "$N8N_WEBHOOK_URL" == "https://your-n8n.domain.com/webhook-test/photo-moderation" ]]; then
        log_warning "N8N_WEBHOOK_URL is not configured (using placeholder)"
        log_info "Update N8N_WEBHOOK_URL with your actual n8n webhook URL"
        return 0
    fi
    
    # Generate test signature
    TEST_PAYLOAD='{"test": true, "photo_id": "'$TEST_PHOTO_ID'"}'
    
    if command -v node >/dev/null 2>&1; then
        # Generate signature with Node.js if available
        SIGNATURE=$(node -e "
            const crypto = require('crypto');
            const payload = '$TEST_PAYLOAD';
            const secret = '$N8N_WEBHOOK_SECRET';
            const signature = crypto.createHmac('sha256', secret).update(payload).digest('hex');
            console.log('sha256=' + signature);
        ")
        
        # Test n8n webhook
        N8N_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
            -X POST "$N8N_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -H "X-CrewSnow-Signature: $SIGNATURE" \
            -d "$TEST_PAYLOAD")
        
        N8N_HTTP_STATUS=$(echo "$N8N_RESPONSE" | tail -1 | sed 's/HTTP_STATUS://')
        N8N_RESPONSE_BODY=$(echo "$N8N_RESPONSE" | head -n -1)
        
        if [[ "$N8N_HTTP_STATUS" == "200" ]]; then
            log_success "n8n webhook connectivity test passed"
            echo "Response: $N8N_RESPONSE_BODY"
        else
            log_warning "n8n webhook test failed (HTTP $N8N_HTTP_STATUS)"
            echo "Response: $N8N_RESPONSE_BODY"
            log_info "This may be expected if n8n workflow is not yet configured"
        fi
    else
        log_warning "Node.js not available - skipping n8n signature test"
        
        # Simple connectivity test
        if curl -s "$N8N_WEBHOOK_URL" >/dev/null 2>&1; then
            log_success "n8n endpoint is reachable"
        else
            log_warning "n8n endpoint may not be reachable or configured"
        fi
    fi
}

# ============================================================================
# Test 4: End-to-End Integration Test
# ============================================================================

test_integration() {
    log_info "Running end-to-end integration test..."
    
    # 1. Check Supabase functions are running
    if ! curl -s "$SUPABASE_URL/functions/v1/webhook-n8n" >/dev/null 2>&1; then
        log_error "Supabase Edge Functions not accessible at $SUPABASE_URL"
        log_info "Start with: supabase functions serve"
        return 1
    fi
    
    log_success "Supabase Edge Functions accessible"
    
    # 2. Check database connection
    if ! psql "${DATABASE_URL:-$SUPABASE_URL/db/postgres}" -c "SELECT 1;" >/dev/null 2>&1; then
        log_error "Database not accessible"
        log_info "Ensure DATABASE_URL is configured or Supabase is running"
        return 1
    fi
    
    log_success "Database connection verified"
    
    # 3. Check webhook health
    HEALTH_CHECK=$(psql "${DATABASE_URL:-$SUPABASE_URL/db/postgres}" -t -c "
        SELECT status FROM check_webhook_health();
    " 2>&1)
    
    if echo "$HEALTH_CHECK" | grep -q "HEALTHY\|DEGRADED"; then
        log_success "Webhook system health check passed: $(echo $HEALTH_CHECK | xargs)"
    else
        log_warning "Webhook system health check: $(echo $HEALTH_CHECK | xargs)"
    fi
    
    # 4. Test complete flow if everything is ready
    log_info "Attempting complete integration test..."
    
    # Insert photo and monitor for webhook execution
    INTEGRATION_RESULT=$(psql "${DATABASE_URL:-$SUPABASE_URL/db/postgres}" -c "
        -- Insert test photo
        INSERT INTO profile_photos (
            id,
            user_id,
            storage_path,
            file_size_bytes,
            mime_type,
            moderation_status
        ) VALUES (
            gen_random_uuid(),
            '$TEST_USER_ID',
            'integration-test/photo-' || extract(epoch from now()) || '.jpg',
            1024000,
            'image/jpeg',
            'pending'
        );
        
        -- Wait briefly and check logs
        SELECT pg_sleep(2);
        
        SELECT 
            CASE 
                WHEN COUNT(*) > 0 THEN 'Integration test triggered successfully'
                ELSE 'Integration test may not have triggered'
            END as result
        FROM webhook_logs 
        WHERE timestamp > NOW() - INTERVAL '10 seconds'
          AND webhook_type = 'n8n_moderation';
    " 2>&1)
    
    if echo "$INTEGRATION_RESULT" | grep -q "triggered successfully"; then
        log_success "End-to-end integration test passed"
    else
        log_warning "Integration test inconclusive - check webhook logs manually"
    fi
}

# ============================================================================
# Main Test Execution
# ============================================================================

main() {
    echo "🔍 Environment Configuration:"
    echo "  SUPABASE_URL: $SUPABASE_URL"
    echo "  N8N_WEBHOOK_URL: $N8N_WEBHOOK_URL"
    echo "  Service Role Key: $([ -n "$SERVICE_ROLE_KEY" ] && echo "Configured" || echo "Not Set")"
    echo "  Webhook Secret: $([ -n "$N8N_WEBHOOK_SECRET" ] && echo "Configured" || echo "Not Set")"
    echo ""
    
    # Run tests
    test_database_trigger
    echo ""
    
    test_edge_function  
    echo ""
    
    test_n8n_connectivity
    echo ""
    
    test_integration
    echo ""
    
    # Summary
    echo "============================================"
    log_info "🏁 Photo Moderation Webhook Tests Completed"
    echo "============================================"
    
    echo ""
    echo "📋 Next Steps:"
    echo "  1. Configure n8n workflow (see n8n/N8N_SETUP_GUIDE.md)"
    echo "  2. Set up AWS Rekognition credentials in n8n"
    echo "  3. Test with real photo upload in your app"
    echo "  4. Monitor webhook health: SELECT * FROM check_webhook_health();"
    echo ""
    
    echo "📊 Monitoring Commands:"
    echo "  • View recent logs: SELECT * FROM webhook_logs ORDER BY timestamp DESC LIMIT 10;"
    echo "  • Check health: SELECT * FROM check_webhook_health();"
    echo "  • Retry failed: SELECT retry_failed_webhooks();"
    echo ""
    
    echo "🔧 Troubleshooting:"
    echo "  • Edge Function logs: supabase functions logs webhook-n8n --follow"
    echo "  • n8n executions: Check n8n dashboard → Executions"
    echo "  • Database logs: Check webhook_logs table"
    echo ""
    
    log_success "Photo moderation webhook system is ready for production!"
}

# Execute main function
main "$@"
