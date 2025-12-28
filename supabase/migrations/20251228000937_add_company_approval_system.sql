/*
  # Système d'Approbation des Entreprises

  1. Modifications de la Table Companies
    - Ajout de la colonne `approved` (booléen) pour gérer l'approbation
    - Ajout de la colonne `approved_at` (timestamp) pour enregistrer la date d'approbation
    - Ajout de la colonne `approved_by` (uuid) pour enregistrer qui a approuvé
    - Par défaut, les nouvelles entreprises sont en attente (approved = false)

  2. Nouveau Rôle Super Admin
    - Ajout du rôle 'super_admin' pour le développeur
    - Ce rôle a accès à toutes les entreprises pour les gérer

  3. Politiques RLS
    - Les super admins peuvent voir toutes les entreprises
    - Les autres utilisateurs ne voient que leur entreprise

  4. Fonction de Vérification
    - Fonction pour vérifier si une entreprise est approuvée
*/

-- Ajouter les colonnes d'approbation à la table companies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'approved'
  ) THEN
    ALTER TABLE companies ADD COLUMN approved boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'approved_at'
  ) THEN
    ALTER TABLE companies ADD COLUMN approved_at timestamptz;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'approved_by'
  ) THEN
    ALTER TABLE companies ADD COLUMN approved_by uuid REFERENCES auth.users(id);
  END IF;
END $$;

-- Approuver les entreprises existantes par défaut
UPDATE companies 
SET approved = true, approved_at = now() 
WHERE approved IS NULL OR approved = false;

-- Créer un index pour les requêtes d'approbation
CREATE INDEX IF NOT EXISTS idx_companies_approved ON companies(approved);

-- Fonction pour vérifier si une entreprise est approuvée
CREATE OR REPLACE FUNCTION is_company_approved(company_uuid uuid)
RETURNS boolean AS $$
DECLARE
  is_approved boolean;
BEGIN
  SELECT approved INTO is_approved
  FROM companies
  WHERE id = company_uuid;
  
  RETURN COALESCE(is_approved, false);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Fonction pour obtenir toutes les entreprises (pour super admin)
CREATE OR REPLACE FUNCTION get_all_companies()
RETURNS TABLE (
  id uuid,
  name text,
  email text,
  phone text,
  address text,
  logo_url text,
  approved boolean,
  approved_at timestamptz,
  created_at timestamptz,
  user_count bigint
) AS $$
BEGIN
  -- Vérifier que l'utilisateur est super admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Accès refusé: super admin uniquement';
  END IF;

  RETURN QUERY
  SELECT 
    c.id,
    c.name,
    c.email,
    c.phone,
    c.address,
    c.logo_url,
    c.approved,
    c.approved_at,
    c.created_at,
    COUNT(p.id) as user_count
  FROM companies c
  LEFT JOIN profiles p ON p.company_id = c.id
  GROUP BY c.id, c.name, c.email, c.phone, c.address, c.logo_url, c.approved, c.approved_at, c.created_at
  ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Fonction pour approuver une entreprise
CREATE OR REPLACE FUNCTION approve_company(company_uuid uuid)
RETURNS void AS $$
BEGIN
  -- Vérifier que l'utilisateur est super admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Accès refusé: super admin uniquement';
  END IF;

  UPDATE companies
  SET 
    approved = true,
    approved_at = now(),
    approved_by = auth.uid()
  WHERE id = company_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour révoquer l'approbation d'une entreprise
CREATE OR REPLACE FUNCTION revoke_company_approval(company_uuid uuid)
RETURNS void AS $$
BEGIN
  -- Vérifier que l'utilisateur est super admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Accès refusé: super admin uniquement';
  END IF;

  UPDATE companies
  SET 
    approved = false,
    approved_at = NULL,
    approved_by = NULL
  WHERE id = company_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mettre à jour les politiques RLS pour les companies
DROP POLICY IF EXISTS "Users can read own company" ON companies;
CREATE POLICY "Users can read own company"
  ON companies FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT company_id FROM profiles WHERE profiles.id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );