-- CrewSnow Performance Optimization - Week 8
-- 3. Optimisation des performances selon spécifications

-- ============================================================================
-- ANALYSE REQUÊTES LENTES ET OPTIMISATION
-- ============================================================================

-- Extension pour monitoring requêtes
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Fonction analyse requêtes lentes avec EXPLAIN ANALYZE
CREATE OR REPLACE FUNCTION analyze_slow_queries()
RETURNS TABLE (
    query_hash TEXT,
    query_snippet TEXT,
    calls BIGINT,
    total_time_ms DECIMAL,
    avg_time_ms DECIMAL,
    max_time_ms DECIMAL,
    optimization_suggestion TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        LEFT(md5(pss.query), 12) as query_hash,
        LEFT(pss.query, 100) || '...' as query_snippet,
        pss.calls,
        ROUND(pss.total_exec_time, 2) as total_time_ms,
        ROUND(pss.mean_exec_time, 2) as avg_time_ms,
        ROUND(pss.max_exec_time, 2) as max_time_ms,
        CASE 
            WHEN pss.mean_exec_time > 1000 THEN 'CRITICAL: Consider index optimization or query rewrite'
            WHEN pss.mean_exec_time > 500 THEN 'WARNING: Monitor and consider optimization'
            WHEN pss.mean_exec_time > 200 THEN 'INFO: Performance acceptable but could be improved'
            ELSE 'GOOD: Performance within targets'
        END as optimization_suggestion
    FROM pg_stat_statements pss
    WHERE pss.calls > 10 -- Only frequent queries
        AND pss.mean_exec_time > 50 -- Only slow queries
    ORDER BY pss.mean_exec_time DESC, pss.total_exec_time DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- INDEX MANQUANTS DÉTECTION
-- ============================================================================

-- Fonction détection index manquants
CREATE OR REPLACE FUNCTION suggest_missing_indexes()
RETURNS TABLE (
    table_name TEXT,
    column_suggestions TEXT,
    index_type TEXT,
    priority VARCHAR(10),
    create_statement TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Messages table optimizations
    SELECT 
        'messages'::TEXT,
        'sender_id, created_at'::TEXT,
        'BTREE'::TEXT,
        'HIGH'::VARCHAR(10),
        'CREATE INDEX IF NOT EXISTS idx_messages_sender_time ON messages (sender_id, created_at DESC);'::TEXT
    WHERE NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'messages' AND indexname = 'idx_messages_sender_time'
    )
    
    UNION ALL
    
    -- Likes table for collaborative filtering
    SELECT 
        'likes'::TEXT,
        'created_at, liker_id'::TEXT, 
        'BTREE'::TEXT,
        'MEDIUM'::VARCHAR(10),
        'CREATE INDEX IF NOT EXISTS idx_likes_time_liker ON likes (created_at DESC, liker_id);'::TEXT
    WHERE NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'likes' AND indexname = 'idx_likes_time_liker'
    )
    
    UNION ALL
    
    -- User station status spatial
    SELECT 
        'user_station_status'::TEXT,
        'location_geom (spatial)'::TEXT,
        'GIST'::TEXT,
        'HIGH'::VARCHAR(10),
        'CREATE INDEX IF NOT EXISTS idx_uss_location_spatial ON user_station_status USING GIST(location_geom) WHERE is_active = true;'::TEXT
    WHERE NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'user_station_status' AND indexname = 'idx_uss_location_spatial'
    )
    
    UNION ALL
    
    -- Analytics events performance
    SELECT 
        'analytics_events'::TEXT,
        'properties (JSON)'::TEXT,
        'GIN'::TEXT,
        'MEDIUM'::VARCHAR(10),
        'CREATE INDEX IF NOT EXISTS idx_analytics_properties ON analytics_events USING GIN(properties);'::TEXT
    WHERE NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'analytics_events' AND indexname = 'idx_analytics_properties'
    );
END;
$$ LANGUAGE plpgsql;

-- Exécuter suggestions index
DO $$
DECLARE
    index_suggestion RECORD;
BEGIN
    FOR index_suggestion IN SELECT * FROM suggest_missing_indexes() LOOP
        EXECUTE index_suggestion.create_statement;
        RAISE NOTICE 'Created index: %', index_suggestion.create_statement;
    END LOOP;
END $$;

-- ============================================================================
-- PARTITIONING POUR TABLES VOLUMINEUSES
-- ============================================================================

