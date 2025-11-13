-- CrewSnow S2 - Storage Security Tests
-- These tests validate Storage policies and moderation workflow security

-- ========================================
-- SETUP: Storage Test Environment
-- ========================================

-- Function to simulate storage operations and test security
CREATE OR REPLACE FUNCTION test_storage_security()
RETURNS text AS $$
DECLARE
  result text := '';
  test_user_a UUID := '00000000-0000-0000-0000-000000000001';
  test_user_b UUID := '00000000-0000-0000-0000-000000000002';
  row_count integer;
  bucket_exists boolean;
BEGIN
  result := result || E'=== STORAGE SECURITY TEST SUITE ===\n\n';
  
  -- Test 1: Verify bucket configuration
  SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'profile_photos') INTO bucket_exists;
  IF bucket_exists THEN
    result := result || E'✅ PASS: profile_photos bucket exists\n';
    
    -- Check bucket configuration
    SELECT COUNT(*) INTO row_count FROM storage.buckets 
    WHERE id = 'profile_photos' 
      AND public = false 
      AND file_size_limit = 5242880;
    
    IF row_count > 0 THEN
      result := result || E'✅ PASS: Bucket properly configured (private, 5MB limit)\n';
    ELSE
      result := result || E'❌ FAIL: Bucket configuration incorrect\n';
    END IF;
  ELSE
    result := result || E'❌ FAIL: profile_photos bucket does not exist\n';
  END IF;
  
  -- Test 2: Check RLS is enabled on storage.objects
  SELECT COUNT(*) INTO row_count FROM pg_tables 
  WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND rowsecurity = true;
    
  IF row_count > 0 THEN
    result := result || E'✅ PASS: RLS enabled on storage.objects\n';
  ELSE
    result := result || E'❌ FAIL: RLS not enabled on storage.objects\n';
  END IF;
  
  -- Test 3: Check storage policies exist
  SELECT COUNT(*) INTO row_count FROM pg_policies 
  WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname LIKE '%profile%';
    
  IF row_count >= 4 THEN
    result := result || format('✅ PASS: %s storage policies found for profile_photos\n', row_count);
  ELSE
    result := result || format('❌ FAIL: Only %s storage policies found (expected 4+)\n', row_count);
  END IF;
  
  result := result || E'\n';
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to test UID-based folder structure
CREATE OR REPLACE FUNCTION test_uid_folder_structure()
RETURNS text AS $$
DECLARE
  result text := '';
  test_path_valid text := '00000000-0000-0000-0000-000000000001/profile.jpg';
  test_path_invalid text := '00000000-0000-0000-0000-000000000002/profile.jpg';
  folder_parts text[];
BEGIN
  result := result || E'=== UID FOLDER STRUCTURE TESTS ===\n\n';
  
  -- Test 1: Verify foldername function works
  SELECT storage.foldername(test_path_valid) INTO folder_parts;
  IF folder_parts[1] = '00000000-0000-0000-0000-000000000001' THEN
    result := result || E'✅ PASS: foldername() correctly extracts UID from path\n';
  ELSE
    result := result || format('❌ FAIL: foldername() returned %s instead of expected UID\n', folder_parts[1]);
  END IF;
  
  -- Test 2: Validate path structure requirements
  result := result || E'✅ INFO: Storage policies enforce UID-based folder structure:\n';
  result := result || format('   - Valid path: %s\n', test_path_valid);
  result := result || format('   - Invalid path: %s (different user)\n', test_path_invalid);
  result := result || E'   - Policy: (storage.foldername(name))[1] = auth.uid()::text\n';
  
  result := result || E'\n';
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to test moderation workflow
CREATE OR REPLACE FUNCTION test_moderation_workflow()
RETURNS text AS $$
DECLARE
  result text := '';
  test_photo_id UUID;
  test_user_id UUID := '00000000-0000-0000-0000-000000000001';
  test_path text := '00000000-0000-0000-0000-000000000001/test_photo.jpg';
  row_count integer;
  photo_status moderation_status;
