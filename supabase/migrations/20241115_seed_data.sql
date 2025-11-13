-- CrewSnow Migration - Seed Data (Stations & Test Users)
-- Description: Populates initial reference data and sample users for testing
-- Note: This migration consolidates the contents of supabase/seed/01_seed_stations.sql
--       and supabase/seed/02_seed_test_users.sql so that remote environments
--       receive the same baseline dataset.

-- ============================================================================
-- STATIONS SEED DATA
-- ============================================================================

INSERT INTO stations (name, country_code, region, latitude, longitude, elevation_m, official_website, season_start_month, season_end_month) VALUES
-- Les 3 Vallées
('Val Thorens', 'FR', 'Savoie', 45.2979, 6.5799, 2300, 'https://www.valthorens.com', 11, 5),
('Courchevel', 'FR', 'Savoie', 45.4168, 6.6344, 1850, 'https://www.courchevel.com', 12, 4),
('Méribel', 'FR', 'Savoie', 45.3847, 6.5694, 1450, 'https://www.meribel.net', 12, 4),
('Les Menuires', 'FR', 'Savoie', 45.3142, 6.5358, 1850, 'https://www.lesmenuires.com', 12, 4),
('La Tania', 'FR', 'Savoie', 45.4333, 6.6000, 1400, 'https://www.la-tania.com', 12, 4),

-- Espace Killy
('Val d''Isère', 'FR', 'Savoie', 45.4487, 6.9797, 1850, 'https://www.valdisere.com', 11, 5),
('Tignes', 'FR', 'Savoie', 45.4667, 6.9069, 2100, 'https://www.tignes.net', 10, 5),

-- Paradiski
('La Plagne', 'FR', 'Savoie', 45.5147, 6.6753, 1970, 'https://www.la-plagne.com', 12, 4),
('Les Arcs', 'FR', 'Savoie', 45.5736, 6.8100, 1600, 'https://www.lesarcs.com', 12, 4),

-- Chamonix Valley
('Chamonix', 'FR', 'Haute-Savoie', 45.9237, 6.8694, 1035, 'https://www.chamonix.com', 12, 4),
('Argentière', 'FR', 'Haute-Savoie', 45.9833, 6.9333, 1252, 'https://www.chamonix.com', 12, 4),

-- Other major French resorts
('Alpe d''Huez', 'FR', 'Isère', 45.0906, 6.0728, 1860, 'https://www.alpedhuez.com', 12, 4),
('Les Deux Alpes', 'FR', 'Isère', 45.0139, 6.1244, 1650, 'https://www.les2alpes.com', 12, 4),
('La Clusaz', 'FR', 'Haute-Savoie', 45.9044, 6.4233, 1100, 'https://www.laclusaz.com', 12, 4),
('Le Grand-Bornand', 'FR', 'Haute-Savoie', 45.9431, 6.4267, 1000, 'https://www.legrandbornand.com', 12, 4),
('Megève', 'FR', 'Haute-Savoie', 45.8564, 6.6167, 1113, 'https://www.megeve.com', 12, 4),
('Avoriaz', 'FR', 'Haute-Savoie', 46.1922, 6.7697, 1800, 'https://www.avoriaz.com', 12, 4),
('Morzine', 'FR', 'Haute-Savoie', 46.1789, 6.7086, 1000, 'https://www.morzine-avoriaz.com', 12, 4),
('Flaine', 'FR', 'Haute-Savoie', 46.0089, 6.6969, 1600, 'https://www.flaine.com', 12, 4),

-- ============================================================================
-- MAJOR SWISS SKI RESORTS
-- ============================================================================

('Zermatt', 'CH', 'Valais', 46.0207, 7.7491, 1620, 'https://www.zermatt.ch', 11, 4),
('St. Moritz', 'CH', 'Graubünden', 46.4908, 9.8355, 1856, 'https://www.stmoritz.com', 12, 4),
('Verbier', 'CH', 'Valais', 46.0964, 7.2283, 1500, 'https://www.verbier.ch', 12, 4),
('Davos', 'CH', 'Graubünden', 46.8039, 9.8339, 1560, 'https://www.davos.ch', 12, 4),
('Saas-Fee', 'CH', 'Valais', 46.1081, 7.9286, 1800, 'https://www.saas-fee.ch', 12, 4),
('Engelberg', 'CH', 'Obwalden', 46.8189, 8.4039, 1020, 'https://www.engelberg.ch', 12, 4),
('Andermatt', 'CH', 'Uri', 46.6361, 8.5944, 1444, 'https://www.andermatt.ch', 12, 4),
('Laax', 'CH', 'Graubünden', 46.7944, 9.2597, 1100, 'https://www.laax.com', 12, 4),

-- ============================================================================
-- MAJOR AUSTRIAN SKI RESORTS
-- ============================================================================

('St. Anton am Arlberg', 'AT', 'Tirol', 47.1269, 10.2608, 1304, 'https://www.stantonamarlberg.com', 12, 4),
('Innsbruck', 'AT', 'Tirol', 47.2692, 11.4041, 574, 'https://www.innsbruck.info', 12, 4),
('Kitzbühel', 'AT', 'Tirol', 47.4467, 12.3833, 762, 'https://www.kitzbuehel.com', 12, 4),
('Sölden', 'AT', 'Tirol', 46.9686, 11.0094, 1368, 'https://www.soelden.com', 10, 5),
('Salzburg', 'AT', 'Salzburg', 47.8095, 13.0550, 424, 'https://www.salzburg.info', 12, 4),
('Bad Gastein', 'AT', 'Salzburg', 47.1158, 13.1344, 1002, 'https://www.badgastein.at', 12, 4),

-- ============================================================================
-- MAJOR ITALIAN SKI RESORTS
-- ============================================================================

('Cortina d''Ampezzo', 'IT', 'Veneto', 46.5369, 12.1350, 1224, 'https://www.cortinadampezzo.it', 12, 4),
('Val Gardena', 'IT', 'Alto Adige', 46.5569, 11.6744, 1563, 'https://www.valgardena.it', 12, 4),
('Madonna di Campiglio', 'IT', 'Trentino', 46.2272, 10.8278, 1522, 'https://www.campiglio.it', 12, 4),
('Cervinia', 'IT', 'Aosta', 45.9331, 7.6306, 2050, 'https://www.cervinia.it', 11, 5),
('Livigno', 'IT', 'Lombardia', 46.5367, 10.1344, 1816, 'https://www.livigno.eu', 11, 5),
('Courmayeur', 'IT', 'Aosta', 45.7972, 6.9681, 1224, 'https://www.courmayeur.it', 12, 4),

-- ============================================================================
-- ANDORRAN SKI RESORTS
-- ============================================================================

('Grandvalira', 'AD', 'Andorra', 42.5397, 1.6561, 1710, 'https://www.grandvalira.com', 12, 4),
('Vallnord', 'AD', 'Andorra', 42.6011, 1.4875, 1550, 'https://www.vallnord.com', 12, 4),

-- ============================================================================
-- SPANISH SKI RESORTS
-- ============================================================================

('Baqueira Beret', 'ES', 'Cataluña', 42.7833, 0.9333, 1500, 'https://www.baqueira.es', 12, 4),
('Formigal', 'ES', 'Aragón', 42.7739, -0.3711, 1550, 'https://www.formigal.com', 12, 4),
('Sierra Nevada', 'ES', 'Andalucía', 37.0978, -3.3944, 2100, 'https://www.sierranevada.es', 12, 4),

-- ============================================================================
-- GERMAN SKI RESORTS
-- ============================================================================

('Garmisch-Partenkirchen', 'DE', 'Bayern', 47.4922, 11.0955, 708, 'https://www.garmisch-partenkirchen.de', 12, 4),
('Oberstdorf', 'DE', 'Bayern', 47.4097, 10.2761, 813, 'https://www.oberstdorf.de', 12, 4),

-- ============================================================================
-- SCANDINAVIAN SKI RESORTS
-- ============================================================================

('Åre', 'SE', 'Jämtland', 63.3983, 13.0819, 380, 'https://www.skistar.com/are', 12, 4),
('Trysil', 'NO', 'Hedmark', 61.3167, 12.2667, 540, 'https://www.trysil.no', 12, 4),
('Lillehammer', 'NO', 'Oppland', 61.1153, 10.4661, 180, 'https://www.lillehammer.com', 12, 4),

-- ============================================================================
-- EASTERN EUROPE SKI RESORTS
-- ============================================================================

('Zakopane', 'PL', 'Małopolska', 49.2992, 19.9496, 838, 'https://www.zakopane.pl', 12, 3),
('Bansko', 'BG', 'Blagoevgrad', 41.8350, 23.4892, 925, 'https://www.bansko.bg', 12, 4),
('Jasná', 'SK', 'Žilina', 48.9500, 19.6167, 1200, 'https://www.jasna.sk', 12, 4);

-- Update statistics after bulk insert for optimal query performance
ANALYZE stations;

