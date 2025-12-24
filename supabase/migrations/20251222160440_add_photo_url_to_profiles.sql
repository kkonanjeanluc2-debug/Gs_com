/*
  # Add photo URL field to profiles table

  1. Changes
    - Add `photo_url` (text) - URL to commercial's photo
  
  2. Notes
    - This field stores the URL of the commercial's profile photo
    - Optional field for all users
*/

-- Add photo_url field to profiles table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'photo_url'
  ) THEN
    ALTER TABLE profiles ADD COLUMN photo_url text;
  END IF;
END $$;