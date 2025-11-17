-- ============================================================================
-- CREWSNOW - TESTS RLS RAPIDES
-- ============================================================================
-- Description: Scripts de test RLS pour validation QA rapide
-- Usage: supabase db run --file scripts/test-rls.sql
-- ============================================================================

-- ============================================================================
-- TESTS UTILISATEUR ANONYME (DOIT ÉCHOUER)
-- ============================================================================

\echo '=== TESTS UTILISATEUR ANONYME ==='
\echo 'Les requêtes suivantes doivent retourner 0 lignes ou échouer avec RLS'
\echo ''

-- Test 1: Accès direct table users (DOIT ÉCHOUER)
\echo '1. Test accès direct table users (doit retourner 0 lignes):'
SELECT COUNT(*) as user_count FROM users;
\echo 'Résultat attendu: 0 ou erreur RLS'
\echo ''

-- Test 2: Accès direct table likes (DOIT ÉCHOUER)  
\echo '2. Test accès direct table likes (doit retourner 0 lignes):'
SELECT COUNT(*) as likes_count FROM likes;
\echo 'Résultat attendu: 0 ou erreur RLS'
\echo ''

-- Test 3: Accès direct table messages (DOIT ÉCHOUER)
\echo '3. Test accès direct table messages (doit retourner 0 lignes):'
SELECT COUNT(*) as messages_count FROM messages;
\echo 'Résultat attendu: 0 ou erreur RLS'
\echo ''

-- Test 4: Accès direct table matches (DOIT ÉCHOUER)
\echo '4. Test accès direct table matches (doit retourner 0 lignes):'
SELECT COUNT(*) as matches_count FROM matches;
\echo 'Résultat attendu: 0 ou erreur RLS'
\echo ''

-- Test 5: Accès direct table user_station_status (DOIT ÉCHOUER)
\echo '5. Test accès direct table user_station_status (doit retourner 0 lignes):'
SELECT COUNT(*) as station_status_count FROM user_station_status;
\echo 'Résultat attendu: 0 ou erreur RLS'
\echo ''

-- ============================================================================
-- TESTS UTILISATEUR ANONYME (DOIT RÉUSSIR)
-- ============================================================================

\echo '=== TESTS ACCÈS PUBLIC AUTORISÉ ==='
\echo 'Les requêtes suivantes doivent fonctionner pour les utilisateurs anonymes'
\echo ''

-- Test 6: Vue publique accessible (DOIT RÉUSSIR)
\echo '6. Test vue publique public_profiles_v (doit fonctionner):'
SELECT COUNT(*) as public_profiles_count FROM public_profiles_v;
\echo 'Résultat attendu: > 0 (nombre de profils publics)'
\echo ''

-- Test 7: Stations publiques accessibles (DOIT RÉUSSIR)
\echo '7. Test stations publiques (doit fonctionner):'
SELECT COUNT(*) as stations_count FROM stations;
\echo 'Résultat attendu: > 0 (nombre de stations)'
\echo ''

-- Test 8: Photos approuvées accessibles (DOIT RÉUSSIR)
\echo '8. Test photos approuvées (doit fonctionner):'
SELECT COUNT(*) as approved_photos_count 
FROM profile_photos 
WHERE moderation_status = 'approved';
\echo 'Résultat attendu: >= 0 (photos approuvées)'
\echo ''

-- ============================================================================
-- TESTS ISOLATION CROSS-USER
-- ============================================================================

\echo '=== TESTS ISOLATION CROSS-USER ==='
\echo 'Simulation tests avec différents utilisateurs'
\echo ''

-- Test 9: Vérifier que les policies existent
\echo '9. Vérification policies RLS actives:'
SELECT 
  schemaname,
  tablename,
  COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;
\echo 'Résultat attendu: Chaque table doit avoir au moins 1 policy'
\echo ''

-- Test 10: Vérifier que RLS est activé
\echo '10. Vérification RLS activé sur les tables:'
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename NOT LIKE '%_view'
ORDER BY tablename;
\echo 'Résultat attendu: rowsecurity = t pour toutes les tables'
\echo ''

-- ============================================================================
-- TESTS FONCTIONNELS AVEC DONNÉES DE TEST
-- ============================================================================

\echo '=== TESTS FONCTIONNELS ==='
\echo 'Tests avec les données de seed si disponibles'
\echo ''

-- Test 11: Profils publics avec détails
\echo '11. Échantillon profils publics (top 5):'
SELECT 
  pseudo,
  level,
  ride_styles,
  languages,
  is_premium
FROM public_profiles_v 
LIMIT 5;
\echo ''

