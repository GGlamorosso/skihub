-- ============================================================================
-- CREWSNOW - TESTS PERFORMANCE RAPIDES
-- ============================================================================
-- Description: Scripts de test performance pour validation QA rapide
-- Usage: supabase db run --file scripts/test-perf.sql
-- ============================================================================

-- ============================================================================
-- CONFIGURATION TESTS
-- ============================================================================

-- Activer l'affichage des plans d'exécution et timings
\timing on

-- Variables de test
\set test_user_id '00000000-0000-0000-0000-000000000001'
\set target_time_ms 100

\echo '=== TESTS PERFORMANCE CREWSNOW ==='
\echo 'Objectif: Requêtes critiques < 100ms'
\echo 'Requêtes complexes < 300ms'
\echo ''

-- ============================================================================
-- TEST 1: LIKES PERFORMANCE (< 100ms)
-- ============================================================================

\echo '1. TEST LIKES PERFORMANCE'
\echo '========================='
\echo ''

\echo '1a. "Qui m\'a liké" (doit utiliser likes_liked_id_idx):'
EXPLAIN (ANALYZE, BUFFERS)
SELECT l.*, u.username as liker_username
FROM likes l
JOIN users u ON u.id = l.liker_id
WHERE l.liked_id = :'test_user_id'
ORDER BY l.created_at DESC;

\echo ''
\echo '1b. "Mes likes envoyés" (doit utiliser likes_liker_id_idx):'
EXPLAIN (ANALYZE, BUFFERS)
SELECT l.*, u.username as liked_username
FROM likes l
JOIN users u ON u.id = l.liked_id
WHERE l.liker_id = :'test_user_id'
ORDER BY l.created_at DESC;

\echo ''

-- ============================================================================
-- TEST 2: MESSAGES PERFORMANCE (< 100ms)
-- ============================================================================

\echo '2. TEST MESSAGES PERFORMANCE'
\echo '============================'
\echo ''

-- Obtenir un match_id de test
\echo '2a. Messages pagination (doit utiliser messages_match_created_desc_idx):'
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.*, u.username as sender_username
FROM messages m
JOIN users u ON u.id = m.sender_id
WHERE m.match_id = (SELECT id FROM matches LIMIT 1)
ORDER BY m.created_at DESC
LIMIT 50;

\echo ''
\echo '2b. Comptage messages par match:'
EXPLAIN (ANALYZE, BUFFERS)
SELECT match_id, COUNT(*) as message_count
FROM messages
WHERE match_id IN (SELECT id FROM matches LIMIT 5)
GROUP BY match_id;

\echo ''

-- ============================================================================
-- TEST 3: MATCHING ALGORITHM PERFORMANCE (< 300ms)
-- ============================================================================

\echo '3. TEST MATCHING ALGORITHM'
\echo '========================='
\echo ''

\echo '3a. Utilisateurs par ride style (doit utiliser GIN index):'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, username, ride_styles
FROM users
WHERE ride_styles @> ARRAY['alpine']::ride_style[]
  AND is_active = true 
  AND is_banned = false
LIMIT 20;

\echo ''
\echo '3b. Utilisateurs par langue (doit utiliser GIN index):'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, username, languages
FROM users
WHERE languages @> ARRAY['en']::language_code[]
  AND is_active = true 
  AND is_banned = false
LIMIT 20;

\echo ''
\echo '3c. Matching par station et date:'
EXPLAIN (ANALYZE, BUFFERS)
SELECT uss.*, u.username, s.name as station_name
FROM user_station_status uss
JOIN users u ON u.id = uss.user_id
JOIN stations s ON s.id = uss.station_id
WHERE uss.station_id = (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1)
  AND uss.date_from <= CURRENT_DATE + 7
  AND uss.date_to >= CURRENT_DATE
ORDER BY uss.date_from;

\echo ''

-- ============================================================================
-- TEST 4: VUE PUBLIQUE PERFORMANCE (< 200ms)
-- ============================================================================

\echo '4. TEST VUE PUBLIQUE PERFORMANCE'
\echo '================================'
\echo ''

