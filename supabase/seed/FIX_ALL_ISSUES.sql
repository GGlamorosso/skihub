-- ============================================================================
-- 🔧 SCRIPT COMPLET POUR CORRIGER TOUTES LES ERREURS
-- ============================================================================
-- 
-- Ce script :
-- 1. Exécute la migration candidate_scoring_views (fonction get_optimized_candidates)
-- 2. Crée votre profil utilisateur si nécessaire
-- 3. Vérifie que tout est OK
--
-- INSTRUCTIONS :
-- 1. Remplacez '8671c159-6689-4cf2-8387-ef491a4fdb42' par votre UUID (ligne 20)
-- 2. Remplacez 'votre_username' par votre username (ligne 21)
-- 3. Remplacez 'Chamonix-Mont-Blanc' par votre station (ligne 22)
-- 4. Exécutez dans Supabase Dashboard > SQL Editor
--
-- ============================================================================

-- ============================================================================
-- ÉTAPE 1 : EXÉCUTER LA MIGRATION CANDIDATE_SCORING_VIEWS
-- ============================================================================

-- Note: Si la migration complète n'a pas été exécutée, exécutez d'abord :
-- supabase/migrations/20250110_candidate_scoring_views.sql
-- Puis continuez avec ce script.

-- Vérifier si la fonction existe déjà
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'get_optimized_candidates'
    ) THEN
        RAISE NOTICE '⚠️ La fonction get_optimized_candidates n''existe pas.';
        RAISE NOTICE '📝 Exécutez d''abord le fichier: supabase/migrations/20250110_candidate_scoring_views.sql';
        RAISE EXCEPTION 'Migration manquante. Exécutez d''abord 20250110_candidate_scoring_views.sql';
    ELSE
        RAISE NOTICE '✅ Fonction get_optimized_candidates trouvée';
    END IF;
END $$;

-- ============================================================================
-- ÉTAPE 2 : CRÉER VOTRE PROFIL UTILISATEUR
-- ============================================================================

DO $$
DECLARE
    -- ⚠️ REMPLACEZ CES VALEURS PAR LES VÔTRES
    v_user_id UUID := '8671c159-6689-4cf2-8387-ef491a4fdb42'::UUID;  -- Votre UUID
    v_username TEXT := 'votre_username';  -- Votre username
    v_station_name TEXT := 'Chamonix-Mont-Blanc';  -- Votre station préférée
    
    v_email TEXT;
    v_station_id UUID;
    v_profile_exists BOOLEAN;
