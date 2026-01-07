/*
  # Fix User Registration with Automatic Profile Creation
  
  1. Changes
    - Create trigger to automatically create profile when user signs up
    - Allow users to insert their own profile during signup
    - Keep admin restriction for creating other users' profiles
  
  2. Security
    - Users can only insert their own profile (id must match auth.uid())
    - Admins can insert any profile
*/

-- Drop existing policy
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;

-- Create new policies for profile insertion
CREATE POLICY "Users can insert own profile on signup"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can insert any profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (get_user_role(auth.uid()) = 'admin');

-- Function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'commercial')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();