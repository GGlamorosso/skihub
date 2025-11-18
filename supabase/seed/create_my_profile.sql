-- ============================================================================
-- Créer votre profil utilisateur dans public.users
-- ============================================================================
-- 
-- Ce script crée votre profil dans public.users si vous êtes connecté
-- mais que votre profil n'existe pas encore.
--
-- INSTRUCTIONS :
-- 1. Remplacez '8671c159-6689-4cf2-8387-ef491a4fdb42' par votre UUID
-- 2. Remplacez 'votre_username' par votre username
-- 3. Remplacez 'votre_email@example.com' par votre email
-- 4. Remplacez 'Chamonix-Mont-Blanc' par la station de votre choix
-- 5. Exécutez dans Supabase Dashboard > SQL Editor
--
-- ============================================================================

-- Votre UUID (remplacez-le)
\set user_id '8671c159-6689-4cf2-8387-ef491a4fdb42'

-- Récupérer l'email depuis auth.users
DO $$
DECLARE
    v_user_id UUID := '8671c159-6689-4cf2-8387-ef491a4fdb42'::UUID;
    v_email TEXT;
    v_username TEXT := 'votre_username';  -- ⚠️ REMPLACEZ par votre username
    v_station_name TEXT := 'Chamonix-Mont-Blanc';  -- ⚠️ REMPLACEZ par votre station
    v_station_id UUID;
BEGIN
    -- Vérifier que l'utilisateur existe dans auth.users
    SELECT email INTO v_email 
    FROM auth.users 
    WHERE id = v_user_id;
    
    IF v_email IS NULL THEN
        RAISE EXCEPTION 'L''utilisateur avec l''UUID % n''existe pas dans auth.users', v_user_id;
    END IF;
    
    RAISE NOTICE 'Email trouvé : %', v_email;
    
    -- Créer le profil dans public.users s'il n'existe pas
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
    )
    ON CONFLICT (id) DO UPDATE
    SET 
        username = EXCLUDED.username,
        email = EXCLUDED.email,
        updated_at = NOW(),
        last_active_at = NOW();
    
    RAISE NOTICE '✅ Profil créé/mis à jour pour : %', v_username;
    
    -- Trouver la station
    SELECT id INTO v_station_id 
    FROM public.stations 
    WHERE name = v_station_name 
        AND is_active = true 
    LIMIT 1;
    
    IF v_station_id IS NULL THEN
        RAISE WARNING 'Station "%" non trouvée, utilisation de la première station disponible', v_station_name;
        SELECT id INTO v_station_id 
        FROM public.stations 
        WHERE is_active = true 
        ORDER BY name 
        LIMIT 1;
    END IF;
    
    -- Ajouter la station avec dates
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
        ON CONFLICT DO NOTHING;
        
        RAISE NOTICE '✅ Station configurée : % (du % au %)', 
            v_station_name, 
            CURRENT_DATE, 
            CURRENT_DATE + INTERVAL '7 days';
    ELSE
        RAISE WARNING 'Aucune station trouvée, station non configurée';
    END IF;
    
    RAISE NOTICE '🎉 Profil créé avec succès !';
END $$;

