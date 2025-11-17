// CrewSnow n8n Webhook Integration - Photo Moderation Trigger
// Description: Sends webhook to n8n when profile_photos are uploaded for moderation
// Author: CrewSnow Team - Week 5
// Date: January 2025

import { createClient } from 'npm:@supabase/supabase-js@2'
import { crypto } from 'node:crypto'

interface WebhookPayload {
  id: string
  user_id: string
  storage_path: string
  file_size_bytes: number
  mime_type: string
  created_at: string
  bucket_name: string
  signed_url_expires_in?: number
}

interface N8nWebhookResponse {
  success: boolean
  message?: string
  error?: string
}

// ============================================================================
// 1. WEBHOOK SUPABASE → n8n POUR MODÉRATION PHOTOS
// ============================================================================

// Generate HMAC signature for webhook security
function generateSignature(payload: string, secret: string): string {
  const hmac = crypto.createHmac('sha256', secret)
  hmac.update(payload, 'utf8')
  return hmac.digest('hex')
}

// Create signed URL for private photo access
async function createPhotoSignedUrl(
  supabaseClient: any,
  storagePath: string,
  expiresIn: number = 3600
): Promise<string | null> {
  try {
    const { data, error } = await supabaseClient.storage
      .from('profile_photos')
      .createSignedUrl(storagePath, expiresIn)

    if (error) {
      console.error('❌ Error creating signed URL:', error)
      return null
    }

    return data.signedUrl
  } catch (error) {
    console.error('❌ Exception creating signed URL:', error)
    return null
  }
}

// Send webhook to n8n with photo moderation data
async function sendToN8n(payload: WebhookPayload, signature: string): Promise<N8nWebhookResponse> {
  const n8nWebhookUrl = Deno.env.get('N8N_WEBHOOK_URL')
  
  if (!n8nWebhookUrl) {
    throw new Error('N8N_WEBHOOK_URL environment variable not configured')
  }

  try {
    console.log('📡 Sending webhook to n8n:', n8nWebhookUrl)
    
    const response = await fetch(n8nWebhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CrewSnow-Signature': `sha256=${signature}`,
        'User-Agent': 'CrewSnow-Webhook/1.0',
      },
      body: JSON.stringify(payload),
    })

    if (!response.ok) {
      throw new Error(`n8n webhook failed: ${response.status} ${response.statusText}`)
    }

    const result = await response.json()
    
    console.log('✅ n8n webhook successful:', result)
    return { success: true, message: 'Webhook sent to n8n successfully' }
    
  } catch (error) {
    console.error('❌ Error sending to n8n:', error)
    return { 
      success: false, 
      error: `Failed to send to n8n: ${error.message}` 
    }
  }
}

// Log webhook attempt for debugging and monitoring
async function logWebhookAttempt(
  supabaseClient: any,
  photoId: string,
  success: boolean,
  error?: string
): Promise<void> {
  try {
    // We'll create a webhook_logs table for tracking
    await supabaseClient
      .from('webhook_logs')
      .insert({
        table_name: 'profile_photos',
        record_id: photoId,
        webhook_type: 'n8n_moderation',
        success: success,
        error_message: error,
        timestamp: new Date().toISOString(),
      })
  } catch (logError) {
    console.warn('⚠️ Failed to log webhook attempt:', logError)
    // Don't fail the main function if logging fails
  }
}

Deno.serve(async (req: Request): Promise<Response> => {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    // =====================================
    // 1. PARSE INCOMING WEBHOOK DATA
    // =====================================

    const webhookPayload = await req.json()
    console.log('📨 Received profile photo webhook:', webhookPayload)

    // Extract photo data from Supabase trigger payload
    const photoData = webhookPayload.record || webhookPayload
    
    if (!photoData.id || !photoData.user_id || !photoData.storage_path) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields: id, user_id, or storage_path' 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Validate that photo is pending moderation
    if (photoData.moderation_status !== 'pending') {
      console.log('⏭️ Photo not pending, skipping moderation webhook')
      return new Response(
        JSON.stringify({ 
          message: 'Photo not pending moderation, no action needed' 
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // 2. CREATE SUPABASE CLIENT
    // =====================================

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', // Use service role for storage access
    )

    // =====================================
    // 3. GENERATE SIGNED URL FOR PHOTO
    // =====================================

    console.log(`🔗 Creating signed URL for photo: ${photoData.storage_path}`)
    
    const signedUrl = await createPhotoSignedUrl(
      supabaseClient,
      photoData.storage_path,
      3600 // 1 hour expiration for moderation
    )

    if (!signedUrl) {
      console.error('❌ Failed to create signed URL for photo')
      await logWebhookAttempt(supabaseClient, photoData.id, false, 'Failed to create signed URL')
      
      return new Response(
        JSON.stringify({ error: 'Failed to create signed URL for photo' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // 4. PREPARE n8n WEBHOOK PAYLOAD
    // =====================================

    const n8nPayload: WebhookPayload = {
      id: photoData.id,
      user_id: photoData.user_id,
      storage_path: photoData.storage_path,
      file_size_bytes: photoData.file_size_bytes || 0,
      mime_type: photoData.mime_type || 'image/jpeg',
      created_at: photoData.created_at || new Date().toISOString(),
      bucket_name: 'profile_photos',
      signed_url_expires_in: 3600,
      // Add the signed URL for n8n to download the image
      signed_url: signedUrl,
    } as any

    // =====================================
    // 5. GENERATE SECURITY SIGNATURE
    // =====================================

    const webhookSecret = Deno.env.get('N8N_WEBHOOK_SECRET')
    if (!webhookSecret) {
      console.error('❌ N8N_WEBHOOK_SECRET not configured')
      await logWebhookAttempt(supabaseClient, photoData.id, false, 'Webhook secret not configured')
      
      return new Response(
        JSON.stringify({ error: 'Webhook secret not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const payloadString = JSON.stringify(n8nPayload)
    const signature = generateSignature(payloadString, webhookSecret)

    // =====================================
    // 6. SEND TO n8n
    // =====================================

    console.log('🚀 Sending moderation request to n8n...')
    
    const n8nResult = await sendToN8n(n8nPayload, signature)
    
    // Log the attempt
    await logWebhookAttempt(
      supabaseClient, 
      photoData.id, 
      n8nResult.success, 
      n8nResult.error
    )

    if (n8nResult.success) {
      console.log('✅ Photo moderation webhook sent successfully')
      
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Photo sent for moderation',
          photo_id: photoData.id,
          webhook_status: 'sent_to_n8n',
        }),
        { 
          status: 200, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    } else {
      console.error('❌ Failed to send photo to n8n for moderation')
      
      return new Response(
        JSON.stringify({
          error: 'Failed to send photo for moderation',
          details: n8nResult.error,
        }),
        { 
          status: 500, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

  } catch (error) {
    console.error('❌ Webhook processing error:', error)
    
    return new Response(
      JSON.stringify({
        error: 'Internal webhook error',
        details: error.message,
      }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }
})
