/*
  # Mise à jour de la contrainte de rôle

  1. Modifications
    - Supprimer l'ancienne contrainte sur le rôle
    - Créer une nouvelle contrainte qui inclut 'super_admin'
  
  2. Rôles autorisés
    - admin
    - superviseur
    - commercial
    - super_admin (nouveau)
*/

-- Supprimer l'ancienne contrainte
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

-- Créer la nouvelle contrainte avec super_admin
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
  CHECK (role IN ('admin', 'superviseur', 'commercial', 'super_admin'));
