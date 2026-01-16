/*
  # Système de plans d'abonnement et paiements CinetPay

  1. Nouvelles tables
    - `subscription_plans` - Plans d'abonnement disponibles
      - `id` (uuid, primary key)
      - `name` (text) - Nom du plan (Mensuel, Trimestriel, Annuel)
      - `duration_days` (integer) - Durée en jours
      - `price` (integer) - Prix en FCFA
      - `description` (text) - Description du plan
      - `is_active` (boolean) - Plan actif ou non
      - `created_at` (timestamptz)

    - `payments` - Historique des paiements
      - `id` (uuid, primary key)
      - `company_id` (uuid, foreign key)
      - `plan_id` (uuid, foreign key)
      - `amount` (integer) - Montant en FCFA
      - `currency` (text) - Devise (XOF)
      - `payment_method` (text) - Méthode de paiement (MOBILE_MONEY, WAVE)
      - `transaction_id` (text) - ID de transaction CinetPay
      - `payment_token` (text) - Token de paiement CinetPay
      - `status` (text) - Status: pending, completed, failed, cancelled
      - `cinetpay_data` (jsonb) - Données brutes de CinetPay
      - `created_at` (timestamptz)
      - `completed_at` (timestamptz)

  2. Modifications
    - Mettre à jour trial_days par défaut à 30 jours
    - Créer un trigger pour définir automatiquement la période d'essai de 30 jours

  3. Sécurité
    - RLS pour les plans (public en lecture)
    - RLS pour les paiements (accessible uniquement par l'entreprise concernée)
*/

-- Créer la table subscription_plans
CREATE TABLE IF NOT EXISTS subscription_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  duration_days integer NOT NULL,
  price integer NOT NULL,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;

-- Tout le monde peut voir les plans actifs
CREATE POLICY "Anyone can view active subscription plans"
  ON subscription_plans FOR SELECT
  USING (is_active = true);

-- Seul le super admin peut gérer les plans
CREATE POLICY "Super admin can manage subscription plans"
  ON subscription_plans FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );

-- Créer la table payments
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  plan_id uuid REFERENCES subscription_plans(id) ON DELETE SET NULL,
  amount integer NOT NULL,
  currency text DEFAULT 'XOF' NOT NULL,
  payment_method text NOT NULL,
  transaction_id text,
  payment_token text,
  status text DEFAULT 'pending' NOT NULL,
  cinetpay_data jsonb,
  created_at timestamptz DEFAULT now(),
  completed_at timestamptz
);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Contraintes pour les statuts de paiement
ALTER TABLE payments
ADD CONSTRAINT payments_status_check
CHECK (status IN ('pending', 'completed', 'failed', 'cancelled'));

-- Contraintes pour les méthodes de paiement
ALTER TABLE payments
ADD CONSTRAINT payments_payment_method_check
CHECK (payment_method IN ('MOBILE_MONEY', 'WAVE', 'ORANGE_MONEY', 'MTN_MONEY', 'MOOV_MONEY', 'DEXCHANGE'));

-- Index pour accélération des requêtes
CREATE INDEX IF NOT EXISTS idx_payments_company_id ON payments(company_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_transaction_id ON payments(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at DESC);

-- Les entreprises peuvent voir leurs propres paiements
CREATE POLICY "Companies can view their payments"
  ON payments FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Les entreprises peuvent créer des paiements
CREATE POLICY "Companies can create payments"
  ON payments FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Seul le super admin peut voir tous les paiements
CREATE POLICY "Super admin can view all payments"
  ON payments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );

-- Insérer les plans d'abonnement par défaut
INSERT INTO subscription_plans (name, duration_days, price, description, is_active)
VALUES
  ('Mensuel', 30, 15000, 'Abonnement mensuel - Renouvellement automatique', true),
  ('Trimestriel', 90, 40000, 'Abonnement trimestriel - Économisez 11%', true),
  ('Annuel', 365, 150000, 'Abonnement annuel - Économisez 17%', true)
ON CONFLICT DO NOTHING;

-- Modifier la valeur par défaut de trial_days à 30
ALTER TABLE companies
ALTER COLUMN trial_days SET DEFAULT 30;

-- Créer ou remplacer le trigger pour définir automatiquement la période d'essai
CREATE OR REPLACE FUNCTION set_company_trial_period()
RETURNS TRIGGER AS $$
BEGIN
  -- Définir automatiquement 30 jours d'essai
  IF NEW.trial_days IS NULL OR NEW.trial_days = 0 THEN
    NEW.trial_days := 30;
  END IF;

  -- Calculer la date de fin d'essai si elle n'est pas définie
  IF NEW.trial_end_date IS NULL AND NEW.is_approved = true THEN
    NEW.trial_end_date := NOW() + (NEW.trial_days || ' days')::INTERVAL;
  END IF;

  -- S'assurer que le statut est trial pour les nouvelles entreprises
  IF NEW.subscription_status IS NULL THEN
    NEW.subscription_status := 'trial';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger sur INSERT et UPDATE
DROP TRIGGER IF EXISTS trigger_set_company_trial_period ON companies;
CREATE TRIGGER trigger_set_company_trial_period
  BEFORE INSERT OR UPDATE ON companies
  FOR EACH ROW
  EXECUTE FUNCTION set_company_trial_period();

-- Fonction pour activer l'abonnement après un paiement réussi
CREATE OR REPLACE FUNCTION activate_subscription_after_payment()
RETURNS TRIGGER AS $$
DECLARE
  plan_duration integer;
  new_end_date timestamptz;
BEGIN
  -- Vérifier si le paiement vient d'être complété
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN

    -- Récupérer la durée du plan
    SELECT duration_days INTO plan_duration
    FROM subscription_plans
    WHERE id = NEW.plan_id;

    -- Calculer la nouvelle date de fin d'abonnement
    SELECT GREATEST(
      COALESCE(subscription_end_date, NOW()),
      NOW()
    ) + (plan_duration || ' days')::INTERVAL
    INTO new_end_date
    FROM companies
    WHERE id = NEW.company_id;

    -- Mettre à jour l'entreprise
    UPDATE companies
    SET
      subscription_status = 'active',
      subscription_end_date = new_end_date,
      blocked_reason = NULL
    WHERE id = NEW.company_id;

    -- Mettre à jour la date de complétion du paiement
    NEW.completed_at := NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger sur la table payments
DROP TRIGGER IF EXISTS trigger_activate_subscription_after_payment ON payments;
CREATE TRIGGER trigger_activate_subscription_after_payment
  BEFORE UPDATE ON payments
  FOR EACH ROW
  EXECUTE FUNCTION activate_subscription_after_payment();

-- Mettre à jour les entreprises existantes sans période d'essai
UPDATE companies
SET
  trial_days = 30,
  trial_end_date = CASE
    WHEN is_approved = true AND (trial_end_date IS NULL OR trial_end_date < NOW())
    THEN NOW() + INTERVAL '30 days'
    ELSE trial_end_date
  END,
  subscription_status = CASE
    WHEN subscription_status = 'trial' OR subscription_status IS NULL
    THEN 'trial'
    ELSE subscription_status
  END
WHERE trial_days = 0 OR trial_days IS NULL;

-- Accorder les permissions nécessaires
GRANT EXECUTE ON FUNCTION set_company_trial_period() TO authenticated;
GRANT EXECUTE ON FUNCTION activate_subscription_after_payment() TO authenticated;