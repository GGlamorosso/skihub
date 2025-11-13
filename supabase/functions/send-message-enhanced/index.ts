// CrewSnow Enhanced Send Message with Usage Quotas - Week 7

import { createClient } from 'npm:@supabase/supabase-js@2'

interface SendMessageRequest {
  match_id: string
  content: string
  message_type?: 'text' | 'image' | 'location' | 'system'
}

interface SendMessageResponse {
  message_id: string
  sent: boolean
  quota_info: {
    messages_remaining: number
    tier: string
    unlimited: boolean
  }
}

function isValidUUID(str: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
  return uuidRegex.test(str)
}

Deno.serve(async (req: Request): Promise<Response> => {
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

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    // =====================================
    // 1. AUTHENTICATION
    // =====================================
    
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing Authorization header' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      },
    )

    const { data: userData, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !userData.user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const userId = userData.user.id

    // =====================================
    // 2. INPUT VALIDATION
    // =====================================

    let requestBody: SendMessageRequest
    try {
      requestBody = await req.json()
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON payload' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { match_id, content, message_type = 'text' } = requestBody

    if (!isValidUUID(match_id)) {
      return new Response(
        JSON.stringify({ error: 'Invalid match_id format' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!content || content.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Message content cannot be empty' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (content.length > 2000) {
      return new Response(
        JSON.stringify({ error: 'Message content too long (max 2000 characters)' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // 3. MATCH PARTICIPATION VERIFICATION
    // =====================================

    const { data: matchCheck, error: matchError } = await supabaseClient
      .from('matches')
      .select('id, user1_id, user2_id')
      .eq('id', match_id)
      .eq('is_active', true)
      .single()

    if (matchError || !matchCheck) {
      return new Response(
        JSON.stringify({ error: 'Match not found or not active' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (matchCheck.user1_id !== userId && matchCheck.user2_id !== userId) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized: not a participant in this match' }),
        { status: 403, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // 4. MESSAGE QUOTA CHECK - WEEK 7
    // =====================================

    console.log(`Checking message quota for user ${userId}`)
    
    const { data: quotaCheck, error: quotaError } = await supabaseClient
      .rpc('check_and_increment_message_quota', { p_user_id: userId })
      .single()

    if (quotaError) {
      console.error('Message quota check error:', quotaError)
      return new Response(
        JSON.stringify({ error: 'Message quota check failed', detail: quotaError.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!quotaCheck.can_message) {
      console.log(`Message quota exceeded for user ${userId}: ${quotaCheck.reason}`)
      
      return new Response(
        JSON.stringify({ 
          error: 'Daily message limit exceeded',
          reason: quotaCheck.reason,
          messages_remaining: quotaCheck.messages_remaining,
          tier: quotaCheck.tier,
          upgrade_required: quotaCheck.tier === 'free',
          quota_info: {
            messages_remaining: quotaCheck.messages_remaining,
            tier: quotaCheck.tier,
            unlimited: quotaCheck.tier === 'premium'
          }
        }),
        { status: 429, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`✅ Message quota OK: ${quotaCheck.messages_remaining} remaining (${quotaCheck.tier})`)

    // =====================================
    // 5. SEND MESSAGE
    // =====================================

    const { data: messageData, error: messageError } = await supabaseClient
      .from('messages')
      .insert({
        match_id: match_id,
        sender_id: userId,
        content: content.trim(),
        message_type: message_type,
      })
      .select('id')
      .single()

    if (messageError || !messageData) {
      console.error('Error sending message:', messageError)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to send message', 
          detail: messageError?.message 
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`✅ Message sent: ${messageData.id}`)

    // =====================================
    // 6. SUCCESS RESPONSE WITH QUOTA INFO
    // =====================================

    const response: SendMessageResponse = {
      message_id: messageData.id,
      sent: true,
      quota_info: {
        messages_remaining: Math.max(0, quotaCheck.messages_remaining - 1),
        tier: quotaCheck.tier,
        unlimited: quotaCheck.tier === 'premium'
      }
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*' 
      },
    })

  } catch (error) {
    console.error('Send message error:', error)
    
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        detail: error.message,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