-- ============================================================================
-- TEST USERS & ACTIVITY DATA
-- ============================================================================

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
('00000000-0000-0000-0000-000000000001', 'alpine_alex', 'alex@example.com', 'Passionate skier from Chamonix. Love steep slopes and powder days! Always looking for new adventures.', '1990-03-15', 'advanced', ARRAY['alpine', 'freeride', 'powder']::ride_style[], ARRAY['en', 'fr']::language_code[], true, NOW() + INTERVAL '1 year', 'approved', true),
('00000000-0000-0000-0000-000000000002', 'powder_marie', 'marie@example.com', 'Snowboard instructor from Val d''Isère. Love teaching and exploring off-piste areas with experienced riders.', '1987-11-22', 'expert', ARRAY['freeride', 'powder', 'freestyle']::ride_style[], ARRAY['fr', 'en', 'it']::language_code[], true, NOW() + INTERVAL '6 months', 'approved', true),
('00000000-0000-0000-0000-000000000003', 'beginner_tom', 'tom@example.com', 'Just started skiing last year. Looking for patient people to ski with and improve my technique!', '1995-07-08', 'beginner', ARRAY['alpine']::ride_style[], ARRAY['en', 'de']::language_code[], false, NULL, 'not_submitted', true),
('00000000-0000-0000-0000-000000000004', 'park_rider_sam', 'sam@example.com', 'Freestyle snowboarder who lives for park sessions. Always down to hit rails and jumps!', '1992-01-30', 'intermediate', ARRAY['freestyle', 'park']::ride_style[], ARRAY['en']::language_code[], false, NULL, 'pending', true),
('00000000-0000-0000-0000-000000000005', 'touring_julie', 'julie@example.com', 'Ski touring enthusiast. Love earning my turns and exploring untouched snow in the backcountry.', '1988-09-12', 'advanced', ARRAY['touring', 'freeride']::ride_style[], ARRAY['fr', 'de', 'it']::language_code[], false, NULL, 'approved', true),
('00000000-0000-0000-0000-000000000006', 'race_mike', 'mike@example.com', 'Former ski racer, now skiing for fun. Still love carving perfect turns on groomed slopes.', '1985-05-17', 'expert', ARRAY['racing', 'alpine']::ride_style[], ARRAY['en', 'fr']::language_code[], true, NOW() + INTERVAL '3 months', 'approved', true),
('00000000-0000-0000-0000-000000000007', 'swiss_anna', 'anna@example.com', 'From Zermatt, skiing since I could walk. Love showing visitors the best spots in the Alps.', '1990-12-03', 'expert', ARRAY['alpine', 'freeride']::ride_style[], ARRAY['de', 'fr', 'en']::language_code[], false, NULL, 'approved', true),
('00000000-0000-0000-0000-000000000008', 'italiano_marco', 'marco@example.com', 'Sciatore appassionato dalle Dolomiti. Amo le piste perfettamente preparate e la buona compagnia!', '1993-04-26', 'intermediate', ARRAY['alpine', 'moguls']::ride_style[], ARRAY['it', 'en']::language_code[], false, NULL, 'not_submitted', true),
('00000000-0000-0000-0000-000000000009', 'spanish_sofia', 'sofia@example.com', 'From Madrid but love skiing in the Pyrenees. Always excited to meet new people on the slopes!', '1991-08-19', 'intermediate', ARRAY['alpine', 'freestyle']::ride_style[], ARRAY['es', 'en', 'fr']::language_code[], false, NULL, 'pending', true),
('00000000-0000-0000-0000-000000000010', 'young_emma', 'emma@example.com', 'Uni student who spends every weekend on the mountain. Love exploring new resorts and meeting people!', '2000-02-14', 'intermediate', ARRAY['alpine', 'freestyle']::ride_style[], ARRAY['en', 'fr']::language_code[], false, NULL, 'not_submitted', true);

-- ============================================================================
-- USER STATION STATUS
-- ============================================================================

DO $$
DECLARE 
    val_thorens_id UUID;
    chamonix_id UUID;
    val_isere_id UUID;
    courchevel_id UUID;
    zermatt_id UUID;
