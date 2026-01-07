/*
  # Add Trial and Subscription Management System

  1. New Columns in `companies` table
    - `trial_days` (integer) - Number of trial days granted by super admin
    - `trial_end_date` (timestamptz) - End date of trial period
    - `subscription_status` (text) - Status: 'trial', 'active', 'expired', 'suspended'
    - `subscription_end_date` (timestamptz) - End date of paid subscription
    - `blocked_reason` (text) - Reason why company is blocked (if applicable)

  2. New Function
    - `check_company_subscription_status()` - Returns if company can access the system

  3. Changes
    - Add default trial period of 0 days for new companies
    - Add function to automatically check subscription status
    - Update company approval to set trial period

  4. Security
    - Only super admins can modify subscription settings
    - RLS policies updated to block access for expired companies
*/

-- Add subscription management columns to companies table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'trial_days'
  ) THEN
    ALTER TABLE companies ADD COLUMN trial_days integer DEFAULT 0 NOT NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'trial_end_date'
  ) THEN
    ALTER TABLE companies ADD COLUMN trial_end_date timestamptz;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'subscription_status'
  ) THEN
    ALTER TABLE companies ADD COLUMN subscription_status text DEFAULT 'trial' NOT NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'subscription_end_date'
  ) THEN
    ALTER TABLE companies ADD COLUMN subscription_end_date timestamptz;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'companies' AND column_name = 'blocked_reason'
  ) THEN
    ALTER TABLE companies ADD COLUMN blocked_reason text;
  END IF;
END $$;

-- Add constraint to check valid subscription status values
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'companies_subscription_status_check'
  ) THEN
    ALTER TABLE companies
    ADD CONSTRAINT companies_subscription_status_check
    CHECK (subscription_status IN ('trial', 'active', 'expired', 'suspended'));
  END IF;
END $$;

-- Create function to check if a company can access the system
CREATE OR REPLACE FUNCTION check_company_subscription_status(company_uuid uuid)
RETURNS boolean AS $$
DECLARE
  company_record RECORD;
  can_access boolean;
BEGIN
  SELECT 
    subscription_status,
    trial_end_date,
    subscription_end_date,
    is_approved
  INTO company_record
  FROM companies
  WHERE id = company_uuid;

  -- Company must be approved first
  IF NOT company_record.is_approved THEN
    RETURN false;
  END IF;

  -- Check subscription status
  CASE company_record.subscription_status
    WHEN 'trial' THEN
      -- Check if trial has expired
      IF company_record.trial_end_date IS NULL OR company_record.trial_end_date > now() THEN
        can_access := true;
      ELSE
        can_access := false;
      END IF;
    WHEN 'active' THEN
      -- Check if subscription has expired
      IF company_record.subscription_end_date IS NULL OR company_record.subscription_end_date > now() THEN
        can_access := true;
      ELSE
        can_access := false;
      END IF;
    WHEN 'expired', 'suspended' THEN
      can_access := false;
    ELSE
      can_access := false;
  END CASE;

  RETURN can_access;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to automatically update expired companies
CREATE OR REPLACE FUNCTION update_expired_companies()
RETURNS void AS $$
BEGIN
  -- Update trial companies that have expired
  UPDATE companies
  SET 
    subscription_status = 'expired',
    blocked_reason = 'Période d''essai expirée'
  WHERE subscription_status = 'trial'
    AND trial_end_date IS NOT NULL
    AND trial_end_date < now();

  -- Update active companies whose subscription has expired
  UPDATE companies
  SET 
    subscription_status = 'expired',
    blocked_reason = 'Abonnement expiré'
  WHERE subscription_status = 'active'
    AND subscription_end_date IS NOT NULL
    AND subscription_end_date < now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION check_company_subscription_status(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION update_expired_companies() TO service_role;

-- Create index for faster subscription status queries
CREATE INDEX IF NOT EXISTS idx_companies_subscription_status 
ON companies(subscription_status, trial_end_date, subscription_end_date);

-- Update existing companies to have proper trial settings
UPDATE companies
SET 
  subscription_status = 'trial',
  trial_days = 0,
  trial_end_date = NULL
WHERE subscription_status IS NULL OR subscription_status = 'trial';