/*
  # Fix super admin profile policy to avoid recursive RLS checks

  1. Changes
    - Remove the policy that uses a subquery on profiles table
    - Super admins will use a different approach via app logic
*/

-- Drop the problematic policy
DROP POLICY IF EXISTS "Super admins can view all profiles" ON profiles;
