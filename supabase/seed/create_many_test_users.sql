-- ============================================================================
-- Créer BEAUCOUP d'utilisateurs de test pour CrewSnow Bêta
-- ============================================================================
-- 
-- Ce script crée 20+ utilisateurs de test avec des profils variés
-- et des dates de séjour différentes pour tester le matching
--
-- INSTRUCTIONS :
-- 1. Créez d'abord les comptes dans Supabase Dashboard > Authentication > Users
-- 2. Notez leurs UUIDs
-- 3. Remplacez les UUIDs ci-dessous (cherchez "REMPLACER_PAR_UUID")
-- 4. Exécutez : supabase db execute --file supabase/seed/create_many_test_users.sql
--
-- ============================================================================

-- Désactiver temporairement le trigger analytics pour éviter les erreurs
ALTER TABLE public.users DISABLE TRIGGER analytics_user_signup;

-- Fonction helper pour créer un utilisateur
CREATE OR REPLACE FUNCTION create_test_user(
    p_user_id UUID,
    p_username VARCHAR,
    p_level user_level,
    p_ride_styles ride_style[],
    p_languages language_code[],
    p_objectives TEXT[],
    p_bio TEXT,
    p_birth_date DATE,
    p_station_name VARCHAR DEFAULT NULL,
    p_date_from DATE DEFAULT CURRENT_DATE,
    p_date_to DATE DEFAULT CURRENT_DATE + INTERVAL '7 days',
    p_radius_km INTEGER DEFAULT 25
) RETURNS VOID AS $$
DECLARE
    v_station_id UUID;
    v_user_exists BOOLEAN;
    v_auth_user_exists BOOLEAN;
    v_email TEXT;
BEGIN
    -- Vérifier que l'utilisateur existe dans auth.users
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = p_user_id) INTO v_auth_user_exists;
    
    IF NOT v_auth_user_exists THEN
        RAISE EXCEPTION 'L''utilisateur avec l''UUID % n''existe pas dans auth.users. Créez d''abord le compte dans Authentication > Users.', p_user_id;
    END IF;
    
    -- Récupérer l'email depuis auth.users
    SELECT email INTO v_email FROM auth.users WHERE id = p_user_id;
    
    -- Vérifier si l'utilisateur existe dans public.users
    SELECT EXISTS(SELECT 1 FROM public.users WHERE id = p_user_id) INTO v_user_exists;
    
    IF NOT v_user_exists THEN
        -- Créer l'utilisateur dans public.users
        INSERT INTO public.users (
            id,
            username,
            email,
            level,
            ride_styles,
            languages,
            objectives,
            bio,
            birth_date,
            is_active,
            last_active_at,
            created_at,
            updated_at
        ) VALUES (
            p_user_id,
            p_username,
            v_email,
            p_level,
            p_ride_styles,
            p_languages,
            p_objectives,
            p_bio,
            p_birth_date,
            true,
            NOW(),
            NOW(),
            NOW()
        );
    ELSE
        -- Mettre à jour le profil existant
        UPDATE public.users 
        SET 
            username = p_username,
            is_active = true,
            level = p_level,
            ride_styles = p_ride_styles,
            languages = p_languages,
            objectives = p_objectives,
            bio = p_bio,
            birth_date = p_birth_date,
            last_active_at = NOW(),
            updated_at = NOW()
        WHERE id = p_user_id;
    END IF;
    
    -- Trouver ou utiliser la station
    IF p_station_name IS NOT NULL THEN
        SELECT id INTO v_station_id 
        FROM public.stations 
        WHERE name = p_station_name AND is_active = true 
        LIMIT 1;
    END IF;
    
    -- Si pas de station spécifique, prendre la première disponible
    IF v_station_id IS NULL THEN
        SELECT id INTO v_station_id 
        FROM public.stations 
        WHERE is_active = true 
        ORDER BY name 
        LIMIT 1;
    END IF;
    
    -- Ajouter la station avec dates
    IF v_station_id IS NOT NULL THEN
        -- Vérifier si un enregistrement existe déjà pour cet utilisateur et cette station
        IF EXISTS (
            SELECT 1 FROM public.user_station_status 
            WHERE user_id = p_user_id AND station_id = v_station_id
        ) THEN
            -- Mettre à jour l'enregistrement existant
            UPDATE public.user_station_status
            SET 
                date_from = p_date_from,
                date_to = p_date_to,
                radius_km = p_radius_km,
                is_active = true,
                updated_at = NOW()
            WHERE user_id = p_user_id AND station_id = v_station_id;
        ELSE
            -- Insérer un nouvel enregistrement
            INSERT INTO public.user_station_status (
                user_id, station_id, date_from, date_to, radius_km, is_active
            )
            VALUES (p_user_id, v_station_id, p_date_from, p_date_to, p_radius_km, true);
        END IF;
    END IF;
    
    RAISE NOTICE '✅ Utilisateur créé : %', p_username;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- UTILISATEURS EXPERT/AVANCÉ (10 utilisateurs)
