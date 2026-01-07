/*
  # Fix User Registration to Handle Company ID

  ## Overview
  Update the user registration trigger to handle company_id from user metadata.

  ## Changes
  - Modify handle_new_user() function to read company_id from user metadata
  - Allow company_id to be null temporarily during registration
  - The edge function will then update the profile with the correct company_id

  ## Security
  - Maintains existing RLS policies
  - Only affects the registration flow
*/

-- Update the trigger function to handle company_id
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_company_id uuid;
BEGIN
  -- Try to get company_id from user metadata
  user_company_id := (NEW.raw_user_meta_data->>'company_id')::uuid;
  
  -- Insert profile with company_id if provided
  INSERT INTO public.profiles (id, email, full_name, role, company_id)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'commercial'),
    user_company_id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Make company_id nullable temporarily to allow registration flow
ALTER TABLE profiles ALTER COLUMN company_id DROP NOT NULL;

-- Add a check to ensure company_id is set for active users
-- This will be enforced at the application level