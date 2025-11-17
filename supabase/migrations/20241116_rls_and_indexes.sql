-- CrewSnow Migration - Row Level Security (RLS) and Additional Indexes
-- This migration enables RLS on all tables, creates public view, and implements comprehensive security policies

-- ========================================
-- 1. ENABLE ROW LEVEL SECURITY ON ALL TABLES
-- ========================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_station_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ride_stats_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.boosts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 2. CREATE PUBLIC PROFILES VIEW
-- ========================================

CREATE OR REPLACE VIEW public.public_profiles_v AS
SELECT
  u.id,
  u.username AS pseudo,
  u.level,
  u.ride_styles,
  u.languages,
  u.is_premium,
  u.last_active_at,
  -- jointure photo approuvée et marquée is_main=true
  p.storage_path AS photo_main_url,
  us.station_id,
  us.date_from,
  us.date_to,
  us.radius_km
FROM public.users u
LEFT JOIN public.profile_photos p 
  ON p.user_id = u.id 
  AND p.is_main = true 
  AND p.moderation_status = 'approved'
LEFT JOIN public.user_station_status us 
  ON us.user_id = u.id
WHERE u.is_active = true 
  AND u.is_banned = false;

-- ========================================
-- 3. RLS POLICIES FOR STATIONS (Public Read)
-- ========================================

-- Stations are public reference data
CREATE POLICY "Stations are publicly readable"
  ON public.stations FOR SELECT
  TO authenticated, anon
  USING (true);

-- ========================================
-- 4. RLS POLICIES FOR PUBLIC_PROFILES_V
-- ========================================

CREATE POLICY "Public profiles view is accessible"
  ON public.public_profiles_v FOR SELECT
  TO authenticated, anon
  USING (true);

-- ========================================
-- 5. RLS POLICIES FOR USERS
-- ========================================

-- Users can only view their own complete profile
CREATE POLICY "Users can view their own profile"
  ON public.users FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "Users can update their own profile"
  ON public.users FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = id)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = id);

-- Users can insert their own profile (during signup)
CREATE POLICY "Users can insert their own profile"
  ON public.users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = id);

-- ========================================
-- 6. RLS POLICIES FOR PROFILE_PHOTOS
-- ========================================

-- Users can insert their own photos
CREATE POLICY "User can insert their own photo"
  ON public.profile_photos FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Public can read approved photos
CREATE POLICY "Public read approved photos"
  ON public.profile_photos FOR SELECT
  TO anon, authenticated
  USING (moderation_status = 'approved');

-- Users can read their own photos (any status)
CREATE POLICY "User can read their own photos"
  ON public.profile_photos FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Users can update their own photos (for is_main flag)
CREATE POLICY "User can update their own photos"
  ON public.profile_photos FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Users can delete their own photos
CREATE POLICY "User can delete their own photos"
  ON public.profile_photos FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- ========================================
-- 7. RLS POLICIES FOR USER_STATION_STATUS
-- ========================================

-- Users can insert their own station status
CREATE POLICY "User can insert their own station status"
  ON public.user_station_status FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Users can read their own station status
CREATE POLICY "User can read their own station status"
  ON public.user_station_status FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Users can update their own station status
CREATE POLICY "User can update their own station status"
  ON public.user_station_status FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Users can delete their own station status
CREATE POLICY "User can delete their own station status"
  ON public.user_station_status FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- ========================================
-- 8. RLS POLICIES FOR LIKES
-- ========================================

-- Users can like someone (insert)
CREATE POLICY "User can like someone"
  ON public.likes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = liker_id);

-- Users can read likes they gave or received
CREATE POLICY "User can read their likes"
  ON public.likes FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL AND (auth.uid() = liker_id OR auth.uid() = liked_id));

-- Users can delete their own likes (unlike)
CREATE POLICY "User can delete their own likes"
  ON public.likes FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = liker_id);

-- ========================================
-- 9. RLS POLICIES FOR MATCHES
-- ========================================

-- Users can view their own matches
CREATE POLICY "User can view their matches"
  ON public.matches FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL AND (auth.uid() = user1_id OR auth.uid() = user2_id));

-- ========================================
-- 10. RLS POLICIES FOR MESSAGES
-- ========================================

-- Users can view messages in their matches
CREATE POLICY "User can view messages in their matches"
  ON public.messages FOR SELECT
  TO authenticated
  USING (
    auth.uid() IS NOT NULL 
    AND (
      auth.uid() = sender_id
      OR auth.uid() = (SELECT user1_id FROM public.matches m WHERE m.id = match_id)
      OR auth.uid() = (SELECT user2_id FROM public.matches m WHERE m.id = match_id)
    )
  );

