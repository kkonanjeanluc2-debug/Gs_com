/*
  # Fix Approved Column Naming
  
  1. Changes
    - Rename `approved` to `is_approved` for consistency
    - Rename `approved_at` to `is_approved_at`
    - Rename `approved_by` to `is_approved_by`
    - Update all functions and indexes to use the new column names
  
  2. Security
    - Maintain all existing RLS policies with updated column references
*/

-- Rename columns if they exist
DO $$
BEGIN
  -- Rename approved to is_approved
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'approved'
  ) THEN
    ALTER TABLE companies RENAME COLUMN approved TO is_approved;
  END IF;

  -- Rename approved_at to is_approved_at
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'approved_at'
  ) THEN
    ALTER TABLE companies RENAME COLUMN approved_at TO is_approved_at;
  END IF;

  -- Rename approved_by to is_approved_by
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'approved_by'
  ) THEN
    ALTER TABLE companies RENAME COLUMN approved_by TO is_approved_by;
  END IF;
END $$;

-- Drop old index if exists
DROP INDEX IF EXISTS idx_companies_approved;

-- Create new index
CREATE INDEX IF NOT EXISTS idx_companies_is_approved ON companies(is_approved);

-- Update function to check if a company is approved
CREATE OR REPLACE FUNCTION is_company_approved(company_uuid uuid)
RETURNS boolean AS $$
DECLARE
  is_approved_val boolean;
BEGIN
  SELECT is_approved INTO is_approved_val
  FROM companies
  WHERE id = company_uuid;
  
  RETURN COALESCE(is_approved_val, false);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Update function to get all companies
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
    c.is_approved as approved,
    c.is_approved_at as approved_at,
    c.created_at,
    COUNT(p.id) as user_count
  FROM companies c
  LEFT JOIN profiles p ON p.company_id = c.id
  GROUP BY c.id, c.name, c.email, c.phone, c.address, c.logo_url, c.is_approved, c.is_approved_at, c.created_at
  ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Update function to approve a company
CREATE OR REPLACE FUNCTION approve_company(company_uuid uuid)
RETURNS void AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Accès refusé: super admin uniquement';
  END IF;

  UPDATE companies
  SET 
    is_approved = true,
    is_approved_at = now(),
    is_approved_by = auth.uid()
  WHERE id = company_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update function to revoke company approval
CREATE OR REPLACE FUNCTION revoke_company_approval(company_uuid uuid)
RETURNS void AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Accès refusé: super admin uniquement';
  END IF;

  UPDATE companies
  SET 
    is_approved = false,
    is_approved_at = NULL,
    is_approved_by = NULL
  WHERE id = company_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;