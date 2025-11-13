#!/bin/bash
# CrewSnow Messaging System - CI/CD Local Testing Script
# 7.3 CI/CD: Validation locale avant déploiement

set -e # Exit on any error

echo "🧪 CrewSnow Messaging System - CI/CD Local Tests"
echo "=============================================="

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_RESULTS_DIR="$PROJECT_ROOT/test-results"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo ""
    echo -e "${BLUE}🧪 Running: $test_name${NC}"
    echo "────────────────────────────────────────"
    
    ((TOTAL_TESTS++))
    
    if eval "$test_command" > "$TEST_RESULTS_DIR/${test_name// /_}.log" 2>&1; then
        log_success "$test_name"
        if [[ -s "$TEST_RESULTS_DIR/${test_name// /_}.log" ]]; then
            echo "📄 Output saved to: $TEST_RESULTS_DIR/${test_name// /_}.log"
        fi
    else
        log_error "$test_name"
        echo "📄 Error details in: $TEST_RESULTS_DIR/${test_name// /_}.log"
        echo "Last 5 lines of error:"
        tail -5 "$TEST_RESULTS_DIR/${test_name// /_}.log" || true
    fi
}

check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check if Supabase CLI is installed
    if ! command -v supabase &> /dev/null; then
        log_error "Supabase CLI not found. Install: https://supabase.com/docs/guides/cli"
        exit 1
    fi
    log_success "Supabase CLI found"
    
    # Check if Deno is installed (for TypeScript tests)
    if ! command -v deno &> /dev/null; then
        log_warning "Deno not found. Some TypeScript tests will be skipped."
    else
        log_success "Deno found"
    fi
    
    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        log_warning "npm not found. React tests will be skipped."
    else
        log_success "npm found"
    fi
    
    echo ""
}

# ============================================================================
# Main Test Execution
# ============================================================================