-- Users can send messages in their matches
CREATE POLICY "User can send messages in their matches"
  ON public.messages FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL 
    AND auth.uid() = sender_id
    AND (
      auth.uid() = (SELECT user1_id FROM public.matches m WHERE m.id = match_id)
      OR auth.uid() = (SELECT user2_id FROM public.matches m WHERE m.id = match_id)
    )
  );

-- ========================================
-- 11. RLS POLICIES FOR GROUPS
-- ========================================

-- Users can create groups
CREATE POLICY "User can create groups"
  ON public.groups FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = created_by);

-- Users can view groups they created or are members of
CREATE POLICY "User can view their groups"
  ON public.groups FOR SELECT
  TO authenticated
  USING (
    auth.uid() IS NOT NULL 
    AND (
      auth.uid() = created_by
      OR EXISTS (
        SELECT 1 FROM public.group_members gm 
        WHERE gm.group_id = id AND gm.user_id = auth.uid()
      )
    )
  );

-- Users can update groups they created
CREATE POLICY "User can update their groups"
  ON public.groups FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = created_by)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = created_by);

-- ========================================
-- 12. RLS POLICIES FOR GROUP_MEMBERS
-- ========================================

-- Users can join groups (insert)
CREATE POLICY "User can join groups"
  ON public.group_members FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Users can view group memberships for groups they're in
CREATE POLICY "User can view group memberships"
  ON public.group_members FOR SELECT
  TO authenticated
  USING (
    auth.uid() IS NOT NULL 
    AND EXISTS (
      SELECT 1 FROM public.group_members gm2 
      WHERE gm2.group_id = group_id AND gm2.user_id = auth.uid()
    )
  );

-- Users can leave groups (delete their own membership)
CREATE POLICY "User can leave groups"
  ON public.group_members FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- ========================================
-- 13. RLS POLICIES FOR FRIENDS
-- ========================================

-- Users can send friend requests
CREATE POLICY "User can send friend requests"
  ON public.friends FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = requester_id);

-- Users can view friendships they're involved in
CREATE POLICY "User can view their friendships"
  ON public.friends FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL AND (auth.uid() = requester_id OR auth.uid() = requested_id));

-- Users can update friendship status (accept/reject)
CREATE POLICY "User can update friendship status"
  ON public.friends FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = requested_id)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = requested_id);

-- Users can delete friendships they're involved in
CREATE POLICY "User can delete friendships"
  ON public.friends FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND (auth.uid() = requester_id OR auth.uid() = requested_id));

-- ========================================
-- 14. RLS POLICIES FOR RIDE_STATS_DAILY
-- ========================================

-- Users can read their own stats
CREATE POLICY "User can read own stats"
  ON public.ride_stats_daily FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Users can insert their own stats
CREATE POLICY "User can insert their stats"
  ON public.ride_stats_daily FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Users can update their own stats
CREATE POLICY "User can update their stats"
  ON public.ride_stats_daily FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- ========================================
-- 15. RLS POLICIES FOR BOOSTS
-- ========================================

-- Users can create boosts for themselves
CREATE POLICY "User can create their own boosts"
  ON public.boosts FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Users can view their own boosts
CREATE POLICY "User can view their own boosts"
  ON public.boosts FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- ========================================
-- 16. RLS POLICIES FOR SUBSCRIPTIONS
-- ========================================

-- Users can read their own subscription
CREATE POLICY "User can read own subscription"
  ON public.subscriptions FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- ========================================
-- 17. ADDITIONAL INDEXES FOR PERFORMANCE
-- ========================================

-- Index for "who liked me" queries (reverse lookup)
CREATE INDEX IF NOT EXISTS likes_liked_id_idx
  ON public.likes (liked_id);

-- Index for active users lookup
CREATE INDEX IF NOT EXISTS users_active_idx
  ON public.users (is_active, is_banned) 
  WHERE is_active = true AND is_banned = false;

-- Index for premium users lookup
CREATE INDEX IF NOT EXISTS users_premium_idx
  ON public.users (is_premium, premium_expires_at)
  WHERE is_premium = true;

-- Index for photo moderation status
CREATE INDEX IF NOT EXISTS profile_photos_moderation_idx
  ON public.profile_photos (moderation_status, is_main);

-- Index for user station status by date range
CREATE INDEX IF NOT EXISTS user_station_status_date_range_idx
  ON public.user_station_status (station_id, date_from, date_to);

-- Index for boosts by station and time
CREATE INDEX IF NOT EXISTS boosts_station_time_idx
  ON public.boosts (station_id, ends_at)
  WHERE ends_at > NOW();

-- ========================================
-- MIGRATION COMPLETE
-- ========================================

-- Add comment to track migration completion
COMMENT ON SCHEMA public IS 'CrewSnow schema with RLS enabled - Migration 20241116 completed';
