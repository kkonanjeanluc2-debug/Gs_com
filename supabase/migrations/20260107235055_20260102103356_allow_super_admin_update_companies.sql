/*
  # Allow Super Admins to Update All Companies
  
  1. Changes
    - Update RLS policy for companies UPDATE to allow super admins
    - Super admins can now update any company's subscription settings
  
  2. Security
    - Regular admins can still only update their own company
    - Super admins have full access to all companies
*/

-- Drop existing policy
DROP POLICY IF EXISTS "Admins can update own company" ON companies;

-- Recreate with super admin support
CREATE POLICY "Admins and super admins can update companies"
  ON companies FOR UPDATE
  TO authenticated
  USING (
    -- Own company admin OR super admin
    (id = get_user_company(auth.uid()) AND get_user_role(auth.uid()) = 'admin')
    OR
    get_user_role(auth.uid()) = 'super_admin'
  )
  WITH CHECK (
    -- Own company admin OR super admin
    (id = get_user_company(auth.uid()) AND get_user_role(auth.uid()) = 'admin')
    OR
    get_user_role(auth.uid()) = 'super_admin'
  );