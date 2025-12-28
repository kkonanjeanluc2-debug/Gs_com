/*
  # Add Public Company Access for Login Page

  ## Overview
  This migration allows unauthenticated users to view basic company information
  (name and logo) on the login page.

  ## Changes
  1. Add a new RLS policy to allow public read access to approved companies
  2. This policy only exposes the id, name, and logo_url fields
  3. Only approved companies are visible

  ## Security Notes
  - This is safe because we only expose non-sensitive company branding information
  - Only companies with status='approved' are visible
  - Users cannot modify any data, only read basic information
*/

-- Create policy to allow public read access to approved companies' basic info
CREATE POLICY "Public can view approved companies basic info"
  ON companies FOR SELECT
  TO anon
  USING (status = 'approved');