-- ============================================================================

-- 1. Expert Freeride - Chamonix (semaine prochaine)
SELECT create_test_user(
    '4cab82c6-5828-406f-b047-5c58c076ec30'::UUID,
    'freeride_expert'::VARCHAR,
    'expert'::user_level,
    ARRAY['freeride', 'powder', 'touring']::ride_style[],
    ARRAY['fr', 'en']::language_code[],
    ARRAY['explorer de nouveaux terrains', 'partager ma passion', 'trouver des partenaires expérimentés']::TEXT[],
    'Expert en freeride avec 15 ans d''expérience. Passionné de poudreuse et de ski de randonnée !'::TEXT,
    '1985-03-15'::DATE,
    'Chamonix-Mont-Blanc'::VARCHAR,
    (CURRENT_DATE + INTERVAL '7 days')::DATE,
    (CURRENT_DATE + INTERVAL '14 days')::DATE,
    30::INTEGER
);

-- 2. Expert Alpine - Val d'Isère (cette semaine)
SELECT create_test_user(
    'e2ad92c9-9a5a-4413-a5da-562efbca3d99'::UUID,
    'alpine_master'::VARCHAR,
    'expert'::user_level,
    ARRAY['alpine', 'racing']::ride_style[],
    ARRAY['fr', 'en', 'de']::language_code[],
    ARRAY['améliorer ma technique', 'faire de la vitesse', 'rencontrer des skieurs rapides']::TEXT[],
    'Ancien compétiteur, maintenant je skie pour le plaisir. J''adore les pistes noires et la vitesse !'::TEXT,
    '1982-07-20'::DATE,
    'Val d''Isère'::VARCHAR,
    CURRENT_DATE::DATE,
    (CURRENT_DATE + INTERVAL '7 days')::DATE,
    25::INTEGER
);

-- 3. Expert Snowboard - Courchevel (dans 2 semaines)
SELECT create_test_user(
    '195ede2f-6942-4893-95fd-65ff74fb1292'::UUID,
    'snowboard_pro'::VARCHAR,
    'expert'::user_level,
    ARRAY['freestyle', 'park', 'freeride']::ride_style[],
    ARRAY['fr', 'en', 'es']::language_code[],
    ARRAY['progresser en freestyle', 'rider avec d''autres', 'découvrir de nouveaux spots']::TEXT[],
    'Snowboardeur depuis 12 ans, passionné de freestyle et de park. Toujours partant pour une session ! 🏂'::TEXT,
    '1990-11-08'::DATE,
    'Courchevel'::VARCHAR,
    (CURRENT_DATE + INTERVAL '14 days')::DATE,
    (CURRENT_DATE + INTERVAL '21 days')::DATE,
    30::INTEGER
);

-- 4. Expert Touring - Zermatt (cette semaine)
SELECT create_test_user(
    'df18619e-19f0-4d6d-8ef4-2aa520c968e8'::UUID,
    'touring_enthusiast'::VARCHAR,
    'expert'::user_level,
    ARRAY['touring', 'freeride', 'powder']::ride_style[],
    ARRAY['de', 'fr', 'en']::language_code[],
    ARRAY['explorer le backcountry', 'ski de randonnée', 'découvrir des itinéraires']::TEXT[],
    'Passionné de ski de randonnée et de backcountry. J''adore gagner mes virages !'::TEXT,
    '1987-05-12'::DATE,
    'Zermatt'::VARCHAR,
    CURRENT_DATE::DATE,
    (CURRENT_DATE + INTERVAL '10 days')::DATE,
    40::INTEGER
);