\echo '4a. Vue publique avec filtres:'
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM public_profiles_v
WHERE station_id IS NOT NULL
  AND ride_styles @> ARRAY['alpine']::ride_style[]
  AND languages @> ARRAY['en']::language_code[]
LIMIT 20;

\echo ''
\echo '4b. Vue publique par station:'
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.*, s.name as station_name
FROM public_profiles_v p
JOIN stations s ON s.id = p.station_id
WHERE s.country_code = 'FR'
LIMIT 30;

\echo ''

-- ============================================================================
-- TEST 5: MODÉRATION QUEUE PERFORMANCE (< 100ms)
-- ============================================================================

\echo '5. TEST MODÉRATION PERFORMANCE'
\echo '=============================='
\echo ''

\echo '5a. Queue photos pending (doit utiliser index partiel):'
EXPLAIN (ANALYZE, BUFFERS)
SELECT pp.*, u.username
FROM profile_photos pp
JOIN users u ON u.id = pp.user_id
WHERE pp.moderation_status = 'pending'
ORDER BY pp.created_at
LIMIT 50;

\echo ''
\echo '5b. Review photos rejected:'
EXPLAIN (ANALYZE, BUFFERS)
SELECT pp.*, u.username, pp.moderation_reason
FROM profile_photos pp
JOIN users u ON u.id = pp.user_id
WHERE pp.moderation_status = 'rejected'
ORDER BY pp.updated_at DESC
LIMIT 20;

\echo ''

-- ============================================================================
-- TEST 6: FONCTIONS UTILITAIRES PERFORMANCE
-- ============================================================================

\echo '6. TEST FONCTIONS UTILITAIRES'
\echo '============================='
\echo ''

\echo '6a. Fonction get_potential_matches:'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM get_potential_matches(:'test_user_id', 20);

\echo ''
\echo '6b. Fonction find_users_at_station:'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM find_users_at_station(
  (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1),
  50,
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '7 days'
);

\echo ''

-- ============================================================================
-- TEST 7: INDEX USAGE VERIFICATION
-- ============================================================================

\echo '7. VÉRIFICATION USAGE INDEX'
\echo '==========================='
\echo ''

\echo '7a. Index les plus utilisés:'
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan as scans,
  idx_tup_read as tuples_read,
  idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND idx_scan > 0
ORDER BY idx_scan DESC
LIMIT 10;

\echo ''
\echo '7b. Index inutilisés (0 scans):'
SELECT 
  schemaname,
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND idx_scan = 0
  AND indexname NOT LIKE '%_pkey'
ORDER BY pg_relation_size(indexrelid) DESC;

\echo ''

-- ============================================================================
-- TEST 8: PERFORMANCE BENCHMARKS AUTOMATISÉS
-- ============================================================================

-- Fonction de benchmark automatisé
CREATE OR REPLACE FUNCTION quick_performance_test()
RETURNS text AS $$
DECLARE
  result text := '';
  start_time timestamp;
  end_time timestamp;
  duration_ms numeric;
  test_user_id uuid := '00000000-0000-0000-0000-000000000001';
  test_match_id uuid;
  row_count integer;
