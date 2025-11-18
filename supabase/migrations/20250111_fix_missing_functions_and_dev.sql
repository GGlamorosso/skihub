-- ============================================================================
-- Corrections pour développement - Fonctions manquantes et ajustements
-- ============================================================================

-- 1. Vérifier et créer les fonctions de consentement si elles n'existent pas
-- (au cas où la migration 20250110_gdpr_compliance_system.sql n'a pas été exécutée)

DO $$
BEGIN
    -- Vérifier si check_user_consent existe
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'check_user_consent' 
        AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    ) THEN
        CREATE OR REPLACE FUNCTION check_user_consent(
            p_user_id UUID,
            p_purpose TEXT,
            p_required_version INTEGER DEFAULT 1
        ) RETURNS BOOLEAN AS $$
        DECLARE
            consent_exists BOOLEAN := false;
        BEGIN
            SELECT EXISTS (
                SELECT 1 FROM consents 
                WHERE user_id = p_user_id 
                    AND purpose = p_purpose
                    AND version >= p_required_version
                    AND revoked_at IS NULL
            ) INTO consent_exists;
            
            RETURN consent_exists;
        END;
        $$ LANGUAGE plpgsql;
        
        RAISE NOTICE '✅ Created function check_user_consent';
    ELSE
        RAISE NOTICE 'ℹ️ Function check_user_consent already exists';
    END IF;

    -- Vérifier si grant_consent existe
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'grant_consent' 
        AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    ) THEN
        CREATE OR REPLACE FUNCTION grant_consent(
            p_user_id UUID,
            p_purpose TEXT,
            p_version INTEGER DEFAULT 1
        ) RETURNS UUID AS $$
        DECLARE
            consent_id UUID;
        BEGIN
            -- Révoquer consentements précédents
            UPDATE consents 
            SET revoked_at = NOW()
            WHERE user_id = p_user_id 
                AND purpose = p_purpose 
                AND revoked_at IS NULL;
            
            -- Accorder nouveau consentement
            INSERT INTO consents (user_id, purpose, granted_at, version)
            VALUES (p_user_id, p_purpose, NOW(), p_version)
            RETURNING id INTO consent_id;
            
            RETURN consent_id;
        END;
        $$ LANGUAGE plpgsql;
        
        RAISE NOTICE '✅ Created function grant_consent';
    ELSE
        RAISE NOTICE 'ℹ️ Function grant_consent already exists';
    END IF;
END $$;

-- 2. Rendre file_size_bytes nullable (pour éviter les erreurs si non fourni)
-- OU créer une fonction pour calculer automatiquement depuis storage

DO $$
BEGIN
    -- Vérifier si la colonne existe et est NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profile_photos' 
        AND column_name = 'file_size_bytes'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE profile_photos
        ALTER COLUMN file_size_bytes DROP NOT NULL;
        
        RAISE NOTICE '✅ Made file_size_bytes nullable';
    ELSE
        RAISE NOTICE 'ℹ️ file_size_bytes is already nullable or does not exist';
    END IF;
END $$;

-- 3. Fonction pour calculer automatiquement file_size_bytes depuis storage_path
-- (optionnel, mais utile pour les photos existantes)

CREATE OR REPLACE FUNCTION update_photo_file_size()
RETURNS TRIGGER AS $$
BEGIN
    -- Si file_size_bytes n'est pas fourni, on peut le laisser NULL
    -- ou le calculer depuis les métadonnées du storage (nécessite une extension)
    -- Pour l'instant, on accepte NULL
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Augmenter les quotas en développement (pour éviter les blocages)
-- Créer une fonction pour reset les quotas quotidiens (dev only)

CREATE OR REPLACE FUNCTION reset_daily_usage_for_dev(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Réinitialiser le compteur quotidien pour un utilisateur
    UPDATE daily_usage
    SET count = 0
    WHERE user_id = p_user_id
        AND date = CURRENT_DATE
        AND usage_type = 'swipes';
    
    RAISE NOTICE '✅ Reset daily swipes for user %', p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION reset_daily_usage_for_dev(UUID) IS 
'DEV ONLY: Reset daily usage quota for a user. Use with caution in production.';

-- 5. Fonction pour augmenter temporairement les quotas (dev only)
CREATE OR REPLACE FUNCTION increase_daily_limit_for_dev(
    p_user_id UUID,
    p_new_limit INTEGER DEFAULT 1000
)
RETURNS VOID AS $$
BEGIN
    -- Mettre à jour ou créer un quota personnalisé pour dev
    INSERT INTO daily_usage (user_id, date, usage_type, count, limit_count)
    VALUES (p_user_id, CURRENT_DATE, 'swipes', 0, p_new_limit)
    ON CONFLICT (user_id, date, usage_type)
    DO UPDATE SET limit_count = p_new_limit;
    
    RAISE NOTICE '✅ Increased daily limit to % for user %', p_new_limit, p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION increase_daily_limit_for_dev(UUID, INTEGER) IS 
'DEV ONLY: Increase daily usage limit for a user. Use with caution in production.';

-- 6. Vérifier que la table consents existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'consents'
    ) THEN
        -- Créer la table consents si elle n'existe pas
        CREATE TABLE consents (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            purpose TEXT NOT NULL,
            granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            revoked_at TIMESTAMPTZ,
            version INTEGER NOT NULL DEFAULT 1,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            
            CONSTRAINT consents_purpose_valid CHECK (
                purpose IN ('gps', 'ai_moderation', 'marketing', 'analytics', 
                           'push_notifications', 'email_marketing', 'data_processing')
            )
        );
        
        CREATE INDEX idx_consents_user_purpose ON consents(user_id, purpose);
        CREATE INDEX idx_consents_active ON consents(user_id, purpose) 
            WHERE revoked_at IS NULL;
        
        RAISE NOTICE '✅ Created table consents';
    ELSE
        RAISE NOTICE 'ℹ️ Table consents already exists';
    END IF;
END $$;

-- 7. Vérifier que la table daily_usage existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'daily_usage'
    ) THEN
        -- Créer la table daily_usage si elle n'existe pas
        CREATE TABLE daily_usage (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            date DATE NOT NULL DEFAULT CURRENT_DATE,
            usage_type TEXT NOT NULL,
            count INTEGER NOT NULL DEFAULT 0,
            limit_count INTEGER NOT NULL DEFAULT 10,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            
            CONSTRAINT daily_usage_unique UNIQUE (user_id, date, usage_type),
            CONSTRAINT daily_usage_type_valid CHECK (
                usage_type IN ('swipes', 'messages', 'boosts', 'matches')
            )
        );
        
        CREATE INDEX idx_daily_usage_user_date ON daily_usage(user_id, date);
        
        RAISE NOTICE '✅ Created table daily_usage';
    ELSE
        RAISE NOTICE 'ℹ️ Table daily_usage already exists';
    END IF;
END $$;

-- ============================================================================
-- RÉSUMÉ
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ Corrections appliquées :';
    RAISE NOTICE '  1. Fonctions check_user_consent et grant_consent créées/vérifiées';
    RAISE NOTICE '  2. file_size_bytes rendu nullable';
    RAISE NOTICE '  3. Fonctions dev pour reset/augmenter quotas créées';
    RAISE NOTICE '  4. Tables consents et daily_usage créées/vérifiées';
    RAISE NOTICE '';
    RAISE NOTICE '📝 Pour augmenter votre quota en dev, exécutez :';
    RAISE NOTICE '  SELECT increase_daily_limit_for_dev(''VOTRE_USER_ID'', 1000);';
    RAISE NOTICE '';
END $$;

