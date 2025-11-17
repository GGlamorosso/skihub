-- Migration complète : Créer toutes les tables manquantes selon le plan DEV 2
-- Cette migration crée les tables principales si elles n'existent pas déjà

-- ============================================
-- 1. TABLE USERS (si pas déjà créée complètement)
-- ============================================

-- Vérifier et ajouter colonnes manquantes à users
DO $$ 
BEGIN
  -- Ajouter colonnes si elles n'existent pas
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'onboarding_completed') THEN
    ALTER TABLE public.users ADD COLUMN onboarding_completed BOOLEAN NOT NULL DEFAULT false;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'is_active') THEN
    ALTER TABLE public.users ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'level') THEN
    ALTER TABLE public.users ADD COLUMN level TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'bio') THEN
    ALTER TABLE public.users ADD COLUMN bio TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'birth_date') THEN
    ALTER TABLE public.users ADD COLUMN birth_date DATE;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'last_active_at') THEN
    ALTER TABLE public.users ADD COLUMN last_active_at TIMESTAMPTZ;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'created_at') THEN
    ALTER TABLE public.users ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'updated_at') THEN
    ALTER TABLE public.users ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'is_premium') THEN
    ALTER TABLE public.users ADD COLUMN is_premium BOOLEAN NOT NULL DEFAULT false;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'premium_expires_at') THEN
    ALTER TABLE public.users ADD COLUMN premium_expires_at TIMESTAMPTZ;
  END IF;
END $$;

-- ============================================
-- 2. TABLE LIKES
-- ============================================

CREATE TABLE IF NOT EXISTS public.likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  liker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  liked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  direction TEXT NOT NULL CHECK (direction IN ('like', 'dislike', 'super_like')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(liker_id, liked_id)
);

CREATE INDEX IF NOT EXISTS idx_likes_liker_id ON public.likes(liker_id);
CREATE INDEX IF NOT EXISTS idx_likes_liked_id ON public.likes(liked_id);
CREATE INDEX IF NOT EXISTS idx_likes_composite ON public.likes(liker_id, liked_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON public.likes(created_at DESC);

-- ============================================
-- 3. TABLE MATCHES
-- ============================================

CREATE TABLE IF NOT EXISTS public.matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_message_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true,
  UNIQUE(user1_id, user2_id),
  CHECK (user1_id != user2_id)
);

CREATE INDEX IF NOT EXISTS idx_matches_user1_id ON public.matches(user1_id);
CREATE INDEX IF NOT EXISTS idx_matches_user2_id ON public.matches(user2_id);
CREATE INDEX IF NOT EXISTS idx_matches_composite ON public.matches(user1_id, user2_id);
CREATE INDEX IF NOT EXISTS idx_matches_last_message_at ON public.matches(last_message_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_matches_created_at ON public.matches(created_at DESC);

-- ============================================
-- 4. TABLE MESSAGES
-- ============================================

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'image', 'system')),
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_match_id ON public.messages(match_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_read_at ON public.messages(read_at) WHERE read_at IS NULL;

-- ============================================
-- 5. TABLE STATIONS
-- ============================================

CREATE TABLE IF NOT EXISTS public.stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  country_code TEXT NOT NULL,
  region TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(name, country_code)
);

CREATE INDEX IF NOT EXISTS idx_stations_country_code ON public.stations(country_code);
CREATE INDEX IF NOT EXISTS idx_stations_name ON public.stations(name);

-- ============================================
-- 6. TABLE USER_STATION_STATUS
-- ============================================

CREATE TABLE IF NOT EXISTS public.user_station_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  station_id UUID NOT NULL REFERENCES public.stations(id) ON DELETE CASCADE,
  date_from DATE NOT NULL,
  date_to DATE NOT NULL,
  radius_km INTEGER NOT NULL DEFAULT 25,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK (date_to >= date_from)
);

