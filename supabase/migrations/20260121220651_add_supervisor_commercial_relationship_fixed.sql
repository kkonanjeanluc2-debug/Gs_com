/*
  # Ajouter Relation Superviseur-Commercial

  1. Modifications de la table profiles
    - Ajout de la colonne `created_by` pour savoir qui a créé l'utilisateur
    - Ajout de la colonne `supervisor_id` pour lier un commercial à son superviseur
    - Contraintes de clé étrangère vers la table profiles
    - Index pour optimiser les requêtes

  2. Modification des politiques RLS
    - Les superviseurs peuvent voir UNIQUEMENT:
      * Leur propre profil
      * Les commerciaux qu'ils ont créés (created_by = supervisor_id)
      * Les commerciaux qui leur sont attribués (supervisor_id = auth.uid())
    - Les admins peuvent voir tous les utilisateurs de leur entreprise
    - Les super_admins peuvent tout voir

  3. Notes importantes
    - Un commercial peut avoir un seul superviseur
    - Un superviseur peut gérer plusieurs commerciaux
    - Les admins peuvent attribuer des commerciaux aux superviseurs
*/

-- Ajouter les colonnes created_by et supervisor_id à la table profiles
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES profiles(id) ON DELETE SET NULL;

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS supervisor_id uuid REFERENCES profiles(id) ON DELETE SET NULL;

-- Créer des index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_profiles_created_by ON profiles(created_by);
CREATE INDEX IF NOT EXISTS idx_profiles_supervisor_id ON profiles(supervisor_id);

-- Supprimer les anciennes politiques de sélection pour les recréer
DROP POLICY IF EXISTS "Profiles viewable by authenticated users" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in their company" ON profiles;
DROP POLICY IF EXISTS "Supervisors can view all profiles in their company" ON profiles;
DROP POLICY IF EXISTS "Profiles viewable with restrictions" ON profiles;

-- Nouvelle politique de sélection pour les profiles
CREATE POLICY "Profiles viewable with supervisor restrictions"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    -- Super admins peuvent tout voir
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'super_admin'
    )
    OR
    -- Admins peuvent voir tous les utilisateurs de leur entreprise
    (
      EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.role = 'admin'
        AND p.company_id = profiles.company_id
      )
    )
    OR
    -- Superviseurs peuvent voir:
    -- 1. Leur propre profil
    -- 2. Les commerciaux qu'ils ont créés
    -- 3. Les commerciaux qui leur sont attribués
    (
      EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.role IN ('supervisor', 'superviseur')
        AND p.company_id = profiles.company_id
      )
      AND (
        profiles.id = auth.uid() -- Leur propre profil
        OR profiles.created_by = auth.uid() -- Commerciaux créés par le superviseur
        OR profiles.supervisor_id = auth.uid() -- Commerciaux attribués au superviseur
      )
    )
    OR
    -- Commerciaux peuvent voir leur propre profil
    (
      auth.uid() = profiles.id
    )
  );

-- Supprimer les anciennes politiques de mise à jour
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update supervisor assignments" ON profiles;

-- Politique pour permettre la mise à jour des profils
CREATE POLICY "Profiles update with restrictions"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    -- Super admins peuvent tout modifier
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'super_admin'
    )
    OR
    -- Admins peuvent modifier les utilisateurs de leur entreprise
    (
      EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.role = 'admin'
        AND p.company_id = profiles.company_id
      )
    )
    OR
    -- Superviseurs peuvent modifier leur propre profil
    (
      auth.uid() = profiles.id
      AND EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.role IN ('supervisor', 'superviseur')
      )
    )
    OR
    -- Commerciaux peuvent modifier leur propre profil
    (
      auth.uid() = profiles.id
      AND EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.role = 'commercial'
      )
    )
  )
  WITH CHECK (
    -- Même logique pour WITH CHECK
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin', 'super_admin')
    )
    OR
    (
      auth.uid() = profiles.id
      AND EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.role IN ('supervisor', 'superviseur', 'commercial')
      )
    )
  );

-- Supprimer l'ancienne politique d'insertion
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;

-- Politique d'insertion (inchangée, seuls admin et super_admin peuvent créer des utilisateurs)
CREATE POLICY "Admins and super admins can insert profiles"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('admin', 'super_admin')
    )
  );
