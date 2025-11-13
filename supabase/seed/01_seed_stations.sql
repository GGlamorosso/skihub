-- CrewSnow Seed Data - Ski Stations
-- Description: Popular ski stations in Europe for testing and initial data

-- ============================================================================
-- MAJOR FRENCH SKI RESORTS
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
-- SPANISH SKI RESORTS (Pyrenees)
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

-- ============================================================================
-- PERFORMANCE NOTE
-- ============================================================================

-- Update statistics after bulk insert for optimal query performance
ANALYZE stations;
