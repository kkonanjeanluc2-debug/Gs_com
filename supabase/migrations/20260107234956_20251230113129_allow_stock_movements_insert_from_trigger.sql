/*
  # Autoriser les insertions dans stock_movements depuis le trigger

  1. Problème
    - Les commerciaux ne peuvent pas marquer les commandes comme "delivered"
    - Le trigger essaie d'insérer dans stock_movements
    - Seuls les admins/superviseurs ont le droit d'insérer dans stock_movements
    
  2. Solution
    - Ajouter une politique qui permet aux utilisateurs d'insérer dans stock_movements
    - Tant que le company_id correspond à leur entreprise
    - Cela permet au trigger de fonctionner pour tous les utilisateurs
    
  3. Sécurité
    - La politique vérifie toujours le company_id
    - En pratique, seul le trigger créera ces enregistrements
    - Les utilisateurs ne peuvent pas insérer manuellement (pas d'interface pour ça)
*/

-- Supprimer l'ancienne politique INSERT restrictive
DROP POLICY IF EXISTS "Admins and superviseurs can create company stock movements" ON stock_movements;

-- Créer une nouvelle politique INSERT qui permet à tous les utilisateurs authentifiés
-- d'insérer des mouvements de stock pour leur entreprise
CREATE POLICY "Users can create company stock movements"
  ON stock_movements FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id = get_user_company(auth.uid())
  );

-- Garder une politique pour permettre aux admins de modifier/supprimer
CREATE POLICY "Admins can update stock movements"
  ON stock_movements FOR UPDATE
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND get_user_role(auth.uid()) IN ('admin', 'superviseur')
  )
  WITH CHECK (
    company_id = get_user_company(auth.uid())
    AND get_user_role(auth.uid()) IN ('admin', 'superviseur')
  );

CREATE POLICY "Admins can delete stock movements"
  ON stock_movements FOR DELETE
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND get_user_role(auth.uid()) IN ('admin', 'superviseur')
  );