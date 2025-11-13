// ============================================================================
// CREWSNOW STRIPE WEBHOOK - Edge Function
// ============================================================================
// Description: Handle Stripe webhooks for subscriptions and payments
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@12.18.0?target=deno'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
)

interface WebhookEvent {
  id: string
  type: string
  data: {
    object: any
  }
  created: number
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const signature = req.headers.get('stripe-signature')
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')

  if (!signature || !webhookSecret) {
    console.error('Missing signature or webhook secret')
    return new Response('Webhook signature verification failed', { status: 400 })
  }

  try {
    const body = await req.text()
    const event = stripe.webhooks.constructEvent(body, signature, webhookSecret) as WebhookEvent

    console.log(`Processing webhook: ${event.type}`)

    // Check for duplicate events (idempotency)
    const { data: existingEvent } = await supabase
      .from('processed_events')
      .select('event_id')
      .eq('event_id', event.id)
      .single()

    if (existingEvent) {
      console.log(`Event ${event.id} already processed`)
      return new Response('Event already processed', { status: 200 })
    }

    // Process the event
    switch (event.type) {
      case 'checkout.session.completed':
        await handleCheckoutCompleted(event.data.object)
        break
        
      case 'invoice.paid':
        await handleInvoicePaid(event.data.object)
        break
        
      case 'invoice.payment_failed':
        await handlePaymentFailed(event.data.object)
        break
        
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        await handleSubscriptionUpdate(event.data.object)
        break
        
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object)
        break
        
      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    // Mark event as processed
    await supabase.from('processed_events').insert({
      event_id: event.id,
      event_type: event.type,
      processed_at: new Date().toISOString()
    })

    return new Response('Webhook processed successfully', { status: 200 })

  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(`Webhook error: ${error.message}`, { status: 400 })
  }
})

// ============================================================================
// WEBHOOK HANDLERS
// ============================================================================

async function handleCheckoutCompleted(session: any) {
  console.log('Processing checkout.session.completed', session.id)
  
  const customerId = session.customer
  const subscriptionId = session.subscription
  
  if (subscriptionId) {
    // This is a subscription checkout
    const subscription = await stripe.subscriptions.retrieve(subscriptionId)
    await handleSubscriptionUpdate(subscription)
  } else {
    // This is a one-time payment (boost)
    const userId = session.metadata?.user_id
    const stationId = session.metadata?.station_id
    const boostDuration = parseInt(session.metadata?.boost_duration || '24') // hours
    
    if (userId && stationId) {
      await createBoost(userId, stationId, session, boostDuration)
    }
  }
}

async function handleInvoicePaid(invoice: any) {
  console.log('Processing invoice.paid', invoice.id)
  
  const subscriptionId = invoice.subscription
  if (subscriptionId) {
    const subscription = await stripe.subscriptions.retrieve(subscriptionId)
    await handleSubscriptionUpdate(subscription)
  }
}

async function handlePaymentFailed(invoice: any) {
  console.log('Processing invoice.payment_failed', invoice.id)
  
  const subscriptionId = invoice.subscription
  if (subscriptionId) {
    // Update subscription status
    const { error } = await supabase
      .from('subscriptions')
      .update({
        status: 'past_due',
        updated_at: new Date().toISOString()
      })
      .eq('stripe_subscription_id', subscriptionId)
    
    if (error) {
      console.error('Error updating subscription for failed payment:', error)
    }
  }
}