BEGIN
    RAISE NOTICE '🔍 Vérification du profil utilisateur...';
    
    -- Vérifier que l'utilisateur existe dans auth.users
    SELECT email INTO v_email 
    FROM auth.users 
    WHERE id = v_user_id;
    
    IF v_email IS NULL THEN
        RAISE EXCEPTION '❌ L''utilisateur avec l''UUID % n''existe pas dans auth.users. Créez d''abord le compte dans Authentication > Users.', v_user_id;
    END IF;
    
    RAISE NOTICE '✅ Email trouvé : %', v_email;
    
    -- Vérifier si le profil existe déjà
    SELECT EXISTS(SELECT 1 FROM public.users WHERE id = v_user_id) INTO v_profile_exists;
    
    IF v_profile_exists THEN
        RAISE NOTICE 'ℹ️ Profil existant trouvé, mise à jour...';
        
        -- Mettre à jour le profil existant
        UPDATE public.users
        SET 
            username = v_username,
            email = v_email,
            updated_at = NOW(),
            last_active_at = NOW()
        WHERE id = v_user_id;
        
        RAISE NOTICE '✅ Profil mis à jour : %', v_username;
    ELSE
        RAISE NOTICE '📝 Création du nouveau profil...';
        
        -- Créer le profil
        INSERT INTO public.users (
            id,
            username,
            email,
            level,
            ride_styles,
            languages,
            objectives,
            is_active,
            created_at,
            updated_at,
            last_active_at
        ) VALUES (
            v_user_id,
            v_username,
            v_email,
            'intermediate'::user_level,
            ARRAY['alpine']::ride_style[],
            ARRAY['fr', 'en']::language_code[],
            ARRAY[]::TEXT[],
            true,
            NOW(),
            NOW(),
            NOW()
        );
        
        RAISE NOTICE '✅ Profil créé : %', v_username;
    END IF;
    
    -- Trouver la station
    SELECT id INTO v_station_id 
    FROM public.stations 
    WHERE name = v_station_name 
        AND is_active = true 
    LIMIT 1;
    
    IF v_station_id IS NULL THEN
        RAISE WARNING '⚠️ Station "%" non trouvée, utilisation de la première station disponible', v_station_name;
        SELECT id INTO v_station_id 
        FROM public.stations 
        WHERE is_active = true 
        ORDER BY name 
        LIMIT 1;
        
        IF v_station_id IS NOT NULL THEN
            SELECT name INTO v_station_name FROM public.stations WHERE id = v_station_id;
        END IF;
    END IF;
    
    -- Ajouter/mettre à jour la station
    IF v_station_id IS NOT NULL THEN
        INSERT INTO public.user_station_status (
            user_id,
            station_id,
            date_from,
            date_to,
            radius_km,
            is_active
        ) VALUES (
            v_user_id,
            v_station_id,
            CURRENT_DATE,
            CURRENT_DATE + INTERVAL '7 days',
            25,
            true
        )
        ON CONFLICT (user_id, station_id) DO UPDATE
        SET 
            date_from = EXCLUDED.date_from,
            date_to = EXCLUDED.date_to,
            radius_km = EXCLUDED.radius_km,
            is_active = true,
            updated_at = NOW();
        
        RAISE NOTICE '✅ Station configurée : % (du % au %)', 
            v_station_name, 
            CURRENT_DATE, 
            CURRENT_DATE + INTERVAL '7 days';
    ELSE
        RAISE WARNING '⚠️ Aucune station trouvée, station non configurée';
    END IF;
    
    RAISE NOTICE '🎉 Profil utilisateur configuré avec succès !';
END $$;

-- ============================================================================
-- ÉTAPE 3 : VÉRIFICATIONS FINALES
-- ============================================================================

-- Vérifier que la fonction existe
SELECT 
    CASE 
        WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'get_optimized_candidates')
        THEN '✅ Fonction get_optimized_candidates : OK'
        ELSE '❌ Fonction get_optimized_candidates : MANQUANTE'
    END as fonction_status;

-- Vérifier votre profil
SELECT 
    CASE 
        WHEN EXISTS(SELECT 1 FROM public.users WHERE id = '8671c159-6689-4cf2-8387-ef491a4fdb42'::UUID)
        THEN '✅ Profil utilisateur : OK'
        ELSE '❌ Profil utilisateur : MANQUANT'
    END as profil_status;

-- Vérifier votre station
SELECT 
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM public.user_station_status uss
            WHERE uss.user_id = '8671c159-6689-4cf2-8387-ef491a4fdb42'::UUID
                AND uss.is_active = true
        )
        THEN '✅ Station configurée : OK'
        ELSE '❌ Station configurée : MANQUANTE'
    END as station_status;

-- Afficher votre profil complet
SELECT 
    u.id,
    u.username,
    u.email,
    u.level,
    u.ride_styles,
    u.languages,
    u.is_active,
    s.name as station,
    uss.date_from,
    uss.date_to,
    uss.radius_km
FROM public.users u
LEFT JOIN public.user_station_status uss ON u.id = uss.user_id AND uss.is_active = true
LEFT JOIN public.stations s ON uss.station_id = s.id
WHERE u.id = '8671c159-6689-4cf2-8387-ef491a4fdb42'::UUID;

-- Message final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '✅ CORRECTIONS TERMINÉES !';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Prochaines étapes :';
    RAISE NOTICE '1. Vérifiez que les Edge Functions sont déployées';
    RAISE NOTICE '2. Nettoyez Flutter : flutter clean && flutter pub get';
    RAISE NOTICE '3. Relancez l''app : flutter run';
    RAISE NOTICE '';
END $$;