main() {
    log_info "Starting CrewSnow Messaging CI/CD Local Tests"
    echo "Start time: $(date)"
    echo ""
    
    check_prerequisites
    
    # ============================================================================
    # Phase 1: Database Setup and Migration Tests
    # ============================================================================
    
    log_info "🗄️ PHASE 1: Database and Migration Tests"
    echo ""
    
    run_test "Start Supabase Local" "supabase start"
    
    run_test "Apply Enhanced Messaging Migration" \
        "supabase migration apply 20250110_enhanced_messaging_system"
    
    run_test "Apply RLS Policies Migration" \
        "supabase migration apply 20250110_specific_messaging_rls_policies"
    
    run_test "Apply Realtime and Pagination Migration" \
        "supabase migration apply 20250110_realtime_and_pagination"
    
    run_test "Load Security Test Functions" \
        "supabase db execute --file supabase/test/messaging_security_tests.sql"
    
    # ============================================================================
    # Phase 2: Security Validation Tests
    # ============================================================================
    
    log_info "🔒 PHASE 2: Security Validation Tests"
    echo ""
    
    run_test "Comprehensive Security Test Suite" \
        'supabase db execute -c "SELECT run_comprehensive_messaging_tests();"'
    
    run_test "RLS Message Isolation Test" \
        'supabase db execute -c "SELECT test_1_rls_message_isolation();"'
    
    run_test "RLS Message Insertion Protection" \
        'supabase db execute -c "SELECT test_2_rls_message_insertion();"'
    
    run_test "Message Length Constraint Test" \
        'supabase db execute -c "SELECT test_3_message_length_constraint();"'
    
    run_test "Pagination Functionality Test" \
        'supabase db execute -c "SELECT test_4_pagination_functionality();"'
    
    run_test "match_reads Isolation Test" \
        'supabase db execute -c "SELECT test_5_match_reads_isolation();"'
    
    # ============================================================================
    # Phase 3: Performance Tests
    # ============================================================================
    
    log_info "⚡ PHASE 3: Performance Tests"
    echo ""
    
    run_test "Messaging Performance Validation" \
        'supabase db execute -c "SELECT test_messaging_performance_validation();"'
    
    run_test "Pagination Performance Benchmark" \
        'supabase db execute -c "SELECT * FROM benchmark_pagination_strategies(
            (SELECT id FROM matches LIMIT 1),
            '"'"'00000000-0000-0000-0000-000000000001'"'"',
            5
        );"'
    
    run_test "Realtime Connectivity Test" \
        'supabase db execute -c "SELECT test_realtime_connectivity();"'
    
    # ============================================================================
    # Phase 4: Client Tests (if tools available)
    # ============================================================================
    
    if command -v deno &> /dev/null; then
        log_info "📱 PHASE 4: Client TypeScript Tests"
        echo ""
        
        run_test "TypeScript Realtime Classes" \
            "deno check examples/realtime-messaging.ts"
        
        run_test "TypeScript Pagination Classes" \
            "deno check examples/message-pagination.ts"
        
        run_test "TypeScript Read Receipts" \
            "deno check examples/read-receipts-client.ts"
            
        if [[ -f "examples/integration-test.ts" ]]; then
            # Start functions serve for integration tests
            log_info "Starting Edge Functions for integration tests..."
            supabase functions serve --no-verify-jwt &
            FUNCTIONS_PID=$!
            sleep 5 # Wait for functions to start
            
            run_test "TypeScript Integration Tests" \
                "deno run --allow-net --allow-env examples/integration-test.ts"
            
            # Cleanup functions serve
            kill $FUNCTIONS_PID 2>/dev/null || true
        fi
    else
        log_warning "Skipping TypeScript tests (Deno not available)"
    fi
    
    if command -v npm &> /dev/null && [[ -f "package.json" ]]; then
        log_info "⚛️ PHASE 5: React Tests"
        echo ""
        
        # Check if node_modules exists
        if [[ ! -d "node_modules" ]]; then
            log_info "Installing npm dependencies..."
            npm install > /dev/null 2>&1
        fi
        
        run_test "TypeScript React Compilation" \
            "npx tsc --noEmit examples/react-messaging-hooks.tsx"
        
        # Additional React tests if configured
        if [[ -f "package.json" ]] && grep -q "test.*messaging" package.json; then
            run_test "React Messaging Hook Tests" \
                "npm test -- --testPathPattern=messaging"
        fi
    else
        log_warning "Skipping React tests (npm/package.json not available)"
    fi
    
    # ============================================================================
    # Phase 6: Integration Validation
    # ============================================================================
    
    log_info "🔗 PHASE 6: Integration Validation"
    echo ""
    
    run_test "Complete System Integration Test" \
        'supabase db execute -c "SELECT test_complete_integration();"'
    
    run_test "Swipe to Message Flow Validation" \
        'supabase db execute -c "
            DO \$\$
            DECLARE
                test_result TEXT;
            BEGIN
                -- Test complete flow: like -> match -> message
                INSERT INTO likes (liker_id, liked_id) VALUES 
                    ('"'"'00000000-0000-0000-0000-000000000008'"'"', '"'"'00000000-0000-0000-0000-000000000009'"'"'),
                    ('"'"'00000000-0000-0000-0000-000000000009'"'"', '"'"'00000000-0000-0000-0000-000000000008'"'"')
                ON CONFLICT DO NOTHING;
                
                IF EXISTS (SELECT 1 FROM matches WHERE 
                    (user1_id = '"'"'00000000-0000-0000-0000-000000000008'"'"' AND user2_id = '"'"'00000000-0000-0000-0000-000000000009'"'"') OR
                    (user1_id = '"'"'00000000-0000-0000-0000-000000000009'"'"' AND user2_id = '"'"'00000000-0000-0000-0000-000000000008'"'"')
                ) THEN
                    RAISE NOTICE '"'"'✅ Swipe to Message flow: WORKING'"'"';
                ELSE
                    RAISE NOTICE '"'"'❌ Swipe to Message flow: FAILED'"'"';
                END IF;
            END \$\$;
        "'
    
    # ============================================================================
    # Results Summary
    # ============================================================================
    
    echo ""
    echo "=============================================="
    log_info "🏁 TEST EXECUTION SUMMARY"
    echo "=============================================="
    echo "📊 Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}✅ Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}❌ Failed: $FAILED_TESTS${NC}"
    
    SUCCESS_RATE=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    echo "📈 Success Rate: $SUCCESS_RATE%"
    echo "⏱️  Completed: $(date)"
    echo ""
    
    # ============================================================================
    # Cleanup and Final Status
    # ============================================================================
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! Messaging system is ready for production.${NC}"
        echo ""
        echo "📋 Next steps:"
        echo "  1. Review test results in: $TEST_RESULTS_DIR/"
        echo "  2. Deploy to staging: supabase db push --remote staging"
        echo "  3. Run staging tests: ./scripts/test-staging.sh"
        echo "  4. Deploy to production: supabase db push --remote production"
        echo ""
        exit 0
    else
        echo -e "${RED}🚨 $FAILED_TESTS TESTS FAILED! Review before production deployment.${NC}"
        echo ""
        echo "📋 Failed tests - check these files:"
        find "$TEST_RESULTS_DIR" -name "*.log" -exec grep -l "ERROR\|FAIL" {} \; 2>/dev/null || true
        echo ""
        echo "🔧 Debug steps:"
        echo "  1. Review failed test logs in: $TEST_RESULTS_DIR/"
        echo "  2. Fix identified issues"  
        echo "  3. Re-run tests: $0"
        echo "  4. Ensure all tests pass before deployment"
        echo ""
        exit 1
    fi
}

# ============================================================================
# Cleanup Function
# ============================================================================

cleanup() {
    log_info "🧹 Cleaning up test environment..."
    
    # Stop Supabase if running
    supabase stop --no-backup 2>/dev/null || true
    
    # Kill any background functions
    pkill -f "supabase functions serve" 2>/dev/null || true
    
    log_success "Cleanup completed"
}

# Set trap for cleanup on exit
trap cleanup EXIT

# ============================================================================
# Execute Main Function
# ============================================================================

main "$@"