CREATE INDEX IF NOT EXISTS idx_user_station_status_user_id ON public.user_station_status(user_id);
CREATE INDEX IF NOT EXISTS idx_user_station_status_station_id ON public.user_station_status(station_id);
CREATE INDEX IF NOT EXISTS idx_user_station_status_dates ON public.user_station_status(date_from, date_to);
CREATE INDEX IF NOT EXISTS idx_user_station_status_active ON public.user_station_status(is_active) WHERE is_active = true;

-- ============================================
-- 7. TABLE RIDE_STATS
-- ============================================

CREATE TABLE IF NOT EXISTS public.ride_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id TEXT,
  station_id UUID REFERENCES public.stations(id),
  distance_meters DECIMAL(10, 2),
  duration_seconds INTEGER,
  max_speed_kmh DECIMAL(5, 2),
  elevation_gain_meters DECIMAL(8, 2),
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ride_stats_user_id ON public.ride_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_ride_stats_station_id ON public.ride_stats(station_id);
CREATE INDEX IF NOT EXISTS idx_ride_stats_started_at ON public.ride_stats(started_at DESC);

-- ============================================
-- 8. TABLE SUBSCRIPTIONS
-- ============================================

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_subscription_id TEXT UNIQUE,
  stripe_customer_id TEXT,
  stripe_price_id TEXT,
  status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'incomplete', 'incomplete_expired', 'past_due', 'trialing', 'unpaid')),
  current_period_start TIMESTAMPTZ NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  cancel_at_period_end BOOLEAN NOT NULL DEFAULT false,
  canceled_at TIMESTAMPTZ,
  amount_cents INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'EUR',
  interval TEXT NOT NULL CHECK (interval IN ('month', 'year')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_subscription_id ON public.subscriptions(stripe_subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);

-- ============================================
-- 9. TABLE PROFILE_PHOTOS
-- ============================================

CREATE TABLE IF NOT EXISTS public.profile_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  is_main BOOLEAN NOT NULL DEFAULT false,
  moderation_status TEXT NOT NULL DEFAULT 'pending' CHECK (moderation_status IN ('pending', 'approved', 'rejected')),
  moderation_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profile_photos_user_id ON public.profile_photos(user_id);
CREATE INDEX IF NOT EXISTS idx_profile_photos_moderation_status ON public.profile_photos(moderation_status);
CREATE INDEX IF NOT EXISTS idx_profile_photos_is_main ON public.profile_photos(is_main) WHERE is_main = true;

-- ============================================
-- 10. TABLE FRIENDS (pour mode crew)
-- ============================================

CREATE TABLE IF NOT EXISTS public.friends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user1_id, user2_id),
  CHECK (user1_id != user2_id)
);

CREATE INDEX IF NOT EXISTS idx_friends_user1_id ON public.friends(user1_id);
CREATE INDEX IF NOT EXISTS idx_friends_user2_id ON public.friends(user2_id);
CREATE INDEX IF NOT EXISTS idx_friends_status ON public.friends(status);

-- ============================================
-- 11. TABLE BOOSTS
-- ============================================

CREATE TABLE IF NOT EXISTS public.boosts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  station_id UUID NOT NULL REFERENCES public.stations(id) ON DELETE CASCADE,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  boost_multiplier DECIMAL(3, 2) NOT NULL DEFAULT 2.0,
  amount_paid_cents INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'EUR',
  stripe_payment_intent_id TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (ends_at > starts_at)
);

