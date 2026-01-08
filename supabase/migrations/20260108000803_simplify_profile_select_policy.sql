/*
  # Simplify profile SELECT policy to avoid RLS dependency issues

  1. Changes
    - Simplify the profile SELECT policy to allow users to read their own profile
    - This avoids calling get_user_role which can cause RLS dependency issues during login
*/

-- Drop the complex policy
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;

-- Create a simple policy that allows users to view their own profile
-- without calling any functions that might trigger RLS checks
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Add a separate policy for super admins to view all profiles
CREATE POLICY "Super admins can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'super_admin'
    )
  );
