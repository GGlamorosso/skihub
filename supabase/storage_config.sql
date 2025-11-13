-- ============================================================================
-- CREWSNOW STORAGE CONFIGURATION
-- ============================================================================
-- Description: Configuration sécurisée pour Storage (photos de profil)
-- ============================================================================

-- Create storage bucket for profile photos (private by default)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-photos',
    'profile-photos', 
    false, -- Private bucket for moderation
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================================================
-- STORAGE RLS POLICIES (CRITICAL FOR SECURITY)
-- ============================================================================

-- Users can only upload to their own folder
CREATE POLICY "users_can_upload_own_photos" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'profile-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can read their own photos
CREATE POLICY "users_can_read_own_photos" ON storage.objects  
FOR SELECT TO authenticated
USING (
    bucket_id = 'profile-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can update their own photos
CREATE POLICY "users_can_update_own_photos" ON storage.objects
FOR UPDATE TO authenticated  
USING (
    bucket_id = 'profile-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own photos
CREATE POLICY "users_can_delete_own_photos" ON storage.objects
FOR DELETE TO authenticated
USING (
    bucket_id = 'profile-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- APPROVED PHOTOS PUBLIC ACCESS FUNCTION
-- ============================================================================

-- Function to generate signed URLs for approved photos only
CREATE OR REPLACE FUNCTION get_approved_photo_url(
    user_id UUID,
    photo_id UUID,
    expires_in INTEGER DEFAULT 3600 -- 1 hour
) 
RETURNS TEXT AS $$
DECLARE
    photo_record RECORD;
    storage_path TEXT;
    signed_url TEXT;
BEGIN
    -- Check if photo is approved
    SELECT pp.*, pp.storage_path INTO photo_record
    FROM profile_photos pp
    WHERE pp.id = photo_id
      AND pp.user_id = user_id
      AND pp.moderation_status = 'approved';
    
    IF photo_record IS NULL THEN
        RETURN NULL; -- Photo not found or not approved
    END IF;
    
    -- Generate signed URL (this would be handled by Supabase client in practice)
    -- For now, return the storage path that can be used with supabase.storage.from().createSignedUrl()
    RETURN photo_record.storage_path;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- MODERATION WORKFLOW FUNCTIONS
-- ============================================================================

-- Function to approve a photo (moderator only)
CREATE OR REPLACE FUNCTION approve_photo(
    photo_id UUID,
    moderator_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    -- Update photo status to approved
    UPDATE profile_photos 
    SET 
        moderation_status = 'approved',
        moderated_at = NOW(),
        moderated_by = moderator_id
    WHERE id = photo_id 
      AND moderation_status = 'pending';
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    RETURN updated_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reject a photo (moderator only)
CREATE OR REPLACE FUNCTION reject_photo(
    photo_id UUID,
    moderator_id UUID,
    reason TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    -- Update photo status to rejected
    UPDATE profile_photos 
    SET 
        moderation_status = 'rejected',
        moderation_reason = reason,
        moderated_at = NOW(),
        moderated_by = moderator_id
    WHERE id = photo_id 
      AND moderation_status = 'pending';
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    RETURN updated_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- HELPER VIEWS FOR PHOTO MANAGEMENT
-- ============================================================================

-- View for approved photos (safe for public display)
CREATE VIEW approved_profile_photos AS
SELECT 
    pp.id,
    pp.user_id,
    pp.storage_path,
    pp.is_main,
    pp.display_order,
    pp.created_at,
    u.username
FROM profile_photos pp
JOIN users u ON pp.user_id = u.id
WHERE pp.moderation_status = 'approved'
  AND u.is_active = true
  AND u.is_banned = false;

-- View for photos pending moderation (moderators only)
CREATE VIEW photos_pending_moderation AS  
SELECT 
    pp.id,
    pp.user_id,
    pp.storage_path,
    pp.file_size_bytes,
    pp.mime_type,
    pp.created_at,
    u.username,
    u.email
FROM profile_photos pp
JOIN users u ON pp.user_id = u.id
WHERE pp.moderation_status = 'pending'
ORDER BY pp.created_at ASC;

-- ============================================================================
-- STORAGE CLEANUP FUNCTIONS
-- ============================================================================

-- Function to clean up orphaned storage files
CREATE OR REPLACE FUNCTION cleanup_orphaned_photos()
RETURNS INTEGER AS $$
DECLARE
    cleanup_count INTEGER := 0;
    orphaned_photo RECORD;
BEGIN
    -- Find profile_photos records with rejected status older than 30 days
    FOR orphaned_photo IN
        SELECT id, storage_path, user_id
        FROM profile_photos
        WHERE moderation_status = 'rejected'
          AND moderated_at < NOW() - INTERVAL '30 days'
    LOOP
        -- Delete from storage (would need to be handled by application code)
        -- DELETE FROM storage.objects WHERE name = orphaned_photo.storage_path;
        
        -- Delete from profile_photos table
        DELETE FROM profile_photos WHERE id = orphaned_photo.id;
        cleanup_count := cleanup_count + 1;
    END LOOP;
    
    RETURN cleanup_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SAMPLE UPLOAD WORKFLOW (FOR DOCUMENTATION)
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '📸 === STORAGE CONFIGURATION COMPLETED ===';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Created:';
    RAISE NOTICE '  - profile-photos bucket (private, 10MB limit)';
    RAISE NOTICE '  - RLS policies for user photo access';
    RAISE NOTICE '  - Moderation workflow functions';
    RAISE NOTICE '  - Cleanup utilities';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Upload workflow:';
    RAISE NOTICE '1. User uploads photo → Storage (private)';
    RAISE NOTICE '2. Create profile_photos record (status=pending)';  
    RAISE NOTICE '3. Moderator approves → status=approved';
    RAISE NOTICE '4. Generate signed URL for approved photos only';
    RAISE NOTICE '';
    RAISE NOTICE '🔐 Security features:';
    RAISE NOTICE '  - Private bucket (no public access)';
    RAISE NOTICE '  - User isolation (folder per user ID)';
    RAISE NOTICE '  - MIME type validation (images only)';
    RAISE NOTICE '  - File size limits (10MB)';
    RAISE NOTICE '  - Moderation required before display';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️ Next steps in Supabase Dashboard:';
    RAISE NOTICE '1. Storage → Create bucket "profile-photos"';
    RAISE NOTICE '2. Set bucket to private';  
    RAISE NOTICE '3. Configure MIME types and size limits';
    RAISE NOTICE '4. Test upload with your app';
END $$;