async function handleSubscriptionUpdate(subscription: any) {
  console.log('Processing subscription update', subscription.id)
  
  // Find user by Stripe customer ID
  const { data: user, error: userError } = await supabase
    .from('users')
    .select('id')
    .eq('stripe_customer_id', subscription.customer)
    .single()
    
  if (userError || !user) {
    console.error('User not found for customer:', subscription.customer)
    return
  }
  
  const subscriptionData = {
    user_id: user.id,
    stripe_subscription_id: subscription.id,
    stripe_customer_id: subscription.customer,
    stripe_price_id: subscription.items.data[0]?.price.id,
    status: subscription.status,
    current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
    current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
    cancel_at_period_end: subscription.cancel_at_period_end,
    canceled_at: subscription.canceled_at ? new Date(subscription.canceled_at * 1000).toISOString() : null,
    amount_cents: subscription.items.data[0]?.price.unit_amount || 0,
    currency: subscription.items.data[0]?.price.currency || 'eur',
    interval: subscription.items.data[0]?.price.recurring?.interval || 'month',
    updated_at: new Date().toISOString()
  }
  
  // Upsert subscription
  const { error: subError } = await supabase
    .from('subscriptions')
    .upsert(subscriptionData, { 
      onConflict: 'stripe_subscription_id',
      ignoreDuplicates: false 
    })
    
  if (subError) {
    console.error('Error upserting subscription:', subError)
    return
  }
  
  // Update user premium status
  const isPremiumActive = ['active', 'trialing'].includes(subscription.status)
  const premiumExpiresAt = isPremiumActive 
    ? new Date(subscription.current_period_end * 1000).toISOString()
    : null
    
  const { error: userUpdateError } = await supabase
    .from('users')
    .update({
      is_premium: isPremiumActive,
      premium_expires_at: premiumExpiresAt,
      updated_at: new Date().toISOString()
    })
    .eq('id', user.id)
    
  if (userUpdateError) {
    console.error('Error updating user premium status:', userUpdateError)
  }
  
  console.log(`Updated user ${user.id} premium status: ${isPremiumActive}`)
}

async function handleSubscriptionDeleted(subscription: any) {
  console.log('Processing subscription.deleted', subscription.id)
  
  // Find user by Stripe customer ID  
  const { data: user, error: userError } = await supabase
    .from('users')
    .select('id')
    .eq('stripe_customer_id', subscription.customer)
    .single()
    
  if (userError || !user) {
    console.error('User not found for customer:', subscription.customer)
    return
  }
  
  // Update subscription status
  const { error: subError } = await supabase
    .from('subscriptions')
    .update({
      status: 'canceled',
      canceled_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    })
    .eq('stripe_subscription_id', subscription.id)
    
  if (subError) {
    console.error('Error updating canceled subscription:', subError)
  }
  
  // Remove premium status
  const { error: userUpdateError } = await supabase
    .from('users')
    .update({
      is_premium: false,
      premium_expires_at: null,
      updated_at: new Date().toISOString()
    })
    .eq('id', user.id)
    
  if (userUpdateError) {
    console.error('Error removing user premium status:', userUpdateError)
  }
  
  console.log(`Removed premium status for user ${user.id}`)
}

async function createBoost(userId: string, stationId: string, session: any, durationHours: number) {
  console.log(`Creating boost for user ${userId} at station ${stationId}`)
  
  const now = new Date()
  const endsAt = new Date(now.getTime() + durationHours * 60 * 60 * 1000)
  
  const boostData = {
    user_id: userId,
    station_id: stationId,
    starts_at: now.toISOString(),
    ends_at: endsAt.toISOString(),
    boost_multiplier: parseFloat(session.metadata?.boost_multiplier || '2.0'),
    amount_paid_cents: session.amount_total,
    currency: session.currency,
    stripe_payment_intent_id: session.payment_intent,
    is_active: true,
    created_at: now.toISOString()
  }
  
  const { error } = await supabase
    .from('boosts')
    .insert(boostData)
    
  if (error) {
    console.error('Error creating boost:', error)
  } else {
    console.log(`Boost created successfully for ${durationHours}h`)
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Create processed_events table if it doesn't exist (run once)
async function ensureProcessedEventsTable() {
  const { error } = await supabase.rpc('create_processed_events_table_if_not_exists')
  if (error) {
    console.error('Error creating processed_events table:', error)
  }
}
