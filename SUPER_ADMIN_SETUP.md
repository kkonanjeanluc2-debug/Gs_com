# Configuration du Super Administrateur

Ce guide explique comment créer et configurer le compte super administrateur pour gérer les entreprises inscrites.

## Qu'est-ce qu'un Super Admin ?

Le super administrateur est un compte spécial qui :
- A accès à toutes les entreprises inscrites
- Peut approuver ou révoquer l'accès des entreprises
- Ne fait pas partie d'une entreprise spécifique
- Gère le système au niveau global

## Création du Compte Super Admin

### Méthode 1 : Via l'interface Supabase Dashboard

1. Connectez-vous à votre [Supabase Dashboard](https://app.supabase.com)
2. Sélectionnez votre projet
3. Allez dans "Authentication" > "Users"
4. Créez un nouvel utilisateur avec votre email et mot de passe
5. Allez dans "Table Editor" > "profiles"
6. Trouvez le profil correspondant à l'utilisateur créé
7. Modifiez les champs suivants :
   - `role` : `super_admin`
   - `company_id` : Laissez NULL
   - `full_name` : Votre nom

### Méthode 2 : Via SQL

Exécutez ce script SQL dans le SQL Editor de Supabase :

```sql
-- Remplacez les valeurs ci-dessous par vos informations
DO $$
DECLARE
  v_user_id uuid;
  v_email text := 'admin@example.com';  -- VOTRE EMAIL
  v_password text := 'VotreMotDePasse123!';  -- VOTRE MOT DE PASSE
  v_full_name text := 'Super Admin';  -- VOTRE NOM
BEGIN
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
    aud
  )
  VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    v_email,
    crypt(v_password, gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('full_name', v_full_name),
    'authenticated',
    'authenticated'
  )
  RETURNING id INTO v_user_id;

  -- Créer ou mettre à jour le profil
  INSERT INTO profiles (id, email, full_name, role, company_id)
  VALUES (v_user_id, v_email, v_full_name, 'super_admin', NULL)
  ON CONFLICT (id) DO UPDATE
  SET
    role = 'super_admin',
    company_id = NULL,
    full_name = v_full_name;

  RAISE NOTICE 'Super admin créé avec succès: %', v_email;
END $$;
```

## Connexion en tant que Super Admin

1. Allez sur la page de connexion de l'application
2. Utilisez l'email et le mot de passe du compte super admin
3. Vous serez redirigé vers le tableau de bord avec un onglet "Entreprises"

## Gestion des Entreprises

### Approuver une Entreprise

1. Connectez-vous en tant que super admin
2. Cliquez sur l'onglet "Entreprises"
3. Trouvez l'entreprise en attente
4. Cliquez sur "Approuver"
5. Les utilisateurs de cette entreprise peuvent maintenant se connecter

### Révoquer une Entreprise

1. Dans l'onglet "Entreprises"
2. Trouvez l'entreprise approuvée
3. Cliquez sur "Révoquer"
4. Tous les utilisateurs de cette entreprise seront immédiatement déconnectés et ne pourront plus se reconnecter

## Processus d'Inscription des Entreprises

1. Une nouvelle entreprise s'inscrit via le formulaire d'inscription
2. L'entreprise est créée avec le statut "En attente d'approbation"
3. L'administrateur de l'entreprise ne peut pas se connecter
4. Le super admin reçoit la demande dans l'onglet "Entreprises"
5. Le super admin approuve l'entreprise
6. L'administrateur peut maintenant se connecter et créer des utilisateurs

## Sécurité

- Ne partagez jamais les identifiants du super admin
- Utilisez un mot de passe fort et unique
- Changez régulièrement le mot de passe
- Limitez l'accès au compte super admin aux personnes autorisées
- Le super admin ne doit pas être utilisé pour les opérations quotidiennes

## Dépannage

### Je ne vois pas l'onglet "Entreprises"

Vérifiez que :
- Votre profil a bien `role = 'super_admin'`
- Vous êtes bien connecté avec le compte super admin
- Vous avez vidé le cache de votre navigateur

### Une entreprise ne peut pas se connecter après approbation

1. Vérifiez dans la table `companies` que `approved = true`
2. Demandez à l'utilisateur de se déconnecter complètement
3. Demandez-lui de vider le cache de son navigateur
4. Réessayez la connexion

### Je ne peux pas approuver une entreprise

Vérifiez que :
- Vous êtes bien connecté en tant que super admin
- La fonction `approve_company` existe dans la base de données
- Vous avez les permissions nécessaires

## Support

Pour toute question ou problème, contactez l'équipe de développement.
