/*
  # Création du Compte Super Administrateur

  1. Informations de connexion
    - Email: superadmin@system.com
    - Mot de passe: SuperAdmin2024!
  
  2. Configuration du profil
    - Role: super_admin
    - Nom: Super Administrateur
    - Aucune entreprise associée
  
  3. Accès
    - Peut gérer toutes les entreprises inscrites
    - Peut approuver/révoquer l'accès des entreprises
*/

DO $$
DECLARE
  v_user_id uuid;
  v_email text := 'superadmin@system.com';
  v_password text := 'SuperAdmin2024!';
  v_full_name text := 'Super Administrateur';
BEGIN
  -- Créer l'ID utilisateur
  v_user_id := gen_random_uuid();

  -- Créer l'utilisateur dans auth.users
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    role,
    aud,
    confirmation_token,
    recovery_token,
    email_change_token_new
  )
  VALUES (
    v_user_id,
    '00000000-0000-0000-0000-000000000000',
    v_email,
    crypt(v_password, gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', v_full_name, 'role', 'super_admin'),
    'authenticated',
    'authenticated',
    '',
    '',
    ''
  );

  -- Créer le profil
  INSERT INTO profiles (id, email, full_name, role, company_id)
  VALUES (v_user_id, v_email, v_full_name, 'super_admin', NULL);

  RAISE NOTICE '===========================================';
  RAISE NOTICE 'COMPTE SUPER ADMINISTRATEUR CRÉÉ';
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'Email: %', v_email;
  RAISE NOTICE 'Mot de passe: %', v_password;
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'Connectez-vous avec ces identifiants';
  RAISE NOTICE '===========================================';
  
EXCEPTION
  WHEN unique_violation THEN
    RAISE NOTICE 'Un utilisateur avec cet email existe déjà';
  WHEN OTHERS THEN
    RAISE NOTICE 'Erreur: %', SQLERRM;
END $$;