-- 5. Expert Freestyle - Tignes (semaine prochaine)
SELECT create_test_user(
    'e4fad424-2cb1-4910-a249-cf63c48aba44'::UUID,
    'freestyle_king'::VARCHAR,
    'expert'::user_level,
    ARRAY['freestyle', 'park', 'moguls']::ride_style[],
    ARRAY['en', 'fr']::language_code[],
    ARRAY['faire des tricks', 'progresser en park', 's''amuser']::TEXT[],
    'Freestyle skier depuis toujours. Les rails et les jumps, c''est ma vie !'::TEXT,
    '1993-01-25'::DATE,
    'Tignes'::VARCHAR,
    (CURRENT_DATE + INTERVAL '7 days')::DATE,
    (CURRENT_DATE + INTERVAL '14 days')::DATE,
    25::INTEGER
);

-- 6. Avancé Alpine - Les Arcs (cette semaine)
SELECT create_test_user(
    'c2445575-b21d-4ffc-b475-d5625debd45a'::UUID,
    'alpine_lover'::VARCHAR,
    'advanced'::user_level,
    ARRAY['alpine', 'racing']::ride_style[],
    ARRAY['fr', 'en', 'de']::language_code[],
    ARRAY['améliorer ma technique', 'profiter des paysages', 'faire de nouvelles rencontres']::TEXT[],
    'Passionnée de ski alpin ! J''aime découvrir de nouveaux domaines et partager de bons moments ☕️'::TEXT,
    '1988-02-14'::DATE,
    'Les Arcs'::VARCHAR,
    CURRENT_DATE::DATE,
    (CURRENT_DATE + INTERVAL '8 days')::DATE,
    20::INTEGER
);

-- 7. Avancé Freeride - Verbier (dans 3 semaines)
SELECT create_test_user(
    '35be981a-cb06-48e4-a173-fe4316bb88aa'::UUID,
    'powder_seeker'::VARCHAR,
    'advanced'::user_level,
    ARRAY['freeride', 'powder']::ride_style[],
    ARRAY['fr', 'en']::language_code[],
    ARRAY['chercher la poudreuse', 'explorer hors-piste', 'partager des spots']::TEXT[],
    'Toujours à la recherche de la meilleure poudreuse ! Passionné de hors-piste sécurisé.'::TEXT,
    '1991-09-30'::DATE,
    'Verbier'::VARCHAR,
    (CURRENT_DATE + INTERVAL '21 days')::DATE,
    (CURRENT_DATE + INTERVAL '28 days')::DATE,
    35::INTEGER
);

-- 8. Avancé Snowboard - St. Anton (cette semaine)
SELECT create_test_user(
    '4e57a5f8-0781-4db6-93f9-d25a3fb62bad'::UUID,
    'snowboard_advanced'::VARCHAR,
    'advanced'::user_level,
    ARRAY['freeride', 'freestyle']::ride_style[],
    ARRAY['de', 'en', 'fr']::language_code[],
    ARRAY['progresser en snowboard', 'découvrir de nouveaux spots', 'rider avec d''autres']::TEXT[],
    'Snowboardeur avancé, j''adore explorer les domaines et rencontrer d''autres riders !'::TEXT,
    '1989-12-05'::DATE,
    'St. Anton'::VARCHAR,
    CURRENT_DATE::DATE,
    (CURRENT_DATE + INTERVAL '6 days')::DATE,
    30::INTEGER
);

-- 9. Avancé Alpine - Courchevel (semaine prochaine)
SELECT create_test_user(
    '36232b95-1aaf-4efb-a1c0-b6e5ca019f4e'::UUID,
    'ski_advanced'::VARCHAR,
    'advanced'::user_level,
    ARRAY['alpine', 'moguls']::ride_style[],
    ARRAY['fr', 'en']::language_code[],
    ARRAY['améliorer ma technique', 'skier sur tous les terrains', 'rencontrer des skieurs']::TEXT[],
    'Skieur confirmé, j''aime varier les plaisirs : pistes, bosses, tout me plaît !'::TEXT,
    '1986-04-18'::DATE,
    'Courchevel'::VARCHAR,
    (CURRENT_DATE + INTERVAL '7 days')::DATE,
    (CURRENT_DATE + INTERVAL '14 days')::DATE,
    25::INTEGER
);

-- 10. Avancé Touring - Chamonix (dans 2 semaines)
SELECT create_test_user(
    '59e4d0f6-1829-4725-b8df-484ea1af33b2'::UUID,
    'backcountry_lover'::VARCHAR,
    'advanced'::user_level,
    ARRAY['touring', 'freeride']::ride_style[],
    ARRAY['fr', 'en', 'it']::language_code[],
    ARRAY['ski de randonnée', 'explorer le backcountry', 'partager des itinéraires']::TEXT[],
    'Passionné de ski de randonnée et de montagne. Toujours prêt pour une sortie !'::TEXT,
    '1992-08-22'::DATE,
    'Chamonix-Mont-Blanc'::VARCHAR,
    (CURRENT_DATE + INTERVAL '14 days')::DATE,
    (CURRENT_DATE + INTERVAL '21 days')::DATE,
    40::INTEGER
);

-- ============================================================================
-- UTILISATEURS INTERMÉDIAIRES (8 utilisateurs)
-- ============================================================================

-- 11. Intermédiaire Alpine - Val d'Isère (cette semaine)
SELECT create_test_user(
    'd12b10ec-b1c3-4daf-99e3-3d1a2c010328'::UUID,
    'intermediate_skier'::VARCHAR,
    'intermediate'::user_level,
    ARRAY['alpine']::ride_style[],
    ARRAY['fr', 'en']::language_code[],
    ARRAY['progresser', 'découvrir de nouvelles pistes', 'rencontrer des gens']::TEXT[],
    'Skieur intermédiaire, j''aime découvrir de nouveaux domaines et progresser !'::TEXT,
    '1994-06-10'::DATE,
    'Val d''Isère'::VARCHAR,
    CURRENT_DATE::DATE,
    (CURRENT_DATE + INTERVAL '5 days')::DATE,
    20::INTEGER
);

-- 12. Intermédiaire Snowboard - Tignes (semaine prochaine)
SELECT create_test_user(
    '4b1c5448-eb3a-4e85-b700-d0a678e1464d'::UUID,
    'snowboard_intermediate'::VARCHAR,
    'intermediate'::user_level,
    ARRAY['freestyle', 'park']::ride_style[],
    ARRAY['en', 'fr']::language_code[],
    ARRAY['apprendre des tricks', 'progresser', 's''amuser']::TEXT[],
    'Snowboardeur intermédiaire, je commence à m''amuser en park !'::TEXT,
    '1996-03-15'::DATE,
    'Tignes'::VARCHAR,
    (CURRENT_DATE + INTERVAL '7 days')::DATE,
    (CURRENT_DATE + INTERVAL '12 days')::DATE,
    25::INTEGER
);

-- 13. Intermédiaire Alpine - Les Arcs (cette semaine)
SELECT create_test_user(
    'd09f3145-e62e-4424-8d8e-1bfb235983b8'::UUID,
    'weekend_skier'::VARCHAR,
    'intermediate'::user_level,
    ARRAY['alpine']::ride_style[],
    ARRAY['fr']::language_code[],
    ARRAY['passer un bon week-end', 'skier avec des amis', 'profiter']::TEXT[],
    'Je skie le week-end pour me détendre et passer de bons moments !'::TEXT,
    '1995-11-28'::DATE,
    'Les Arcs'::VARCHAR,
    CURRENT_DATE::DATE,
    (CURRENT_DATE + INTERVAL '3 days')::DATE,
    15::INTEGER
);

-- 14. Intermédiaire Freestyle - Courchevel (dans 2 semaines)
SELECT create_test_user(
    'ab008180-cdde-4e16-8d3f-e45c717aa6e1'::UUID,
    'park_rider'::VARCHAR,
    'intermediate'::user_level,
    ARRAY['freestyle', 'park']::ride_style[],
    ARRAY['en', 'fr']::language_code[],
    ARRAY['progresser en park', 'apprendre des tricks', 's''amuser']::TEXT[],
    'Passionné de park et de freestyle ! Toujours partant pour rider !'::TEXT,
    '1997-07-04'::DATE,
    'Courchevel'::VARCHAR,
    (CURRENT_DATE + INTERVAL '14 days')::DATE,
    (CURRENT_DATE + INTERVAL '21 days')::DATE,
    20::INTEGER
);

