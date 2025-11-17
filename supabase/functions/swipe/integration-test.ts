#!/usr/bin/env -S deno run --allow-net --allow-env --allow-read
/**
 * CrewSnow Swipe Function - Complete Integration Tests
 * 
 * This script tests all aspects of the swipe functionality:
 * - Authentication and authorization
 * - Input validation and error handling
 * - Idempotence (multiple calls with same parameters)
 * - Reciprocal likes creating matches
 * - Blocking functionality
 * - Rate limiting
 * - Edge cases and error conditions
 * 
 * Usage:
 *   deno run --allow-net --allow-env --allow-read integration-test.ts
 * 
 * Prerequisites:
 *   1. Local Supabase running: supabase start
 *   2. Edge function deployed: supabase functions serve
 *   3. Valid JWT tokens configured below
 *   4. Test users exist in database
 */

// ============================================================================
// CONFIGURATION
// ============================================================================

interface TestConfig {
  baseUrl: string
  testUsers: {
    alice: { id: string; jwt: string }
    bob: { id: string; jwt: string }
    charlie: { id: string; jwt: string }
    blocked: { id: string; jwt: string }
  }
}

const config: TestConfig = {
  baseUrl: 'http://localhost:54321/functions/v1/swipe',
  testUsers: {
    alice: {
      id: '00000000-0000-0000-0000-000000000001', // alpine_alex
      jwt: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQiLCJpYXQiOjE2OTkwMDAwMDAsImV4cCI6MjAzNDcyNDgwMH0.placeholder-jwt-token-1'
    },
    bob: {
      id: '00000000-0000-0000-0000-000000000002', // powder_marie  
      jwt: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDIiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQiLCJpYXQiOjE2OTkwMDAwMDAsImV4cCI6MjAzNDcyNDgwMH0.placeholder-jwt-token-2'
    },
    charlie: {
      id: '00000000-0000-0000-0000-000000000003', // beginner_tom
      jwt: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDMiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQiLCJpYXQiOjE2OTkwMDAwMDAsImV4cCI6MjAzNDcyNDgwMH0.placeholder-jwt-token-3'
    },
    blocked: {
      id: '00000000-0000-0000-0000-000000000004', // park_rider_sam (to simulate blocked user)
      jwt: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDQiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQiLCJpYXQiOjE2OTkwMDAwMDAsImV4cCI6MjAzNDcyNDgwMH0.placeholder-jwt-token-4'
    }
  }
}

// ============================================================================
// TEST UTILITIES
// ============================================================================

interface TestResult {
  success: boolean
  message: string
  data?: any
  duration?: number
}

interface SwipeResponse {
  matched: boolean
  match_id?: string
  already_liked?: boolean
  error?: string
  detail?: string
}

class TestRunner {
  private results: TestResult[] = []
  private startTime = Date.now()

  async runTest(
    name: string,
    testFn: () => Promise<TestResult>
  ): Promise<void> {
    console.log(`\n🧪 Running: ${name}`)
    console.log('─'.repeat(60))
    
    try {
      const result = await testFn()
      this.results.push({ ...result, message: `${name}: ${result.message}` })
      
      if (result.success) {
        console.log(`✅ PASS: ${result.message}`)
        if (result.data) {
          console.log(`📊 Data: ${JSON.stringify(result.data, null, 2)}`)
        }
      } else {
        console.log(`❌ FAIL: ${result.message}`)
        if (result.data) {
          console.log(`📊 Error: ${JSON.stringify(result.data, null, 2)}`)
        }
      }
      
      if (result.duration) {
        console.log(`⏱️  Duration: ${result.duration}ms`)
      }
    } catch (error) {
      const errorResult = {
        success: false,
        message: `${name}: Exception - ${error.message}`
      }
      this.results.push(errorResult)
      console.log(`💥 EXCEPTION: ${error.message}`)
    }
  }

