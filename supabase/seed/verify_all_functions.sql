-- ============================================================================
-- Script de vérification complète de toutes les fonctions nécessaires
-- ============================================================================
-- Ce script vérifie que toutes les fonctions SQL/RPC appelées par le frontend
-- et les Edge Functions existent avec les bonnes signatures.
-- ============================================================================

DO $$
DECLARE
    func_count INTEGER;
    missing_funcs TEXT[] := ARRAY[]::TEXT[];
BEGIN
    RAISE NOTICE '🔍 Vérification des fonctions SQL/RPC...';
    RAISE NOTICE '';
    
    -- 1. get_optimized_candidates
    SELECT COUNT(*) INTO func_count
    FROM pg_proc 
    WHERE proname = 'get_optimized_candidates'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    
    IF func_count = 0 THEN
        missing_funcs := array_append(missing_funcs, 'get_optimized_candidates');
        RAISE NOTICE '❌ get_optimized_candidates: MANQUANTE';
    ELSE
        RAISE NOTICE '✅ get_optimized_candidates: EXISTE';
    END IF;
    
    -- 2. get_candidate_scores
    SELECT COUNT(*) INTO func_count
    FROM pg_proc 
    WHERE proname = 'get_candidate_scores'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    
    IF func_count = 0 THEN
        missing_funcs := array_append(missing_funcs, 'get_candidate_scores');
        RAISE NOTICE '❌ get_candidate_scores: MANQUANTE';
    ELSE
        RAISE NOTICE '✅ get_candidate_scores: EXISTE';
    END IF;
    
    -- 3. check_user_consent
    SELECT COUNT(*) INTO func_count
    FROM pg_proc 
    WHERE proname = 'check_user_consent'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    
    IF func_count = 0 THEN
        missing_funcs := array_append(missing_funcs, 'check_user_consent');
        RAISE NOTICE '❌ check_user_consent: MANQUANTE';
    ELSE
        RAISE NOTICE '✅ check_user_consent: EXISTE';
        -- Vérifier la signature
        SELECT COUNT(*) INTO func_count
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'check_user_consent'
          AND n.nspname = 'public'
          AND pg_get_function_arguments(p.oid) LIKE '%p_user_id%uuid%p_purpose%text%';
        
        IF func_count = 0 THEN
            RAISE WARNING '⚠️  check_user_consent: Signature incorrecte (attendu: p_user_id UUID, p_purpose TEXT, p_required_version INTEGER)';
        ELSE
            RAISE NOTICE '   Signature correcte';
        END IF;
    END IF;
    
    -- 4. grant_consent
    SELECT COUNT(*) INTO func_count
    FROM pg_proc 
    WHERE proname = 'grant_consent'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    
    IF func_count = 0 THEN
        missing_funcs := array_append(missing_funcs, 'grant_consent');
        RAISE NOTICE '❌ grant_consent: MANQUANTE';
    ELSE
        RAISE NOTICE '✅ grant_consent: EXISTE';
        -- Vérifier la signature
        SELECT COUNT(*) INTO func_count
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'grant_consent'
          AND n.nspname = 'public'
          AND pg_get_function_arguments(p.oid) LIKE '%p_user_id%uuid%p_purpose%text%';
        
        IF func_count = 0 THEN
            RAISE WARNING '⚠️  grant_consent: Signature incorrecte (attendu: p_user_id UUID, p_purpose TEXT, p_version INTEGER)';
        ELSE
            RAISE NOTICE '   Signature correcte';
        END IF;
    END IF;
    
    -- 5. revoke_consent
    SELECT COUNT(*) INTO func_count
    FROM pg_proc 
    WHERE proname = 'revoke_consent'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    
    IF func_count = 0 THEN
        missing_funcs := array_append(missing_funcs, 'revoke_consent');
        RAISE NOTICE '❌ revoke_consent: MANQUANTE';
    ELSE
        RAISE NOTICE '✅ revoke_consent: EXISTE';
    END IF;
    
    -- 6. check_and_increment_usage
    SELECT COUNT(*) INTO func_count
    FROM pg_proc 
    WHERE proname = 'check_and_increment_usage'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    
    IF func_count = 0 THEN
        missing_funcs := array_append(missing_funcs, 'check_and_increment_usage');
        RAISE NOTICE '❌ check_and_increment_usage: MANQUANTE';
    ELSE
        RAISE NOTICE '✅ check_and_increment_usage: EXISTE';
    END IF;
    
    -- 7. mark_match_read
    SELECT COUNT(*) INTO func_count
    FROM pg_proc 
    WHERE proname = 'mark_match_read'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    
    IF func_count = 0 THEN
        RAISE NOTICE '⚠️  mark_match_read: MANQUANTE (optionnel, utilisé pour le chat)';
    ELSE
        RAISE NOTICE '✅ mark_match_read: EXISTE';
    END IF;
    
    -- 8. get_total_unread_count
    SELECT COUNT(*) INTO func_count
    FROM pg_proc 
    WHERE proname = 'get_total_unread_count'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    
    IF func_count = 0 THEN
        RAISE NOTICE '⚠️  get_total_unread_count: MANQUANTE (optionnel, utilisé pour le chat)';
    ELSE
        RAISE NOTICE '✅ get_total_unread_count: EXISTE';
    END IF;
    
    -- 9. is_feature_enabled
    SELECT COUNT(*) INTO func_count
    FROM pg_proc 
    WHERE proname = 'is_feature_enabled'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    
    IF func_count = 0 THEN
        RAISE NOTICE '⚠️  is_feature_enabled: MANQUANTE (optionnel, feature flags)';
    ELSE
        RAISE NOTICE '✅ is_feature_enabled: EXISTE';
    END IF;
    
    -- 10. get_user_feature_flags
    SELECT COUNT(*) INTO func_count
    FROM pg_proc 
    WHERE proname = 'get_user_feature_flags'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    
    IF func_count = 0 THEN
        RAISE NOTICE '⚠️  get_user_feature_flags: MANQUANTE (optionnel, feature flags)';
    ELSE
        RAISE NOTICE '✅ get_user_feature_flags: EXISTE';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    
    IF array_length(missing_funcs, 1) > 0 THEN
        RAISE NOTICE '❌ FONCTIONS MANQUANTES: %', array_to_string(missing_funcs, ', ');
        RAISE NOTICE '';
        RAISE NOTICE '👉 Action requise: Exécuter la migration 20250118_fix_all_critical_errors.sql';
    ELSE
        RAISE NOTICE '✅ TOUTES LES FONCTIONS CRITIQUES SONT PRÉSENTES';
    END IF;
    
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    
END $$;

