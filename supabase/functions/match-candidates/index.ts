// CrewSnow Match Candidates Edge Function - Optimized
// Description: Endpoint for optimized matching with pagination and multi-level fallbacks

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
  photo_url?: string | null
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

// 🔍 Helper pour filtrer + trier les candidats (ne PAS couper à limit ici)
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
    .slice(0, limit) // ici limit sera déjà "limit + 1" pour détecter has_more

  return filtered.map((candidate: any) => ({
    candidate_id: candidate.candidate_id,
    username: candidate.username,
    bio: candidate.bio,
    level: candidate.level,
    compatibility_score: candidate.compatibility_score,
    distance_km: candidate.distance_km,
    station_name: candidate.station_name,
    score_breakdown: candidate.score_breakdown || {
      level_score: 0,
      styles_score: 0,
      languages_score: 0,
      distance_score: 0,
      overlap_score: 0,
    },
    is_premium: candidate.is_premium,
    last_active_at: candidate.last_active_at,
    photo_url: candidate.photo_url,
  }))
}

// 🔄 Helper pour transformer des users en CandidateResponse (fallback SQL)
function transformUsersToCandidates(users: any[], defaultScore: number = 1.0): CandidateResponse[] {
  return users.map((item: any) => {
    const user = item.users || item // Support both formats (user_station_status join users ou users direct)

    const mainPhoto =
      user.profile_photos?.find(
        (p: any) => p.is_main && p.moderation_status === 'approved'
      ) || user.profile_photos?.[0]

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
      photo_url: mainPhoto?.storage_path ?? null,
    }
  })
}