-- 15. Intermédiaire Alpine - Zermatt (cette semaine)
SELECT create_test_user(
    'af7fff88-75eb-4c85-ac19-fe8812353e7e'::UUID,
    'alpine_intermediate'::VARCHAR,
    'intermediate'::user_level,
    ARRAY['alpine', 'moguls']::ride_style[],
    ARRAY['de', 'en', 'fr']::language_code[],
    ARRAY['améliorer ma technique', 'découvrir de nouveaux domaines', 'rencontrer']::TEXT[],
    'Skieur intermédiaire passionné, j''adore découvrir de nouveaux domaines !'::TEXT,
    '1993-09-12'::DATE,
    'Zermatt'::VARCHAR,
    CURRENT_DATE::DATE,
    (CURRENT_DATE + INTERVAL '6 days')::DATE,
    25::INTEGER
);

-- 16. Intermédiaire Snowboard - Verbier (semaine prochaine)
SELECT create_test_user(
    '6d828329-1b97-4884-9a98-3752b4751a8a'::UUID,
    'snowboard_weekend'::VARCHAR,
    'intermediate'::user_level,
    ARRAY['freestyle']::ride_style[],
    ARRAY['fr', 'en']::language_code[],
    ARRAY['passer un bon séjour', 'rider avec d''autres', 'découvrir']::TEXT[],
    'Snowboardeur intermédiaire, j''aime rider et rencontrer d''autres passionnés !'::TEXT,
    '1994-12-20'::DATE,
    'Verbier'::VARCHAR,
    (CURRENT_DATE + INTERVAL '7 days')::DATE,
    (CURRENT_DATE + INTERVAL '14 days')::DATE,
    20::INTEGER
);

-- 17. Intermédiaire Alpine - St. Anton (cette semaine)
SELECT create_test_user(
    '97721e4c-077c-40fa-933d-90fa0a4a7051'::UUID,
    'ski_intermediate'::VARCHAR,
    'intermediate'::user_level,
    ARRAY['alpine']::ride_style[],
    ARRAY['de', 'en']::language_code[],
    ARRAY['progresser', 'découvrir', 'rencontrer']::TEXT[],
    'Skieur intermédiaire enthousiaste, toujours prêt pour de nouvelles aventures !'::TEXT,
    '1996-02-08'::DATE,
    'St. Anton'::VARCHAR,
    CURRENT_DATE::DATE,
    (CURRENT_DATE + INTERVAL '5 days')::DATE,
    20::INTEGER
);

-- 18. Intermédiaire Freestyle - Chamonix (dans 3 semaines)
SELECT create_test_user(
    '09c65d6b-a7f9-496e-903b-56ffb401b71d'::UUID,
    'freestyle_intermediate'::VARCHAR,
    'intermediate'::user_level,
    ARRAY['freestyle', 'park']::ride_style[],
    ARRAY['fr', 'en']::language_code[],
    ARRAY['apprendre en park', 'progresser', 's''amuser']::TEXT[],
    'Freestyle skier intermédiaire, j''adore le park et apprendre de nouveaux tricks !'::TEXT,
    '1995-05-25'::DATE,
    'Chamonix-Mont-Blanc'::VARCHAR,
    (CURRENT_DATE + INTERVAL '21 days')::DATE,
    (CURRENT_DATE + INTERVAL '28 days')::DATE,
    25::INTEGER
);

-- ============================================================================
-- UTILISATEURS DÉBUTANTS (4 utilisateurs)
-- ============================================================================

-- 19. Débutant Alpine - Val d'Isère (cette semaine)
SELECT create_test_user(
    '6b5fc934-a86d-47ba-9c92-0bfe218b70c9'::UUID,
    'ski_newbie'::VARCHAR,
    'beginner'::user_level,
    ARRAY['alpine']::ride_style[],
    ARRAY['fr']::language_code[],
    ARRAY['apprendre les bases', 'rencontrer des gens', 'découvrir de belles pistes']::TEXT[],
    'Tout nouveau dans le monde du ski ! Très motivé pour apprendre 😊'::TEXT,
    '1995-07-22'::DATE,
    'Val d''Isère'::VARCHAR,
    CURRENT_DATE::DATE,
    (CURRENT_DATE + INTERVAL '7 days')::DATE,
    15::INTEGER
);

