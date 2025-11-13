-- CrewSnow - Storage Validation Tests
-- These tests validate Storage policies and moderation workflow

-- ========================================
-- TEST 1: BUCKET CONFIGURATION
-- ========================================

-- Verify bucket exists with correct configuration
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'profile_photos';

-- Expected: 
-- id: profile_photos, public: false, file_size_limit: 5242880 (5MB)
-- allowed_mime_types: {image/jpeg,image/png,image/webp,image/gif}

-- ========================================
-- TEST 2: STORAGE POLICIES VALIDATION
-- ========================================

-- Check that RLS is enabled on storage.objects
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- Expected: rowsecurity = true

-- List all policies on storage.objects for profile_photos
SELECT 
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND policyname LIKE '%profile%' OR policyname LIKE '%photo%';

-- Expected policies:
-- - user can upload to their folder (INSERT)
-- - public read approved profile photos (SELECT)
-- - owner read their photos (SELECT) 
-- - owner update their photos (UPDATE)
-- - owner delete their photos (DELETE)

-- ========================================
-- TEST 3: MODERATION SYNC FUNCTIONS
-- ========================================

-- Test that sync function exists
SELECT 
  proname,
  pronargs,
  prorettype::regtype
FROM pg_proc 
WHERE proname IN (
  'sync_photo_moderation_to_storage',
  'sync_photo_moderation_from_storage',
  'handle_photo_upload',
  'moderate_photo',
  'get_approved_photo_signed_url'
);

-- Expected: 5 functions returned

-- Test trigger exists
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trigger_sync_photo_moderation';

-- Expected: trigger on profile_photos table, AFTER UPDATE

-- ========================================
-- TEST 4: FOLDER STRUCTURE VALIDATION
-- ========================================

-- Test foldername function (simulated)
-- This would normally be tested with actual file uploads
SELECT storage.foldername('12345678-1234-1234-1234-123456789abc/profile.jpg') as folder_parts;

-- Expected: {12345678-1234-1234-1234-123456789abc}

-- ========================================
-- TEST 5: METADATA STRUCTURE VALIDATION
-- ========================================

-- Test that we can build the expected metadata structure
SELECT jsonb_build_object(
  'moderation_status', 'pending',
  'is_main', true,
  'user_id', '12345678-1234-1234-1234-123456789abc',
  'uploaded_at', NOW()::text
) as expected_metadata;

-- Expected: Valid JSON structure

-- ========================================
-- TEST 6: MODERATION WORKFLOW SIMULATION
-- ========================================

-- Test photo upload workflow (simulation)
-- This would be called after actual file upload
DO $$
DECLARE
  test_user_id uuid := '00000000-0000-0000-0000-000000000001';
  test_storage_path text := '00000000-0000-0000-0000-000000000001/test_photo.jpg';
  photo_id uuid;
BEGIN
  -- Simulate photo upload
  SELECT handle_photo_upload(test_user_id, test_storage_path, true) INTO photo_id;
  
  RAISE NOTICE 'Photo uploaded with ID: %', photo_id;
  
  -- Test moderation approval
  PERFORM moderate_photo(photo_id, 'approved'::moderation_status, 'Looks good');
  
  RAISE NOTICE 'Photo moderated successfully';
  
  -- Cleanup test data
  DELETE FROM public.profile_photos WHERE id = photo_id;
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Test failed: %', SQLERRM;
END $$;

-- ========================================
-- TEST 7: ACCESS CONTROL SIMULATION
-- ========================================

-- These tests simulate different user access scenarios
-- Note: These would need actual auth context in real testing

-- Test 1: Anonymous user trying to access pending photo
-- Should fail - only approved photos visible to anon
/*
SET ROLE anon;
SELECT * FROM storage.objects 
WHERE bucket_id = 'profile_photos' 
  AND metadata->>'moderation_status' = 'pending';
-- Expected: No rows or access denied
*/

-- Test 2: Authenticated user accessing their own photos
-- Should work - owner can see all their photos
/*
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000001"}';
SELECT * FROM storage.objects 
WHERE bucket_id = 'profile_photos' 
  AND (storage.foldername(name))[1] = '00000000-0000-0000-0000-000000000001';
-- Expected: Returns user's photos
*/

-- Test 3: User trying to access another user's folder
-- Should fail - can't access other users' folders
/*
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000001"}';
SELECT * FROM storage.objects 
WHERE bucket_id = 'profile_photos' 
  AND (storage.foldername(name))[1] = '00000000-0000-0000-0000-000000000002';
-- Expected: No rows or access denied
*/

-- ========================================
-- TEST 8: INTEGRATION WITH PROFILE_PHOTOS TABLE
-- ========================================

-- Test that profile_photos entries have corresponding storage paths
SELECT 
  pp.id,
  pp.storage_path,
  pp.moderation_status as db_status,
  so.metadata->>'moderation_status' as storage_status,
  CASE 
    WHEN pp.moderation_status::text = so.metadata->>'moderation_status' 
    THEN 'SYNCED' 
    ELSE 'OUT_OF_SYNC' 
  END as sync_status
FROM public.profile_photos pp
LEFT JOIN storage.objects so ON so.name = pp.storage_path AND so.bucket_id = 'profile_photos'
WHERE pp.storage_path IS NOT NULL
LIMIT 10;

-- Expected: All entries should show 'SYNCED' status

-- ========================================
-- EXPECTED RESULTS SUMMARY
-- ========================================

/*
BUCKET CONFIGURATION:
✅ profile_photos bucket exists
✅ Private bucket (public = false)
✅ 5MB size limit
✅ Image MIME types only

STORAGE POLICIES:
✅ RLS enabled on storage.objects
✅ 5 policies created for profile_photos bucket
✅ UID-based folder structure enforced

ACCESS CONTROL:
✅ Users can upload to /<uid>/ folder only
✅ Public can read approved photos only
✅ Owners can read all their photos
✅ Owners can delete their photos

MODERATION WORKFLOW:
✅ DB ↔ Storage metadata sync
✅ Automatic trigger on status change
✅ Manual moderation functions
✅ Photo upload workflow

INTEGRATION:
✅ profile_photos table synced with Storage
✅ Metadata consistency maintained
✅ Helper functions for common operations
*/
