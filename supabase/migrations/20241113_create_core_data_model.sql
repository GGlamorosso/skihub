-- CrewSnow Core Data Model Migration
-- Date: 2024-11-13
-- Description: Complete data model with performance optimizations and security

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================================
-- ENUMS
-- ============================================================================

-- User skill levels
CREATE TYPE user_level AS ENUM (
    'beginner',
    'intermediate', 
    'advanced',
    'expert'
);

-- Photo moderation status
CREATE TYPE moderation_status AS ENUM (
    'pending',
    'approved',
    'rejected'
);

-- Video verification status
CREATE TYPE verified_video_status AS ENUM (
    'not_submitted',
    'pending',
    'approved',
    'rejected'
);

-- Subscription status (Stripe)
CREATE TYPE subscription_status AS ENUM (
    'active',
    'canceled',
    'incomplete',
    'incomplete_expired',
    'past_due',
    'trialing',
    'unpaid'
);

-- Ride styles
CREATE TYPE ride_style AS ENUM (
    'alpine',
    'freestyle',
    'freeride',
    'touring',
    'racing',
    'moguls',
    'powder',
    'park'
);

-- Languages (subset for array usage)
CREATE TYPE language_code AS ENUM (
    'en',
    'fr',
    'de',
    'it',
    'es',
    'pt',
    'nl',
    'sv',
    'no',
    'da',
    'ru',
    'ja',
    'ko',
    'zh'
);

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Users table - Central profile and settings
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(30) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    bio TEXT CHECK (length(bio) <= 500),
    birth_date DATE,
    
    -- Ski/snowboard preferences
    level user_level NOT NULL DEFAULT 'beginner',
    ride_styles ride_style[] DEFAULT '{}',
    languages language_code[] DEFAULT '{}',
    
    -- Premium features
    is_premium BOOLEAN NOT NULL DEFAULT false,
    premium_expires_at TIMESTAMPTZ,
    
    -- Video verification
    verified_video_status verified_video_status NOT NULL DEFAULT 'not_submitted',
    verified_video_url TEXT,
    verified_at TIMESTAMPTZ,
    
    -- Stripe integration
    stripe_customer_id VARCHAR(255),
    
    -- Profile visibility
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_banned BOOLEAN NOT NULL DEFAULT false,
    banned_reason TEXT,
    banned_until TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT users_birth_date_realistic CHECK (birth_date > '1900-01-01' AND birth_date <= CURRENT_DATE - INTERVAL '13 years'),
    CONSTRAINT users_username_format CHECK (username ~ '^[a-zA-Z0-9_]{3,30}$'),
    CONSTRAINT users_premium_logic CHECK (
        (is_premium = false) OR 
        (is_premium = true AND premium_expires_at IS NOT NULL)
    )
);

-- Stations table - Reference data for ski stations
CREATE TABLE stations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    country_code CHAR(2) NOT NULL,
    region VARCHAR(255),
    
    -- Geographic data
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    elevation_m INTEGER,
    geom GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)) STORED,
    
    -- Station info
    official_website TEXT,
    season_start_month INTEGER CHECK (season_start_month BETWEEN 1 AND 12),
    season_end_month INTEGER CHECK (season_end_month BETWEEN 1 AND 12),
    
    -- Metadata
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT stations_name_country_unique UNIQUE (name, country_code),
    CONSTRAINT stations_coordinates_valid CHECK (
        latitude BETWEEN -90 AND 90 AND 
        longitude BETWEEN -180 AND 180
    )
);

-- Profile photos table - Photo management and moderation
CREATE TABLE profile_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Storage info
    storage_path TEXT NOT NULL,
    file_size_bytes INTEGER NOT NULL,
    mime_type VARCHAR(50) NOT NULL,
    
    -- Photo status
    is_main BOOLEAN NOT NULL DEFAULT false,
    display_order INTEGER NOT NULL DEFAULT 0,
    
    -- Moderation
    moderation_status moderation_status NOT NULL DEFAULT 'pending',
    moderation_reason TEXT,
    moderated_at TIMESTAMPTZ,
    moderated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT profile_photos_mime_type_valid CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp')),
    CONSTRAINT profile_photos_file_size_reasonable CHECK (file_size_bytes > 0 AND file_size_bytes <= 10485760), -- 10MB max
    CONSTRAINT profile_photos_display_order_positive CHECK (display_order >= 0)
);

-- ============================================================================
-- USER LOCATION AND PRESENCE
-- ============================================================================

