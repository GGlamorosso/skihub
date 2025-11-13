-- ============================================================================
-- CREWSNOW REALTIME CONFIGURATION
-- ============================================================================
-- Description: Configuration pour Supabase Realtime sur les tables critiques
-- ============================================================================

-- Enable realtime on critical tables for instant updates
ALTER PUBLICATION supabase_realtime ADD TABLE matches;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE likes;
ALTER PUBLICATION supabase_realtime ADD TABLE user_station_status;

-- Create indexes for realtime performance
CREATE INDEX IF NOT EXISTS idx_matches_realtime ON matches(created_at DESC) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_messages_realtime ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_likes_realtime ON likes(created_at DESC);

-- ============================================================================
-- RLS POLICIES FOR REALTIME (CRITICAL FOR SECURITY)
-- ============================================================================

-- Ensure only match participants can subscribe to match updates
CREATE POLICY "matches_realtime_policy" ON matches
FOR SELECT TO authenticated
USING (
    user1_id = auth.uid() OR user2_id = auth.uid()
);

-- Messages can only be seen by match participants  
CREATE POLICY "messages_realtime_policy" ON messages
FOR ALL TO authenticated  
USING (
    EXISTS (
        SELECT 1 FROM matches m
        WHERE m.id = match_id 
        AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
    )
);

-- Users can see likes they made or received
CREATE POLICY "likes_realtime_policy" ON likes
FOR SELECT TO authenticated
USING (
    liker_id = auth.uid() OR liked_id = auth.uid()
);

-- Users can see their own station status updates
CREATE POLICY "user_station_status_realtime_policy" ON user_station_status
FOR ALL TO authenticated
USING (
    user_id = auth.uid()
);

DO $$
BEGIN
    RAISE NOTICE '⚡ Realtime configuration completed!';
    RAISE NOTICE '';
    RAISE NOTICE 'Enabled realtime on:';
    RAISE NOTICE '  - matches (for new matches notifications)'; 
    RAISE NOTICE '  - messages (for chat updates)';
    RAISE NOTICE '  - likes (for like notifications)';
    RAISE NOTICE '  - user_station_status (for location updates)';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. In Supabase Dashboard → Database → Replication';
    RAISE NOTICE '2. Verify these tables are listed in supabase_realtime publication';
    RAISE NOTICE '3. Test realtime subscriptions in your app';
    RAISE NOTICE '';
    RAISE NOTICE 'Example client code:';
    RAISE NOTICE 'supabase.channel("matches").on("postgres_changes", {';
    RAISE NOTICE '  event: "INSERT", schema: "public", table: "matches"';  
    RAISE NOTICE '}, handleNewMatch).subscribe()';
END $$;