-- Partitioning messages par mois selon spécifications
CREATE TABLE IF NOT EXISTS messages_partitioned (
    LIKE messages INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- Fonction création partitions automatique
CREATE OR REPLACE FUNCTION create_monthly_partitions(
    table_name TEXT,
    start_date DATE DEFAULT CURRENT_DATE,
    months_ahead INTEGER DEFAULT 3
) RETURNS INTEGER AS $$
DECLARE
    partition_date DATE;
    partition_name TEXT;
    partition_count INTEGER := 0;
    i INTEGER;
BEGIN
    FOR i IN 0..months_ahead LOOP
        partition_date := DATE_TRUNC('month', start_date + INTERVAL '1 month' * i)::DATE;
        partition_name := table_name || '_y' || EXTRACT(year FROM partition_date) || 'm' || LPAD(EXTRACT(month FROM partition_date)::text, 2, '0');
        
        BEGIN
            EXECUTE format(
                'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I 
                 FOR VALUES FROM (%L) TO (%L)',
                partition_name,
                table_name,
                partition_date,
                partition_date + INTERVAL '1 month'
            );
            partition_count := partition_count + 1;
            RAISE NOTICE 'Created partition: %', partition_name;
        EXCEPTION
            WHEN duplicate_table THEN
                RAISE NOTICE 'Partition % already exists', partition_name;
        END;
    END LOOP;
    
    RETURN partition_count;
END;
$$ LANGUAGE plpgsql;

-- Créer partitions pour analytics_events
ALTER TABLE analytics_events 
RENAME TO analytics_events_base;

CREATE TABLE analytics_events (
    LIKE analytics_events_base INCLUDING ALL
) PARTITION BY RANGE (timestamp);

-- Créer partitions initiales
SELECT create_monthly_partitions('analytics_events', CURRENT_DATE - INTERVAL '1 month', 6);

-- ============================================================================
-- POOLING ET CONNECTION OPTIMIZATION
-- ============================================================================

-- Vue monitoring connexions
CREATE OR REPLACE VIEW connection_monitoring AS
SELECT 
    state,
    COUNT(*) as connection_count,
    MAX(query_start) as oldest_query_start,
    AVG(EXTRACT(epoch FROM (NOW() - query_start))) as avg_query_duration_seconds
FROM pg_stat_activity 
WHERE state IS NOT NULL
GROUP BY state
ORDER BY connection_count DESC;

-- Fonction monitoring performance
CREATE OR REPLACE FUNCTION performance_health_check()
RETURNS TABLE (
    metric VARCHAR(50),
    current_value TEXT,
    threshold TEXT,
    status VARCHAR(20),
    recommendation TEXT
) AS $$
DECLARE
    active_connections INTEGER;
    avg_query_time DECIMAL;
    slow_queries INTEGER;
    materialized_view_lag INTERVAL;
BEGIN
    -- Check active connections
    SELECT COUNT(*) INTO active_connections 
    FROM pg_stat_activity WHERE state = 'active';
    
    -- Check average query time
    SELECT AVG(mean_exec_time) INTO avg_query_time 
    FROM pg_stat_statements WHERE calls > 10;
    
    -- Check slow queries
    SELECT COUNT(*) INTO slow_queries 
    FROM pg_stat_statements WHERE mean_exec_time > 1000;
    
    -- Check materialized view freshness
    SELECT NOW() - (
        SELECT MAX(date) FROM kpi_activation_mv
    ) INTO materialized_view_lag;
    
    RETURN QUERY VALUES
    ('Active Connections', active_connections::TEXT, '<50', 
     CASE WHEN active_connections < 50 THEN 'OK' ELSE 'WARNING' END,
     CASE WHEN active_connections >= 50 THEN 'Consider connection pooling' ELSE 'Normal' END),
    
    ('Avg Query Time', ROUND(avg_query_time, 2)::TEXT || 'ms', '<200ms',
     CASE WHEN avg_query_time < 200 THEN 'OK' ELSE 'WARNING' END,
     CASE WHEN avg_query_time >= 200 THEN 'Review slow queries and add indexes' ELSE 'Performance good' END),
    
    ('Slow Queries', slow_queries::TEXT, '<10',
     CASE WHEN slow_queries < 10 THEN 'OK' ELSE 'CRITICAL' END,  
     CASE WHEN slow_queries >= 10 THEN 'Urgent optimization needed' ELSE 'Query performance acceptable' END),
    
    ('KPI Freshness', materialized_view_lag::TEXT, '<2 hours',
     CASE WHEN materialized_view_lag < INTERVAL '2 hours' THEN 'OK' ELSE 'WARNING' END,
     CASE WHEN materialized_view_lag >= INTERVAL '2 hours' THEN 'Check cron job and refresh process' ELSE 'KPIs up to date' END);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- OPTIMIZATION MAINTENANCE
-- ============================================================================

-- Fonction maintenance automatique
CREATE OR REPLACE FUNCTION run_performance_maintenance()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    analyze_result TEXT;
    vacuum_result TEXT;
BEGIN
    result_text := E'🔧 PERFORMANCE MAINTENANCE\n========================\n\n';
    
    -- Update table statistics
    ANALYZE users, matches, messages, likes, user_station_status;
    result_text := result_text || E'✅ Table statistics updated\n';
    
    -- Vacuum critical tables
    VACUUM ANALYZE daily_usage;
    VACUUM ANALYZE analytics_events;
    result_text := result_text || E'✅ Critical tables vacuumed\n';
    
    -- Refresh KPIs
    SELECT refresh_all_kpi_views() INTO analyze_result;
    result_text := result_text || E'✅ KPI views refreshed: ' || analyze_result || E'\n';
    
    -- Cleanup old data
    DELETE FROM slow_query_log WHERE timestamp < NOW() - INTERVAL '30 days';
    DELETE FROM analytics_events WHERE timestamp < NOW() - INTERVAL '90 days';
    result_text := result_text || E'✅ Old analytics data cleaned\n';
    
    result_text := result_text || E'\n🎯 Performance maintenance completed\n';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Planifier maintenance quotidienne
SELECT cron.schedule('performance-maintenance', '0 2 * * *', 'SELECT run_performance_maintenance();');

-- ============================================================================
-- COMPLETION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '⚡ Week 8 Performance Optimization Complete!';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Features implemented:';
    RAISE NOTICE '  ✅ Slow query monitoring and analysis';
    RAISE NOTICE '  ✅ Missing index detection and creation';
    RAISE NOTICE '  ✅ Table partitioning for analytics_events';
    RAISE NOTICE '  ✅ Connection monitoring and health checks';
    RAISE NOTICE '  ✅ Automated maintenance with pg_cron';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Monitoring commands:';
    RAISE NOTICE '  • Performance: SELECT * FROM performance_health_check();';
    RAISE NOTICE '  • Slow queries: SELECT * FROM analyze_slow_queries();';
    RAISE NOTICE '  • Connections: SELECT * FROM connection_monitoring;';
    RAISE NOTICE '  • Missing indexes: SELECT * FROM suggest_missing_indexes();';
END $$;
