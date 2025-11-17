-- Migration: Ajouter colonne is_active à la table stations
-- Cette colonne permet de filtrer les stations actives/inactives

ALTER TABLE public.stations
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- Mettre toutes les stations existantes comme actives (si elles n'ont pas de valeur)
UPDATE public.stations
SET is_active = true
WHERE is_active IS NULL;

-- Index pour performance (stations actives uniquement)
CREATE INDEX IF NOT EXISTS idx_stations_is_active 
ON public.stations(is_active) 
WHERE is_active = true;

-- Commentaire
COMMENT ON COLUMN public.stations.is_active IS 'Indique si la station est active et visible dans l''app';