-- Vérifier les vues
DO $$
DECLARE
    view_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 Vérification des vues...';
    RAISE NOTICE '';
    
    -- public_profiles_v
    SELECT COUNT(*) INTO view_count
    FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'public_profiles_v';
    
    IF view_count = 0 THEN
        RAISE NOTICE '⚠️  public_profiles_v: MANQUANTE (optionnel)';
    ELSE
        RAISE NOTICE '✅ public_profiles_v: EXISTE';
    END IF;
    
    -- candidate_scores_v
    SELECT COUNT(*) INTO view_count
    FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'candidate_scores_v';
    
    IF view_count = 0 THEN
        RAISE NOTICE '⚠️  candidate_scores_v: MANQUANTE (optionnel)';
    ELSE
        RAISE NOTICE '✅ candidate_scores_v: EXISTE';
    END IF;
    
    -- active_users_with_location
    SELECT COUNT(*) INTO view_count
    FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'active_users_with_location';
    
    IF view_count = 0 THEN
        RAISE NOTICE '⚠️  active_users_with_location: MANQUANTE (optionnel)';
    ELSE
        RAISE NOTICE '✅ active_users_with_location: EXISTE';
    END IF;
    
    -- recent_matches_with_users
    SELECT COUNT(*) INTO view_count
    FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'recent_matches_with_users';
    
    IF view_count = 0 THEN
        RAISE NOTICE '⚠️  recent_matches_with_users: MANQUANTE (optionnel)';
    ELSE
        RAISE NOTICE '✅ recent_matches_with_users: EXISTE';
    END IF;
    
END $$;

-- Vérifier les tables critiques
DO $$
DECLARE
    table_name TEXT;
    table_exists INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 Vérification des tables critiques...';
    RAISE NOTICE '';
    
    FOR table_name IN 
        SELECT unnest(ARRAY['users', 'profile_photos', 'stations', 'user_station_status', 
                           'likes', 'matches', 'messages', 'consents', 'daily_usage'])
    LOOP
        SELECT COUNT(*) INTO table_exists
        FROM information_schema.tables t
        WHERE t.table_schema = 'public' AND t.table_name = table_name;
        
        IF table_exists = 0 THEN
            RAISE NOTICE '❌ %: MANQUANTE', table_name;
        ELSE
            RAISE NOTICE '✅ %: EXISTE', table_name;
        END IF;
    END LOOP;
    
END $$;

