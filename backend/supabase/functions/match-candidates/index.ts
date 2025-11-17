// Edge Function: match-candidates
// Retourne les candidats potentiels pour le matching

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get Authorization header
    const authHeader = req.headers.get('Authorization')
    
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing Authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get authenticated user
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser()

    if (authError || !user) {
      return new Response(
        JSON.stringify({ 
          error: 'Unauthorized',
          details: authError?.message || 'User not found'
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const body = await req.json()
    const { limit = 10, cursor, latitude, longitude, filters } = body

    // Build query for candidates using the public_profiles_v view
    // This view includes all necessary columns and filters active users
    let query = supabaseClient
      .from('public_profiles_v')
      .select('id, email, username, birth_date, level, ride_styles, languages, bio, objectives, age, main_photo_path, current_station, created_at')
      .neq('id', user.id) // Exclude current user
      .limit(limit)

    // Apply filters if provided
    // Note: age is calculated from birth_date, not stored directly
    if (filters) {
      // Age filtering would need to be done in SQL with date calculations
      // For now, skip age filtering or implement it in SQL
      if (filters.level) query = query.eq('level', filters.level)
      if (filters.rideStyles && filters.rideStyles.length > 0) {
        query = query.contains('ride_styles', filters.rideStyles)
      }
    }

    // Filter by location if provided (TODO: implement distance filtering with PostGIS)
    if (latitude && longitude) {
      // For now, we'll just return candidates
      // TODO: Add distance filtering using PostGIS if available
    }

    // Apply cursor for pagination
    if (cursor) {
      query = query.gt('id', cursor)
    }

    const { data: candidates, error } = await query

    if (error) {
      throw error
    }

    return new Response(
      JSON.stringify({
        candidates: candidates || [],
        nextCursor: candidates && candidates.length > 0 
          ? candidates[candidates.length - 1].id 
          : null,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
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
