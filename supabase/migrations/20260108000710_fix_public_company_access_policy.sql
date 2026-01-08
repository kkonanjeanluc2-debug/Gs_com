/*
  # Fix public company access policy

  1. Changes
    - Update the public access policy to use `is_approved` instead of `status = 'approved'`
    - This aligns with the actual data model where companies have `is_approved` boolean field
*/

-- Drop the old policy
DROP POLICY IF EXISTS "Public can view approved companies basic info" ON companies;

-- Create the corrected policy
CREATE POLICY "Public can view approved companies basic info"
  ON companies FOR SELECT
  TO anon
  USING (is_approved = true);
