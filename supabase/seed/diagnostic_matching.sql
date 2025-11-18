-- ============================================================================
-- Script de diagnostic pour le matching
-- ============================================================================

-- 1. Vérifier que la fonction get_optimized_candidates existe et fonctionne
DO $$
DECLARE
    test_user_id UUID;
    test_result_count INTEGER;
BEGIN
    -- Prendre le premier utilisateur avec une station active
    SELECT user_id INTO test_user_id
    FROM user_station_status
    WHERE is_active = true
    LIMIT 1;
    
    IF test_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur avec station active trouvé';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test avec user_id: %', test_user_id;
    
    -- Tester get_candidate_scores
    BEGIN
        SELECT COUNT(*) INTO test_result_count
        FROM get_candidate_scores(test_user_id);
        
        RAISE NOTICE '✅ get_candidate_scores retourne % candidats', test_result_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur get_candidate_scores: %', SQLERRM;
    END;
    
    -- Tester get_optimized_candidates
    BEGIN
        SELECT COUNT(*) INTO test_result_count
        FROM get_optimized_candidates(test_user_id, 20, false);
        
        RAISE NOTICE '✅ get_optimized_candidates retourne % candidats', test_result_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur get_optimized_candidates: %', SQLERRM;
    END;
END $$;

-- 2. Vérifier les utilisateurs actifs avec stations
SELECT 
    'Utilisateurs actifs avec stations' as check_name,
    COUNT(DISTINCT uss.user_id) as count
FROM user_station_status uss
JOIN users u ON u.id = uss.user_id
WHERE uss.is_active = true
  AND u.is_active = true
  AND u.is_banned = false;

-- 3. Vérifier les stations actives
SELECT 
    'Stations actives' as check_name,
    COUNT(*) as count
FROM stations
WHERE is_active = true;

-- 4. Vérifier les chevauchements de dates
SELECT 
    'Paires avec dates qui se chevauchent' as check_name,
    COUNT(DISTINCT uss1.user_id || '-' || uss2.user_id) as count
FROM user_station_status uss1
JOIN user_station_status uss2 
    ON uss1.station_id = uss2.station_id
    AND uss1.user_id != uss2.user_id
WHERE uss1.is_active = true
  AND uss2.is_active = true
  AND uss1.date_from <= uss2.date_to
  AND uss2.date_from <= uss1.date_to;

-- 5. Vérifier les utilisateurs qui peuvent matcher (exemple avec un user_id spécifique)
-- Remplacez 'VOTRE_USER_ID' par votre UUID
DO $$
DECLARE
    test_user_id UUID := '8671c159-6689-4cf2-8387-ef491a4fdb42'; -- Remplacez par votre UUID
    candidate_count INTEGER;
BEGIN
    -- Vérifier si l'utilisateur a une station
    IF NOT EXISTS (
        SELECT 1 FROM user_station_status 
        WHERE user_id = test_user_id AND is_active = true
    ) THEN
        RAISE NOTICE '❌ L''utilisateur % n''a pas de station active', test_user_id;
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ L''utilisateur % a une station active', test_user_id;
    
    -- Compter les candidats potentiels
    SELECT COUNT(*) INTO candidate_count
    FROM get_candidate_scores(test_user_id);
    
    RAISE NOTICE '📊 get_candidate_scores retourne % candidats', candidate_count;
    
    -- Tester get_optimized_candidates
    BEGIN
        SELECT COUNT(*) INTO candidate_count
        FROM get_optimized_candidates(test_user_id, 20, false);
        
        RAISE NOTICE '📊 get_optimized_candidates retourne % candidats', candidate_count;
        
        IF candidate_count = 0 THEN
            RAISE NOTICE '⚠️ Aucun candidat trouvé. Raisons possibles :';
            RAISE NOTICE '   - Aucun autre utilisateur à la même station';
            RAISE NOTICE '   - Dates qui ne se chevauchent pas';
            RAISE NOTICE '   - Tous les utilisateurs déjà likés/matchés';
            RAISE NOTICE '   - Distance trop grande';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur get_optimized_candidates: %', SQLERRM;
        RAISE NOTICE '   Détails: %', SQLSTATE;
    END;
END $$;

