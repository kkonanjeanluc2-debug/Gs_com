/*
  # Ajouter l'accès aux profils pour les superviseurs

  1. Modifications
    - Ajouter une politique RLS permettant aux superviseurs de voir les profils des commerciaux de leur compagnie
    - Permettre aux superviseurs de modifier les profils des commerciaux (sauf suppression gérée par l'edge function)

  2. Sécurité
    - Les superviseurs peuvent uniquement voir et modifier les profils de leur propre compagnie
    - Pas d'accès aux profils d'admin ou d'autres superviseurs
*/

-- Politique pour permettre aux superviseurs de voir les profils des commerciaux de leur compagnie
CREATE POLICY "Superviseurs can view commercials profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    get_user_role(auth.uid()) = 'superviseur' 
    AND company_id = get_user_company(auth.uid())
    AND role = 'commercial'
  );

-- Politique pour permettre aux superviseurs de mettre à jour les profils des commerciaux
CREATE POLICY "Superviseurs can update commercials profiles"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    get_user_role(auth.uid()) = 'superviseur' 
    AND company_id = get_user_company(auth.uid())
    AND role = 'commercial'
  )
  WITH CHECK (
    get_user_role(auth.uid()) = 'superviseur' 
    AND company_id = get_user_company(auth.uid())
    AND role = 'commercial'
  );