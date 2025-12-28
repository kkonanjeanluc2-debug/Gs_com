/*
  # Permettre aux commerciaux de voir les autres commerciaux de leur entreprise

  1. Modifications
    - Ajout d'une policy SELECT pour permettre aux commerciaux de voir les profils des autres commerciaux de la même entreprise
    - Permet d'afficher le classement des top 5 commerciaux à tous les commerciaux
  
  2. Sécurité
    - Les commerciaux peuvent uniquement VOIR les profils, pas les modifier
    - Restriction aux commerciaux de la même entreprise uniquement
    - Les informations sensibles restent protégées (pas d'accès en écriture)
*/

-- Permettre aux commerciaux de voir les profils des autres commerciaux de leur entreprise
CREATE POLICY "Commercials can view other commercials in same company"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    get_user_role(auth.uid()) = 'commercial'
    AND company_id = get_user_company(auth.uid())
    AND role = 'commercial'
  );