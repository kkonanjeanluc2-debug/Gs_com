/*
  # Add RCCM and NCC fields to company settings

  1. Changes
    - Add `rccm` (text) - Company registration number (RCCM)
    - Add `ncc` (text) - Tax number (NCC)
  
  2. Notes
    - These fields are optional and used for company identification
*/

-- Add RCCM and NCC fields to company_settings table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'company_settings' AND column_name = 'rccm'
  ) THEN
    ALTER TABLE company_settings ADD COLUMN rccm text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'company_settings' AND column_name = 'ncc'
  ) THEN
    ALTER TABLE company_settings ADD COLUMN ncc text;
  END IF;
END $$;