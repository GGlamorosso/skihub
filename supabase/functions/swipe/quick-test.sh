#!/bin/bash
# CrewSnow Swipe Function - Quick Test Script
# Usage: ./quick-test.sh

echo "🧪 CrewSnow Swipe Function - Quick Validation Tests"
echo "=================================================="

# Configuration
BASE_URL="http://localhost:54321/functions/v1/swipe"
TEST_JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQifQ.placeholder"
ALICE_ID="00000000-0000-0000-0000-000000000001"
BOB_ID="00000000-0000-0000-0000-000000000002"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

test_count=0
passed_count=0

run_test() {
    local test_name="$1"
    local curl_command="$2"
    local expected_status="$3"
    
    echo ""
    echo -e "${BLUE}🧪 Test: $test_name${NC}"
    echo "────────────────────────────────────────"
    
    # Execute curl command and capture response
    response=$(eval "$curl_command" 2>/dev/null)
    status_code=$(echo "$response" | tail -1)
    response_body=$(echo "$response" | head -n -1)
    
    ((test_count++))
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC} - Status: $status_code"
        echo "Response: $response_body"
        ((passed_count++))
    else
        echo -e "${RED}❌ FAIL${NC} - Expected: $expected_status, Got: $status_code"
        echo "Response: $response_body"
    fi
}

# Check if local Supabase is running
echo -e "${YELLOW}🔍 Checking if local Supabase is running...${NC}"
if ! curl -s "$BASE_URL" >/dev/null 2>&1; then
    echo -e "${RED}❌ Local Supabase functions not accessible at $BASE_URL${NC}"
    echo "Please run: supabase functions serve"
    exit 1
fi
echo -e "${GREEN}✅ Local Supabase is running${NC}"

# Test 1: Valid swipe
run_test "Valid Swipe Request" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL' \
    -H 'Authorization: Bearer $TEST_JWT' \
    -H 'Content-Type: application/json' \
    -d '{\"liker_id\":\"$ALICE_ID\",\"liked_id\":\"$BOB_ID\"}'" \
    "200"

# Test 2: Missing auth header
run_test "Missing Authorization Header" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL' \
    -H 'Content-Type: application/json' \
    -d '{\"liker_id\":\"$ALICE_ID\",\"liked_id\":\"$BOB_ID\"}'" \
    "401"

# Test 3: Self-like
run_test "Self-Like Prevention" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL' \
    -H 'Authorization: Bearer $TEST_JWT' \
    -H 'Content-Type: application/json' \
    -d '{\"liker_id\":\"$ALICE_ID\",\"liked_id\":\"$ALICE_ID\"}'" \
    "400"

# Test 4: Invalid UUID
run_test "Invalid UUID Format" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL' \
    -H 'Authorization: Bearer $TEST_JWT' \
    -H 'Content-Type: application/json' \
    -d '{\"liker_id\":\"invalid-uuid\",\"liked_id\":\"$BOB_ID\"}'" \
    "400"

# Test 5: Wrong HTTP method
run_test "Wrong HTTP Method" \
    "curl -s -w '\n%{http_code}' -X GET '$BASE_URL' \
    -H 'Authorization: Bearer $TEST_JWT'" \
    "405"

# Test 6: CORS preflight
run_test "CORS Preflight" \
    "curl -s -w '\n%{http_code}' -X OPTIONS '$BASE_URL'" \
    "200"

# Test 7: Invalid JSON
run_test "Invalid JSON Payload" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL' \
    -H 'Authorization: Bearer $TEST_JWT' \
    -H 'Content-Type: application/json' \
    -d 'invalid-json'" \
    "400"

# Test 8: Idempotence test (same request twice)
echo ""
echo -e "${BLUE}🧪 Test: Idempotence (Duplicate Request)${NC}"
echo "────────────────────────────────────────"

response1=$(curl -s -w '\n%{http_code}' -X POST "$BASE_URL" \
    -H "Authorization: Bearer $TEST_JWT" \
    -H "Content-Type: application/json" \
    -d "{\"liker_id\":\"$ALICE_ID\",\"liked_id\":\"$BOB_ID\"}")

response2=$(curl -s -w '\n%{http_code}' -X POST "$BASE_URL" \
    -H "Authorization: Bearer $TEST_JWT" \
    -H "Content-Type: application/json" \
    -d "{\"liker_id\":\"$ALICE_ID\",\"liked_id\":\"$BOB_ID\"}")

status1=$(echo "$response1" | tail -1)
status2=$(echo "$response2" | tail -1)
body1=$(echo "$response1" | head -n -1)
body2=$(echo "$response2" | head -n -1)

((test_count++))

if [ "$status1" = "200" ] && [ "$status2" = "200" ] && [ "$body1" = "$body2" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Both requests returned consistent results"
    echo "Response: $body1"
    ((passed_count++))
else
    echo -e "${RED}❌ FAIL${NC} - Inconsistent responses"
    echo "Response 1: $body1 (Status: $status1)"
    echo "Response 2: $body2 (Status: $status2)"
fi

# Summary
echo ""
echo "=================================================="
echo -e "${BLUE}📊 Test Summary${NC}"
echo "=================================================="
echo -e "Total Tests: $test_count"
echo -e "${GREEN}Passed: $passed_count${NC}"
echo -e "${RED}Failed: $((test_count - passed_count))${NC}"

if [ $passed_count -eq $test_count ]; then
    echo -e "${GREEN}🎉 All tests passed! The swipe function is working correctly.${NC}"
    success_rate="100%"
else
    echo -e "${YELLOW}⚠️  Some tests failed. Check the output above for details.${NC}"
    success_rate=$(( (passed_count * 100) / test_count ))"%"
fi

echo -e "Success Rate: $success_rate"

# Instructions
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "1. Run full integration tests: deno run --allow-net integration-test.ts"
echo "2. Update JWT tokens with real tokens from Supabase Auth"
echo "3. Test against production environment"
echo "4. Monitor logs: supabase functions logs swipe --follow"
echo ""

exit 0
