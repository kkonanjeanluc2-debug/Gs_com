/*
  # Système de géolocalisation des commerciaux

  1. Nouvelles Tables
    - `commercial_locations`
      - `id` (uuid, primary key) - Identifiant unique
      - `user_id` (uuid, foreign key) - ID du commercial
      - `company_id` (uuid, foreign key) - ID de l'entreprise
      - `latitude` (numeric) - Latitude GPS
      - `longitude` (numeric) - Longitude GPS
      - `accuracy` (numeric) - Précision en mètres
      - `timestamp` (timestamptz) - Horodatage de la position
      - `is_active` (boolean) - Indique si c'est la position actuelle
      - `activity_type` (text) - Type d'activité (en_visite, en_deplacement, pause, etc.)
      - `created_at` (timestamptz) - Date de création

  2. Sécurité
    - Enable RLS on `commercial_locations` table
    - Les commerciaux peuvent insérer leur propre position
    - Les commerciaux peuvent voir leur propre historique
    - Les admins et superviseurs peuvent voir toutes les positions de leur entreprise
    - Les super admins peuvent tout voir

  3. Index
    - Index sur user_id pour requêtes rapides
    - Index sur company_id pour filtrage par entreprise
    - Index sur timestamp pour récupération chronologique
    - Index sur is_active pour récupérer les positions actuelles

  4. Fonctions
    - Fonction pour désactiver les anciennes positions lors d'une nouvelle insertion
*/

-- Create commercial_locations table
CREATE TABLE IF NOT EXISTS commercial_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  latitude numeric(10, 7) NOT NULL,
  longitude numeric(10, 7) NOT NULL,
  accuracy numeric(10, 2),
  timestamp timestamptz NOT NULL DEFAULT now(),
  is_active boolean DEFAULT true,
  activity_type text DEFAULT 'en_deplacement' CHECK (activity_type IN ('en_visite', 'en_deplacement', 'pause', 'inactif')),
  created_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_commercial_locations_user_id ON commercial_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_commercial_locations_company_id ON commercial_locations(company_id);
CREATE INDEX IF NOT EXISTS idx_commercial_locations_timestamp ON commercial_locations(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_commercial_locations_is_active ON commercial_locations(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_commercial_locations_user_active ON commercial_locations(user_id, is_active) WHERE is_active = true;

-- Function to deactivate old positions before inserting a new one
CREATE OR REPLACE FUNCTION deactivate_old_positions()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE commercial_locations
  SET is_active = false
  WHERE user_id = NEW.user_id
    AND is_active = true
    AND id != NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to deactivate old positions
DROP TRIGGER IF EXISTS trigger_deactivate_old_positions ON commercial_locations;
CREATE TRIGGER trigger_deactivate_old_positions
  AFTER INSERT ON commercial_locations
  FOR EACH ROW
  EXECUTE FUNCTION deactivate_old_positions();

-- Enable RLS
ALTER TABLE commercial_locations ENABLE ROW LEVEL SECURITY;

-- Policy: Commercials can insert their own location
CREATE POLICY "Commercials can insert own location"
  ON commercial_locations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'commercial'
      AND profiles.company_id = commercial_locations.company_id
    )
  );

-- Policy: Users can view locations in their company
CREATE POLICY "Users can view company locations"
  ON commercial_locations
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.company_id = commercial_locations.company_id
      AND profiles.role IN ('admin', 'superviseur')
    )
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );

-- Policy: Users can update their own location status
CREATE POLICY "Users can update own location status"
  ON commercial_locations
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Admins can delete old locations
CREATE POLICY "Admins can delete old locations"
  ON commercial_locations
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.company_id = commercial_locations.company_id
      AND profiles.role = 'admin'
    )
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );