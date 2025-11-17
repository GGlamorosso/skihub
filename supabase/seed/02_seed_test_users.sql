-- CrewSnow Seed Data - Test Users
-- Description: Sample users for testing the application

-- ============================================================================
-- TEST USERS WITH DIVERSE PROFILES
-- ============================================================================

-- Insert test users with different characteristics for matching testing
INSERT INTO users (
    id,
    username,
    email,
    bio,
    birth_date,
    level,
    ride_styles,
    languages,
    is_premium,
    premium_expires_at,
    verified_video_status,
    is_active
) VALUES
-- Premium advanced skiers
(
    '00000000-0000-0000-0000-000000000001',
    'alpine_alex',
    'alex@example.com',
    'Passionate skier from Chamonix. Love steep slopes and powder days! Always looking for new adventures.',
    '1990-03-15',
    'advanced',
    ARRAY['alpine', 'freeride', 'powder']::ride_style[],
    ARRAY['en', 'fr']::language_code[],
    true,
    NOW() + INTERVAL '1 year',
    'approved',
    true
),
(
    '00000000-0000-0000-0000-000000000002',
    'powder_marie',
    'marie@example.com',
    'Snowboard instructor from Val d''Isère. Love teaching and exploring off-piste areas with experienced riders.',
    '1987-11-22',
    'expert',
    ARRAY['freeride', 'powder', 'freestyle']::ride_style[],
    ARRAY['fr', 'en', 'it']::language_code[],
    true,
    NOW() + INTERVAL '6 months',
    'approved',
    true
),

-- Regular users - various levels
(
    '00000000-0000-0000-0000-000000000003',
    'beginner_tom',
    'tom@example.com',
    'Just started skiing last year. Looking for patient people to ski with and improve my technique!',
    '1995-07-08',
    'beginner',
    ARRAY['alpine']::ride_style[],
    ARRAY['en', 'de']::language_code[],
    false,
    NULL,
    'not_submitted',
    true
),
(
    '00000000-0000-0000-0000-000000000004',
    'park_rider_sam',
    'sam@example.com',
    'Freestyle snowboarder who lives for park sessions. Always down to hit rails and jumps!',
    '1992-01-30',
    'intermediate',
    ARRAY['freestyle', 'park']::ride_style[],
    ARRAY['en']::language_code[],
    false,
    NULL,
    'pending',
    true
),
(
    '00000000-0000-0000-0000-000000000005',
    'touring_julie',
    'julie@example.com',
    'Ski touring enthusiast. Love earning my turns and exploring untouched snow in the backcountry.',
    '1988-09-12',
    'advanced',
    ARRAY['touring', 'freeride']::ride_style[],
    ARRAY['fr', 'de', 'it']::language_code[],
    false,
    NULL,
    'approved',
    true
),
(
    '00000000-0000-0000-0000-000000000006',
    'race_mike',
    'mike@example.com',
    'Former ski racer, now skiing for fun. Still love carving perfect turns on groomed slopes.',
    '1985-05-17',
    'expert',
    ARRAY['racing', 'alpine']::ride_style[],
    ARRAY['en', 'fr']::language_code[],
    true,
    NOW() + INTERVAL '3 months',
    'approved',
    true
),

-- International users for testing language matching
(
    '00000000-0000-0000-0000-000000000007',
    'swiss_anna',
    'anna@example.com',
    'From Zermatt, skiing since I could walk. Love showing visitors the best spots in the Alps.',
    '1990-12-03',
    'expert',
    ARRAY['alpine', 'freeride']::ride_style[],
    ARRAY['de', 'fr', 'en']::language_code[],
    false,
    NULL,
    'approved',
    true
),
(
    '00000000-0000-0000-0000-000000000008',
    'italiano_marco',
    'marco@example.com',
    'Sciatore appassionato dalle Dolomiti. Amo le piste perfettamente preparate e la buona compagnia!',
    '1993-04-26',
    'intermediate',
    ARRAY['alpine', 'moguls']::ride_style[],
    ARRAY['it', 'en']::language_code[],
    false,
    NULL,
    'not_submitted',
    true
),
(
    '00000000-0000-0000-0000-000000000009',
    'spanish_sofia',
    'sofia@example.com',
    'From Madrid but love skiing in the Pyrenees. Always excited to meet new people on the slopes!',
    '1991-08-19',
    'intermediate',
    ARRAY['alpine', 'freestyle']::ride_style[],
    ARRAY['es', 'en', 'fr']::language_code[],
    false,
    NULL,
    'pending',
    true
),

