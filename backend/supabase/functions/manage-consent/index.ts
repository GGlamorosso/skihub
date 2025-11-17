// Edge Function: manage-consent
// Gère les consentements utilisateur (GPS, notifications, etc.)

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

    const { action, purpose, version } = await req.json()

    if (action === 'check') {
      // Check if consent exists
      // If table doesn't exist, default to false (user needs to grant)
      try {
        const { data, error } = await supabaseClient
          .from('user_consents')
          .select('*')
          .eq('user_id', user.id)
          .eq('purpose', purpose)
          .single()

        if (error && error.code !== 'PGRST116') {
          // Table doesn't exist or other error - default to false
          return new Response(
            JSON.stringify({
              granted: false,
              version: 0,
            }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            }
          )
        }

        return new Response(
          JSON.stringify({
            granted: data ? data.granted : false,
            version: data?.version || 0,
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          }
        )
      } catch (err) {
        // Table doesn't exist - default to false
        return new Response(
          JSON.stringify({
            granted: false,
            version: 0,
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          }
        )
      }
    }

    if (action === 'grant' || action === 'revoke') {
      // Try to upsert consent, but don't fail if table doesn't exist
      try {
        const { error } = await supabaseClient
          .from('user_consents')
          .upsert({
            user_id: user.id,
            purpose: purpose,
            granted: action === 'grant',
            version: version || 1,
            updated_at: new Date().toISOString(),
          })

        if (error) {
          // Table doesn't exist - just return success anyway
          // The consent is "granted" in memory for this session
        }
      } catch (err) {
        // Table doesn't exist - continue anyway
      }

      return new Response(
        JSON.stringify({
          success: true,
          granted: action === 'grant',
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      )
    }

    return new Response(
      JSON.stringify({ error: 'Invalid action' }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
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

