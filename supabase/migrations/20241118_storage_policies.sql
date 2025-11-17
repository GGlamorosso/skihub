-- CrewSnow Migration - Storage Policies for Profile Photos
-- This migration creates comprehensive Storage policies with UID-based folder structure

-- ========================================
-- 1. CREATE PROFILE_PHOTOS BUCKET (IF NOT EXISTS)
-- ========================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile_photos',
  'profile_photos',
  false, -- Private bucket by default
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- ========================================
-- 2. ENABLE RLS ON STORAGE.OBJECTS
-- ========================================

-- Enable RLS on storage objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 3. STORAGE POLICIES FOR PROFILE_PHOTOS
-- ========================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "user can upload to their folder" ON storage.objects;
DROP POLICY IF EXISTS "public read approved profile photos" ON storage.objects;
DROP POLICY IF EXISTS "owner read their photos" ON storage.objects;
DROP POLICY IF EXISTS "owner delete their photos" ON storage.objects;
DROP POLICY IF EXISTS "owner update their photos" ON storage.objects;

-- INSERT: User can upload to their own folder /<uid>/
CREATE POLICY "user can upload to their folder"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'profile_photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND auth.uid() IS NOT NULL
  );

-- SELECT: Public can read approved photos only
CREATE POLICY "public read approved profile photos"
  ON storage.objects FOR SELECT
  TO anon, authenticated
  USING (
    bucket_id = 'profile_photos'
    AND metadata->>'moderation_status' = 'approved'
  );

-- SELECT: Owner can read all their photos (any moderation status)
CREATE POLICY "owner read their photos"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'profile_photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND auth.uid() IS NOT NULL
  );

-- UPDATE: Owner can update their photo metadata
CREATE POLICY "owner update their photos"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'profile_photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND auth.uid() IS NOT NULL
  )
  WITH CHECK (
    bucket_id = 'profile_photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND auth.uid() IS NOT NULL
  );

-- DELETE: Owner can delete their own photos
CREATE POLICY "owner delete their photos"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'profile_photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND auth.uid() IS NOT NULL
  );

-- ========================================
-- 4. MODERATION SYNC FUNCTIONS
-- ========================================

-- Function to sync moderation status from DB to Storage
CREATE OR REPLACE FUNCTION sync_photo_moderation_to_storage()
RETURNS TRIGGER AS $$
BEGIN
  -- Update Storage metadata when profile_photos moderation_status changes
  UPDATE storage.objects
  SET metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
    'moderation_status', NEW.moderation_status,
    'is_main', NEW.is_main,
    'updated_at', NOW()::text
  )
  WHERE bucket_id = 'profile_photos'
    AND name = NEW.storage_path;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically sync moderation status
DROP TRIGGER IF EXISTS trigger_sync_photo_moderation ON public.profile_photos;
CREATE TRIGGER trigger_sync_photo_moderation
  AFTER UPDATE OF moderation_status, is_main ON public.profile_photos
  FOR EACH ROW
  EXECUTE FUNCTION sync_photo_moderation_to_storage();

-- Function to sync moderation status from Storage to DB (for manual moderation)
CREATE OR REPLACE FUNCTION sync_photo_moderation_from_storage(
  storage_path text,
  new_status moderation_status
) RETURNS void AS $$
BEGIN
  -- Update DB when moderation is done directly in Storage
  UPDATE public.profile_photos
  SET 
    moderation_status = new_status,
    updated_at = NOW()
  WHERE storage_path = sync_photo_moderation_from_storage.storage_path;
  
  -- Also update Storage metadata for consistency
  UPDATE storage.objects
  SET metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
    'moderation_status', new_status,
    'updated_at', NOW()::text
  )
  WHERE bucket_id = 'profile_photos'
    AND name = sync_photo_moderation_from_storage.storage_path;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 5. HELPER FUNCTIONS FOR PHOTO MANAGEMENT
-- ========================================

-- Function to get signed URL for approved photos
CREATE OR REPLACE FUNCTION get_approved_photo_signed_url(
  user_id uuid,
  expires_in_seconds integer DEFAULT 3600
) RETURNS text AS $$
DECLARE
  photo_path text;
  signed_url text;
BEGIN
  -- Get the main approved photo path for the user
  SELECT storage_path INTO photo_path
  FROM public.profile_photos
  WHERE profile_photos.user_id = get_approved_photo_signed_url.user_id
    AND is_main = true
    AND moderation_status = 'approved'
  LIMIT 1;
  
  IF photo_path IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Generate signed URL (this would typically be done via Edge Function)
  -- For now, return the path - implement actual signing in Edge Function
  RETURN photo_path;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle photo upload workflow
CREATE OR REPLACE FUNCTION handle_photo_upload(
  user_id uuid,
  storage_path text,
  is_main boolean DEFAULT false
) RETURNS uuid AS $$
DECLARE
  photo_id uuid;
BEGIN
  -- Insert into profile_photos table
  INSERT INTO public.profile_photos (
    user_id,
    storage_path,
    is_main,
    moderation_status,
    created_at,
    updated_at
  ) VALUES (
    handle_photo_upload.user_id,
    handle_photo_upload.storage_path,
    handle_photo_upload.is_main,
    'pending',
    NOW(),
    NOW()
  ) RETURNING id INTO photo_id;
  
  -- If this is set as main, unset other main photos
  IF is_main THEN
    UPDATE public.profile_photos
    SET is_main = false, updated_at = NOW()
    WHERE profile_photos.user_id = handle_photo_upload.user_id
      AND id != photo_id;
  END IF;
  
  -- Update Storage metadata
  UPDATE storage.objects
  SET metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
    'moderation_status', 'pending',
    'is_main', is_main,
    'user_id', user_id::text,
    'uploaded_at', NOW()::text
  )
  WHERE bucket_id = 'profile_photos'
    AND name = handle_photo_upload.storage_path;
  
  RETURN photo_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function for moderation workflow
CREATE OR REPLACE FUNCTION moderate_photo(
  photo_id uuid,
  new_status moderation_status,
  moderation_reason text DEFAULT NULL
) RETURNS boolean AS $$
DECLARE
  photo_record record;
BEGIN
  -- Get photo record
  SELECT * INTO photo_record
  FROM public.profile_photos
  WHERE id = moderate_photo.photo_id;
  
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- Update moderation status
  UPDATE public.profile_photos
  SET 
    moderation_status = new_status,
    moderation_reason = moderate_photo.moderation_reason,
    updated_at = NOW()
  WHERE id = moderate_photo.photo_id;
  
  -- Sync to Storage (trigger will handle this automatically)
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 6. STORAGE BUCKET CONFIGURATION COMMENTS
-- ========================================

COMMENT ON TABLE storage.buckets IS 'Storage buckets configuration - profile_photos bucket configured with 5MB limit and image MIME types only';

-- Add comments to policies for documentation
COMMENT ON POLICY "user can upload to their folder" ON storage.objects IS 
'Users can upload photos to their own UID-based folder structure /<uid>/filename';

COMMENT ON POLICY "public read approved profile photos" ON storage.objects IS 
'Public can access photos only when moderation_status=approved in metadata';

COMMENT ON POLICY "owner read their photos" ON storage.objects IS 
'Users can access all their own photos regardless of moderation status';

COMMENT ON POLICY "owner delete their photos" ON storage.objects IS 
'Users can delete their own photos from their UID folder';

-- ========================================
-- MIGRATION COMPLETE
-- ========================================

-- Add comment to track migration completion
COMMENT ON SCHEMA storage IS 'CrewSnow Storage policies configured - Migration 20241118 completed';
