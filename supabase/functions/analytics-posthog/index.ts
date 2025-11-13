// CrewSnow PostHog Analytics Integration - Week 8
// 2. Pipeline analytics PostHog/Supabase Analytics selon spécifications

import { createClient } from 'npm:@supabase/supabase-js@2'

interface AnalyticsEvent {
  event: string
  distinct_id: string
  properties?: Record<string, any>
  timestamp?: string
}

interface PostHogConfig {
  api_key: string
  host?: string
}

class PostHogClient {
  private apiKey: string
  private host: string

  constructor(config: PostHogConfig) {
    this.apiKey = config.api_key
    this.host = config.host || 'https://app.posthog.com'
  }

  async capture(events: AnalyticsEvent[]): Promise<boolean> {
    try {
      const response = await fetch(`${this.host}/capture/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          api_key: this.apiKey,
          batch: events.map(event => ({
            event: event.event,
            distinct_id: event.distinct_id,
            properties: {
              ...event.properties,
              $lib: 'crewsnow-backend',
              $lib_version: '1.0.0',
            },
            timestamp: event.timestamp || new Date().toISOString(),
          })),
        }),
      })

      return response.ok
    } catch (error) {
      console.error('PostHog capture error:', error)
      return false
    }
  }
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
)

const posthog = new PostHogClient({
  api_key: Deno.env.get('POSTHOG_API_KEY') || '',
  host: Deno.env.get('POSTHOG_HOST')
})

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    // =====================================
    // BATCH PROCESS PENDING EVENTS
    // =====================================

    // Get events not yet sent to PostHog
    const { data: pendingEvents, error: eventsError } = await supabase
      .from('analytics_events')
      .select('*')
      .eq('posthog_sent', false)
      .order('timestamp', { ascending: true })
      .limit(100)

    if (eventsError) {
      throw new Error(`Failed to fetch pending events: ${eventsError.message}`)
    }

    if (!pendingEvents || pendingEvents.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No pending events to process', processed: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // TRANSFORM EVENTS FOR POSTHOG
    // =====================================

    const posthogEvents: AnalyticsEvent[] = pendingEvents.map(event => ({
      event: event.event_name,
      distinct_id: event.distinct_id || event.user_id,
      properties: {
        ...event.properties,
        ...event.user_properties,
        $session_id: event.session_id,
        $ip: event.ip_address,
        $user_agent: event.user_agent,
        platform: event.platform,
        app_version: event.app_version,
        // Add CrewSnow specific context
        $source: 'crewsnow_backend',
        event_id: event.id,
      },
      timestamp: event.timestamp,
    }))

    console.log(`📡 Sending ${posthogEvents.length} events to PostHog...`)

    // =====================================
    // SEND TO POSTHOG
    // =====================================

    const success = await posthog.capture(posthogEvents)

    if (success) {
      // Mark events as sent
      const eventIds = pendingEvents.map(e => e.id)
      
      const { error: updateError } = await supabase
        .from('analytics_events')
        .update({
          posthog_sent: true,
          posthog_sent_at: new Date().toISOString(),
        })
        .in('id', eventIds)

      if (updateError) {
        console.error('Failed to mark events as sent:', updateError)
        // Continue anyway - better to send duplicates than miss events
      }

      console.log(`✅ Successfully sent ${posthogEvents.length} events to PostHog`)

      return new Response(
        JSON.stringify({
          message: 'Events sent to PostHog successfully',
          processed: posthogEvents.length,
          success: true,
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    } else {
      console.error('❌ Failed to send events to PostHog')

      return new Response(
        JSON.stringify({
          error: 'Failed to send events to PostHog',
          processed: 0,
          retry_needed: true,
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    console.error('Analytics processing error:', error)
    
    return new Response(
      JSON.stringify({
        error: 'Analytics processing failed',
        detail: error.message,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Track specific events with proper context
export async function trackUserEvent(
  eventName: string,
  userId: string,
  properties: Record<string, any> = {},
  sessionId?: string
): Promise<boolean> {
  try {
    const { error } = await supabase.rpc('track_analytics_event', {
      p_event_name: eventName,
      p_user_id: userId,
      p_properties: properties,
      p_session_id: sessionId,
    })

    return !error
  } catch (error) {
    console.error('Event tracking error:', error)
    return false
  }
}

// Batch event processing
export async function processPendingEvents(): Promise<number> {
  try {
    const response = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/analytics-posthog`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
      },
    })

    const result = await response.json()
    return result.processed || 0
  } catch (error) {
    console.error('Batch processing error:', error)
    return 0
  }
}