-- Young enthusiastic skiers
(
    '00000000-0000-0000-0000-000000000010',
    'young_emma',
    'emma@example.com',
    'Uni student who spends every weekend on the mountain. Love exploring new resorts and meeting people!',
    '2000-02-14',
    'intermediate',
    ARRAY['alpine', 'freestyle']::ride_style[],
    ARRAY['en', 'fr']::language_code[],
    false,
    NULL,
    'not_submitted',
    true
);

-- ============================================================================
-- USER STATION STATUS - WHERE USERS ARE SKIING
-- ============================================================================

-- Set current/upcoming station status for matching testing
-- Get station IDs for reference
DO $$
DECLARE 
    val_thorens_id UUID;
    chamonix_id UUID;
    val_isere_id UUID;
    courchevel_id UUID;
    zermatt_id UUID;
BEGIN
    -- Get station IDs
    SELECT id INTO val_thorens_id FROM stations WHERE name = 'Val Thorens' LIMIT 1;
    SELECT id INTO chamonix_id FROM stations WHERE name = 'Chamonix' LIMIT 1;
    SELECT id INTO val_isere_id FROM stations WHERE name = 'Val d''Isère' LIMIT 1;
    SELECT id INTO courchevel_id FROM stations WHERE name = 'Courchevel' LIMIT 1;
    SELECT id INTO zermatt_id FROM stations WHERE name = 'Zermatt' LIMIT 1;

    -- Insert user station statuses
    INSERT INTO user_station_status (user_id, station_id, date_from, date_to, radius_km) VALUES
    -- Users currently at Val Thorens
    ('00000000-0000-0000-0000-000000000001', val_thorens_id, CURRENT_DATE - 1, CURRENT_DATE + 5, 25),
    ('00000000-0000-0000-0000-000000000003', val_thorens_id, CURRENT_DATE, CURRENT_DATE + 3, 15),
    ('00000000-0000-0000-0000-000000000010', val_thorens_id, CURRENT_DATE - 2, CURRENT_DATE + 2, 30),
    
    -- Users at Chamonix
    ('00000000-0000-0000-0000-000000000002', chamonix_id, CURRENT_DATE, CURRENT_DATE + 7, 20),
    ('00000000-0000-0000-0000-000000000005', chamonix_id, CURRENT_DATE + 1, CURRENT_DATE + 4, 25),
    
    -- Users at Val d'Isère  
    ('00000000-0000-0000-0000-000000000004', val_isere_id, CURRENT_DATE - 1, CURRENT_DATE + 6, 20),
    ('00000000-0000-0000-0000-000000000006', val_isere_id, CURRENT_DATE + 2, CURRENT_DATE + 8, 15),
    
    -- Users planning to go to Courchevel
    ('00000000-0000-0000-0000-000000000007', courchevel_id, CURRENT_DATE + 10, CURRENT_DATE + 17, 30),
    ('00000000-0000-0000-0000-000000000008', courchevel_id, CURRENT_DATE + 12, CURRENT_DATE + 15, 25),
    
    -- User at Zermatt
    ('00000000-0000-0000-0000-000000000009', zermatt_id, CURRENT_DATE - 3, CURRENT_DATE + 1, 20);
END $$;

-- ============================================================================
-- SAMPLE LIKES FOR MATCHING TESTING
-- ============================================================================

INSERT INTO likes (liker_id, liked_id) VALUES
-- Create some mutual likes (which should create matches)
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003'), -- alex likes tom
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001'), -- tom likes alex back
('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001'), -- emma likes alex
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000010'), -- alex likes emma back

-- One-way likes (no matches yet)
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000005'), -- marie likes julie
('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000006'), -- sam likes mike
('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000008'), -- anna likes marco
('00000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000009'), -- marco likes sofia

-- Create mutual likes between users at Chamonix
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000005'), -- marie likes julie
('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002'); -- julie likes marie back

