// CrewSnow Create Stripe Customer - Week 7  
// 1.2 Lier l'utilisateur à Stripe

import Stripe from 'npm:stripe@14'
import { createClient } from 'npm:@supabase/supabase-js@2'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
})

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_ANON_KEY') ?? '',
  {
    global: {
      headers: { Authorization: req.headers.get('Authorization')! },
    },
  },
)

interface CreateCustomerRequest {
  user_id: string
  email: string
  name?: string
  metadata?: Record<string, string>
}

interface CreateCustomerResponse {
  customer_id: string
  user_linked: boolean
  message: string
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

    const { data: userData, error: userError } = await supabase.auth.getUser()
    if (userError || !userData.user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // PARSE REQUEST
    // =====================================

    let requestBody: CreateCustomerRequest
    try {
      requestBody = await req.json()
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON payload' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { user_id, email, name, metadata = {} } = requestBody

    // Verify user owns this profile
    if (userData.user.id !== user_id) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized: can only create customer for own profile' }),
        { status: 403, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // CHECK EXISTING CUSTOMER
    // =====================================

    const { data: existingUser } = await supabase
      .from('users')
      .select('stripe_customer_id, username, email')
      .eq('id', user_id)
      .single()

    if (existingUser?.stripe_customer_id) {
      return new Response(
        JSON.stringify({
          customer_id: existingUser.stripe_customer_id,
          user_linked: true,
          message: 'Customer already exists and linked'
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // CREATE STRIPE CUSTOMER
    // =====================================

    console.log(`Creating Stripe customer for user ${user_id}`)

    const customer = await stripe.customers.create({
      email: email,
      name: name || existingUser?.username || email.split('@')[0],
      metadata: {
        user_id: user_id,
        source: 'crewsnow_app',
        created_via: 'edge_function',
        ...metadata
      }
    })

    console.log(`✅ Stripe customer created: ${customer.id}`)

    // =====================================
    // LINK USER TO CUSTOMER
    // =====================================

    const { data: linkResult, error: linkError } = await supabase.rpc(
      'link_user_to_stripe_customer',
      {
        p_user_id: user_id,
        p_stripe_customer_id: customer.id
      }
    )

    if (linkError) {
      console.error('❌ Error linking user to customer:', linkError)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to link customer to user profile',
          customer_id: customer.id 
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`✅ User ${user_id} successfully linked to customer ${customer.id}`)

    // =====================================
    // RESPONSE
    // =====================================

    const response: CreateCustomerResponse = {
      customer_id: customer.id,
      user_linked: true,
      message: 'Stripe customer created and linked successfully'
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('❌ Create customer error:', error)
    
    return new Response(
      JSON.stringify({
        error: 'Failed to create Stripe customer',
        details: error.message,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
