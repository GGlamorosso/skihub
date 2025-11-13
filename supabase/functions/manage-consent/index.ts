// CrewSnow Consent Management - Week 9
// 3.2 & 3.3 Interface consentements selon spécifications

import { createClient } from 'npm:@supabase/supabase-js@2'

interface ConsentRequest {
  purpose: string
  action: 'grant' | 'revoke' | 'check'
  version?: number
}

interface ConsentResponse {
  purpose: string
  granted: boolean
  version?: number
  granted_at?: string
  revoked_at?: string
  message: string
}

const CONSENT_PURPOSES = [
  'gps', 'ai_moderation', 'marketing', 'analytics', 
  'push_notifications', 'email_marketing', 'data_processing'
] as const

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
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

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: userData, error: userError } = await supabase.auth.getUser()
    if (userError || !userData.user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const userId = userData.user.id

    // =====================================
    // GET ALL CONSENTS
    // =====================================
    
    if (req.method === 'GET') {
      const { data: consents, error: consentsError } = await supabase
        .from('consents')
        .select('purpose, granted_at, version, revoked_at')
        .eq('user_id', userId)
        .order('granted_at', { ascending: false })

      if (consentsError) {
        throw new Error(`Failed to fetch consents: ${consentsError.message}`)
      }

      // Groupe par purpose avec dernière version
      const consentMap = new Map()
      consents?.forEach(consent => {
        const existing = consentMap.get(consent.purpose)
        if (!existing || consent.granted_at > existing.granted_at) {
          consentMap.set(consent.purpose, consent)
        }
      })

      const currentConsents = CONSENT_PURPOSES.map(purpose => {
        const consent = consentMap.get(purpose)
        return {
          purpose,
          granted: consent ? !consent.revoked_at : false,
          version: consent?.version,
          granted_at: consent?.granted_at,
          revoked_at: consent?.revoked_at
        }
      })

      return new Response(JSON.stringify({
        consents: currentConsents,
        total_purposes: CONSENT_PURPOSES.length,
        granted_count: currentConsents.filter(c => c.granted).length
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // =====================================
    // MANAGE CONSENT (POST)
    // =====================================

    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    let requestBody: ConsentRequest
    try {
      requestBody = await req.json()
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON payload' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { purpose, action, version = 1 } = requestBody

    if (!CONSENT_PURPOSES.includes(purpose as any)) {
      return new Response(
        JSON.stringify({ error: 'Invalid consent purpose', valid_purposes: CONSENT_PURPOSES }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    let response: ConsentResponse

    // =====================================
    // ACTIONS SELON SPÉCIFICATIONS
    // =====================================

    switch (action) {
      case 'check':
        const { data: hasConsent, error: checkError } = await supabase
          .rpc('check_user_consent', {
            p_user_id: userId,
            p_purpose: purpose,
            p_required_version: version
          })

        if (checkError) {
          throw new Error(`Consent check failed: ${checkError.message}`)
        }

        response = {
          purpose,
          granted: hasConsent,
          version,
          message: hasConsent ? 'Consent is granted' : 'Consent not granted or outdated'
        }
        break

      case 'grant':
        const { data: grantId, error: grantError } = await supabase
          .rpc('grant_consent', {
            p_user_id: userId,
            p_purpose: purpose,
            p_version: version
          })

        if (grantError) {
          throw new Error(`Failed to grant consent: ${grantError.message}`)
        }

        response = {
          purpose,
          granted: true,
          version,
          granted_at: new Date().toISOString(),
          message: `Consent granted for ${purpose} v${version}`
        }

        console.log(`✅ Consent granted: ${userId} -> ${purpose} v${version}`)
        break

      case 'revoke':
        const { data: revoked, error: revokeError } = await supabase
          .rpc('revoke_consent', {
            p_user_id: userId,
            p_purpose: purpose
          })

        if (revokeError) {
          throw new Error(`Failed to revoke consent: ${revokeError.message}`)
        }

        response = {
          purpose,
          granted: false,
          revoked_at: new Date().toISOString(),
          message: revoked ? `Consent revoked for ${purpose}` : `No active consent found for ${purpose}`
        }

        console.log(`❌ Consent revoked: ${userId} -> ${purpose}`)
        break

      default:
        return new Response(
          JSON.stringify({ error: 'Invalid action. Must be: grant, revoke, or check' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        )
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Consent management error:', error)
    
    return new Response(
      JSON.stringify({
        error: 'Consent management failed',
        detail: error.message,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
