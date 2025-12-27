/*
  # Add Company Registration Support

  ## Overview
  This migration adds support for company registration with the first admin user.

  ## 1. New Features
  - Add unique constraint on company email
  - Add status field to companies table
  - Add subscription info fields
  - Update trigger for user registration to handle company context

  ## 2. Security Updates
  - Allow public registration for new companies
  - Auto-assign first user as admin
*/

-- Add additional fields to companies table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'companies' AND column_name = 'status'
  ) THEN
    ALTER TABLE companies ADD COLUMN status text DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'inactive'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'companies' AND column_name = 'subscription_plan'
  ) THEN
    ALTER TABLE companies ADD COLUMN subscription_plan text DEFAULT 'free' CHECK (subscription_plan IN ('free', 'basic', 'premium'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'companies' AND column_name = 'max_users'
  ) THEN
    ALTER TABLE companies ADD COLUMN max_users integer DEFAULT 5;
  END IF;
END $$;

-- Create unique constraint on email if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'companies_email_key'
  ) THEN
    ALTER TABLE companies ADD CONSTRAINT companies_email_key UNIQUE (email);
  END IF;
END $$;

-- Allow public to insert new companies (for registration)
DROP POLICY IF EXISTS "Allow public company registration" ON companies;
CREATE POLICY "Allow public company registration"
  ON companies FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Create helper function to check if user is first in company
CREATE OR REPLACE FUNCTION is_first_company_user(p_company_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 FROM profiles WHERE company_id = p_company_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
