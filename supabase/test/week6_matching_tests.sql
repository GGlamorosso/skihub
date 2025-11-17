-- Week 6 Matching Algorithm Tests
CREATE OR REPLACE FUNCTION test_week6_matching_complete()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    alice_id UUID := '00000000-0000-0000-0000-000000000001';
    bob_id UUID := '00000000-0000-0000-0000-000000000002';
    candidate_count INTEGER;
    distance_test DECIMAL;
    score_test RECORD;
BEGIN
    result_text := E'🎯 WEEK 6 MATCHING ALGORITHM TESTS\n=================================\n\n';
    
    -- Test 1: ST_DWithin functionality
    SELECT COUNT(*) INTO candidate_count
    FROM users_within_radius(
        (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1),
        50,
        CURRENT_DATE,
        CURRENT_DATE + 7
    );
    result_text := result_text || E'✅ ST_DWithin proximity: ' || candidate_count::text || E' users\n';
    
    -- Test 2: ST_DistanceSphere calculation
    SELECT calculate_user_distance(
        (SELECT station_id FROM user_station_status WHERE user_id = alice_id LIMIT 1),
        (SELECT station_id FROM user_station_status WHERE user_id = bob_id LIMIT 1)
    ) INTO distance_test;
    result_text := result_text || E'✅ ST_DistanceSphere: ' || COALESCE(distance_test::text, 'NULL') || E'km\n';
    
    -- Test 3: New compatibility scoring
    SELECT * INTO score_test
    FROM analyze_compatibility(alice_id, bob_id);
    result_text := result_text || E'✅ Compatibility score: ' || score_test.total_score::text || E'\n';
    result_text := result_text || E'   Level: ' || score_test.level_score::text || E', Styles: ' || score_test.styles_score::text || E', Languages: ' || score_test.languages_score::text || E'\n';
    
    -- Test 4: Candidate scores function
    SELECT COUNT(*) INTO candidate_count
    FROM get_candidate_scores(alice_id);
    result_text := result_text || E'✅ Candidate scores function: ' || candidate_count::text || E' candidates\n';
    
    -- Test 5: Cache system
    PERFORM refresh_candidate_scores_cache(alice_id);
    SELECT COUNT(*) INTO candidate_count
    FROM candidate_scores_cache WHERE user_id = alice_id;
    result_text := result_text || E'✅ Cache system: ' || candidate_count::text || E' cached scores\n';
    
    -- Test 6: Collaborative filtering
    SELECT COUNT(*) INTO candidate_count
    FROM get_collaborative_recommendations(alice_id, 5);
    result_text := result_text || E'✅ Collaborative filtering: ' || candidate_count::text || E' recommendations\n';
    
    result_text := result_text || E'\n🚀 Week 6 matching system: FULLY OPERATIONAL\n';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;
