// CrewSnow Delete User Account - Week 9
// 2.3 Suppression côté Auth + données selon spécifications

import { createClient } from 'npm:@supabase/supabase-js@2'

interface DeleteAccountRequest {
  confirmation_text: string // User must type confirmation
  deletion_reason?: string
}

interface DeleteAccountResponse {
  success: boolean
  message: string
  deleted_categories: string[]
  files_deleted: number
  deletion_id: string
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
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

    // =====================================
    // VALIDATION CONFIRMATION
    // =====================================

    let requestBody: DeleteAccountRequest
    try {
      requestBody = await req.json()
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON payload' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { confirmation_text, deletion_reason = 'user_request' } = requestBody

    // Vérifier confirmation utilisateur
    if (confirmation_text !== 'DELETE MY ACCOUNT') {
      return new Response(
        JSON.stringify({ 
          error: 'Invalid confirmation', 
          required: 'Please type exactly: DELETE MY ACCOUNT' 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`🗑️ Account deletion request for user: ${userId}`)

    // =====================================
    // VÉRIFIER UTILISATEUR EXISTE
    // =====================================

    const { data: userExists } = await supabase
      .from('users')
      .select('id, email, username')
      .eq('id', userId)
      .single()

    if (!userExists) {
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // SUPPRESSION DONNÉES COMPLÈTE
    // =====================================

    console.log('🔥 Starting complete user data deletion...')

    const { data: deletionResult, error: deletionError } = await supabase
      .rpc('delete_user_data', {
        p_user_id: userId,
        p_deletion_reason: deletion_reason
      })
      .single()

    if (deletionError) {
      console.error('Database deletion error:', deletionError)
      throw new Error(`Database deletion failed: ${deletionError.message}`)
    }

    if (!deletionResult.success) {
      throw new Error(`Deletion failed: ${deletionResult.message}`)
    }

    console.log(`✅ Database deletion completed: ${deletionResult.deleted_categories.length} categories`)

    // =====================================
    // SUPPRESSION AUTH UTILISATEUR selon spécifications
    // =====================================

    console.log('🔐 Deleting user from Supabase Auth...')

    // Créer admin client pour suppression auth
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { error: authDeleteError } = await adminClient.auth.admin.deleteUser(userId)

    if (authDeleteError) {
      console.error('Auth deletion error:', authDeleteError)
      // Ne pas échouer si suppression auth échoue - données déjà supprimées
      console.warn('Auth deletion failed but data deletion completed')
    } else {
      console.log('✅ User deleted from Supabase Auth')
    }

    // =====================================
    // RÉPONSE FINALE
    // =====================================

    const response: DeleteAccountResponse = {
      success: true,
      message: 'Account and all personal data have been permanently deleted',
      deleted_categories: deletionResult.deleted_categories,
      files_deleted: deletionResult.files_deleted,
      deletion_id: `del_${Date.now()}_${userId.substring(0, 8)}`
    }

    console.log(`✅ Complete account deletion finished for user ${userId}`)

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('❌ Account deletion error:', error)
    
    return new Response(
      JSON.stringify({
        error: 'Account deletion failed',
        message: 'Please contact support if you continue to have issues',
        detail: error.message,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
