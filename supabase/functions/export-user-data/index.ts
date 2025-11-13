// CrewSnow User Data Export - Week 9
// 1.1 Edge Function export_user_data pour RGPD Article 20

import { createClient } from 'npm:@supabase/supabase-js@2'

interface UserDataExport {
  user_profile: any
  profile_photos: any[]
  likes_given: any[]
  likes_received: any[]
  matches: any[]
  messages: any[]
  ride_stats: any[]
  subscriptions: any[]
  groups: any[]
  consents: any[]
  daily_usage: any[]
  swipe_events: any[]
  export_metadata: {
    exported_at: string
    export_id: string
    data_retention_info: string
    contact_info: string
  }
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '' // Service role pour accès complet
)

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    // =====================================
    // AUTHENTICATION FORTE
    // =====================================
    
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing Authorization header' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Vérifier JWT avec client user context
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: userData, error: userError } = await userClient.auth.getUser()
    if (userError || !userData.user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const userId = userData.user.id
    console.log(`📥 Data export request for user: ${userId}`)

    // =====================================
    // LOG EXPORT REQUEST
    // =====================================
    
    const clientIP = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown'
    
    await supabase.from('export_logs').insert({
      user_id: userId,
      requested_at: new Date().toISOString(),
      ip_address: clientIP,
      user_agent: req.headers.get('user-agent'),
      status: 'initiated'
    })

    // =====================================
    // COLLECTE DONNÉES UTILISATEUR
    // =====================================

    console.log('🔍 Collecting user data...')

    // Profil utilisateur (masquer données sensibles)
    const { data: userProfile } = await supabase
      .from('users')
      .select('id, username, email, bio, birth_date, level, ride_styles, languages, is_premium, premium_expires_at, verified_video_status, created_at, updated_at, last_active_at')
      .eq('id', userId)
      .single()

    // Photos avec URLs signées temporaires
    const { data: photos } = await supabase
      .from('profile_photos')
      .select('id, storage_path, is_main, display_order, moderation_status, created_at')
      .eq('user_id', userId)

    const photosWithUrls = []
    if (photos) {
      for (const photo of photos) {
        let signedUrl = null
        if (photo.moderation_status === 'approved') {
          const { data: urlData } = await supabase.storage
            .from('profile_photos')
            .createSignedUrl(photo.storage_path, 300) // 5 minutes selon spécifications
          signedUrl = urlData?.signedUrl
        }
        
        photosWithUrls.push({
          ...photo,
          signed_url: signedUrl,
          note: photo.moderation_status !== 'approved' ? 'Photo not approved - no download URL provided' : null
        })
      }
    }

    // Likes donnés
    const { data: likesGiven } = await supabase
      .from('likes')
      .select('liked_id, created_at')
      .eq('liker_id', userId)

    // Likes reçus  
    const { data: likesReceived } = await supabase
      .from('likes')
      .select('liker_id, created_at')
      .eq('liked_id', userId)

    // Matches
    const { data: matches } = await supabase
      .from('matches')
      .select('id, user1_id, user2_id, created_at, matched_at_station_id, is_active')
      .or(`user1_id.eq.${userId},user2_id.eq.${userId}`)

    // Messages
    const { data: messages } = await supabase
      .from('messages')
      .select('id, match_id, content, message_type, created_at, is_read, read_at')
      .eq('sender_id', userId)

    // Statistiques ski
    const { data: rideStats } = await supabase
      .from('ride_stats_daily')
      .select('*')
      .eq('user_id', userId)

    // Abonnements (masquer stripe_customer_id)
    const { data: subscriptions } = await supabase
      .from('subscriptions')
      .select('id, status, current_period_start, current_period_end, amount_cents, currency, interval, created_at')
      .eq('user_id', userId)

    // Groupes
    const { data: groups } = await supabase
      .from('group_members')
      .select('group_id, joined_at, is_active, groups(name, description, created_at)')
      .eq('user_id', userId)

    // Consentements
    const { data: consents } = await supabase
      .from('consents')
      .select('*')
      .eq('user_id', userId)

    // Usage quotidien
    const { data: dailyUsage } = await supabase
      .from('daily_usage')
      .select('*')
      .eq('user_id', userId)

    // Événements swipe
    const { data: swipeEvents } = await supabase
      .from('swipe_events')
      .select('target_id, swipe_value, created_at')
      .eq('user_id', userId)

    // =====================================
    // AGRÉGATION JSON SELON RGPD
    // =====================================

    const exportData: UserDataExport = {
      user_profile: userProfile,
      profile_photos: photosWithUrls || [],
      likes_given: likesGiven || [],
      likes_received: likesReceived || [],
      matches: matches || [],
      messages: messages || [],
      ride_stats: rideStats || [],
      subscriptions: subscriptions || [], // Données sensibles masquées
      groups: groups || [],
      consents: consents || [],
      daily_usage: dailyUsage || [],
      swipe_events: swipeEvents || [],
      export_metadata: {
        exported_at: new Date().toISOString(),
        export_id: `export_${userId}_${Date.now()}`,
        data_retention_info: 'Data exported as per GDPR Article 20. Original data retention: 2 years after account deletion.',
        contact_info: 'For questions about this export: privacy@crewsnow.com'
      }
    }

    console.log(`📊 Collected data for user ${userId}: ${Object.keys(exportData).length} categories`)

    // =====================================
    // ÉCRITURE FICHIER TEMPORAIRE
    // =====================================

    const exportFileName = `${userId}_export_${Date.now()}.json`
    const exportPath = `exports/${exportFileName}`
    
    const exportBlob = new Blob([JSON.stringify(exportData, null, 2)], {
      type: 'application/json'
    })
    
    // Upload vers bucket privé
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('exports')
      .upload(exportPath, exportBlob, {
        cacheControl: '300', // 5 minutes cache
        upsert: false
      })

    if (uploadError) {
      console.error('Upload error:', uploadError)
      throw new Error(`Failed to create export file: ${uploadError.message}`)
    }

    // =====================================
    // URL SIGNÉE TEMPORAIRE
    // =====================================

    const { data: signedUrlData, error: urlError } = await supabase.storage
      .from('exports')
      .createSignedUrl(exportPath, 300) // 5 minutes selon spécifications

    if (urlError || !signedUrlData?.signedUrl) {
      console.error('Signed URL error:', urlError)
      throw new Error('Failed to create download link')
    }

    // =====================================
    // LOG SUCCÈS
    // =====================================

    await supabase.from('export_logs').insert({
      user_id: userId,
      requested_at: new Date().toISOString(),
      ip_address: clientIP,
      user_agent: req.headers.get('user-agent'),
      status: 'completed',
      export_file_path: exportPath,
      expires_at: new Date(Date.now() + 5 * 60 * 1000).toISOString() // 5 minutes
    })

    console.log(`✅ Export completed for user ${userId}`)

    // =====================================
    // RÉPONSE
    // =====================================

    return new Response(JSON.stringify({
      success: true,
      message: 'Personal data export completed',
      download_url: signedUrlData.signedUrl,
      expires_in_minutes: 5,
      export_id: exportData.export_metadata.export_id,
      data_categories: Object.keys(exportData).filter(k => k !== 'export_metadata').length,
      total_records: Object.values(exportData).flat().length,
      legal_notice: 'This export contains all your personal data stored in CrewSnow as per GDPR Article 20. The download link expires in 5 minutes for security.'
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('❌ Export error:', error)
    
    // Log échec
    try {
      await supabase.from('export_logs').insert({
        user_id: userData?.user?.id || null,
        requested_at: new Date().toISOString(),
        ip_address: req.headers.get('x-forwarded-for') || 'unknown',
        status: 'failed',
        error_message: error.message
      })
    } catch (logError) {
      console.error('Failed to log export error:', logError)
    }
    
    return new Response(
      JSON.stringify({
        error: 'Data export failed',
        message: 'Please try again or contact support if the problem persists',
        details: error.message,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
