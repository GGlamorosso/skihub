-- Migration: Ajouter colonne objectives à la table users
-- Cette colonne est utilisée dans le code Flutter pour stocker les objectifs de l'utilisateur

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS objectives TEXT[] DEFAULT ARRAY[]::TEXT[];

-- Commentaire
COMMENT ON COLUMN public.users.objectives IS 'Objectifs de l''utilisateur (ex: "rencontrer des gens", "améliorer ma technique", etc.)';