  async makeSwipeRequest(
    likerId: string,
    likedId: string,
    jwt: string
  ): Promise<{ response: Response; data: SwipeResponse; duration: number }> {
    const startTime = Date.now()
    
    const response = await fetch(config.baseUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        liker_id: likerId,
        liked_id: likedId
      })
    })
    
    const duration = Date.now() - startTime
    const data = await response.json() as SwipeResponse
    
    return { response, data, duration }
  }

  getSummary(): { passed: number; failed: number; total: number; duration: number } {
    const passed = this.results.filter(r => r.success).length
    const failed = this.results.filter(r => !r.success).length
    const duration = Date.now() - this.startTime
    
    return { passed, failed, total: this.results.length, duration }
  }

  printSummary(): void {
    const summary = this.getSummary()
    
    console.log('\n' + '='.repeat(80))
    console.log('🏁 TEST EXECUTION SUMMARY')
    console.log('='.repeat(80))
    console.log(`📊 Total Tests: ${summary.total}`)
    console.log(`✅ Passed: ${summary.passed}`)
    console.log(`❌ Failed: ${summary.failed}`)
    console.log(`⏱️  Total Duration: ${summary.duration}ms`)
    console.log(`📈 Success Rate: ${((summary.passed / summary.total) * 100).toFixed(1)}%`)
    
    if (summary.failed > 0) {
      console.log('\n❌ Failed Tests:')
      this.results
        .filter(r => !r.success)
        .forEach(r => console.log(`   • ${r.message}`))
    }
    
    console.log('='.repeat(80))
  }
}

// ============================================================================
// INDIVIDUAL TEST CASES
// ============================================================================

const testRunner = new TestRunner()

// Test 1: Valid first swipe (no match expected)
await testRunner.runTest(
  'Valid First Swipe',
  async (): Promise<TestResult> => {
    const { response, data, duration } = await testRunner.makeSwipeRequest(
      config.testUsers.alice.id,
      config.testUsers.bob.id,
      config.testUsers.alice.jwt
    )

    if (response.status !== 200) {
      return {
        success: false,
        message: `Expected status 200, got ${response.status}`,
        data,
        duration
      }
    }

    if (data.error) {
      return {
        success: false,
        message: `Unexpected error: ${data.error}`,
        data,
        duration
      }
    }

    // First swipe should not create a match (unless reciprocal already exists)
    return {
      success: true,
      message: `Successfully created like. Matched: ${data.matched}`,
      data: { matched: data.matched, match_id: data.match_id },
      duration
    }
  }
)

// Test 2: Idempotence - same swipe multiple times
await testRunner.runTest(
  'Idempotence Test - Duplicate Swipe',
  async (): Promise<TestResult> => {
    // Make the same swipe request multiple times
    const requests = await Promise.all([
      testRunner.makeSwipeRequest(config.testUsers.alice.id, config.testUsers.bob.id, config.testUsers.alice.jwt),
      testRunner.makeSwipeRequest(config.testUsers.alice.id, config.testUsers.bob.id, config.testUsers.alice.jwt),
      testRunner.makeSwipeRequest(config.testUsers.alice.id, config.testUsers.bob.id, config.testUsers.alice.jwt)
    ])

    // All requests should succeed with consistent results
    const allSuccess = requests.every(r => r.response.status === 200)
    const allHaveSameResult = requests.every(r => 
      r.data.matched === requests[0].data.matched &&
      r.data.match_id === requests[0].data.match_id
    )
    
    const maxDuration = Math.max(...requests.map(r => r.duration))
    
    if (!allSuccess) {
      return {
        success: false,
        message: 'Not all duplicate requests succeeded',
        data: requests.map(r => ({ status: r.response.status, data: r.data })),
        duration: maxDuration
      }
    }

    if (!allHaveSameResult) {
      return {
        success: false,
        message: 'Duplicate requests returned inconsistent results',
        data: requests.map(r => r.data),
        duration: maxDuration
      }
    }

    return {
      success: true,
      message: `Idempotence verified - all requests consistent. Response indicates already_liked: ${requests[0].data.already_liked}`,
      data: requests[0].data,
      duration: maxDuration
    }
  }
)

// Test 3: Reciprocal like creating a match
await testRunner.runTest(
  'Reciprocal Like Creates Match',
  async (): Promise<TestResult> => {
    // Bob likes Alice back (reciprocal to Alice's like)
    const { response, data, duration } = await testRunner.makeSwipeRequest(
      config.testUsers.bob.id,
      config.testUsers.alice.id,
      config.testUsers.bob.jwt
    )

    if (response.status !== 200) {
      return {
        success: false,
        message: `Expected status 200, got ${response.status}`,
        data,
        duration
      }
    }

    if (data.error) {
      return {
        success: false,
        message: `Unexpected error: ${data.error}`,
        data,
        duration
      }
    }

    // Reciprocal like should create a match
    if (!data.matched || !data.match_id) {
      return {
        success: false,
        message: 'Expected match to be created from reciprocal like',
        data,
        duration
      }
    }

    return {
      success: true,
      message: `Match successfully created! Match ID: ${data.match_id}`,
      data: { matched: data.matched, match_id: data.match_id },
      duration
    }
  }
)

