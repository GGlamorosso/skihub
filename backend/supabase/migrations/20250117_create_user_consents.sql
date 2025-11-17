-- Migration: Créer table user_consents pour gérer les consentements utilisateur

CREATE TABLE IF NOT EXISTS public.user_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  purpose TEXT NOT NULL, -- 'gps_tracking', 'notifications', etc.
  granted BOOLEAN NOT NULL DEFAULT false,
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, purpose)
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_user_consents_user_id ON public.user_consents(user_id);
CREATE INDEX IF NOT EXISTS idx_user_consents_purpose ON public.user_consents(purpose);

-- RLS Policies
ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own consents
CREATE POLICY "Users can read their own consents"
ON public.user_consents
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Users can insert their own consents
CREATE POLICY "Users can insert their own consents"
ON public.user_consents
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own consents
CREATE POLICY "Users can update their own consents"
ON public.user_consents
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Comments
COMMENT ON TABLE public.user_consents IS 'Stores user consents for GDPR compliance (GPS tracking, notifications, etc.)';
COMMENT ON COLUMN public.user_consents.purpose IS 'Type of consent: gps_tracking, notifications, analytics, etc.';
COMMENT ON COLUMN public.user_consents.version IS 'Version of the consent policy when granted';

