/*
  # Corriger la récursion infinie dans les politiques RLS

  1. Problème
    - Les politiques actuelles créent une récursion infinie car elles interrogent la table profiles
    - Cela empêche toute connexion

  2. Solution
    - Utiliser une fonction SECURITY DEFINER pour obtenir le rôle sans déclencher les RLS
    - Simplifier les politiques en utilisant cette fonction
    
  3. Notes importantes
    - Les superviseurs voient uniquement leurs commerciaux attribués
    - Les admins voient tous les utilisateurs de leur entreprise
    - Les super_admins voient tous les utilisateurs
*/

-- Créer une fonction sécurisée pour obtenir le rôle et company_id
CREATE OR REPLACE FUNCTION get_user_info()
RETURNS TABLE(role text, company_id uuid, user_id uuid) 
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role, company_id, id
  FROM profiles
  WHERE id = auth.uid()
  LIMIT 1;
$$;

-- Supprimer les anciennes politiques problématiques
DROP POLICY IF EXISTS "Profiles viewable with supervisor restrictions" ON profiles;
DROP POLICY IF EXISTS "Profiles update with restrictions" ON profiles;
DROP POLICY IF EXISTS "Admins and super admins can insert profiles" ON profiles;

-- Nouvelle politique de sélection sans récursion
CREATE POLICY "Profiles select policy"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    -- Cas 1: L'utilisateur regarde son propre profil
    id = auth.uid()
    OR
    -- Cas 2: Super admin peut tout voir
    (SELECT role FROM get_user_info()) = 'super_admin'
    OR
    -- Cas 3: Admin peut voir tous les utilisateurs de son entreprise
    (
      (SELECT role FROM get_user_info()) = 'admin'
      AND company_id = (SELECT company_id FROM get_user_info())
    )
    OR
    -- Cas 4: Superviseur peut voir les commerciaux qu'il a créés ou qui lui sont attribués
    (
      (SELECT role FROM get_user_info()) IN ('supervisor', 'superviseur')
      AND company_id = (SELECT company_id FROM get_user_info())
      AND (
        created_by = auth.uid()
        OR supervisor_id = auth.uid()
      )
    )
  );

-- Politique de mise à jour
CREATE POLICY "Profiles update policy"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    -- Super admin peut tout modifier
    (SELECT role FROM get_user_info()) = 'super_admin'
    OR
    -- Admin peut modifier les utilisateurs de son entreprise
    (
      (SELECT role FROM get_user_info()) = 'admin'
      AND company_id = (SELECT company_id FROM get_user_info())
    )
    OR
    -- Les utilisateurs peuvent modifier leur propre profil
    id = auth.uid()
  )
  WITH CHECK (
    -- Super admin peut tout modifier
    (SELECT role FROM get_user_info()) = 'super_admin'
    OR
    -- Admin peut modifier les utilisateurs de son entreprise
    (
      (SELECT role FROM get_user_info()) = 'admin'
      AND company_id = (SELECT company_id FROM get_user_info())
    )
    OR
    -- Les utilisateurs peuvent modifier leur propre profil
    id = auth.uid()
  );

-- Politique d'insertion
CREATE POLICY "Profiles insert policy"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT role FROM get_user_info()) IN ('admin', 'super_admin', 'supervisor', 'superviseur')
  );
