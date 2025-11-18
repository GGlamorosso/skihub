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

// 🔍 Helper pour filtrer + trier les candidats
function filterAndRankCandidates(
  raw: any[],
  {
    minScore,
    maxDistanceKm,
    limit,
  }: { minScore: number; maxDistanceKm: number; limit: number }
): CandidateResponse[] {
  const filtered = raw
    .filter((candidate) => {
      const score = candidate.compatibility_score ?? 0
      const distance = candidate.distance_km ?? 999999
      const scoreOk = score >= minScore
      const distanceOk = distance <= maxDistanceKm
      return scoreOk && distanceOk
    })
    .sort((a, b) => {
      // Tri principal : meilleur score d'abord
      const scoreDiff = (b.compatibility_score ?? 0) - (a.compatibility_score ?? 0)
      if (scoreDiff !== 0) return scoreDiff
      // En cas d'égalité : plus proche d'abord
      return (a.distance_km ?? 999999) - (b.distance_km ?? 999999)
    })
    .slice(0, limit)

  return filtered.map((candidate: any) => ({
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
    photo_url: candidate.photo_url,
  }))
}

// 🔄 Helper pour transformer des users en CandidateResponse (pour fallback SQL)
function transformUsersToCandidates(users: any[], defaultScore: number = 1.0): CandidateResponse[] {
  return users.map((item: any) => {
    const user = item.users || item // Support both formats
    return {
      candidate_id: user.id || item.user_id,
      username: user.username || 'Utilisateur',
      bio: user.bio || '',
      level: user.level || 'beginner',
      compatibility_score: defaultScore,
      distance_km: item.distance_km ?? 999,
      station_name: item.station_name || 'Non spécifiée',
      score_breakdown: {
        level_score: 0,
        styles_score: 0,
        languages_score: 0,
        distance_score: 0,
        overlap_score: 0,
      },
      is_premium: user.is_premium || false,
      last_active_at: user.last_active_at || new Date().toISOString(),
      photo_url: user.profile_photos
        ?.filter((p: any) => p.is_main && p.moderation_status === 'approved')?.[0]?.storage_path || null,
    }
  })
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
    let candidatesData: any[] = []

    try {
      // Étape 1 : Appel à la fonction SQL optimisée
      console.log(`🔍 Fetching candidates for user ${userId}, limit: ${limit + 1}`)
      
      const { data, error: candidatesError } = await supabaseClient
        .rpc('get_optimized_candidates', {
          p_user_id: userId,
          p_limit: limit + 1, // +1 pour has_more
          use_cache: use_cache
        })

      if (candidatesError) {
        console.error('❌ get_optimized_candidates failed:', candidatesError.message)
        console.error('   Code:', candidatesError.code)
        console.error('   Details:', candidatesError.details)
        // Continue avec fallback SQL
      } else {
        candidatesData = data ?? []
        console.log(`✅ get_optimized_candidates returned ${candidatesData.length} candidates`)
        cacheUsed = candidatesData.length > 0 && use_cache
      }

      // =====================================
      // 🔁 LOGIQUE DE FALLBACK PROGRESSIVE
      // =====================================

      // 1) Strict : paramètres demandés par le front
      if (candidatesData.length > 0) {
        candidates = filterAndRankCandidates(candidatesData, {
          minScore: min_score,
          maxDistanceKm: max_distance_km,
          limit,
        })
      }

      // 2) Si rien → on relâche un peu les critères (sur les mêmes données)
      if (candidates.length === 0 && candidatesData.length > 0) {
        const relaxedScore = Math.max(0, min_score - 1)
        const relaxedDistance = max_distance_km * 2

        candidates = filterAndRankCandidates(candidatesData, {
          minScore: relaxedScore,
          maxDistanceKm: relaxedDistance,
          limit,
        })
      }

      // 3) Si toujours rien → on prend les meilleurs possibles, quoi qu'il arrive
      if (candidates.length === 0 && candidatesData.length > 0) {
        const fallbackSorted = [...candidatesData]
          .sort((a, b) => {
            const scoreDiff = (b.compatibility_score ?? 0) - (a.compatibility_score ?? 0)
            if (scoreDiff !== 0) return scoreDiff
            return (a.distance_km ?? 999999) - (b.distance_km ?? 999999)
          })
          .slice(0, limit)

        candidates = fallbackSorted.map((candidate: any) => ({
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
      }

      // 4) Si get_optimized_candidates a retourné 0 résultats → Fallback SQL
      if (candidates.length === 0 && candidatesData.length === 0) {
        console.log('⚠️ No results from SQL function, trying SQL fallback...')
        
        // Vérifier d'abord si l'utilisateur a une station
        const { data: userStationCheck } = await supabaseClient
          .from('user_station_status')
          .select('station_id, date_from, date_to')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle()
        
        if (!userStationCheck) {
          console.error('❌ User has no active station - cannot match')
          // Retourner liste vide plutôt que de crasher
          return new Response(JSON.stringify({
            candidates: [],
            has_more: false,
            total_found: 0,
            cache_used: false,
            processing_time_ms: Date.now() - startTime,
            error: 'User has no active station'
          }), {
            status: 200,
            headers: { 'Content-Type': 'application/json' },
          })
        }
        
        console.log(`📍 User station: ${userStationCheck.station_id}, dates: ${userStationCheck.date_from} to ${userStationCheck.date_to}`)
        
        // Récupérer la station active de l'utilisateur
        const { data: userStation } = await supabaseClient
          .from('user_station_status')
          .select('station_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle()

        if (userStation?.station_id) {
          // Fallback : Tous les utilisateurs actifs de la même station
          const { data: fallbackUsers, error: fallbackError } = await supabaseClient
            .from('user_station_status')
            .select(`
              user_id,
              users!inner(
                id,
                username,
                bio,
                level,
                is_premium,
                last_active_at,
                profile_photos(storage_path, is_main, moderation_status)
              )
            `)
            .eq('station_id', userStation.station_id)
            .eq('is_active', true)
            .neq('user_id', userId)
            .limit(limit + 1)

          if (!fallbackError && fallbackUsers && fallbackUsers.length > 0) {
            candidates = transformUsersToCandidates(fallbackUsers, 1.0)
            console.log(`✅ SQL fallback returned ${candidates.length} candidates from same station`)
          } else {
            console.log(`⚠️ SQL fallback (same station) returned ${fallbackUsers?.length || 0} users`)
            if (fallbackError) {
              console.error('   Error:', fallbackError.message)
            }
          }
        }

        // 5) Dernier recours : Tous les utilisateurs actifs (n'importe quelle station)
        if (candidates.length === 0) {
          console.log('Trying ultimate SQL fallback: all active users...')
          
          const { data: allUsers, error: allUsersError } = await supabaseClient
            .from('users')
            .select(`
              id,
              username,
              bio,
              level,
              is_premium,
              last_active_at,
              profile_photos(storage_path, is_main, moderation_status)
            `)
            .eq('is_active', true)
            .neq('id', userId)
            .limit(limit + 1)

          if (!allUsersError && allUsers && allUsers.length > 0) {
            candidates = transformUsersToCandidates(allUsers, 0.5)
            console.log(`✅ Ultimate fallback returned ${candidates.length} candidates`)
          } else {
            console.log(`⚠️ Ultimate fallback returned ${allUsers?.length || 0} users`)
            if (allUsersError) {
              console.error('   Error:', allUsersError.message)
            }
          }
        }
      }

      console.log(`✅ Final result: ${candidates.length} candidates (from ${candidatesData.length} raw data)`)
      
      if (candidates.length === 0) {
        console.warn('⚠️ WARNING: Returning 0 candidates - user will see empty feed')
        console.warn('   Possible reasons:')
        console.warn('   - No other users at same station')
        console.warn('   - Date ranges do not overlap')
        console.warn('   - All users already liked/matched')
        console.warn('   - Distance too large')
      }

    } catch (error: any) {
      console.error('Error fetching candidates:', error)
      
      return new Response(
        JSON.stringify({ 
          error: 'Failed to fetch candidates', 
          details: error.message ?? String(error)
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
    const hasMore = candidates.length > limit
    const nextCursor = hasMore && candidates.length > 0 ? {
      score: candidates[candidates.length - 1].compatibility_score,
      distance: candidates[candidates.length - 1].distance_km
    } : null

    // =====================================
    // RESPONSE
    // =====================================
    const processingTime = Date.now() - startTime

    const response: MatchingResponse = {
      candidates: candidates.slice(0, limit), // S'assurer qu'on ne dépasse pas la limite
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

  } catch (error: any) {
    console.error('Match candidates error:', error)
    
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: error.message ?? String(error),
        processing_time_ms: Date.now() - startTime
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
