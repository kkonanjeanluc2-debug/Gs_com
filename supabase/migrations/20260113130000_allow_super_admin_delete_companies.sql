/*
  # Allow Super Admin to Delete Companies

  1. Companies Table
    - Add DELETE policy for super admins to delete any company
    - Deletion will cascade to all related data (users, products, orders, etc.)

  2. Security
    - Only super_admin role can delete companies
    - All related data is automatically deleted via CASCADE constraints

  3. RPC Function
    - Create delete_company function for safe deletion with validation
*/

-- Add DELETE policy for companies
CREATE POLICY IF NOT EXISTS "Super admins can delete companies"
  ON companies FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );

-- Create RPC function to delete company with validation
CREATE OR REPLACE FUNCTION delete_company(company_uuid uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_caller_role text;
  v_user_count int;
  v_company_name text;
BEGIN
  -- Check if caller is super admin
  SELECT role INTO v_caller_role
  FROM profiles
  WHERE id = auth.uid();

  IF v_caller_role != 'super_admin' THEN
    RAISE EXCEPTION 'Permission denied. Only super admins can delete companies.';
  END IF;

  -- Check if company exists and get info
  SELECT name INTO v_company_name
  FROM companies
  WHERE id = company_uuid;

  IF v_company_name IS NULL THEN
    RAISE EXCEPTION 'Company not found';
  END IF;

  -- Get user count for logging
  SELECT COUNT(*) INTO v_user_count
  FROM profiles
  WHERE company_id = company_uuid;

  -- Delete company (CASCADE will handle related data)
  DELETE FROM companies WHERE id = company_uuid;

  -- Return success info
  RETURN json_build_object(
    'success', true,
    'company_name', v_company_name,
    'users_deleted', v_user_count
  );
END;
$$;
