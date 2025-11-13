-- CrewSnow - Test Public Access Policies
-- These queries test anonymous and authenticated access to public data

-- ========================================
-- TEST 1: PUBLIC_PROFILES_V ACCESS (SHOULD WORK)
-- ========================================

-- Test anonymous access to public profiles view
-- Expected: Returns rows with limited columns (no sensitive data)
SELECT 
  id,
  pseudo,
  level,
  ride_styles,
  languages,
  is_premium,
  photo_main_url,
  station_id,
  date_from,
  date_to,
  radius_km
FROM public.public_profiles_v 
LIMIT 5;

-- ========================================
-- TEST 2: DIRECT USERS TABLE ACCESS (SHOULD FAIL)
-- ========================================

-- Test anonymous access to users table directly
-- Expected: Returns 0 rows or access denied (RLS blocks)
SELECT * FROM public.users LIMIT 5;

-- Test specific sensitive columns access
-- Expected: Should fail or return 0 rows
SELECT 
  id,
  username,
  email,                    -- SENSITIVE
  stripe_customer_id,       -- SENSITIVE
  birth_date,              -- SENSITIVE
  verified_video_url       -- SENSITIVE
FROM public.users 
LIMIT 5;

-- ========================================
-- TEST 3: STATIONS ACCESS (SHOULD WORK)
-- ========================================

-- Test anonymous access to stations
-- Expected: Returns station data (public reference)
SELECT 
  name,
  country_code,
  region,
  latitude,
  longitude,
  elevation_m,
  official_website
FROM public.stations 
LIMIT 5;

-- ========================================
-- TEST 4: OTHER PROTECTED TABLES (SHOULD FAIL)
-- ========================================

-- Test access to protected tables (should fail for anonymous)
SELECT * FROM public.likes LIMIT 1;
SELECT * FROM public.matches LIMIT 1;
SELECT * FROM public.messages LIMIT 1;
SELECT * FROM public.profile_photos LIMIT 1;
SELECT * FROM public.ride_stats_daily LIMIT 1;

-- ========================================
-- TEST 5: VERIFY VIEW COLUMNS RESTRICTION
-- ========================================

-- Verify that sensitive columns are not exposed in the view
-- This should fail if trying to access non-existent columns
-- SELECT email FROM public.public_profiles_v LIMIT 1;  -- Should fail
-- SELECT stripe_customer_id FROM public.public_profiles_v LIMIT 1;  -- Should fail

-- ========================================
-- EXPECTED RESULTS SUMMARY
-- ========================================

/*
SHOULD WORK (return data):
- SELECT FROM public.public_profiles_v
- SELECT FROM public.stations

SHOULD FAIL (0 rows or access denied):
- SELECT FROM public.users (direct access)
- SELECT FROM public.likes
- SELECT FROM public.matches  
- SELECT FROM public.messages
- SELECT FROM public.profile_photos
- SELECT FROM public.ride_stats_daily

COLUMN RESTRICTIONS:
- public_profiles_v should NOT expose: email, stripe_customer_id, birth_date, verified_video_url
- public_profiles_v SHOULD expose: id, pseudo, level, ride_styles, languages, is_premium, photo_main_url, station info
*/
