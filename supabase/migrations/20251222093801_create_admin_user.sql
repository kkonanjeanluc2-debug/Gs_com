/*
  # Création du compte administrateur initial

  1. Création de l'utilisateur admin dans auth.users
  2. Création du profil administrateur correspondant
  
  Identifiants:
  - Email: admin@lagrace.ci
  - Mot de passe: Admin123!
  
  IMPORTANT: Changez ce mot de passe après la première connexion
*/

-- Créer l'utilisateur dans auth.users
DO $$
DECLARE
  admin_user_id uuid;
BEGIN
  -- Vérifier si l'utilisateur existe déjà
  SELECT id INTO admin_user_id
  FROM auth.users
  WHERE email = 'admin@lagrace.ci';

  -- Si l'utilisateur n'existe pas, le créer
  IF admin_user_id IS NULL THEN
    INSERT INTO auth.users (
      id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      role,
      aud
    ) VALUES (
      gen_random_uuid(),
      'admin@lagrace.ci',
      crypt('Admin123!', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"full_name":"Administrateur"}'::jsonb,
      now(),
      now(),
      '',
      'authenticated',
      'authenticated'
    ) RETURNING id INTO admin_user_id;

    -- Créer le profil correspondant
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
      admin_user_id,
      'admin@lagrace.ci',
      'Administrateur',
      'admin'
    );
  END IF;
END $$;