CREATE INDEX IF NOT EXISTS idx_boosts_user_id ON public.boosts(user_id);
CREATE INDEX IF NOT EXISTS idx_boosts_station_id ON public.boosts(station_id);
CREATE INDEX IF NOT EXISTS idx_boosts_active ON public.boosts(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_boosts_dates ON public.boosts(starts_at, ends_at);

-- ============================================
-- 12. TABLE GROUPS (équipes de 2 à 4 riders)
-- ============================================

CREATE TABLE IF NOT EXISTS public.groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  station_id UUID REFERENCES public.stations(id),
  max_members INTEGER NOT NULL DEFAULT 4 CHECK (max_members BETWEEN 2 AND 4),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('creator', 'admin', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_groups_creator_id ON public.groups(creator_id);
CREATE INDEX IF NOT EXISTS idx_groups_station_id ON public.groups(station_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON public.group_members(user_id);

-- ============================================
-- 13. TABLE USER_CONSENTS (déjà créée, mais on s'assure qu'elle existe)
-- ============================================

CREATE TABLE IF NOT EXISTS public.user_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  purpose TEXT NOT NULL,
  granted BOOLEAN NOT NULL DEFAULT false,
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, purpose)
);

CREATE INDEX IF NOT EXISTS idx_user_consents_user_id ON public.user_consents(user_id);
CREATE INDEX IF NOT EXISTS idx_user_consents_purpose ON public.user_consents(purpose);

-- ============================================
-- 14. FONCTION get_total_unread_count (si pas déjà créée)
-- ============================================

CREATE OR REPLACE FUNCTION public.get_total_unread_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO v_count
  FROM public.messages m
  INNER JOIN public.matches mt ON m.match_id = mt.id
  WHERE (
    (mt.user1_id = p_user_id AND m.sender_id != p_user_id) OR
    (mt.user2_id = p_user_id AND m.sender_id != p_user_id)
  )
  AND m.read_at IS NULL;
  
  RETURN COALESCE(v_count, 0);
END;
$$;

-- ============================================
-- 15. TRIGGER pour last_message_at (si pas déjà créé)
-- ============================================

CREATE OR REPLACE FUNCTION public.update_match_last_message_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.matches
  SET last_message_at = NEW.created_at
  WHERE id = NEW.match_id;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_match_last_message_at ON public.messages;
CREATE TRIGGER trigger_update_match_last_message_at
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.update_match_last_message_at();

-- ============================================
-- 16. RLS POLICIES - USERS
-- ============================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own profile" ON public.users;
CREATE POLICY "Users can read their own profile"
ON public.users FOR SELECT
TO authenticated
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
CREATE POLICY "Users can update their own profile"
ON public.users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
CREATE POLICY "Users can insert their own profile"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- ============================================
-- 17. RLS POLICIES - LIKES
-- ============================================

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own likes" ON public.likes;
CREATE POLICY "Users can read their own likes"
ON public.likes FOR SELECT
TO authenticated
USING (auth.uid() = liker_id OR auth.uid() = liked_id);

DROP POLICY IF EXISTS "Users can create their own likes" ON public.likes;
CREATE POLICY "Users can create their own likes"
ON public.likes FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = liker_id);

-- ============================================
-- 18. RLS POLICIES - MATCHES
-- ============================================

ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own matches" ON public.matches;
CREATE POLICY "Users can read their own matches"
ON public.matches FOR SELECT
TO authenticated
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- ============================================
-- 19. RLS POLICIES - MESSAGES
-- ============================================

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read messages in their matches" ON public.messages;
CREATE POLICY "Users can read messages in their matches"
ON public.messages FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.matches m
    WHERE m.id = messages.match_id
    AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
  )
);

DROP POLICY IF EXISTS "Users can send messages in their matches" ON public.messages;
CREATE POLICY "Users can send messages in their matches"
ON public.messages FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = sender_id
  AND EXISTS (
    SELECT 1 FROM public.matches m
    WHERE m.id = messages.match_id
    AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
  )
);

-- ============================================
-- 20. RLS POLICIES - PROFILE_PHOTOS
-- ============================================

