# Configuration du compte Admin initial

Pour créer votre premier compte administrateur, vous devez le créer via le tableau de bord Supabase.

## Étapes pour créer le compte admin

### 1. Accédez au tableau de bord Supabase

Ouvrez votre navigateur et allez sur: https://supabase.com/dashboard

### 2. Naviguez vers Authentication

- Sélectionnez votre projet
- Cliquez sur "Authentication" dans le menu de gauche
- Cliquez sur "Users"

### 3. Créez un nouvel utilisateur

- Cliquez sur "Add user" → "Create new user"
- Remplissez les informations:
  - **Email**: admin@entreprise.ci (ou votre email)
  - **Password**: Choisissez un mot de passe sécurisé
  - **Auto Confirm User**: ✅ Cochez cette case

### 4. Ajoutez le profil admin

Une fois l'utilisateur créé, vous devez ajouter son profil dans la table `profiles`:

1. Allez dans "Table Editor" → "profiles"
2. Cliquez sur "Insert" → "Insert row"
3. Remplissez:
   - **id**: Copiez l'UUID de l'utilisateur créé (visible dans Authentication → Users)
   - **email**: admin@entreprise.ci (même email que l'utilisateur)
   - **full_name**: Votre nom complet
   - **role**: admin
   - **phone**: Votre numéro (optionnel)

### 5. Connectez-vous

Retournez sur votre application et connectez-vous avec:
- Email: admin@entreprise.ci
- Mot de passe: celui que vous avez choisi

### 6. Créez d'autres utilisateurs

Une fois connecté en tant qu'admin, vous pouvez créer d'autres utilisateurs directement depuis l'interface:
- Allez dans l'onglet "Utilisateurs"
- Cliquez sur "Nouvel utilisateur"
- Remplissez le formulaire

## Rôles disponibles

- **Admin**: Accès complet, peut créer/supprimer tous les utilisateurs
- **Superviseur**: Peut voir tous les rapports, gérer le stock et créer des commerciaux
- **Commercial**: Ne voit que ses propres données (rapports, clients assignés)

## Alternative rapide avec SQL

Vous pouvez aussi exécuter ce SQL dans "SQL Editor":

```sql
-- 1. Créer l'utilisateur dans auth (remplacez l'email et le mot de passe)
-- Ceci doit être fait via le Dashboard Authentication

-- 2. Après avoir créé l'utilisateur, récupérez son ID et exécutez:
INSERT INTO profiles (id, email, full_name, role)
VALUES (
  'VOTRE_UUID_UTILISATEUR',  -- Remplacez par l'UUID de l'utilisateur
  'admin@entreprise.ci',
  'Administrateur Principal',
  'admin'
);
```

## Support

Si vous rencontrez des problèmes, vérifiez que:
- L'email de l'utilisateur correspond exactement dans `auth.users` et `profiles`
- Le rôle est bien défini dans la table `profiles`
- Les politiques RLS sont activées
