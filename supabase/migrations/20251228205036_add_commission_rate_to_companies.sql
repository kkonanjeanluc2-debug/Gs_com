/*
  # Add Commission Rate to Companies

  1. Schema Changes
    - Add `commission_rate` column to `companies` table
      - Stores the commission percentage (e.g., 5 for 5%)
      - Default value is 5%
      - Can be configured per company

  2. Notes
    - Commission rate is a percentage value
    - Used to calculate commercial commissions based on their monthly revenue
*/

-- Add commission_rate field to companies table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'commission_rate'
  ) THEN
    ALTER TABLE companies ADD COLUMN commission_rate numeric(5,2) DEFAULT 5.00 NOT NULL;
  END IF;
END $$;

COMMENT ON COLUMN companies.commission_rate IS 'Commission percentage for commercials (e.g., 5.00 for 5%)';
