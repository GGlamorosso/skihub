
// CrewSnow Gatekeeper Edge Function - Week 7
// 3.3 Edge Function "Gatekeeper" selon spécifications exactes

import { createClient } from 'npm:@supabase/supabase-js@2'

interface GatekeeperRequest {
  action: 'swipe' | 'message'
  target_function: string
  payload: any
  count?: number
}

interface GatekeeperResponse {
  allowed: boolean
  quota_status: {
    current_count: number
    daily_limit: number
    is_premium: boolean
    remaining: number
  }
  reason?: string
  target_response?: any
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    // =====================================
    // AUTHENTICATION
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
    // PARSE REQUEST
    // =====================================

    let requestBody: GatekeeperRequest
    try {
      requestBody = await req.json()
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON payload' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { action, target_function, payload, count = 1 } = requestBody

    if (!['swipe', 'message'].includes(action)) {
      return new Response(
        JSON.stringify({ error: 'Invalid action: must be swipe or message' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // EXTRACT auth.uid() ET VÉRIFIER PREMIUM SELON SPÉCIFICATIONS
    // =====================================

    // ✅ Vérifier que l'utilisateur existe dans public.users
    let userStatus: { is_premium: boolean; premium_expires_at: string | null } | null = null
    
    const { data: userStatusData, error: statusError } = await supabaseClient
      .from('users')
      .select('is_premium, premium_expires_at')
      .eq('id', userId)
      .maybeSingle()

    // Si l'utilisateur n'existe pas, créer un profil minimal
    if (statusError || !userStatusData) {
      console.log(`⚠️ User ${userId} not found in public.users, creating minimal profile...`)
      
      // Essayer de créer le profil depuis auth.users
      const { data: authUser } = await supabaseClient.auth.getUser()
      if (authUser?.user) {
        try {
          const { error: upsertError } = await supabaseClient.from('users').upsert({
            id: userId,
            email: authUser.user.email || '',
            username: authUser.user.email?.split('@')[0] || `user_${userId.substring(0, 8)}`,
            is_active: true,
            last_active_at: new Date().toISOString(),
            onboarding_completed: false,
          }, { onConflict: 'id' })
          
          if (upsertError) {
            console.error('Failed to create user profile:', upsertError)
            return new Response(
              JSON.stringify({ error: 'User status check failed: unable to create profile', detail: upsertError.message }),
              { status: 500, headers: { 'Content-Type': 'application/json' } }
            )
          }
          
          // Recharger le statut
          const { data: newStatus } = await supabaseClient
            .from('users')
            .select('is_premium, premium_expires_at')
            .eq('id', userId)
            .single()
          
          if (!newStatus) {
            return new Response(
              JSON.stringify({ error: 'User status check failed: unable to read created profile' }),
              { status: 500, headers: { 'Content-Type': 'application/json' } }
            )
          }
          
          userStatus = newStatus
          console.log(`✅ Created minimal profile for user ${userId}`)
        } catch (createError) {
          console.error('Failed to create user profile:', createError)
          return new Response(
            JSON.stringify({ error: 'User status check failed: unable to create profile', detail: createError.message }),
            { status: 500, headers: { 'Content-Type': 'application/json' } }
          )
        }
      } else {
        return new Response(
          JSON.stringify({ error: 'User status check failed: user not found in auth' }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
      }
    } else {
      userStatus = userStatusData
    }
    
    // Calculer isPremium
    const isPremium = userStatus.is_premium && 
                     (!userStatus.premium_expires_at || new Date(userStatus.premium_expires_at) > new Date())

    // =====================================
    // DÉFINIR LIMITES SELON SPÉCIFICATIONS
    // =====================================

    let swipeLimit: number
    let messageLimit: number

    if (isPremium) {
      // Premium selon spécifications: 100 swipes/jour, 500 messages/jour
      swipeLimit = 100
      messageLimit = 500
    } else {
      // Gratuit selon spécifications: 10 swipes/jour, 50 messages/jour
      swipeLimit = 10  
      messageLimit = 50
    }

    // =====================================
    // APPELER FONCTION check_and_increment_usage SELON SPÉCIFICATIONS
    // =====================================

    const incrementSwipe = action === 'swipe' ? count : 0
    const incrementMessage = action === 'message' ? count : 0

    const { data: quotaResult, error: quotaError } = await supabaseClient
      .rpc('check_and_increment_usage', {
        p_user: userId,
        p_limit_swipe: swipeLimit,
        p_limit_message: messageLimit,
        p_count_swipe: incrementSwipe,
        p_count_message: incrementMessage
      })

    if (quotaError) {
      console.error('Quota check error:', quotaError)
      return new Response(
        JSON.stringify({ error: 'Quota check failed', detail: quotaError.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // SI QUOTA OK → LAISSER APPEL SE POURSUIVRE SELON SPÉCIFICATIONS
    // =====================================

    if (quotaResult) {
      // Quota available - proceed with target function
      let targetResponse = null

      if (target_function) {
        try {
          // Call target Edge Function with original payload
          const targetUrl = `${Deno.env.get('SUPABASE_URL')}/functions/v1/${target_function}`
          
          const targetRequest = await fetch(targetUrl, {
            method: 'POST',
            headers: {
              'Authorization': authHeader,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(payload),
          })

          targetResponse = await targetRequest.json()
        } catch (error) {
          console.warn('Target function call failed:', error)
        }
      }

      // Get updated usage for response
      const { data: updatedUsage } = await supabaseClient
        .from('daily_usage')
        .select('swipe_count, message_count')
        .eq('user_id', userId)
        .eq('date', new Date().toISOString().split('T')[0])
        .single()

      const response: GatekeeperResponse = {
        allowed: true,
        quota_status: {
          current_count: action === 'swipe' ? (updatedUsage?.swipe_count || 0) : (updatedUsage?.message_count || 0),
          daily_limit: action === 'swipe' ? swipeLimit : messageLimit,
          is_premium: isPremium,
          remaining: action === 'swipe' ? 
            Math.max(0, swipeLimit - (updatedUsage?.swipe_count || 0)) :
            Math.max(0, messageLimit - (updatedUsage?.message_count || 0))
        },
        ...(targetResponse && { target_response: targetResponse })
      }

      return new Response(JSON.stringify(response), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })

    } else {
      // =====================================
      // SINON → RÉPONSE 429 SELON SPÉCIFICATIONS  
      // =====================================

      // Get current usage for error response
      const { data: currentUsage } = await supabaseClient
        .from('daily_usage')
        .select('swipe_count, message_count')
        .eq('user_id', userId)
        .eq('date', new Date().toISOString().split('T')[0])
        .single()

      const response: GatekeeperResponse = {
        allowed: false,
        quota_status: {
          current_count: action === 'swipe' ? (currentUsage?.swipe_count || 0) : (currentUsage?.message_count || 0),
          daily_limit: action === 'swipe' ? swipeLimit : messageLimit,
          is_premium: isPremium,
          remaining: 0
        },
        reason: `Quota dépassé - ${action === 'swipe' ? 'swipes' : 'messages'} daily limit reached`
      }

      return new Response(JSON.stringify(response), {
        status: 429, // Too Many Requests selon spécifications
        headers: { 'Content-Type': 'application/json' },
      })
    }

  } catch (error) {
    console.error('Gatekeeper error:', error)
    
    return new Response(
      JSON.stringify({
        error: 'Gatekeeper internal error',
        detail: error.message,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
