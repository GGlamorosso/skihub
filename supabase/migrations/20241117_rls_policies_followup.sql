-- CrewSnow Migration - RLS Policies Follow-up (Public Access Corrections)
-- This migration corrects public access policies for views and reference tables

-- ========================================
-- 1. CORRECT PUBLIC_PROFILES_V POLICY
-- ========================================

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "public profiles" ON public.public_profiles_v;
DROP POLICY IF EXISTS "Public profiles view is accessible" ON public.public_profiles_v;

-- Create correct public policy for the view
CREATE POLICY "public profiles"
  ON public.public_profiles_v
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ========================================
-- 2. CORRECT STATIONS PUBLIC POLICY
-- ========================================

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Stations are publicly readable" ON public.stations;

-- Create explicit public read policy for stations
CREATE POLICY "public can read stations"
  ON public.stations
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ========================================
-- 3. ADD COMMENTS FOR CLARITY
-- ========================================

COMMENT ON POLICY "public profiles" ON public.public_profiles_v IS 
'Allows anonymous and authenticated users to read public profile data via secure view only';

COMMENT ON POLICY "public can read stations" ON public.stations IS 
'Allows public read access to stations reference data for all users';

-- ========================================
-- MIGRATION COMPLETE
-- ========================================

-- Add comment to track migration completion
COMMENT ON SCHEMA public IS 'CrewSnow schema with corrected public policies - Migration 20241117 completed';