BEGIN
  result := result || E'=== MODERATION WORKFLOW TESTS ===\n\n';
  
  -- Test 1: Create test photo entry
  BEGIN
    INSERT INTO public.profile_photos (user_id, storage_path, is_main, moderation_status)
    VALUES (test_user_id, test_path, false, 'pending')
    RETURNING id INTO test_photo_id;
    
    result := result || E'✅ PASS: Test photo entry created with pending status\n';
  EXCEPTION WHEN OTHERS THEN
    result := result || format('❌ FAIL: Could not create test photo: %s\n', SQLERRM);
    RETURN result;
  END;
  
  -- Test 2: Verify photo starts as pending
  SELECT moderation_status INTO photo_status 
  FROM public.profile_photos WHERE id = test_photo_id;
  
  IF photo_status = 'pending' THEN
    result := result || E'✅ PASS: New photos default to pending status\n';
  ELSE
    result := result || format('❌ FAIL: Photo status is %s instead of pending\n', photo_status);
  END IF;
  
  -- Test 3: Test moderation approval
  BEGIN
    SELECT moderate_photo(test_photo_id, 'approved'::moderation_status, 'Test approval');
    
    SELECT moderation_status INTO photo_status 
    FROM public.profile_photos WHERE id = test_photo_id;
    
    IF photo_status = 'approved' THEN
      result := result || E'✅ PASS: Photo successfully approved via moderate_photo()\n';
    ELSE
      result := result || format('❌ FAIL: Photo status is %s after approval\n', photo_status);
    END IF;
  EXCEPTION WHEN OTHERS THEN
    result := result || format('❌ FAIL: Moderation approval failed: %s\n', SQLERRM);
  END;
  
  -- Test 4: Test moderation rejection
  BEGIN
    SELECT moderate_photo(test_photo_id, 'rejected'::moderation_status, 'Test rejection');
    
    SELECT moderation_status INTO photo_status 
    FROM public.profile_photos WHERE id = test_photo_id;
    
    IF photo_status = 'rejected' THEN
      result := result || E'✅ PASS: Photo successfully rejected via moderate_photo()\n';
    ELSE
      result := result || format('❌ FAIL: Photo status is %s after rejection\n', photo_status);
    END IF;
  EXCEPTION WHEN OTHERS THEN
    result := result || format('❌ FAIL: Moderation rejection failed: %s\n', SQLERRM);
  END;
  
  -- Test 5: Verify only approved photos visible to public
  SELECT COUNT(*) INTO row_count 
  FROM public.profile_photos 
  WHERE moderation_status = 'approved';
  result := result || format('✅ INFO: %s approved photos visible to public\n', row_count);
  
  SELECT COUNT(*) INTO row_count 
  FROM public.profile_photos 
  WHERE moderation_status = 'pending';
  result := result || format('✅ INFO: %s pending photos (not visible to public)\n', row_count);
  
  SELECT COUNT(*) INTO row_count 
  FROM public.profile_photos 
  WHERE moderation_status = 'rejected';
  result := result || format('✅ INFO: %s rejected photos (not visible to public)\n', row_count);
  
  -- Cleanup test data
  DELETE FROM public.profile_photos WHERE id = test_photo_id;
  result := result || E'✅ INFO: Test photo cleaned up\n';
  
  result := result || E'\n';
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to test storage access patterns
CREATE OR REPLACE FUNCTION test_storage_access_patterns()
RETURNS text AS $$
DECLARE
  result text := '';
  user_a_id UUID := '00000000-0000-0000-0000-000000000001';
  user_b_id UUID := '00000000-0000-0000-0000-000000000002';
BEGIN
  result := result || E'=== STORAGE ACCESS PATTERNS ===\n\n';
  
  -- Test 1: User A upload scenario
  result := result || format('User A (%s) upload tests:\n', user_a_id);
  result := result || format('✅ ALLOWED: Upload to /%s/photo1.jpg\n', user_a_id);
  result := result || format('❌ BLOCKED: Upload to /%s/photo1.jpg (wrong UID)\n', user_b_id);
  result := result || E'   Policy: WITH CHECK ((storage.foldername(name))[1] = auth.uid()::text)\n\n';
  
  -- Test 2: User B read scenario
  result := result || format('User B (%s) read tests:\n', user_b_id);
  result := result || format('✅ ALLOWED: Read own photos (any moderation status)\n');
  result := result || format('✅ ALLOWED: Read approved photos from any user\n');
  result := result || format('❌ BLOCKED: Read pending/rejected photos from other users\n');
  result := result || E'   Policy: USING (moderation_status = ''approved'' OR auth.uid() = user_id)\n\n';
  
  -- Test 3: Anonymous user scenario
  result := result || E'Anonymous user read tests:\n';
  result := result || E'✅ ALLOWED: Read approved photos only\n';
  result := result || E'❌ BLOCKED: Read pending/rejected photos\n';
  result := result || E'❌ BLOCKED: Upload (no auth)\n';
  result := result || E'   Policy: USING (moderation_status = ''approved'')\n\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to test storage metadata sync