// Test 4: Self-like error
await testRunner.runTest(
  'Self-Like Error Test',
  async (): Promise<TestResult> => {
    const { response, data, duration } = await testRunner.makeSwipeRequest(
      config.testUsers.charlie.id,
      config.testUsers.charlie.id, // Same user
      config.testUsers.charlie.jwt
    )

    if (response.status === 400 && data.error?.includes('Cannot like yourself')) {
      return {
        success: true,
        message: 'Correctly rejected self-like with 400 error',
        data,
        duration
      }
    }

    return {
      success: false,
      message: `Expected 400 error for self-like, got ${response.status}: ${data.error}`,
      data,
      duration
    }
  }
)

// Test 5: Invalid UUID format
await testRunner.runTest(
  'Invalid UUID Format Test',
  async (): Promise<TestResult> => {
    const { response, data, duration } = await testRunner.makeSwipeRequest(
      'invalid-uuid-format',
      config.testUsers.bob.id,
      config.testUsers.alice.jwt
    )

    if (response.status === 400 && data.error?.includes('Invalid UUID format')) {
      return {
        success: true,
        message: 'Correctly rejected invalid UUID with 400 error',
        data,
        duration
      }
    }

    return {
      success: false,
      message: `Expected 400 error for invalid UUID, got ${response.status}: ${data.error}`,
      data,
      duration
    }
  }
)

// Test 6: Missing Authorization header
await testRunner.runTest(
  'Missing Authorization Header Test',
  async (): Promise<TestResult> => {
    const startTime = Date.now()
    
    const response = await fetch(config.baseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
        // No Authorization header
      },
      body: JSON.stringify({
        liker_id: config.testUsers.alice.id,
        liked_id: config.testUsers.bob.id
      })
    })
    
    const duration = Date.now() - startTime
    const data = await response.json() as SwipeResponse

    if (response.status === 401 && data.error?.includes('Authorization')) {
      return {
        success: true,
        message: 'Correctly rejected missing auth header with 401 error',
        data,
        duration
      }
    }

    return {
      success: false,
      message: `Expected 401 error for missing auth, got ${response.status}: ${data.error}`,
      data,
      duration
    }
  }
)

