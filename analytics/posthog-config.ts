// CrewSnow PostHog Configuration - Week 8
// Configuration complète PostHog selon spécifications

export const POSTHOG_CONFIG = {
  // API Configuration
  api_key: process.env.NEXT_PUBLIC_POSTHOG_KEY || '',
  api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST || 'https://app.posthog.com',
  
  // Événements définis selon spécifications Week 8
  events: {
    // User lifecycle
    USER_SIGNED_UP: 'user_signed_up',
    PROFILE_COMPLETED: 'profile_completed',
    PHOTO_UPLOADED: 'photo_uploaded', 
    PHOTO_APPROVED: 'photo_approved',
    PHOTO_REJECTED: 'photo_rejected',
    
    // Engagement
    SWIPE_SENT: 'swipe_sent',
    MATCH_CREATED: 'match_created',
    MESSAGE_SENT: 'message_sent',
    CONVERSATION_STARTED: 'conversation_started',
    
    // Monetization  
    PURCHASE_INITIATED: 'purchase_initiated',
    PURCHASE_COMPLETED: 'purchase_completed',
    SUBSCRIPTION_CREATED: 'subscription_created',
    BOOST_PURCHASED: 'boost_purchased',
    
    // App engagement
    APP_OPENED: 'app_opened',
    APP_BACKGROUNDED: 'app_backgrounded'
  },
  
  // Funnels selon spécifications
  funnels: [
    {
      name: 'User Activation',
      steps: [
        { event: 'user_signed_up', name: 'Sign Up' },
        { event: 'photo_uploaded', name: 'Upload Photo' },
        { event: 'photo_approved', name: 'Photo Approved' },
        { event: 'profile_completed', name: 'Profile Complete' }
      ]
    },
    {
      name: 'Matching Success', 
      steps: [
        { event: 'profile_completed', name: 'Profile Complete' },
        { event: 'swipe_sent', name: 'First Swipe' },
        { event: 'match_created', name: 'First Match' },
        { event: 'conversation_started', name: 'First Message' }
      ]
    },
    {
      name: 'Premium Conversion',
      steps: [
        { event: 'swipe_sent', name: 'Active User' },
        { event: 'purchase_initiated', name: 'Purchase Intent' },
        { event: 'purchase_completed', name: 'Premium Subscription' }
      ]
    }
  ],
  
  // Cohorts selon spécifications
  cohorts: [
    {
      name: 'Active Swipers',
      query: 'event = "swipe_sent" AND timestamp > now() - interval 7 day',
      description: 'Users who swiped in last 7 days'
    },
    {
      name: 'Premium Users',
      query: 'properties.$is_premium = true',
      description: 'Currently premium subscribers'
    },
    {
      name: 'Frequent Messagers',
      query: 'event = "message_sent" AND timestamp > now() - interval 7 day',
      description: 'Users with 5+ messages in last 7 days'
    },
    {
      name: 'New Users This Week',
      query: 'event = "user_signed_up" AND timestamp > now() - interval 7 day',
      description: 'Recent signups for onboarding analysis'
    }
  ]
}

// Client-side tracking helpers
export class CrewSnowAnalytics {
  private posthog: any
  
  constructor(posthogInstance: any) {
    this.posthog = posthogInstance
  }
  
  // User lifecycle tracking
  trackSignup(userId: string, signupMethod: string = 'direct') {
    this.posthog.capture(POSTHOG_CONFIG.events.USER_SIGNED_UP, {
      signup_method: signupMethod,
      $set: { user_id: userId }
    })
  }
  
  trackProfileCompleted(userId: string, completionData: any) {
    this.posthog.capture(POSTHOG_CONFIG.events.PROFILE_COMPLETED, {
      ...completionData,
      completion_time_hours: completionData.completion_time_hours,
      $set: { 
        profile_complete: true,
        level: completionData.level,
        ride_styles_count: completionData.ride_styles_count
      }
    })
  }
  
  // Engagement tracking
  trackSwipe(targetUserId: string, matchingContext: any) {
    this.posthog.capture(POSTHOG_CONFIG.events.SWIPE_SENT, {
      target_user_id: targetUserId,
      ...matchingContext,
      $set_once: { first_swipe_date: new Date().toISOString() }
    })
  }
  
  trackMatch(matchId: string, matchedUserId: string) {
    this.posthog.capture(POSTHOG_CONFIG.events.MATCH_CREATED, {
      match_id: matchId,
      matched_user_id: matchedUserId,
      $set_once: { first_match_date: new Date().toISOString() }
    })
  }
  
  trackMessage(matchId: string, isFirstMessage: boolean = false) {
    const event = isFirstMessage ? 
      POSTHOG_CONFIG.events.CONVERSATION_STARTED : 
      POSTHOG_CONFIG.events.MESSAGE_SENT
      
    this.posthog.capture(event, {
      match_id: matchId,
      is_first_message: isFirstMessage,
      $set_once: isFirstMessage ? { first_message_date: new Date().toISOString() } : {}
    })
  }
  
  // Revenue tracking
  trackPurchaseIntent(productType: string, priceId: string) {
    this.posthog.capture(POSTHOG_CONFIG.events.PURCHASE_INITIATED, {
      product_type: productType,
      price_id: priceId
    })
  }
  
  trackPurchaseCompleted(subscriptionId: string, revenue: number) {
    this.posthog.capture(POSTHOG_CONFIG.events.PURCHASE_COMPLETED, {
      subscription_id: subscriptionId,
      revenue_cents: revenue,
      $set: { 
        is_premium: true,
        total_revenue: revenue
      }
    })
  }
  
  // Identify user with rich properties
  identifyUser(userId: string, userProperties: any) {
    this.posthog.identify(userId, {
      email: userProperties.email,
      username: userProperties.username,
      level: userProperties.level,
      is_premium: userProperties.is_premium,
      languages: userProperties.languages,
      ride_styles: userProperties.ride_styles,
      created_at: userProperties.created_at,
      platform: userProperties.platform || 'web'
    })
  }
}

// React Hook for analytics
export function useAnalytics() {
  const analytics = new CrewSnowAnalytics(window.posthog)
  
  return {
    trackSignup: analytics.trackSignup.bind(analytics),
    trackProfileCompleted: analytics.trackProfileCompleted.bind(analytics),
    trackSwipe: analytics.trackSwipe.bind(analytics),
    trackMatch: analytics.trackMatch.bind(analytics),
    trackMessage: analytics.trackMessage.bind(analytics),
    trackPurchaseIntent: analytics.trackPurchaseIntent.bind(analytics),
    trackPurchaseCompleted: analytics.trackPurchaseCompleted.bind(analytics),
    identifyUser: analytics.identifyUser.bind(analytics)
  }
}

export default POSTHOG_CONFIG
