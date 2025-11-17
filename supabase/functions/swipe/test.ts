// Test script for CrewSnow Swipe Edge Function
// Usage: deno run --allow-net test.ts

interface TestCase {
  name: string
  payload: any
  headers?: Record<string, string>
  expectedStatus: number
  expectedFields?: string[]
}

const BASE_URL = 'http://localhost:54321/functions/v1/swipe'
const TEST_JWT = 'your-test-jwt-token' // Replace with actual JWT
const TEST_USER_1 = '00000000-0000-0000-0000-000000000001'
const TEST_USER_2 = '00000000-0000-0000-0000-000000000002'
const TEST_USER_3 = '00000000-0000-0000-0000-000000000003'

const testCases: TestCase[] = [
  {
    name: '✅ Valid swipe - first like',
    payload: {
      liker_id: TEST_USER_1,
      liked_id: TEST_USER_2
    },
    headers: {
      'Authorization': `Bearer ${TEST_JWT}`,
      'Content-Type': 'application/json'
    },
    expectedStatus: 200,
    expectedFields: ['matched']
  },
  
  {
    name: '✅ Valid swipe - reciprocal like (should create match)',
    payload: {
      liker_id: TEST_USER_2,
      liked_id: TEST_USER_1
    },
    headers: {
      'Authorization': `Bearer ${TEST_JWT}`,
      'Content-Type': 'application/json'
    },
    expectedStatus: 200,
    expectedFields: ['matched', 'match_id']
  },
  
  {
    name: '✅ Idempotent - duplicate like',
    payload: {
      liker_id: TEST_USER_1,
      liked_id: TEST_USER_2
    },
    headers: {
      'Authorization': `Bearer ${TEST_JWT}`,
      'Content-Type': 'application/json'
    },
    expectedStatus: 200,
    expectedFields: ['matched', 'already_liked']
  },

  {
    name: '❌ Missing Authorization header',
    payload: {
      liker_id: TEST_USER_1,
      liked_id: TEST_USER_2
    },
    headers: {
      'Content-Type': 'application/json'
    },
    expectedStatus: 401
  },

  {
    name: '❌ Invalid JSON payload',
    payload: 'invalid-json',
    headers: {
      'Authorization': `Bearer ${TEST_JWT}`,
      'Content-Type': 'application/json'
    },
    expectedStatus: 400
  },

  {
    name: '❌ Self-like attempt',
    payload: {
      liker_id: TEST_USER_1,
      liked_id: TEST_USER_1
    },
    headers: {
      'Authorization': `Bearer ${TEST_JWT}`,
      'Content-Type': 'application/json'
    },
    expectedStatus: 400
  },

  {
    name: '❌ Invalid UUID format',
    payload: {
      liker_id: 'invalid-uuid',
      liked_id: TEST_USER_2
    },
    headers: {
      'Authorization': `Bearer ${TEST_JWT}`,
      'Content-Type': 'application/json'
    },
    expectedStatus: 400
  },

  {
    name: '❌ Method not allowed (GET)',
    payload: null,
    headers: {
      'Authorization': `Bearer ${TEST_JWT}`
    },
    expectedStatus: 405
  }
]

async function runTest(test: TestCase): Promise<void> {
  console.log(`\n🧪 Running: ${test.name}`)
  
  try {
    const options: RequestInit = {
      method: test.payload === null ? 'GET' : 'POST',
      headers: test.headers || {},
    }

    if (test.payload && typeof test.payload === 'object') {
      options.body = JSON.stringify(test.payload)
    } else if (test.payload && typeof test.payload === 'string') {
      options.body = test.payload
    }

    const response = await fetch(BASE_URL, options)
    const responseData = await response.text()
    
    let jsonData: any = null
    try {
      jsonData = JSON.parse(responseData)
    } catch {
      // Response might not be JSON
    }

    console.log(`   Status: ${response.status} (expected: ${test.expectedStatus})`)
    console.log(`   Response: ${responseData.slice(0, 200)}${responseData.length > 200 ? '...' : ''}`)

    // Check status code
    if (response.status === test.expectedStatus) {
      console.log('   ✅ Status code correct')
    } else {
      console.log('   ❌ Status code mismatch')
    }

    // Check expected fields
    if (test.expectedFields && jsonData) {
      const hasAllFields = test.expectedFields.every(field => field in jsonData)
      if (hasAllFields) {
        console.log('   ✅ All expected fields present')
      } else {
        console.log(`   ❌ Missing expected fields: ${test.expectedFields.filter(f => !(f in jsonData)).join(', ')}`)
      }
    }

  } catch (error) {
    console.log(`   ❌ Request failed: ${error.message}`)
  }
}

async function runAllTests(): Promise<void> {
  console.log('🚀 Starting CrewSnow Swipe Function Tests')
  console.log('======================================')
  
  console.log(`\n📍 Testing endpoint: ${BASE_URL}`)
  console.log(`🔑 Using JWT: ${TEST_JWT.slice(0, 20)}...`)
  
  // Test CORS preflight
  console.log('\n🧪 Running: CORS Preflight (OPTIONS)')
  try {
    const response = await fetch(BASE_URL, { method: 'OPTIONS' })
    console.log(`   Status: ${response.status} (expected: 200)`)
    console.log(`   CORS headers: ${response.headers.get('Access-Control-Allow-Origin')}`)
  } catch (error) {
    console.log(`   ❌ CORS test failed: ${error.message}`)
  }

  // Run all test cases
  for (const test of testCases) {
    await runTest(test)
    // Small delay between tests
    await new Promise(resolve => setTimeout(resolve, 100))
  }

  console.log('\n🏁 All tests completed!')
  console.log('======================================')
  
  console.log('\n💡 Notes:')
  console.log('- Replace TEST_JWT with a real JWT token from your app')
  console.log('- Ensure your local Supabase instance is running')
  console.log('- Update BASE_URL for production testing')
  console.log('- Check database state after running tests')
}

// Run tests if this file is executed directly
if (import.meta.main) {
  await runAllTests()
}