ALTER TABLE public.profile_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read approved photos" ON public.profile_photos;
CREATE POLICY "Anyone can read approved photos"
ON public.profile_photos FOR SELECT
TO authenticated
USING (moderation_status = 'approved' OR user_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own photos" ON public.profile_photos;
CREATE POLICY "Users can manage their own photos"
ON public.profile_photos FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================
-- 21. RLS POLICIES - USER_STATION_STATUS
-- ============================================

ALTER TABLE public.user_station_status ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own station status" ON public.user_station_status;
CREATE POLICY "Users can manage their own station status"
ON public.user_station_status FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================
-- 22. RLS POLICIES - RIDE_STATS
-- ============================================

ALTER TABLE public.ride_stats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own ride stats" ON public.ride_stats;
CREATE POLICY "Users can manage their own ride stats"
ON public.ride_stats FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================
-- 23. RLS POLICIES - SUBSCRIPTIONS
-- ============================================

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can read their own subscriptions"
ON public.subscriptions FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- ============================================
-- 24. RLS POLICIES - USER_CONSENTS
-- ============================================

ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own consents" ON public.user_consents;
CREATE POLICY "Users can read their own consents"
ON public.user_consents FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own consents" ON public.user_consents;
CREATE POLICY "Users can insert their own consents"
ON public.user_consents FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own consents" ON public.user_consents;
CREATE POLICY "Users can update their own consents"
ON public.user_consents FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 25. RLS POLICIES - BOOSTS
-- ============================================

ALTER TABLE public.boosts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own boosts" ON public.boosts;
CREATE POLICY "Users can manage their own boosts"
ON public.boosts FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================
-- 26. RLS POLICIES - GROUPS
-- ============================================

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read groups they belong to" ON public.groups;
CREATE POLICY "Users can read groups they belong to"
ON public.groups FOR SELECT
TO authenticated
USING (
  creator_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = groups.id
    AND gm.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can create groups" ON public.groups;
CREATE POLICY "Users can create groups"
ON public.groups FOR INSERT
TO authenticated
WITH CHECK (creator_id = auth.uid());

-- ============================================
-- 27. RLS POLICIES - GROUP_MEMBERS
-- ============================================

ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read members of their groups" ON public.group_members;
CREATE POLICY "Users can read members of their groups"
ON public.group_members FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.group_members gm2
    WHERE gm2.group_id = group_members.group_id
    AND gm2.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Users can join groups" ON public.group_members;
CREATE POLICY "Users can join groups"
ON public.group_members FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- ============================================
-- 28. RLS POLICIES - FRIENDS
-- ============================================

ALTER TABLE public.friends ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own friendships" ON public.friends;
CREATE POLICY "Users can read their own friendships"
ON public.friends FOR SELECT
TO authenticated
USING (user1_id = auth.uid() OR user2_id = auth.uid());

DROP POLICY IF EXISTS "Users can create friendships" ON public.friends;
CREATE POLICY "Users can create friendships"
ON public.friends FOR INSERT
TO authenticated
WITH CHECK (user1_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their friendships" ON public.friends;
CREATE POLICY "Users can update their friendships"
ON public.friends FOR UPDATE
TO authenticated
USING (user1_id = auth.uid() OR user2_id = auth.uid())
WITH CHECK (user1_id = auth.uid() OR user2_id = auth.uid());

-- ============================================
-- 29. RLS POLICIES - STATIONS (lecture publique)
-- ============================================

ALTER TABLE public.stations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read stations" ON public.stations;
CREATE POLICY "Anyone can read stations"
ON public.stations FOR SELECT
TO authenticated
USING (true);

-- ============================================
-- 30. COMMENTS
-- ============================================

COMMENT ON TABLE public.likes IS 'Stores user likes/dislikes for matching algorithm';
COMMENT ON TABLE public.matches IS 'Stores mutual matches between users';
COMMENT ON TABLE public.messages IS 'Stores chat messages between matched users';
COMMENT ON TABLE public.stations IS 'Reference table for ski resorts';
COMMENT ON TABLE public.user_station_status IS 'Current station and dates for each user';
COMMENT ON TABLE public.ride_stats IS 'GPS tracking statistics for ski sessions';
COMMENT ON TABLE public.subscriptions IS 'Stripe subscription data';
COMMENT ON TABLE public.profile_photos IS 'User profile photos with moderation status';
COMMENT ON TABLE public.friends IS 'Friendships for crew mode';
COMMENT ON TABLE public.boosts IS 'Station boost purchases';
COMMENT ON TABLE public.groups IS 'Groups of 2-4 riders for crew mode';
COMMENT ON FUNCTION public.get_total_unread_count(UUID) IS 'Returns total unread message count for a user';

