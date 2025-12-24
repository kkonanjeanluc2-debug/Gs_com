/*
  # Cleanup Orphaned Users
  
  1. Purpose
    - Remove users from auth.users who don't have corresponding profiles
    - This can happen when profile creation fails due to RLS restrictions
  
  2. Action
    - Delete user 'kouad@gmail.com' who exists in auth.users but not in profiles
*/

-- Delete orphaned user
DO $$
BEGIN
  -- Delete from auth.users where there's no matching profile
  DELETE FROM auth.users
  WHERE email = 'kouad@gmail.com'
  AND id NOT IN (SELECT id FROM profiles);
END $$;