-- Test 12: Stations par pays
\echo '12. Stations par pays (top pays):'
SELECT 
  country_code,
  COUNT(*) as station_count
FROM stations 
GROUP BY country_code
ORDER BY station_count DESC
LIMIT 5;
\echo ''

-- Test 13: Photos par statut de modération
\echo '13. Photos par statut de modération:'
SELECT 
  moderation_status,
  COUNT(*) as photo_count
FROM profile_photos 
GROUP BY moderation_status
ORDER BY moderation_status;
\echo 'Note: Seules les photos "approved" sont visibles aux anonymes'
\echo ''

-- ============================================================================
-- TESTS DE SÉCURITÉ AVANCÉS
-- ============================================================================

\echo '=== TESTS SÉCURITÉ AVANCÉS ==='
\echo ''

-- Test 14: Tentative d'injection via vue publique
\echo '14. Test sécurité vue publique:'
SELECT COUNT(*) as safe_count
FROM public_profiles_v 
WHERE pseudo IS NOT NULL;
\echo 'Résultat attendu: Pas d\'erreur, données filtrées automatiquement'
\echo ''

-- Test 15: Vérifier que les colonnes sensibles ne sont pas exposées
\echo '15. Colonnes exposées dans vue publique:'
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'public_profiles_v'
ORDER BY ordinal_position;
\echo 'Résultat attendu: Pas d\'email, birth_date, stripe_customer_id'
\echo ''

-- ============================================================================
-- RÉSUMÉ DES TESTS
-- ============================================================================

\echo '=== RÉSUMÉ DES TESTS RLS ==='
\echo ''
\echo 'Tests effectués:'
\echo '✓ Accès direct tables protégées (doit échouer)'
\echo '✓ Accès vue publique (doit réussir)'  
\echo '✓ Accès stations publiques (doit réussir)'
\echo '✓ Photos approuvées accessibles (doit réussir)'
\echo '✓ Policies RLS présentes et actives'
\echo '✓ Données de test fonctionnelles'
\echo '✓ Sécurité vue publique'
\echo ''
\echo 'VALIDATION MANUELLE REQUISE:'
\echo '1. Tester avec utilisateur authentifié (JWT token)'
\echo '2. Vérifier isolation entre User A et User B'
\echo '3. Tester upload/modération photos'
\echo '4. Valider chat entre utilisateurs matchés'
\echo ''
\echo 'COMMANDES POUR TESTS AUTHENTIFIÉS:'
\echo '-- Se connecter comme utilisateur spécifique:'
\echo '-- SET LOCAL "request.jwt.claims" TO '\''{\"sub\": \"user-uuid-here\"}'\'';'
\echo '-- SELECT * FROM users WHERE id = auth.uid(); -- Doit retourner 1 ligne'
\echo ''

-- ============================================================================
-- FONCTION DE TEST RAPIDE
-- ============================================================================

-- Fonction pour exécuter tous les tests RLS en une fois
CREATE OR REPLACE FUNCTION quick_rls_test()
RETURNS text AS $$
DECLARE
  result text := '';
  user_count integer;
  public_count integer;
  station_count integer;
  policy_count integer;
BEGIN
  result := result || E'=== QUICK RLS TEST RESULTS ===\n\n';
  
  -- Test accès direct users (doit être 0)
  SELECT COUNT(*) INTO user_count FROM users;
  result := result || format('Direct users access: %s rows (should be 0)\n', user_count);
  
  -- Test vue publique (doit être > 0)
  SELECT COUNT(*) INTO public_count FROM public_profiles_v;
  result := result || format('Public profiles view: %s rows (should be > 0)\n', public_count);
  
  -- Test stations publiques (doit être > 0)
  SELECT COUNT(*) INTO station_count FROM stations;
  result := result || format('Public stations: %s rows (should be > 0)\n', station_count);
  
  -- Test policies actives
  SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE schemaname = 'public';
  result := result || format('Active RLS policies: %s (should be ~42)\n', policy_count);
  
  result := result || E'\n';
  
  IF user_count = 0 AND public_count > 0 AND station_count > 0 AND policy_count > 30 THEN
    result := result || E'✅ RLS TEST PASSED: Security is working correctly\n';
  ELSE
    result := result || E'❌ RLS TEST FAILED: Check configuration\n';
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Exécuter le test rapide
\echo '=== QUICK RLS TEST ==='
SELECT quick_rls_test();

\echo '=== TEST RLS TERMINÉ ==='
\echo 'Pour des tests plus approfondis, utilisez:'
\echo 'supabase db run --file supabase/test/run_all_s2_tests.sql'
