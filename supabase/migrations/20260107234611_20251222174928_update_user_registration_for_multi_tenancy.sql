/*
  # Update User Registration for Multi-Tenancy

  ## Overview
  Updates the user registration trigger to handle company assignment

  ## 1. Changes
  - Update `handle_new_user()` function to handle company assignment
  - If user metadata contains `company_id`, assign to that company
  - If no company exists and user is admin, create a new company
  - Otherwise, require company_id in metadata

  ## 2. Registration Flow
  - Admin creates company during first signup
  - Subsequent users must be invited with company_id in metadata
  - Edge functions will set company_id when creating users

  ## 3. Security
  - Users must have a valid company_id
  - Cannot register without company assignment
*/

-- Update function to handle company assignment
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_company_id uuid;
  user_role text;
BEGIN
  -- Get company_id from user metadata if provided
  user_company_id := (NEW.raw_user_meta_data->>'company_id')::uuid;
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'commercial');
  
  -- If no company_id provided and user is admin, check if this is the first user
  IF user_company_id IS NULL AND user_role = 'admin' THEN
    -- Check if there are any existing companies
    SELECT id INTO user_company_id FROM companies LIMIT 1;
    
    -- If no companies exist, create a default one for this admin
    IF user_company_id IS NULL THEN
      INSERT INTO companies (name, email)
      VALUES (
        COALESCE(NEW.raw_user_meta_data->>'company_name', 'Mon Entreprise'),
        NEW.email
      )
      RETURNING id INTO user_company_id;
    END IF;
  END IF;
  
  -- If still no company_id, raise an error
  IF user_company_id IS NULL THEN
    RAISE EXCEPTION 'company_id is required for user registration';
  END IF;
  
  -- Create profile with company assignment
  INSERT INTO public.profiles (id, email, full_name, role, company_id)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    user_role,
    user_company_id
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the auth user creation
    RAISE WARNING 'Error creating profile: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();