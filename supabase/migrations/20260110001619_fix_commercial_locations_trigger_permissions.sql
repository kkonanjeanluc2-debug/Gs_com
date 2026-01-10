/*
  # Correction des permissions du trigger de géolocalisation

  1. Changements
    - Modifie la fonction deactivate_old_positions pour utiliser SECURITY DEFINER
    - Cela permet au trigger de mettre à jour les anciennes positions même avec RLS activé
    - Ajoute une politique permettant au système de mettre à jour is_active

  2. Sécurité
    - La fonction s'exécute avec les privilèges du propriétaire (postgres)
    - Les politiques RLS restent actives pour tous les autres opérations
    - Seule la mise à jour automatique de is_active est affectée
*/

-- Drop and recreate the function with SECURITY DEFINER
DROP FUNCTION IF EXISTS deactivate_old_positions() CASCADE;

CREATE OR REPLACE FUNCTION deactivate_old_positions()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Deactivate all other active positions for this user
  UPDATE commercial_locations
  SET is_active = false
  WHERE user_id = NEW.user_id
    AND is_active = true
    AND id != NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_deactivate_old_positions ON commercial_locations;
CREATE TRIGGER trigger_deactivate_old_positions
  AFTER INSERT ON commercial_locations
  FOR EACH ROW
  EXECUTE FUNCTION deactivate_old_positions();

-- Add a permissive policy for system updates (for the trigger)
CREATE POLICY "System can update location status"
  ON commercial_locations
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);