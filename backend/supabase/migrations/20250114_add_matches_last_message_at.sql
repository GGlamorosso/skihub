-- Migration: Ajouter last_message_at dans matches + index + fonction get_total_unread_count

-- 1. Ajouter colonne last_message_at dans matches
ALTER TABLE matches
ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMPTZ;

-- 2. Créer index pour performance
CREATE INDEX IF NOT EXISTS idx_matches_last_message_at 
ON matches(last_message_at DESC NULLS LAST);

-- 3. Fonction pour obtenir le nombre total de messages non lus
CREATE OR REPLACE FUNCTION get_total_unread_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO v_count
  FROM messages m
  INNER JOIN matches mt ON m.match_id = mt.id
  WHERE (
    (mt.user1_id = p_user_id AND m.sender_id != p_user_id) OR
    (mt.user2_id = p_user_id AND m.sender_id != p_user_id)
  )
  AND m.read_at IS NULL;
  -- Note: deleted_at column may not exist, removed check
  
  RETURN COALESCE(v_count, 0);
END;
$$;

-- 4. Trigger pour mettre à jour last_message_at automatiquement
CREATE OR REPLACE FUNCTION update_match_last_message_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE matches
  SET last_message_at = NEW.created_at
  WHERE id = NEW.match_id;
  -- Note: deleted_at column may not exist, removed check
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_match_last_message_at
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION update_match_last_message_at();

-- 5. Mettre à jour last_message_at pour les messages existants
UPDATE matches m
SET last_message_at = (
  SELECT MAX(created_at)
  FROM messages
  WHERE match_id = m.id
)
WHERE EXISTS (
  SELECT 1
  FROM messages
  WHERE match_id = m.id
);

-- Commentaires
COMMENT ON COLUMN matches.last_message_at IS 'Timestamp du dernier message dans cette conversation';
COMMENT ON FUNCTION get_total_unread_count(UUID) IS 'Retourne le nombre total de messages non lus pour un utilisateur';

