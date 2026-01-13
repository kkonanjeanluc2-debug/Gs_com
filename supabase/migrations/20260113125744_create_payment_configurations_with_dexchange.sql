/*
  # Création de la table payment_configurations
  
  1. Nouvelles Tables
    - `payment_configurations` : Configuration des moyens de paiement par entreprise
      - `id` : Identifiant unique
      - `company_id` : Référence à l'entreprise
      - `provider` : Fournisseur de paiement (wave, orange_money, mtn_money, moov_money, cinetpay, paydunya, dexchange)
      - `is_enabled` : Activation du moyen de paiement
      - `api_key` : Clé API
      - `api_secret` : Clé secrète API
      - `merchant_id` : Identifiant marchand
      - `master_key` : Clé principale (pour certains providers)
      - `webhook_url` : URL de callback
      - `test_mode` : Mode test/production
      - `config_data` : Données de configuration supplémentaires (JSON)
      
  2. Sécurité
    - Activation de RLS sur payment_configurations
    - Politique de lecture : Admins et superviseurs de l'entreprise
    - Politique d'insertion : Admins uniquement
    - Politique de mise à jour : Admins uniquement
    - Politique de suppression : Admins uniquement
*/

-- Créer la table payment_configurations
CREATE TABLE IF NOT EXISTS payment_configurations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('wave', 'orange_money', 'mtn_money', 'moov_money', 'cinetpay', 'paydunya', 'dexchange')),
  is_enabled boolean DEFAULT false,
  api_key text,
  api_secret text,
  merchant_id text,
  master_key text,
  webhook_url text,
  test_mode boolean DEFAULT true,
  config_data jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, provider)
);

-- Index pour les recherches rapides
CREATE INDEX IF NOT EXISTS idx_payment_configurations_company ON payment_configurations(company_id);
CREATE INDEX IF NOT EXISTS idx_payment_configurations_enabled ON payment_configurations(company_id, is_enabled) WHERE is_enabled = true;

-- Activer RLS
ALTER TABLE payment_configurations ENABLE ROW LEVEL SECURITY;

-- Politique: Admins et superviseurs peuvent voir les configs de leur entreprise
CREATE POLICY "Admins can view payment configs"
  ON payment_configurations FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'superviseur')
    )
  );

-- Politique: Seuls les admins peuvent créer des configs
CREATE POLICY "Admins can create payment configs"
  ON payment_configurations FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Politique: Seuls les admins peuvent modifier des configs
CREATE POLICY "Admins can update payment configs"
  ON payment_configurations FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Politique: Seuls les admins peuvent supprimer des configs
CREATE POLICY "Admins can delete payment configs"
  ON payment_configurations FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );
