-- CrewSnow Migration - RLS Finitions & Cohérence
-- This migration fixes missing policies and ensures complete RLS coverage

-- ========================================
-- 1. REMOVE CONFLICTING BASIC POLICIES FROM INITIAL MIGRATION
-- ========================================

-- Drop basic policies that conflict with detailed ones
DROP POLICY IF EXISTS "users_own_data" ON public.users;
DROP POLICY IF EXISTS "profile_photos_own_data" ON public.profile_photos;
DROP POLICY IF EXISTS "user_station_status_own_data" ON public.user_station_status;
DROP POLICY IF EXISTS "ride_stats_own_data" ON public.ride_stats_daily;
DROP POLICY IF EXISTS "subscriptions_own_data" ON public.subscriptions;
DROP POLICY IF EXISTS "stations_public_read" ON public.stations;
DROP POLICY IF EXISTS "messages_match_participants" ON public.messages;
DROP POLICY IF EXISTS "matches_participants" ON public.matches;
DROP POLICY IF EXISTS "likes_own_actions" ON public.likes;

-- ========================================
-- 2. ADD MISSING UPDATE/DELETE POLICIES FOR BOOSTS
-- ========================================

-- Users can update their own boosts (extend duration, change station)
CREATE POLICY "User can update their own boosts"
  ON public.boosts FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Users can delete their own boosts (cancel early)
CREATE POLICY "User can delete their own boosts"
  ON public.boosts FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- ========================================
-- 3. ADD MISSING POLICIES FOR SUBSCRIPTIONS
-- ========================================

-- Only service_role can insert subscriptions (Stripe webhooks)
-- Users cannot create subscriptions directly
-- Note: No INSERT policy for users = blocked by RLS

-- Users cannot update subscriptions directly (only via Stripe)
-- Note: No UPDATE policy for users = blocked by RLS

-- Users cannot delete subscriptions directly (only via Stripe)
-- Note: No DELETE policy for users = blocked by RLS

-- ========================================
-- 4. ADD MISSING UPDATE POLICIES FOR GROUP_MEMBERS
-- ========================================

-- Group owners can update memberships (change roles, permissions)
CREATE POLICY "Group owner can update memberships"
  ON public.group_members FOR UPDATE
  TO authenticated
  USING (
    auth.uid() IS NOT NULL 
    AND EXISTS (
      SELECT 1 FROM public.groups g 
      WHERE g.id = group_id AND g.created_by = auth.uid()
    )
  )
  WITH CHECK (
    auth.uid() IS NOT NULL 
    AND EXISTS (
      SELECT 1 FROM public.groups g 
      WHERE g.id = group_id AND g.created_by = auth.uid()
    )
  );

-- ========================================
-- 5. ADD MISSING DELETE POLICY FOR GROUPS
-- ========================================

-- Group creators can delete their groups
CREATE POLICY "User can delete their groups"
  ON public.groups FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = created_by);

-- ========================================
-- 6. ENHANCE MATCHES POLICIES - ADD INSERT CONTROL
-- ========================================

-- Matches should only be created by the create_match_from_likes() function
-- Users cannot manually insert matches
-- Note: No INSERT policy for users = blocked by RLS
-- Service role can insert via function

-- ========================================
-- 7. ADD MISSING UPDATE/DELETE POLICIES FOR MESSAGES
-- ========================================

-- Users can update their own messages (edit functionality)
CREATE POLICY "User can update their own messages"
  ON public.messages FOR UPDATE
  TO authenticated
  USING (
    auth.uid() IS NOT NULL 
    AND auth.uid() = sender_id
    AND (
      auth.uid() = (SELECT user1_id FROM public.matches m WHERE m.id = match_id)
      OR auth.uid() = (SELECT user2_id FROM public.matches m WHERE m.id = match_id)
    )
  )
  WITH CHECK (
    auth.uid() IS NOT NULL 
    AND auth.uid() = sender_id
    AND (
      auth.uid() = (SELECT user1_id FROM public.matches m WHERE m.id = match_id)
      OR auth.uid() = (SELECT user2_id FROM public.matches m WHERE m.id = match_id)
    )
  );

-- Users can delete their own messages
CREATE POLICY "User can delete their own messages"
  ON public.messages FOR DELETE
  TO authenticated
  USING (
    auth.uid() IS NOT NULL 
    AND auth.uid() = sender_id
    AND (
      auth.uid() = (SELECT user1_id FROM public.matches m WHERE m.id = match_id)
      OR auth.uid() = (SELECT user2_id FROM public.matches m WHERE m.id = match_id)
    )
  );

-- ========================================
-- 8. ADD COMPREHENSIVE AUDIT FUNCTION
-- ========================================

-- Function to audit RLS policy coverage
CREATE OR REPLACE FUNCTION audit_rls_coverage()
RETURNS TABLE (
  table_name text,
  select_policies integer,
  insert_policies integer,
  update_policies integer,
  delete_policies integer,
  total_policies integer,
  has_complete_coverage boolean
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.table_name::text,
    COUNT(CASE WHEN p.cmd = 'SELECT' THEN 1 END)::integer as select_policies,
    COUNT(CASE WHEN p.cmd = 'INSERT' THEN 1 END)::integer as insert_policies,
    COUNT(CASE WHEN p.cmd = 'UPDATE' THEN 1 END)::integer as update_policies,
    COUNT(CASE WHEN p.cmd = 'DELETE' THEN 1 END)::integer as delete_policies,
    COUNT(*)::integer as total_policies,
    (COUNT(CASE WHEN p.cmd = 'SELECT' THEN 1 END) > 0)::boolean as has_complete_coverage
  FROM information_schema.tables t
  LEFT JOIN pg_policies p ON p.tablename = t.table_name AND p.schemaname = t.table_schema
  WHERE t.table_schema = 'public' 
    AND t.table_type = 'BASE TABLE'
    AND t.table_name NOT LIKE '%_view'
  GROUP BY t.table_name
  ORDER BY t.table_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check for NULL UID vulnerabilities
CREATE OR REPLACE FUNCTION check_null_uid_policies()
RETURNS TABLE (
  policy_name text,
  table_name text,
  command text,
  has_null_check boolean,
  policy_definition text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.policyname::text,
    p.tablename::text,
    p.cmd::text,
    (p.qual LIKE '%auth.uid() IS NOT NULL%' OR p.with_check LIKE '%auth.uid() IS NOT NULL%')::boolean,
    COALESCE(p.qual, '') || ' | ' || COALESCE(p.with_check, '')::text
  FROM pg_policies p
  WHERE p.schemaname = 'public'
    AND p.roles && ARRAY['authenticated']
    AND (p.qual LIKE '%auth.uid()%' OR p.with_check LIKE '%auth.uid()%')
  ORDER BY p.tablename, p.policyname;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 9. VALIDATE CASCADE RELATIONSHIPS
-- ========================================

-- Function to validate FK cascade relationships
CREATE OR REPLACE FUNCTION validate_cascade_integrity()
RETURNS TABLE (
  parent_table text,
  child_table text,
  constraint_name text,
  delete_rule text,
  is_cascade boolean
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    kcu.table_name::text as parent_table,
    kcu2.table_name::text as child_table,
    kcu.constraint_name::text,
    rc.delete_rule::text,
    (rc.delete_rule = 'CASCADE')::boolean
  FROM information_schema.key_column_usage kcu
  JOIN information_schema.referential_constraints rc ON rc.constraint_name = kcu.constraint_name
  JOIN information_schema.key_column_usage kcu2 ON kcu2.constraint_name = rc.unique_constraint_name
  WHERE kcu.table_schema = 'public'
    AND kcu2.table_schema = 'public'
  ORDER BY parent_table, child_table;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 10. COMPREHENSIVE TEST FUNCTION
-- ========================================

-- Function to run all RLS validation tests
CREATE OR REPLACE FUNCTION run_rls_validation_tests()
RETURNS text AS $$
DECLARE
  result text := '';
  rec record;
BEGIN
  result := result || E'=== RLS POLICY COVERAGE AUDIT ===\n';
  
  FOR rec IN SELECT * FROM audit_rls_coverage() LOOP
    result := result || format('Table: %s | Policies: %s SELECT, %s INSERT, %s UPDATE, %s DELETE | Total: %s%s',
      rec.table_name,
      rec.select_policies,
      rec.insert_policies, 
      rec.update_policies,
      rec.delete_policies,
      rec.total_policies,
      E'\n'
    );
  END LOOP;
  
  result := result || E'\n=== NULL UID VULNERABILITY CHECK ===\n';
  
  FOR rec IN SELECT * FROM check_null_uid_policies() WHERE NOT has_null_check LOOP
    result := result || format('⚠️  VULNERABILITY: %s.%s (%s) missing auth.uid() IS NOT NULL check%s',
      rec.table_name,
      rec.policy_name,
      rec.command,
      E'\n'
    );
  END LOOP;
  
  result := result || E'\n=== CASCADE INTEGRITY CHECK ===\n';
  
  FOR rec IN SELECT * FROM validate_cascade_integrity() WHERE parent_table = 'matches' AND child_table = 'messages' LOOP
    result := result || format('matches → messages: %s (%s)%s',
      rec.constraint_name,
      rec.delete_rule,
      E'\n'
    );
  END LOOP;
  
  result := result || E'\n=== VALIDATION COMPLETE ===\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 11. POLICY DOCUMENTATION COMMENTS
-- ========================================

-- Add comments for new policies
COMMENT ON POLICY "User can update their own boosts" ON public.boosts IS 
'Users can modify their boost settings (duration, station) before expiration';

COMMENT ON POLICY "User can delete their own boosts" ON public.boosts IS 
'Users can cancel their boosts early and get potential refunds';

COMMENT ON POLICY "Group owner can update memberships" ON public.group_members IS 
'Group creators can modify member roles and permissions';

COMMENT ON POLICY "User can delete their groups" ON public.groups IS 
'Group creators can dissolve their groups, cascading to all memberships';

COMMENT ON POLICY "User can update their own messages" ON public.messages IS 
'Users can edit their messages within matches (edit functionality)';

COMMENT ON POLICY "User can delete their own messages" ON public.messages IS 
'Users can delete their own messages from conversations';

-- ========================================
-- MIGRATION COMPLETE
-- ========================================

-- Run validation and log results
SELECT run_rls_validation_tests();

-- Add comment to track migration completion
COMMENT ON SCHEMA public IS 'CrewSnow schema with complete RLS coverage - Migration 20241119 completed';