-- 20. Débutant Snowboard - Courchevel (semaine prochaine)
SELECT create_test_user(
    '6a8b1463-49c5-4351-8eee-491700e8c4a3'::UUID,
    'snowboard_beginner'::VARCHAR,
    'beginner'::user_level,
    ARRAY['freestyle']::ride_style[],
    ARRAY['en', 'fr']::language_code[],
    ARRAY['apprendre le snowboard', 'rencontrer des gens', 's''amuser']::TEXT[],
    'Débutant en snowboard, très motivé pour apprendre et progresser !'::TEXT,
    '1998-10-15'::DATE,
    'Courchevel'::VARCHAR,
    (CURRENT_DATE + INTERVAL '7 days')::DATE,
    (CURRENT_DATE + INTERVAL '14 days')::DATE,
    15::INTEGER
);

-- 21. Débutant Alpine - Les Arcs (cette semaine)
SELECT create_test_user(
    '598cef4d-9228-4c62-bbee-b72431ab3d48'::UUID,
    'beginner_skier'::VARCHAR,
    'beginner'::user_level,
    ARRAY['alpine']::ride_style[],
    ARRAY['fr']::language_code[],
    ARRAY['apprendre à skier', 'rencontrer des débutants', 'passer un bon moment']::TEXT[],
    'Tout nouveau skieur, j''aimerais rencontrer d''autres débutants pour apprendre ensemble !'::TEXT,
    '1997-01-30'::DATE,
    'Les Arcs'::VARCHAR,
    CURRENT_DATE::DATE,
    (CURRENT_DATE + INTERVAL '4 days')::DATE,
    15::INTEGER
);

-- 22. Débutant Alpine - Tignes (dans 2 semaines)
SELECT create_test_user(
    'dbf5cc07-cafe-40cb-89e8-c3d1ef958854'::UUID,
    'new_skier'::VARCHAR,
    'beginner'::user_level,
    ARRAY['alpine']::ride_style[],
    ARRAY['en', 'fr']::language_code[],
    ARRAY['découvrir le ski', 'apprendre', 'rencontrer']::TEXT[],
    'Première fois au ski ! Très excité de découvrir ce sport incroyable !'::TEXT,
    '1999-04-18'::DATE,
    'Tignes'::VARCHAR,
    (CURRENT_DATE + INTERVAL '14 days')::DATE,
    (CURRENT_DATE + INTERVAL '21 days')::DATE,
    15::INTEGER
);

-- ============================================================================
-- NETTOYAGE ET VÉRIFICATION
-- ============================================================================

-- Supprimer la fonction helper
DROP FUNCTION IF EXISTS create_test_user(UUID, VARCHAR, user_level, ride_style[], language_code[], TEXT[], TEXT, DATE, VARCHAR, DATE, DATE, INTEGER);

-- Vérification finale
SELECT 
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE level = 'expert') as experts,
    COUNT(*) FILTER (WHERE level = 'advanced') as advanced,
    COUNT(*) FILTER (WHERE level = 'intermediate') as intermediate,
    COUNT(*) FILTER (WHERE level = 'beginner') as beginners
FROM public.users 
WHERE is_active = true
    AND username IN (
        'freeride_expert', 'alpine_master', 'snowboard_pro', 'touring_enthusiast',
        'freestyle_king', 'alpine_lover', 'powder_seeker', 'snowboard_advanced',
        'ski_advanced', 'backcountry_lover', 'intermediate_skier', 'snowboard_intermediate',
        'weekend_skier', 'park_rider', 'alpine_intermediate', 'snowboard_weekend',
        'ski_intermediate', 'freestyle_intermediate', 'ski_newbie', 'snowboard_beginner',
        'beginner_skier', 'new_skier'
    );

-- Afficher les utilisateurs avec leurs dates de séjour
SELECT 
    u.username,
    u.level,
    s.name as station,
    uss.date_from,
    uss.date_to,
    uss.radius_km
FROM public.users u
JOIN public.user_station_status uss ON u.id = uss.user_id AND uss.is_active = true
JOIN public.stations s ON uss.station_id = s.id
WHERE u.is_active = true
ORDER BY u.level DESC, u.username;

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '🎉 22 utilisateurs de test créés avec des dates de séjour variées !';
    RAISE NOTICE '📅 Les dates sont réparties sur plusieurs semaines pour tester le matching temporel.';
END $$;

-- Réactiver le trigger analytics
ALTER TABLE public.users ENABLE TRIGGER analytics_user_signup;

