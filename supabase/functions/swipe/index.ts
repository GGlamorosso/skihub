// Edge Function: Swipe (Like/Match System)
// Description: Handles user swipe actions with automatic match detection
// Author: CrewSnow Team
// Date: November 2024

import { createClient } from 'npm:@supabase/supabase-js@2'
import { Client } from 'npm:postgres@3.4.3'

interface SwipeRequest {
  liker_id: string
  liked_id: string
}

interface SwipeResponse {
  matched: boolean
  match_id?: string
  already_liked?: boolean
}

interface ErrorResponse {
  error: string
  detail?: string
}

// In-memory rate limiting (basic implementation)
const rateLimitStore = new Map<string, number>()
const RATE_LIMIT_WINDOW_MS = 1000 // 1 second
const MAX_LIKES_PER_WINDOW = 1

function isValidUUID(str: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
  return uuidRegex.test(str)
}

function checkRateLimit(userId: string): boolean {
  const now = Date.now()
  const lastRequest = rateLimitStore.get(userId) || 0
  
  if (now - lastRequest < RATE_LIMIT_WINDOW_MS) {
    return false // Rate limited
  }
  
  rateLimitStore.set(userId, now)
  
  // Clean up old entries (simple cleanup)
  if (rateLimitStore.size > 10000) {
    const cutoff = now - RATE_LIMIT_WINDOW_MS * 2
    for (const [key, timestamp] of rateLimitStore.entries()) {
      if (timestamp < cutoff) {
        rateLimitStore.delete(key)
      }
    }
  }
  
  return true
}

Deno.serve(async (req: Request): Promise<Response> => {
  // CORS headers for preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    })
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    // =====================================
    // 1. AUTHENTICATION VERIFICATION
    // =====================================
    
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing Authorization header' }),
        { 
          status: 401, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create Supabase client with user context
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      },
    )

    // Extract and verify JWT token
    const token = authHeader.replace('Bearer ', '')
    const { data: userData, error: userError } = await supabaseClient.auth.getUser(token)

    if (userError || !userData.user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { 
          status: 401, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    const authenticatedUserId = userData.user.id

    // =====================================
    // 2. INPUT VALIDATION
    // =====================================

    let requestBody: SwipeRequest
    try {
      requestBody = await req.json()
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON payload' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    const { liker_id, liked_id } = requestBody

    // Validate UUID format
    if (!isValidUUID(liker_id) || !isValidUUID(liked_id)) {
      return new Response(
        JSON.stringify({ error: 'Invalid UUID format for user IDs' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // Ensure IDs are different
    if (liker_id === liked_id) {
      return new Response(
        JSON.stringify({ error: 'Cannot like yourself' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // Verify that authenticated user matches liker_id
    if (authenticatedUserId !== liker_id) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized: can only like as authenticated user' }),
        { 
          status: 403, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // Rate limiting check
    if (!checkRateLimit(liker_id)) {
      return new Response(
        JSON.stringify({ error: 'Rate limit exceeded. Please wait before liking again.' }),
        { 
          status: 429, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // =====================================
    // 3. BLOCK CHECK
    // =====================================

    // Check if either user has blocked the other
    const { data: blockCheck, error: blockError } = await supabaseClient
      .from('friends')
      .select('id')
      .eq('status', 'blocked')
      .or(`and(requester_id.eq.${liker_id},addressee_id.eq.${liked_id}),and(requester_id.eq.${liked_id},addressee_id.eq.${liker_id})`)
      .limit(1)

    if (blockError) {
      console.error('Block check error:', blockError)
      return new Response(
        JSON.stringify({ error: 'Database error during block check', detail: blockError.message }),
        { 
          status: 500, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    if (blockCheck && blockCheck.length > 0) {
      return new Response(
        JSON.stringify({ error: 'Action not allowed: user relationship blocked' }),
        { 
          status: 403, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // =====================================
    // 4. DATABASE TRANSACTION
    // =====================================

    // Create direct postgres connection for transaction
    const dbUrl = Deno.env.get('SUPABASE_DB_URL') || Deno.env.get('DATABASE_URL')
    if (!dbUrl) {
      return new Response(
        JSON.stringify({ error: 'Database connection not configured' }),
        { 
          status: 500, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    const pgClient = new Client(dbUrl)
    const conn = await pgClient.connect()

    try {
      await conn.queryObject('BEGIN')

      // 1. Insert the like (idempotent with ON CONFLICT)
      const likeResult = await conn.queryObject(
        `INSERT INTO likes (liker_id, liked_id, created_at)
         VALUES ($1, $2, NOW())
         ON CONFLICT (liker_id, liked_id) DO NOTHING
         RETURNING id`,
        [liker_id, liked_id]
      )

      const alreadyLiked = likeResult.rows.length === 0

      // 2. Check for reciprocal like to determine if match should be created
      const reciprocalResult = await conn.queryObject<{ id: string }>(
        'SELECT id FROM likes WHERE liker_id = $1 AND liked_id = $2',
        [liked_id, liker_id]
      )

      let matchId: string | null = null
      let matched = false

      if (reciprocalResult.rows.length > 0) {
        // 3. Create match with proper ordering (user1_id < user2_id as per DB schema)
        const user1_id = liker_id < liked_id ? liker_id : liked_id
        const user2_id = liker_id < liked_id ? liked_id : liker_id

        const matchResult = await conn.queryObject<{ id: string }>(
          `INSERT INTO matches (user1_id, user2_id, created_at)
           VALUES ($1, $2, NOW())
           ON CONFLICT (user1_id, user2_id) DO NOTHING
           RETURNING id`,
          [user1_id, user2_id]
        )

        if (matchResult.rows.length > 0) {
          matchId = matchResult.rows[0].id
          matched = true
        } else {
          // Match already existed - get the existing match ID
          const existingMatchResult = await conn.queryObject<{ id: string }>(
            'SELECT id FROM matches WHERE user1_id = $1 AND user2_id = $2',
            [user1_id, user2_id]
          )
          if (existingMatchResult.rows.length > 0) {
            matchId = existingMatchResult.rows[0].id
            matched = true
          }
        }
      }

      await conn.queryObject('COMMIT')

      // =====================================
      // 5. SUCCESS RESPONSE
      // =====================================

      const response: SwipeResponse = {
        matched,
        ...(matchId && { match_id: matchId }),
        ...(alreadyLiked && { already_liked: true })
      }

      return new Response(JSON.stringify(response), {
        status: 200,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*' 
        },
      })

    } catch (error) {
      await conn.queryObject('ROLLBACK')
      console.error('Database transaction error:', error)
      
      return new Response(
        JSON.stringify({ 
          error: 'Database transaction failed', 
          detail: error.message 
        }),
        { 
          status: 500, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    } finally {
      await conn.release()
    }

  } catch (error) {
    console.error('Unhandled error in swipe function:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error', 
        detail: error.message 
      }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }
})