BEGIN
  result := result || E'=== QUICK PERFORMANCE TEST RESULTS ===\n\n';
  
  -- Get test match ID
  SELECT id INTO test_match_id FROM matches LIMIT 1;
  
  -- Test 1: Likes "who liked me"
  start_time := clock_timestamp();
  SELECT COUNT(*) INTO row_count FROM likes WHERE liked_id = test_user_id;
  end_time := clock_timestamp();
  duration_ms := EXTRACT(MILLISECONDS FROM (end_time - start_time));
  
  result := result || format('Likes "who liked me": %.2f ms (%s rows)', duration_ms, row_count);
  IF duration_ms < 100 THEN
    result := result || E' ✅ PASS\n';
  ELSE
    result := result || E' ❌ SLOW\n';
  END IF;
  
  -- Test 2: Messages pagination
  IF test_match_id IS NOT NULL THEN
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO row_count 
    FROM messages 
    WHERE match_id = test_match_id
    ORDER BY created_at DESC 
    LIMIT 50;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(MILLISECONDS FROM (end_time - start_time));
    
    result := result || format('Messages pagination: %.2f ms (%s rows)', duration_ms, row_count);
    IF duration_ms < 100 THEN
      result := result || E' ✅ PASS\n';
    ELSE
      result := result || E' ❌ SLOW\n';
    END IF;
  END IF;
  
  -- Test 3: Public view
  start_time := clock_timestamp();
  SELECT COUNT(*) INTO row_count FROM public_profiles_v LIMIT 20;
  end_time := clock_timestamp();
  duration_ms := EXTRACT(MILLISECONDS FROM (end_time - start_time));
  
  result := result || format('Public profiles view: %.2f ms (%s rows)', duration_ms, row_count);
  IF duration_ms < 200 THEN
    result := result || E' ✅ PASS\n';
  ELSE
    result := result || E' ❌ SLOW\n';
  END IF;
  
  -- Test 4: Ride styles search
  start_time := clock_timestamp();
  SELECT COUNT(*) INTO row_count 
  FROM users 
  WHERE ride_styles @> ARRAY['alpine']::ride_style[]
    AND is_active = true;
  end_time := clock_timestamp();
  duration_ms := EXTRACT(MILLISECONDS FROM (end_time - start_time));
  
  result := result || format('Ride styles search: %.2f ms (%s rows)', duration_ms, row_count);
  IF duration_ms < 300 THEN
    result := result || E' ✅ PASS\n';
  ELSE
    result := result || E' ❌ SLOW\n';
  END IF;
  
  result := result || E'\n=== PERFORMANCE SUMMARY ===\n';
  result := result || E'✅ PASS: Query under target time\n';
  result := result || E'❌ SLOW: Query over target time\n';
  result := result || E'\nTargets: Likes/Messages < 100ms, Complex < 300ms\n';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

\echo '8. BENCHMARK AUTOMATISÉ'
\echo '======================='
\echo ''

SELECT quick_performance_test();

-- ============================================================================
-- ANALYSE INDEX EFFECTIVENESS
-- ============================================================================

\echo '9. ANALYSE EFFECTIVENESS INDEX'
\echo '=============================='
\echo ''

-- Utiliser la fonction d'analyse si elle existe
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'check_index_effectiveness') THEN
    RAISE NOTICE 'Analyse effectiveness index:';
    PERFORM check_index_effectiveness();
  ELSE
    RAISE NOTICE 'Fonction check_index_effectiveness non disponible';
  END IF;
END $$;

-- ============================================================================
-- RECOMMANDATIONS PERFORMANCE
-- ============================================================================

\echo ''
\echo '=== RECOMMANDATIONS PERFORMANCE ==='
\echo ''
\echo 'Index attendus pour performance optimale:'
\echo '- likes_liked_id_idx (who liked me)'
\echo '- likes_liker_id_idx (my sent likes)'
\echo '- messages_match_created_desc_idx (chat pagination)'
\echo '- users_ride_styles_gin_idx (ride style search)'
\echo '- users_languages_gin_idx (language search)'
\echo '- profile_photos_pending_idx (moderation queue)'
\echo ''
\echo 'Plans d\'exécution attendus:'
\echo '- Index Scan ou Bitmap Index Scan'
\echo '- JAMAIS Seq Scan sur tables volumineuses'
\echo '- Buffer hits > 95% pour données fréquentes'
\echo ''
\echo 'Si performance insuffisante:'
\echo '1. Vérifier que les index sont créés'
\echo '2. Exécuter ANALYZE sur les tables'
\echo '3. Vérifier les statistiques avec pg_stat_user_indexes'
\echo '4. Considérer REINDEX si nécessaire'
\echo ''
\echo 'Pour tests plus approfondis:'
\echo 'supabase db run --file supabase/test/s2_performance_benchmarks.sql'

\timing off

\echo ''
\echo '=== TEST PERFORMANCE TERMINÉ ==='