-- ============================================================================
-- SAMPLE RIDE STATS FOR TRACKING TESTING
-- ============================================================================

-- Add some ride stats for users to test the tracking feature
INSERT INTO ride_stats_daily (user_id, date, station_id, distance_km, vmax_kmh, elevation_gain_m, moving_time_min, runs_count, data_source) VALUES
-- Alex's stats (advanced skier)
('00000000-0000-0000-0000-000000000001', CURRENT_DATE - 3, 
 (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1), 
 45.2, 87.5, 2800, 380, 28, 'gps_track'),
('00000000-0000-0000-0000-000000000001', CURRENT_DATE - 2, 
 (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1), 
 52.8, 92.1, 3200, 420, 31, 'gps_track'),
('00000000-0000-0000-0000-000000000001', CURRENT_DATE - 1, 
 (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1), 
 38.6, 78.9, 2400, 340, 24, 'manual'),

-- Marie's stats (expert snowboarder)  
('00000000-0000-0000-0000-000000000002', CURRENT_DATE - 2, 
 (SELECT id FROM stations WHERE name = 'Chamonix' LIMIT 1), 
 41.3, 85.2, 2950, 365, 19, 'gps_track'),
('00000000-0000-0000-0000-000000000002', CURRENT_DATE - 1, 
 (SELECT id FROM stations WHERE name = 'Chamonix' LIMIT 1), 
 35.7, 79.4, 2200, 290, 16, 'manual'),

-- Tom's stats (beginner)
('00000000-0000-0000-0000-000000000003', CURRENT_DATE - 1, 
 (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1), 
 12.5, 45.2, 800, 280, 8, 'manual'),
('00000000-0000-0000-0000-000000000003', CURRENT_DATE, 
 (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1), 
 18.3, 52.1, 1200, 320, 12, 'manual'),

-- Sam's stats (park rider)
('00000000-0000-0000-0000-000000000004', CURRENT_DATE - 2, 
 (SELECT id FROM stations WHERE name = 'Val d''Isère' LIMIT 1), 
 25.8, 68.7, 1500, 240, 15, 'gps_track'),
('00000000-0000-0000-0000-000000000004', CURRENT_DATE - 1, 
 (SELECT id FROM stations WHERE name = 'Val d''Isère' LIMIT 1), 
 31.2, 72.3, 1800, 280, 18, 'gps_track');

-- ============================================================================
-- UPDATE LAST ACTIVE TIMESTAMPS
-- ============================================================================

-- Set realistic last_active_at times for users
UPDATE users SET last_active_at = NOW() - INTERVAL '5 minutes' WHERE id = '00000000-0000-0000-0000-000000000001';
UPDATE users SET last_active_at = NOW() - INTERVAL '2 hours' WHERE id = '00000000-0000-0000-0000-000000000002';
UPDATE users SET last_active_at = NOW() - INTERVAL '30 minutes' WHERE id = '00000000-0000-0000-0000-000000000003';
UPDATE users SET last_active_at = NOW() - INTERVAL '1 hour' WHERE id = '00000000-0000-0000-0000-000000000004';
UPDATE users SET last_active_at = NOW() - INTERVAL '15 minutes' WHERE id = '00000000-0000-0000-0000-000000000005';
UPDATE users SET last_active_at = NOW() - INTERVAL '3 hours' WHERE id = '00000000-0000-0000-0000-000000000006';
UPDATE users SET last_active_at = NOW() - INTERVAL '45 minutes' WHERE id = '00000000-0000-0000-0000-000000000007';
UPDATE users SET last_active_at = NOW() - INTERVAL '6 hours' WHERE id = '00000000-0000-0000-0000-000000000008';
UPDATE users SET last_active_at = NOW() - INTERVAL '1 day' WHERE id = '00000000-0000-0000-0000-000000000009';
UPDATE users SET last_active_at = NOW() - INTERVAL '20 minutes' WHERE id = '00000000-0000-0000-0000-000000000010';

-- ============================================================================
-- PERFORMANCE OPTIMIZATION
-- ============================================================================

-- Update table statistics after bulk inserts
ANALYZE users;
ANALYZE user_station_status;
ANALYZE likes;
ANALYZE ride_stats_daily;
