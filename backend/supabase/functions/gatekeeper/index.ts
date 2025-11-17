// Edge Function: gatekeeper
// Vérifie les permissions et quotas avant d'autoriser une action

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { action, resource } = await req.json()

    // Check permissions based on action and resource
    let allowed = false
    let reason = ''

    // Default quota response structure
    let quotaInfo = {
      swipeRemaining: 100,
      messageRemaining: 50,
      limitReached: false,
      limitType: null,
      dailySwipeLimit: 100,
      resetsAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    }

    switch (action) {
      case 'swipe':
        // Check quota for swipes (simplified - always allow for now)
        // TODO: Implement proper quota checking when RPC functions exist
        allowed = true
        quotaInfo.swipeRemaining = 100
        break

      case 'message':
        // Check quota for messages (simplified - always allow for now)
        allowed = true
        quotaInfo.messageRemaining = 50
        break

      case 'view_profile':
        allowed = true
        break

      default:
        reason = 'Action non reconnue'
    }

    return new Response(
      JSON.stringify({
        allowed,
        reason: allowed ? null : reason,
        quotaInfo: quotaInfo,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