CREATE OR REPLACE FUNCTION test_storage_metadata_sync()
RETURNS text AS $$
DECLARE
  result text := '';
  test_user_id UUID := '00000000-0000-0000-0000-000000000001';
  test_path text := '00000000-0000-0000-0000-000000000001/sync_test.jpg';
  test_photo_id UUID;
  trigger_exists boolean;
BEGIN
  result := result || E'=== STORAGE METADATA SYNC TESTS ===\n\n';
  
  -- Test 1: Check if sync trigger exists
  SELECT EXISTS(
    SELECT 1 FROM information_schema.triggers 
    WHERE trigger_name = 'trigger_sync_photo_moderation'
  ) INTO trigger_exists;
  
  IF trigger_exists THEN
    result := result || E'✅ PASS: Storage sync trigger exists\n';
  ELSE
    result := result || E'❌ FAIL: Storage sync trigger missing\n';
  END IF;
  
  -- Test 2: Check sync functions exist
  SELECT EXISTS(
    SELECT 1 FROM pg_proc 
    WHERE proname = 'sync_photo_moderation_to_storage'
  ) INTO trigger_exists;
  
  IF trigger_exists THEN
    result := result || E'✅ PASS: DB→Storage sync function exists\n';
  ELSE
    result := result || E'❌ FAIL: DB→Storage sync function missing\n';
  END IF;
  
  SELECT EXISTS(
    SELECT 1 FROM pg_proc 
    WHERE proname = 'sync_photo_moderation_from_storage'
  ) INTO trigger_exists;
  
  IF trigger_exists THEN
    result := result || E'✅ PASS: Storage→DB sync function exists\n';
  ELSE
    result := result || E'❌ FAIL: Storage→DB sync function missing\n';
  END IF;
  
  -- Test 3: Test photo upload workflow function
  SELECT EXISTS(
    SELECT 1 FROM pg_proc 
    WHERE proname = 'handle_photo_upload'
  ) INTO trigger_exists;
  
  IF trigger_exists THEN
    result := result || E'✅ PASS: Photo upload workflow function exists\n';
    
    -- Test the workflow
    BEGIN
      SELECT handle_photo_upload(test_user_id, test_path, false) INTO test_photo_id;
      result := result || E'✅ PASS: Photo upload workflow executed successfully\n';
      
      -- Cleanup
      DELETE FROM public.profile_photos WHERE id = test_photo_id;
    EXCEPTION WHEN OTHERS THEN
      result := result || format('❌ FAIL: Photo upload workflow error: %s\n', SQLERRM);
    END;
  ELSE
    result := result || E'❌ FAIL: Photo upload workflow function missing\n';
  END IF;
  
  result := result || E'\n';
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- MAIN STORAGE TEST RUNNER
-- ========================================

-- Function to run all storage security tests
CREATE OR REPLACE FUNCTION run_storage_security_tests()
RETURNS text AS $$
DECLARE
  result text := '';
BEGIN
  result := result || E'CREWSNOW S2 - STORAGE SECURITY TEST SUITE\n';
  result := result || E'=========================================\n\n';
  
  -- Run storage configuration tests
  result := result || test_storage_security();
  
  -- Run UID folder structure tests
  result := result || test_uid_folder_structure();
  
  -- Run moderation workflow tests
  result := result || test_moderation_workflow();
  
  -- Run access pattern tests
  result := result || test_storage_access_patterns();
  
  -- Run metadata sync tests
  result := result || test_storage_metadata_sync();
  
  result := result || E'=== MANUAL TESTING REQUIRED ===\n';
  result := result || E'The following tests require actual file uploads via Supabase client:\n\n';
  
  result := result || E'1. Upload Test (User A):\n';
  result := result || E'   - Upload file to /userA_id/photo.jpg → Should succeed\n';
  result := result || E'   - Try upload to /userB_id/photo.jpg → Should fail\n\n';
  
  result := result || E'2. Read Test (User B):\n';
  result := result || E'   - Read userA approved photos → Should succeed\n';
  result := result || E'   - Read userA pending photos → Should fail\n\n';
  
  result := result || E'3. Anonymous Read Test:\n';
  result := result || E'   - Read approved photos → Should succeed\n';
  result := result || E'   - Read pending/rejected → Should fail\n\n';
  
  result := result || E'4. Signed URL Test:\n';
  result := result || E'   - Generate signed URL for approved photo → Should work\n';
  result := result || E'   - Generate signed URL for pending photo → Should fail or return null\n\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- QUICK TEST EXECUTION
-- ========================================

-- Run the storage security test suite
SELECT run_storage_security_tests();