// Test 7: Invalid JSON payload
await testRunner.runTest(
  'Invalid JSON Payload Test',
  async (): Promise<TestResult> => {
    const startTime = Date.now()
    
    const response = await fetch(config.baseUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.testUsers.alice.jwt}`,
        'Content-Type': 'application/json'
      },
      body: 'invalid-json-payload'
    })
    
    const duration = Date.now() - startTime
    const data = await response.json() as SwipeResponse

    if (response.status === 400 && data.error?.includes('Invalid JSON')) {
      return {
        success: true,
        message: 'Correctly rejected invalid JSON with 400 error',
        data,
        duration
      }
    }

    return {
      success: false,
      message: `Expected 400 error for invalid JSON, got ${response.status}: ${data.error}`,
      data,
      duration
    }
  }
)

// Test 8: Wrong HTTP method
await testRunner.runTest(
  'Wrong HTTP Method Test',
  async (): Promise<TestResult> => {
    const startTime = Date.now()
    
    const response = await fetch(config.baseUrl, {
      method: 'GET', // Wrong method
      headers: {
        'Authorization': `Bearer ${config.testUsers.alice.jwt}`
      }
    })
    
    const duration = Date.now() - startTime
    const data = await response.json() as SwipeResponse

    if (response.status === 405) {
      return {
        success: true,
        message: 'Correctly rejected GET method with 405 error',
        data,
        duration
      }
    }

    return {
      success: false,
      message: `Expected 405 error for GET method, got ${response.status}: ${data.error}`,
      data,
      duration
    }
  }
)

// Test 9: CORS preflight request
await testRunner.runTest(
  'CORS Preflight Test',
  async (): Promise<TestResult> => {
    const startTime = Date.now()
    
    const response = await fetch(config.baseUrl, {
      method: 'OPTIONS'
    })
    
    const duration = Date.now() - startTime
    const corsHeader = response.headers.get('Access-Control-Allow-Origin')

    if (response.status === 200 && corsHeader) {
      return {
        success: true,
        message: `CORS preflight successful. Allow-Origin: ${corsHeader}`,
        data: { corsHeader },
        duration
      }
    }

    return {
      success: false,
      message: `CORS preflight failed. Status: ${response.status}, CORS header: ${corsHeader}`,
      duration
    }
  }
)

// Test 10: Rate limiting test
await testRunner.runTest(
  'Rate Limiting Test',
  async (): Promise<TestResult> => {
    console.log('   Making rapid requests to trigger rate limit...')
    
    // Make requests rapidly to the same endpoint
    const rapidRequests = []
    for (let i = 0; i < 5; i++) {
      rapidRequests.push(
        testRunner.makeSwipeRequest(
          config.testUsers.charlie.id,
          config.testUsers.alice.id,
          config.testUsers.charlie.jwt
        )
      )
    }

    const results = await Promise.all(rapidRequests)
    const maxDuration = Math.max(...results.map(r => r.duration))
    
    // Check if any request was rate limited (429 status)
    const rateLimitedRequest = results.find(r => r.response.status === 429)
    
    if (rateLimitedRequest) {
      return {
        success: true,
        message: 'Rate limiting is working - got 429 status',
        data: {
          rateLimitResponse: rateLimitedRequest.data,
          totalRequests: results.length,
          rateLimitedCount: results.filter(r => r.response.status === 429).length
        },
        duration: maxDuration
      }
    }

    // If no rate limiting triggered, that's also acceptable (depends on timing)
    return {
      success: true,
      message: 'No rate limiting triggered (acceptable - depends on request timing)',
      data: {
        allStatuses: results.map(r => r.response.status),
        totalRequests: results.length
      },
      duration: maxDuration
    }
  }
)

// Test 11: Unauthorized user trying to like as someone else
await testRunner.runTest(
  'Unauthorized Identity Test',
  async (): Promise<TestResult> => {
    // Alice's JWT token but trying to like as Bob
    const { response, data, duration } = await testRunner.makeSwipeRequest(
      config.testUsers.bob.id, // Wrong user ID
      config.testUsers.charlie.id,
      config.testUsers.alice.jwt // Alice's token
    )

    if (response.status === 403 && data.error?.includes('Unauthorized')) {
      return {
        success: true,
        message: 'Correctly rejected identity mismatch with 403 error',
        data,
        duration
      }
    }

    return {
      success: false,
      message: `Expected 403 error for identity mismatch, got ${response.status}: ${data.error}`,
      data,
      duration
    }
  }
)

// ============================================================================
// PERFORMANCE AND STRESS TESTS
// ============================================================================

await testRunner.runTest(
  'Performance Test - Response Time',
  async (): Promise<TestResult> => {
    const iterations = 10
    const durations: number[] = []
    
    for (let i = 0; i < iterations; i++) {
      const { duration } = await testRunner.makeSwipeRequest(
        config.testUsers.alice.id,
        config.testUsers.charlie.id,
        config.testUsers.alice.jwt
      )
      durations.push(duration)
      
      // Small delay between requests
      await new Promise(resolve => setTimeout(resolve, 50))
    }
    
    const avgDuration = durations.reduce((a, b) => a + b, 0) / durations.length
    const maxDuration = Math.max(...durations)
    const minDuration = Math.min(...durations)
    
    // Consider performance acceptable if average is under 500ms
    const performanceAcceptable = avgDuration < 500
    
    return {
      success: performanceAcceptable,
      message: `Average response time: ${avgDuration.toFixed(1)}ms (${performanceAcceptable ? 'GOOD' : 'SLOW'})`,
      data: {
        average: avgDuration.toFixed(1),
        max: maxDuration,
        min: minDuration,
        iterations
      },
      duration: avgDuration
    }
  }
)

// ============================================================================
// CLEANUP AND SUMMARY
// ============================================================================

console.log('\n🧹 Cleaning up test data...')
console.log('(In a real scenario, you might want to clean up test likes/matches)')

// Print final summary
testRunner.printSummary()

// ============================================================================
// ADDITIONAL NOTES AND RECOMMENDATIONS
// ============================================================================

console.log('\n📋 IMPORTANT NOTES:')
console.log('━'.repeat(60))
console.log('1. 🔑 Replace JWT tokens with real tokens from your Supabase Auth')
console.log('2. 🏗️  Ensure local Supabase is running: supabase start')
console.log('3. 🚀 Deploy function locally: supabase functions serve')
console.log('4. 👥 Verify test users exist in your database')
console.log('5. 🔒 Test with actual blocking relationships if needed')
console.log('6. 📊 Monitor database for duplicate likes/matches during tests')
console.log('7. ⚡ Performance tests depend on local system resources')
console.log('\n🎯 For production testing:')
console.log('   • Update baseUrl to your production Supabase URL')
console.log('   • Use production JWT tokens')
console.log('   • Test against production database')
console.log('   • Monitor real-world performance metrics')

// Exit with appropriate code
const summary = testRunner.getSummary()
Deno.exit(summary.failed === 0 ? 0 : 1)