-- User station status - Where users are skiing and when
CREATE TABLE user_station_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    station_id UUID NOT NULL REFERENCES stations(id) ON DELETE CASCADE,
    
    -- Date range
    date_from DATE NOT NULL,
    date_to DATE NOT NULL,
    
    -- Proximity settings
    radius_km INTEGER NOT NULL DEFAULT 25,
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT user_station_status_date_range_valid CHECK (date_to >= date_from),
    CONSTRAINT user_station_status_radius_reasonable CHECK (radius_km BETWEEN 0 AND 100),
    CONSTRAINT user_station_status_date_not_too_far_past CHECK (date_from >= CURRENT_DATE - INTERVAL '7 days'),
    CONSTRAINT user_station_status_date_not_too_far_future CHECK (date_from <= CURRENT_DATE + INTERVAL '365 days')
);

-- ============================================================================
-- MATCHING SYSTEM
-- ============================================================================

-- Likes table - Swipe actions log
CREATE TABLE likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    liker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    liked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT likes_no_self_like CHECK (liker_id != liked_id),
    CONSTRAINT likes_unique_pair UNIQUE (liker_id, liked_id)
);

-- Matches table - Mutual likes create matches
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Match metadata
    matched_at_station_id UUID REFERENCES stations(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints - ensure ordered IDs and unique pairs
    CONSTRAINT matches_ordered_users CHECK (user1_id < user2_id),
    CONSTRAINT matches_unique_pair UNIQUE (user1_id, user2_id),
    CONSTRAINT matches_no_self_match CHECK (user1_id != user2_id)
);

-- ============================================================================
-- MESSAGING SYSTEM
-- ============================================================================

-- Messages table - Chat functionality
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Message content
    content TEXT NOT NULL,
    message_type VARCHAR(20) NOT NULL DEFAULT 'text',
    
    -- Status
    is_read BOOLEAN NOT NULL DEFAULT false,
    read_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT messages_content_length CHECK (length(content) > 0 AND length(content) <= 2000),
    CONSTRAINT messages_type_valid CHECK (message_type IN ('text', 'image', 'location', 'system'))
);

-- ============================================================================
-- SOCIAL FEATURES
-- ============================================================================

-- Groups table - Crew functionality
CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT CHECK (length(description) <= 500),
    
    -- Group settings
    max_members INTEGER NOT NULL DEFAULT 4,
    is_private BOOLEAN NOT NULL DEFAULT false,
    invite_code VARCHAR(20) UNIQUE,
    
    -- Creator
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT groups_max_members_reasonable CHECK (max_members BETWEEN 2 AND 8),
    CONSTRAINT groups_name_not_empty CHECK (length(trim(name)) > 0)
);

-- Group members table - Membership in groups
CREATE TABLE group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Role
    role VARCHAR(20) NOT NULL DEFAULT 'member',
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Timestamps
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    left_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT group_members_unique_active_membership UNIQUE (group_id, user_id),
    CONSTRAINT group_members_role_valid CHECK (role IN ('owner', 'admin', 'member'))
);

-- Friends table - Social graph (optional for v1)
CREATE TABLE friends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Friendship status
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT friends_no_self_friendship CHECK (requester_id != addressee_id),
    CONSTRAINT friends_unique_pair UNIQUE (requester_id, addressee_id),
    CONSTRAINT friends_status_valid CHECK (status IN ('pending', 'accepted', 'blocked'))
);

-- ============================================================================
-- TRACKING AND STATS
-- ============================================================================

-- Ride stats daily - Activity tracking
CREATE TABLE ride_stats_daily (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Date (one record per user per day)
    date DATE NOT NULL,
    station_id UUID REFERENCES stations(id) ON DELETE SET NULL,
    
    -- Stats
    distance_km DECIMAL(8, 2) NOT NULL DEFAULT 0,
    vmax_kmh DECIMAL(5, 2) NOT NULL DEFAULT 0,
    elevation_gain_m INTEGER NOT NULL DEFAULT 0,
    moving_time_min INTEGER NOT NULL DEFAULT 0,
    runs_count INTEGER NOT NULL DEFAULT 0,
    
    -- Source tracking
    data_source VARCHAR(50) NOT NULL DEFAULT 'manual',
    external_activity_id TEXT, -- For Strava/GPS imports
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT ride_stats_daily_unique_user_date UNIQUE (user_id, date),
    CONSTRAINT ride_stats_daily_stats_positive CHECK (
        distance_km >= 0 AND 
        vmax_kmh >= 0 AND 
        elevation_gain_m >= 0 AND 
        moving_time_min >= 0 AND
        runs_count >= 0
    ),
    CONSTRAINT ride_stats_daily_realistic_values CHECK (
        distance_km <= 200 AND 
        vmax_kmh <= 250 AND 
        elevation_gain_m <= 10000 AND
        moving_time_min <= 1440 -- 24 hours max
    ),
    CONSTRAINT ride_stats_daily_data_source_valid CHECK (
        data_source IN ('manual', 'strava', 'gps_track', 'apple_health', 'google_fit')
    )
);