Deno.serve(async (req: Request): Promise<Response> => {
  // CORS preflight
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
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    const { data: userData, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !userData.user) {
      return new Response(JSON.stringify({ error: 'Invalid or expired token' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const userId = userData.user.id

    // =====================================
    // PARSE REQUEST
    // =====================================
    let requestBody: MatchingRequest = {}
    try {
      requestBody = await req.json()
    } catch {
      // pas grave, on utilise les defaults
    }

    const {
      limit = 20,
      use_cache = true,
      include_collaborative = false,
      min_score = 3,
      max_distance_km = 100,
      cursor, // pour plus tard si tu veux filtrer côté client
    } = requestBody

    let candidates: CandidateResponse[] = []
    let cacheUsed = false
    let candidatesData: any[] = []

    // =====================================
    // 1) APPEL FONCTION SQL get_optimized_candidates
    // =====================================
    try {
      console.log(`🔍 Fetching candidates for user ${userId}, limit: ${limit + 1}`)

      const { data, error: candidatesError } = await supabaseClient.rpc(
        'get_optimized_candidates',
        {
          p_user_id: userId,
          p_limit: limit + 1, // +1 pour déterminer has_more
          p_use_cache: use_cache,
        }
      )

      if (candidatesError) {
        console.error('❌ get_optimized_candidates failed:', candidatesError.message)
        console.error('   Code:', candidatesError.code)
        console.error('   Details:', candidatesError.details)
        // on continue avec fallback SQL
        candidatesData = []
      } else {
        candidatesData = data ?? []
        console.log(`✅ get_optimized_candidates returned ${candidatesData.length} rows`)
        cacheUsed = candidatesData.length > 0 && use_cache
      }

      // =====================================
      // 2) LOGIQUE DE FILTER + RELAX SUR LES RÉSULTATS SQL
      // =====================================

      // a) Niveau strict sur les résultats SQL
      if (candidatesData.length > 0) {
        candidates = filterAndRankCandidates(candidatesData, {
          minScore: min_score,
          maxDistanceKm: max_distance_km,
          limit: limit + 1, // +1 pour has_more
        })
      }

      // b) Si rien → on relâche un peu (score - 1, distance x2)
      if (candidates.length === 0 && candidatesData.length > 0) {
        const relaxedScore = Math.max(0, min_score - 1)
        const relaxedDistance = max_distance_km * 2

        candidates = filterAndRankCandidates(candidatesData, {
          minScore: relaxedScore,
          maxDistanceKm: relaxedDistance,
          limit: limit + 1,
        })
      }

      // c) Si toujours rien → prendre les meilleurs possibles (scorés par SQL)
      if (candidates.length === 0 && candidatesData.length > 0) {
        const fallbackSorted = [...candidatesData]
          .sort((a, b) => {
            const scoreDiff = (b.compatibility_score ?? 0) - (a.compatibility_score ?? 0)
            if (scoreDiff !== 0) return scoreDiff
            return (a.distance_km ?? 999999) - (b.distance_km ?? 999999)
          })
          .slice(0, limit + 1)

        candidates = fallbackSorted.map((candidate: any) => ({
          candidate_id: candidate.candidate_id,
          username: candidate.username,
          bio: candidate.bio,
          level: candidate.level,
          compatibility_score: candidate.compatibility_score,
          distance_km: candidate.distance_km,
          station_name: candidate.station_name,
          score_breakdown: candidate.score_breakdown || {
            level_score: 0,
            styles_score: 0,
            languages_score: 0,
            distance_score: 0,
            overlap_score: 0,
          },
          is_premium: candidate.is_premium,
          last_active_at: candidate.last_active_at,
          photo_url: candidate.photo_url,
        }))
      }

      // =====================================
      // 3) FALLBACK SQL SI AUCUN RÉSULTAT DE LA FONCTION
      // =====================================
      if (candidates.length === 0 && candidatesData.length === 0) {
        console.log('⚠️ No results from SQL function, trying SQL fallback...')

        // 3.a) Fallback "même station" si l'utilisateur a une station active
        const { data: userStation } = await supabaseClient
          .from('user_station_status')
          .select('station_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle()

        if (userStation?.station_id) {
          const { data: fallbackUsers, error: fallbackError } = await supabaseClient
            .from('user_station_status')
            .select(
              `
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
            `,
            )
            .eq('station_id', userStation.station_id)
            .eq('is_active', true)
            .neq('user_id', userId)
            .limit(limit + 1)

          if (!fallbackError && fallbackUsers && fallbackUsers.length > 0) {
            candidates = transformUsersToCandidates(fallbackUsers, 1.0)
            console.log(
              `✅ SQL fallback (same station) returned ${candidates.length} candidates`,
            )
          } else {
            console.log(
              `⚠️ SQL fallback (same station) returned ${fallbackUsers?.length || 0} users`,
            )
            if (fallbackError) {
              console.error('   Error:', fallbackError.message)
            }
          }
        }

        // 3.b) Ultime fallback : tous les utilisateurs actifs (toutes stations)
        if (candidates.length === 0) {
          console.log('Trying ultimate SQL fallback: all active users...')

          const { data: allUsers, error: allUsersError } = await supabaseClient
            .from('users')
            .select(
              `
              id,
              username,
              bio,
              level,
              is_premium,
              last_active_at,
              profile_photos(storage_path, is_main, moderation_status)
            `,
            )
            .eq('is_active', true)
            .neq('id', userId)
            .limit(limit + 1)

          if (!allUsersError && allUsers && allUsers.length > 0) {
            candidates = transformUsersToCandidates(allUsers, 0.5)
            console.log(`✅ Ultimate fallback returned ${candidates.length} candidates`)
          } else {
            console.log(
              `⚠️ Ultimate fallback returned ${allUsers?.length || 0} users`,
            )
            if (allUsersError) {
              console.error('   Error:', allUsersError.message)
            }
          }
        }
      }

      console.log(
        `✅ Final result before pagination: ${candidates.length} candidates (from ${candidatesData.length} raw SQL rows)`,
      )

      if (candidates.length === 0) {
        console.warn('⚠️ Returning 0 candidates - user will see empty feed')
      }
    } catch (error: any) {
      console.error('Error fetching candidates:', error)

      return new Response(
        JSON.stringify({
          error: 'Failed to fetch candidates',
          details: error.message ?? String(error),
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      )
    }

    // =====================================
    // 4) COLLABORATIVE FILTERING (OPTIONNEL)
    // =====================================
    let collaborativeRecommendations: any[] = []

    if (include_collaborative && candidates.length < limit) {
      try {
        const { data: collabData, error: collabError } = await supabaseClient.rpc(
          'get_collaborative_recommendations',
          {
            target_user_id: userId,
            limit_results: Math.min(10, limit - candidates.length),
          },
        )

        if (!collabError && collabData) {
          collaborativeRecommendations = collabData.map((rec: any) => ({
            user_id: rec.recommended_user_id,
            username: rec.username,
            similarity_score: rec.similarity_score,
            common_likes_count: rec.common_likes_count,
            reason: rec.recommendation_reason,
            type: 'collaborative',
          }))
        }
      } catch (error) {
        console.warn('Collaborative filtering failed:', error)
      }
    }

    // =====================================
    // 5) PAGINATION (has_more + next_cursor)
    // =====================================
    const hasMore = candidates.length > limit
    const paginatedCandidates = candidates.slice(0, limit)

    const last = paginatedCandidates[paginatedCandidates.length - 1]
    const nextCursor =
      hasMore && last
        ? {
            score: last.compatibility_score,
            distance: last.distance_km,
          }
        : null

    const processingTime = Date.now() - startTime

    const response: MatchingResponse = {
      candidates: paginatedCandidates,
      ...(include_collaborative && { collaborative_recommendations: collaborativeRecommendations }),
      has_more: hasMore,
      ...(nextCursor && { next_cursor: nextCursor }),
      total_found: candidates.length,
      cache_used: cacheUsed,
      processing_time_ms: processingTime,
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    })
  } catch (error: any) {
    console.error('Match candidates error:', error)

    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: error.message ?? String(error),
        processing_time_ms: Date.now() - startTime,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})
