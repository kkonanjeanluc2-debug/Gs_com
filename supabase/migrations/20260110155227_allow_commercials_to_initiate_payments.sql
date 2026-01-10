/*
  # Autoriser les commerciaux à initier les paiements en ligne

  1. Modifications des politiques RLS
    - Permettre aux commerciaux de LIRE les configurations de paiement
    - Les commerciaux peuvent déjà créer des paiements (order_payments)
    - Les commerciaux restent limités en lecture seule pour les configs

  2. Sécurité
    - Les commerciaux peuvent uniquement LIRE les configs, pas les modifier
    - Seuls les admins peuvent créer/modifier/supprimer les configs
*/

-- Supprimer l'ancienne politique de lecture pour payment_configurations
DROP POLICY IF EXISTS "Admins can view payment configs" ON payment_configurations;

-- Nouvelle politique: Admins, superviseurs ET commerciaux peuvent voir les configs
CREATE POLICY "Company users can view payment configs"
  ON payment_configurations FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'superviseur', 'commercial')
    )
  );
