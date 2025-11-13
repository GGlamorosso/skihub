// CrewSnow Enhanced Stripe Webhook - Week 7
// 1.3 Webhook Stripe sécurisé selon spécifications exactes

import Stripe from 'npm:stripe@14'
import { createClient } from 'npm:@supabase/supabase-js@2'

// Initialize Stripe with ESM version selon spécifications
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
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

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    // =====================================
    // SIGNATURE VERIFICATION
    // =====================================
    
    const signature = req.headers.get('stripe-signature')
    const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')

    if (!signature || !webhookSecret) {
      console.error('Missing signature or webhook secret')
      return new Response('Webhook signature verification failed', { status: 400 })
    }

    // Récupération corps brut selon spécifications
    const body = await req.text()
    
    // Vérification authenticité avec stripe.webhooks.constructEventAsync selon spécifications  
    const event = stripe.webhooks.constructEvent(body, signature, webhookSecret) as WebhookEvent

    console.log(`📨 Processing webhook: ${event.type} (${event.id})`)

    // =====================================
    // IDEMPOTENCE - Vérification event.id selon Duncan Mackenzie
    // =====================================
    
    const { data: existingEvent } = await supabase
      .from('processed_events')
      .select('event_id')
      .eq('event_id', event.id)
      .single()

    if (existingEvent) {
      console.log(`✅ Event ${event.id} already processed (idempotent)`)
      return new Response('Event already processed', { status: 200 })
    }

    // =====================================
    // GESTION DES TYPES D'ÉVÉNEMENTS
    // =====================================

    let processingResult = { success: true, message: '' }

    switch (event.type) {
      case 'checkout.session.completed':
        processingResult = await handleCheckoutCompleted(event.data.object)
        break
        
      case 'invoice.paid':
        processingResult = await handleInvoicePaid(event.data.object)
        break
        
      case 'invoice.payment_failed':
        processingResult = await handlePaymentFailed(event.data.object)
        break
        
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        processingResult = await handleSubscriptionUpdate(event.data.object)
        break
        
      case 'customer.subscription.deleted':
        processingResult = await handleSubscriptionDeleted(event.data.object)
        break
        
      default:
        console.log(`ℹ️ Unhandled event type: ${event.type}`)
        processingResult = { success: true, message: `Event type ${event.type} noted but not processed` }
    }

    // =====================================
    // MARQUER ÉVÉNEMENT COMME TRAITÉ (IDEMPOTENCE)
    // =====================================
    
    const { error: insertError } = await supabase
      .from('processed_events')
      .insert({
        event_id: event.id,
        event_type: event.type,
        processed_at: new Date().toISOString()
      })

    if (insertError) {
      console.error('❌ Error marking event as processed:', insertError)
      // Continue anyway - better to process twice than miss an event
    }

    // =====================================
    // RÉPONSE HTTP
    // =====================================

    if (processingResult.success) {
      return new Response(
        JSON.stringify({ 
          received: true, 
          event_id: event.id, 
          event_type: event.type,
          message: processingResult.message 
        }), 
        { 
          status: 200, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    } else {
      return new Response(
        JSON.stringify({ 
          error: 'Event processing failed', 
          details: processingResult.message 
        }), 
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

  } catch (error) {
    console.error('❌ Webhook error:', error)
    
    // Renvoyer 400 en cas d'erreur de signature ou payload selon spécifications
    if (error.type === 'StripeSignatureVerificationError') {
      return new Response('Invalid signature', { status: 400 })
    }
    
    return new Response(`Webhook error: ${error.message}`, { status: 400 })
  }
})

// ============================================================================
// HANDLERS D'ÉVÉNEMENTS SELON SPÉCIFICATIONS
// ============================================================================

// checkout.session.completed selon spécifications
async function handleCheckoutCompleted(session: any) {
  console.log('Processing checkout.session.completed', session.id)
  
  try {
    const customerId = session.customer
    const subscriptionId = session.subscription
    
    // Récupération customer et line_items selon spécifications
    const customer = await stripe.customers.retrieve(customerId)
    
    if (subscriptionId) {
      // Abonnement premium selon spécifications
      const subscription = await stripe.subscriptions.retrieve(subscriptionId, {
        expand: ['items.data.price']
      })
      
      const lineItem = subscription.items.data[0]
      
      // Lier utilisateur si nécessaire
      if (session.metadata?.user_id && typeof customer === 'object' && !customer.deleted) {
        await linkUserToStripeCustomer(session.metadata.user_id, customerId)
      }
      
      // Traiter subscription selon spécifications
      return await handleSubscriptionUpdate(subscription)
      
    } else {
      // Paiement one-time (boost) selon spécifications
      const userId = session.metadata?.user_id
      const stationId = session.metadata?.station_id
      
      if (userId && stationId) {
        return await createBoost(userId, stationId, session)
      }
    }
    
    return { success: true, message: 'Checkout completed processed' }
    
  } catch (error) {
    console.error('❌ Error handling checkout.completed:', error)
    return { success: false, message: error.message }
  }
}

// invoice.paid selon spécifications  
async function handleInvoicePaid(invoice: any) {
  console.log('Processing invoice.paid', invoice.id)
  
  try {
    const subscriptionId = invoice.subscription
    
    if (subscriptionId) {
      // Paiements récurrents selon spécifications
      const subscription = await stripe.subscriptions.retrieve(subscriptionId)
      
      // Mise à jour current_period_end et is_premium selon spécifications
      return await handleSubscriptionUpdate(subscription)
    }
    
    return { success: true, message: 'Invoice paid processed' }
    
  } catch (error) {
    console.error('❌ Error handling invoice.paid:', error)
    return { success: false, message: error.message }
  }
}

// customer.subscription.deleted selon spécifications
async function handleSubscriptionDeleted(subscription: any) {
  console.log('Processing customer.subscription.deleted', subscription.id)
  
  try {
    // Trouve user par customer_id
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('stripe_customer_id', subscription.customer)
      .single()
      
    if (userError || !user) {
      console.error('User not found for customer:', subscription.customer)
      return { success: false, message: 'User not found' }
    }
    
    // Mise à jour subscription comme annulée
    const { error: subError } = await supabase
      .from('subscriptions')
      .update({
        status: 'canceled',
        canceled_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('stripe_subscription_id', subscription.id)
      
    // users.is_premium à FALSE selon spécifications
    const { error: userUpdateError } = await supabase
      .from('users')
      .update({
        is_premium: false,
        premium_expires_at: null,
        updated_at: new Date().toISOString()
      })
      .eq('id', user.id)
      
    if (subError || userUpdateError) {
      console.error('Error updating subscription deletion:', { subError, userUpdateError })
      return { success: false, message: 'Database update failed' }
    }
    
    console.log(`✅ Premium revoked for user ${user.id}`)
    return { success: true, message: 'Subscription deleted processed' }
    
  } catch (error) {
    console.error('❌ Error handling subscription.deleted:', error)
    return { success: false, message: error.message }
  }
}

async function handlePaymentFailed(invoice: any) {
  console.log('Processing invoice.payment_failed', invoice.id)
  
  try {
    const subscriptionId = invoice.subscription
    if (subscriptionId) {
      const { error } = await supabase
        .from('subscriptions')
        .update({
          status: 'past_due',
          updated_at: new Date().toISOString()
        })
        .eq('stripe_subscription_id', subscriptionId)
        
      if (error) {
        return { success: false, message: 'Failed to update subscription status' }
      }
    }
    
    return { success: true, message: 'Payment failed processed' }
    
  } catch (error) {
    console.error('❌ Error handling payment.failed:', error)
    return { success: false, message: error.message }
  }
}

async function handleSubscriptionUpdate(subscription: any) {
  console.log('Processing subscription update', subscription.id)
  
  try {
    // Trouve user par Stripe customer ID  
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('stripe_customer_id', subscription.customer)
      .single()
      
    if (userError || !user) {
      console.error('User not found for customer:', subscription.customer)
      return { success: false, message: 'User not found for customer' }
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
    
    // Upsert subscription selon spécifications
    const { error: subError } = await supabase
      .from('subscriptions')
      .upsert(subscriptionData, { 
        onConflict: 'stripe_subscription_id',
        ignoreDuplicates: false 
      })
      
    if (subError) {
      console.error('Error upserting subscription:', subError)
      return { success: false, message: 'Failed to update subscription' }
    }
    
    // Update user premium status selon spécifications
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
      return { success: false, message: 'Failed to update user premium status' }
    }
    
    console.log(`✅ Updated user ${user.id} premium status: ${isPremiumActive}`)
    return { success: true, message: 'Subscription updated successfully' }
    
  } catch (error) {
    console.error('❌ Error handling subscription update:', error)
    return { success: false, message: error.message }
  }
}

// Helper function to link user to Stripe customer
async function linkUserToStripeCustomer(userId: string, customerId: string) {
  const { error } = await supabase.rpc('link_user_to_stripe_customer', {
    p_user_id: userId,
    p_stripe_customer_id: customerId
  })
  
  if (error) {
    console.error('❌ Error linking user to Stripe customer:', error)
  } else {
    console.log(`✅ User ${userId} linked to Stripe customer ${customerId}`)
  }
}

async function createBoost(userId: string, stationId: string, session: any) {
  console.log(`Creating boost for user ${userId} at station ${stationId}`)
  
  try {
    const durationHours = parseInt(session.metadata?.boost_duration_hours || '24')
    const multiplier = parseFloat(session.metadata?.boost_multiplier || '2.0')
    
    const now = new Date()
    const endsAt = new Date(now.getTime() + durationHours * 60 * 60 * 1000)
    
    const boostData = {
      user_id: userId,
      station_id: stationId,
      starts_at: now.toISOString(),
      ends_at: endsAt.toISOString(),
      boost_multiplier: multiplier,
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
      return { success: false, message: 'Failed to create boost' }
    }
    
    console.log(`✅ Boost created for ${durationHours}h with multiplier ${multiplier}`)
    return { success: true, message: 'Boost created successfully' }
    
  } catch (error) {
    console.error('❌ Error creating boost:', error)
    return { success: false, message: error.message }
  }
}
