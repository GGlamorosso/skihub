// CrewSnow Match Candidates Edge Function - Week 6
// Description: Endpoint for optimized matching with pagination and collaborative filtering

import { createClient } from 'npm:@supabase/supabase-js@2'

interface MatchingRequest {
  limit?: number
  use_cache?: boolean
  include_collaborative?: boolean
  min_score?: number
  max_distance_km?: number
  cursor?: {
    score: number
    distance: number
  }
}

interface CandidateResponse {
  candidate_id: string
  username: string
  bio: string
  level: string
  compatibility_score: number
  distance_km: number
  station_name: string
  score_breakdown: {
    level_score: number
    styles_score: number
    languages_score: number
    distance_score: number
    overlap_score: number
  }
  is_premium: boolean
  last_active_at: string
  photo_url?: string
}

interface MatchingResponse {
  candidates: CandidateResponse[]
  collaborative_recommendations?: any[]
  has_more: boolean
  next_cursor?: { score: number; distance: number }
  total_found: number
  cache_used: boolean
  processing_time_ms: number
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const startTime = Date.now()

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

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      },
    )

    const { data: userData, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !userData.user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const userId = userData.user.id

    // =====================================
    // PARSE REQUEST
    // =====================================

    let requestBody: MatchingRequest = {}
    try {
      requestBody = await req.json()
    } catch {
      // Use defaults if no body provided
    }

    const {
      limit = 20,
      use_cache = true,
      include_collaborative = false,
      min_score = 3,
      max_distance_km = 100,
      cursor
    } = requestBody

    // =====================================
    // GET CANDIDATES WITH OPTIMIZED MATCHING
    // =====================================

    let candidates: CandidateResponse[] = []
    let cacheUsed = false
    let candidatesData: any[] | null = null

    try {
      // Use optimized function with cache
      const { data, error: candidatesError } = await supabaseClient
        .rpc('get_optimized_candidates', {
          p_user_id: userId,
          p_limit: limit + 1, // +1 to check has_more
          use_cache: use_cache
        })

      if (candidatesError) {
        throw new Error(`Candidates query failed: ${candidatesError.message}`)
      }

      // ✅ Corrigé : Définir candidatesData explicitement
      candidatesData = data ?? []

      cacheUsed = candidatesData.length > 0 && use_cache

      // Transform data
      candidates = candidatesData.slice(0, limit).map((candidate: any) => ({
        candidate_id: candidate.candidate_id,
        username: candidate.username,
        bio: candidate.bio,
        level: candidate.level,
        compatibility_score: candidate.compatibility_score,
        distance_km: candidate.distance_km,
        station_name: candidate.station_name,
        score_breakdown: candidate.score_breakdown || {},
        is_premium: candidate.is_premium,
        last_active_at: candidate.last_active_at,
        photo_url: candidate.photo_url
      }))

    } catch (error) {
      console.error('Error fetching candidates:', error)
      
      return new Response(
        JSON.stringify({ 
          error: 'Failed to fetch candidates', 
          details: error.message 
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // =====================================
    // COLLABORATIVE FILTERING (OPTIONAL)
    // =====================================

    let collaborativeRecommendations: any[] = []
    
    if (include_collaborative && candidates.length < limit) {
      try {
        const { data: collabData, error: collabError } = await supabaseClient
          .rpc('get_collaborative_recommendations', {
            target_user_id: userId,
            limit_results: Math.min(10, limit - candidates.length)
          })

        if (!collabError && collabData) {
          collaborativeRecommendations = collabData.map((rec: any) => ({
            user_id: rec.recommended_user_id,
            username: rec.username,
            similarity_score: rec.similarity_score,
            common_likes_count: rec.common_likes_count,
            reason: rec.recommendation_reason,
            type: 'collaborative'
          }))
        }
      } catch (error) {
        console.warn('Collaborative filtering failed:', error)
      }
    }

    // =====================================
    // PAGINATION LOGIC
    // =====================================

    // ✅ Corrigé : Utiliser candidatesData qui est maintenant défini dans le scope
    const hasMore = (candidatesData?.length || 0) > limit
    const nextCursor = hasMore && candidates.length > 0 ? {
      score: candidates[candidates.length - 1].compatibility_score,
      distance: candidates[candidates.length - 1].distance_km
    } : null

    // =====================================
    // RESPONSE
    // =====================================

    const processingTime = Date.now() - startTime

    const response: MatchingResponse = {
      candidates,
      ...(include_collaborative && { collaborative_recommendations: collaborativeRecommendations }),
      has_more: hasMore,
      ...(nextCursor && { next_cursor: nextCursor }),
      total_found: candidates.length,
      cache_used: cacheUsed,
      processing_time_ms: processingTime
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*' 
      },
    })

  } catch (error) {
    console.error('Match candidates error:', error)
    
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: error.message,
        processing_time_ms: Date.now() - startTime
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