-- ============================================================================
-- MONETIZATION
-- ============================================================================

-- Boosts table - Profile promotion in stations
CREATE TABLE boosts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    station_id UUID NOT NULL REFERENCES stations(id) ON DELETE CASCADE,
    
    -- Boost period
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    
    -- Boost settings
    boost_multiplier DECIMAL(3, 1) NOT NULL DEFAULT 2.0,
    
    -- Payment
    amount_paid_cents INTEGER NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'EUR',
    stripe_payment_intent_id VARCHAR(255),
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT boosts_time_range_valid CHECK (ends_at > starts_at),
    CONSTRAINT boosts_boost_multiplier_reasonable CHECK (boost_multiplier BETWEEN 1.1 AND 10.0),
    CONSTRAINT boosts_amount_positive CHECK (amount_paid_cents > 0),
    CONSTRAINT boosts_currency_valid CHECK (currency IN ('EUR', 'USD', 'GBP', 'CHF', 'CAD'))
);

-- Subscriptions table - Premium subscriptions (Stripe)
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Stripe data
    stripe_subscription_id VARCHAR(255) NOT NULL UNIQUE,
    stripe_customer_id VARCHAR(255) NOT NULL,
    stripe_price_id VARCHAR(255) NOT NULL,
    
    -- Subscription details
    status subscription_status NOT NULL,
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    cancel_at_period_end BOOLEAN NOT NULL DEFAULT false,
    canceled_at TIMESTAMPTZ,
    
    -- Pricing
    amount_cents INTEGER NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'EUR',
    interval VARCHAR(20) NOT NULL, -- month, year
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT subscriptions_period_valid CHECK (current_period_end > current_period_start),
    CONSTRAINT subscriptions_amount_positive CHECK (amount_cents > 0),
    CONSTRAINT subscriptions_currency_valid CHECK (currency IN ('EUR', 'USD', 'GBP', 'CHF', 'CAD')),
    CONSTRAINT subscriptions_interval_valid CHECK (interval IN ('month', 'year'))
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Users indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_is_premium ON users(is_premium);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_last_active ON users(last_active_at DESC);
CREATE INDEX idx_users_stripe_customer ON users(stripe_customer_id) WHERE stripe_customer_id IS NOT NULL;

-- Array indexes for filtering
CREATE INDEX idx_users_ride_styles ON users USING GIN(ride_styles);
CREATE INDEX idx_users_languages ON users USING GIN(languages);

-- Stations indexes
CREATE INDEX idx_stations_geom ON stations USING GIST(geom);
CREATE INDEX idx_stations_country ON stations(country_code);
CREATE INDEX idx_stations_name_search ON stations USING GIN(to_tsvector('english', name));

-- User station status indexes
CREATE INDEX idx_user_station_status_user ON user_station_status(user_id);
CREATE INDEX idx_user_station_status_station_dates ON user_station_status(station_id, date_from, date_to);
CREATE INDEX idx_user_station_status_active_dates ON user_station_status(date_from, date_to) WHERE is_active = true;

-- Profile photos indexes
CREATE INDEX idx_profile_photos_user ON profile_photos(user_id);
CREATE INDEX idx_profile_photos_main ON profile_photos(user_id, is_main) WHERE is_main = true;
CREATE INDEX idx_profile_photos_moderation ON profile_photos(moderation_status);

-- Likes indexes
CREATE INDEX idx_likes_liker ON likes(liker_id);
CREATE INDEX idx_likes_liked ON likes(liked_id);
CREATE INDEX idx_likes_created_at ON likes(created_at DESC);

-- Matches indexes  
CREATE INDEX idx_matches_user1 ON matches(user1_id);
CREATE INDEX idx_matches_user2 ON matches(user2_id);
CREATE INDEX idx_matches_active ON matches(user1_id, user2_id) WHERE is_active = true;
CREATE INDEX idx_matches_created_at ON matches(created_at DESC);