BEGIN
    SELECT id INTO val_thorens_id FROM stations WHERE name = 'Val Thorens' LIMIT 1;
    SELECT id INTO chamonix_id FROM stations WHERE name = 'Chamonix' LIMIT 1;
    SELECT id INTO val_isere_id FROM stations WHERE name = 'Val d''Isère' LIMIT 1;
    SELECT id INTO courchevel_id FROM stations WHERE name = 'Courchevel' LIMIT 1;
    SELECT id INTO zermatt_id FROM stations WHERE name = 'Zermatt' LIMIT 1;

    INSERT INTO user_station_status (user_id, station_id, date_from, date_to, radius_km) VALUES
    ('00000000-0000-0000-0000-000000000001', val_thorens_id, CURRENT_DATE - 1, CURRENT_DATE + 5, 25),
    ('00000000-0000-0000-0000-000000000003', val_thorens_id, CURRENT_DATE, CURRENT_DATE + 3, 15),
    ('00000000-0000-0000-0000-000000000010', val_thorens_id, CURRENT_DATE - 2, CURRENT_DATE + 2, 30),
    ('00000000-0000-0000-0000-000000000002', chamonix_id, CURRENT_DATE, CURRENT_DATE + 7, 20),
    ('00000000-0000-0000-0000-000000000005', chamonix_id, CURRENT_DATE + 1, CURRENT_DATE + 4, 25),
    ('00000000-0000-0000-0000-000000000004', val_isere_id, CURRENT_DATE - 1, CURRENT_DATE + 6, 20),
    ('00000000-0000-0000-0000-000000000006', val_isere_id, CURRENT_DATE + 2, CURRENT_DATE + 8, 15),
    ('00000000-0000-0000-0000-000000000007', courchevel_id, CURRENT_DATE + 10, CURRENT_DATE + 17, 30),
    ('00000000-0000-0000-0000-000000000008', courchevel_id, CURRENT_DATE + 12, CURRENT_DATE + 15, 25),
    ('00000000-0000-0000-0000-000000000009', zermatt_id, CURRENT_DATE - 3, CURRENT_DATE + 1, 20);
END $$;

-- ============================================================================
-- LIKES & MATCHES DATA
-- ============================================================================

-- Temporarily disable trigger to avoid ambiguity during seed data insertion
ALTER TABLE likes DISABLE TRIGGER trigger_create_match_on_like;

INSERT INTO likes (liker_id, liked_id) VALUES
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003'),
('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000010'),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000005'),
('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000006'),
('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000008'),
('00000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000009'),
('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002');

-- Manually create matches from mutual likes
INSERT INTO matches (user1_id, user2_id, created_at) VALUES
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', NOW()),
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000010', NOW()),
('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000005', NOW());

-- Re-enable trigger for future operations
ALTER TABLE likes ENABLE TRIGGER trigger_create_match_on_like;

-- ============================================================================
-- RIDE STATS DATA
-- ============================================================================

INSERT INTO ride_stats_daily (user_id, date, station_id, distance_km, vmax_kmh, elevation_gain_m, moving_time_min, runs_count, data_source) VALUES
('00000000-0000-0000-0000-000000000001', CURRENT_DATE - 3, (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1), 45.2, 87.5, 2800, 380, 28, 'gps_track'),
('00000000-0000-0000-0000-000000000001', CURRENT_DATE - 2, (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1), 52.8, 92.1, 3200, 420, 31, 'gps_track'),
('00000000-0000-0000-0000-000000000001', CURRENT_DATE - 1, (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1), 38.6, 78.9, 2400, 340, 24, 'manual'),
('00000000-0000-0000-0000-000000000002', CURRENT_DATE - 2, (SELECT id FROM stations WHERE name = 'Chamonix' LIMIT 1), 41.3, 85.2, 2950, 365, 19, 'gps_track'),
('00000000-0000-0000-0000-000000000002', CURRENT_DATE - 1, (SELECT id FROM stations WHERE name = 'Chamonix' LIMIT 1), 35.7, 79.4, 2200, 290, 16, 'manual'),
('00000000-0000-0000-0000-000000000003', CURRENT_DATE - 1, (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1), 12.5, 45.2, 800, 280, 8, 'manual'),
('00000000-0000-0000-0000-000000000003', CURRENT_DATE, (SELECT id FROM stations WHERE name = 'Val Thorens' LIMIT 1), 18.3, 52.1, 1200, 320, 12, 'manual'),
('00000000-0000-0000-0000-000000000004', CURRENT_DATE - 2, (SELECT id FROM stations WHERE name = 'Val d''Isère' LIMIT 1), 25.8, 68.7, 1500, 240, 15, 'gps_track'),
('00000000-0000-0000-0000-000000000004', CURRENT_DATE - 1, (SELECT id FROM stations WHERE name = 'Val d''Isère' LIMIT 1), 31.2, 72.3, 1800, 280, 18, 'gps_track');

-- ============================================================================
-- UPDATE LAST ACTIVE TIMESTAMPS
-- ============================================================================

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

-- Update statistics after inserts
ANALYZE users;
ANALYZE user_station_status;
ANALYZE likes;
ANALYZE ride_stats_daily;