-- Messages indexes
CREATE INDEX idx_messages_match_time ON messages(match_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_unread ON messages(match_id) WHERE is_read = false;

-- Groups and members indexes
CREATE INDEX idx_group_members_group ON group_members(group_id);
CREATE INDEX idx_group_members_user ON group_members(user_id);
CREATE INDEX idx_group_members_active ON group_members(group_id, user_id) WHERE is_active = true;

-- Friends indexes
CREATE INDEX idx_friends_requester ON friends(requester_id);
CREATE INDEX idx_friends_addressee ON friends(addressee_id);
CREATE INDEX idx_friends_status ON friends(status);

-- Ride stats indexes
CREATE INDEX idx_ride_stats_user_date ON ride_stats_daily(user_id, date DESC);
CREATE INDEX idx_ride_stats_station ON ride_stats_daily(station_id, date DESC) WHERE station_id IS NOT NULL;
CREATE INDEX idx_ride_stats_external_id ON ride_stats_daily(external_activity_id) WHERE external_activity_id IS NOT NULL;

-- Boosts indexes
CREATE INDEX idx_boosts_user ON boosts(user_id);
CREATE INDEX idx_boosts_station_active ON boosts(station_id, ends_at) WHERE is_active = true;
CREATE INDEX idx_boosts_active_period ON boosts(starts_at, ends_at) WHERE is_active = true;

-- Subscriptions indexes
CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_stripe_id ON subscriptions(stripe_subscription_id);
CREATE INDEX idx_subscriptions_customer ON subscriptions(stripe_customer_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);

-- ============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER trigger_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trigger_stations_updated_at BEFORE UPDATE ON stations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trigger_profile_photos_updated_at BEFORE UPDATE ON profile_photos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trigger_user_station_status_updated_at BEFORE UPDATE ON user_station_status FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trigger_groups_updated_at BEFORE UPDATE ON groups FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trigger_ride_stats_daily_updated_at BEFORE UPDATE ON ride_stats_daily FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trigger_subscriptions_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- BASIC ROW LEVEL SECURITY (RLS) SETUP
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_station_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_stats_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE boosts ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Basic policies (users can access their own data)
CREATE POLICY users_own_data ON users FOR ALL USING (auth.uid() = id);
CREATE POLICY profile_photos_own_data ON profile_photos FOR ALL USING (auth.uid() = user_id);
CREATE POLICY user_station_status_own_data ON user_station_status FOR ALL USING (auth.uid() = user_id);
CREATE POLICY ride_stats_own_data ON ride_stats_daily FOR ALL USING (auth.uid() = user_id);
CREATE POLICY subscriptions_own_data ON subscriptions FOR ALL USING (auth.uid() = user_id);

-- Stations are public for reading
CREATE POLICY stations_public_read ON stations FOR SELECT TO authenticated USING (true);

-- Messages can be read by match participants
CREATE POLICY messages_match_participants ON messages FOR ALL USING (
    EXISTS (
        SELECT 1 FROM matches m 
        WHERE m.id = match_id 
        AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
    )
);

-- Matches can be seen by participants
CREATE POLICY matches_participants ON matches FOR ALL USING (
    user1_id = auth.uid() OR user2_id = auth.uid()
);

-- Likes visibility (users can see likes they made and received)
CREATE POLICY likes_own_actions ON likes FOR ALL USING (
    liker_id = auth.uid() OR liked_id = auth.uid()
);

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE users IS 'Central user profiles with ski preferences and premium status';
COMMENT ON TABLE stations IS 'Reference data for ski stations with PostGIS geospatial support';
COMMENT ON TABLE profile_photos IS 'User photos with moderation workflow';
COMMENT ON TABLE user_station_status IS 'Tracks user presence at stations for matching';
COMMENT ON TABLE likes IS 'Swipe actions log for match detection';
COMMENT ON TABLE matches IS 'Mutual likes create matches for messaging';
COMMENT ON TABLE messages IS 'Chat messages between matched users';
COMMENT ON TABLE groups IS 'Crew functionality for group activities';
COMMENT ON TABLE group_members IS 'Group membership tracking';
COMMENT ON TABLE friends IS 'Social graph for non-romantic connections';
COMMENT ON TABLE ride_stats_daily IS 'Daily activity tracking for gamification';
COMMENT ON TABLE boosts IS 'Profile promotion in specific stations';
COMMENT ON TABLE subscriptions IS 'Premium subscription management via Stripe';

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'CrewSnow data model created successfully!';
    RAISE NOTICE 'Tables created: % tables with full constraints and indexes', 
        (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE');
    RAISE NOTICE 'Next steps: Run seed data, configure additional RLS policies, set up real-time subscriptions';
END $$;
