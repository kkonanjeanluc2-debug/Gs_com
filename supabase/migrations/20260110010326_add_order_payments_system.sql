/*
  # Système de gestion des avances sur commandes

  1. Modifications de la table orders
    - Ajouter `total_paid` pour suivre le montant total payé
    - Ajouter `payment_status` pour suivre l'état du paiement
    
  2. Nouvelle table order_payments
    - Enregistre tous les paiements/avances effectués sur les commandes
    - `id` (uuid, primary key)
    - `order_id` (uuid, foreign key vers orders)
    - `client_id` (uuid, foreign key vers clients)
    - `company_id` (uuid, foreign key vers companies)
    - `amount` (decimal) : montant du paiement
    - `payment_method` (text) : espèces, mobile money, virement, chèque
    - `payment_reference` (text) : référence de transaction
    - `payment_date` (timestamp)
    - `notes` (text)
    - `created_by` (uuid, foreign key vers profiles)
    - `receipt_number` (text) : numéro de reçu unique
    
  3. Security
    - Enable RLS sur `order_payments`
    - Policies pour limiter l'accès aux utilisateurs de la même entreprise
*/

-- Ajouter les champs de paiement aux commandes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'orders' AND column_name = 'total_paid'
  ) THEN
    ALTER TABLE orders ADD COLUMN total_paid decimal(10,2) NOT NULL DEFAULT 0;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'orders' AND column_name = 'payment_status'
  ) THEN
    ALTER TABLE orders ADD COLUMN payment_status text NOT NULL DEFAULT 'non_paye';
  END IF;
END $$;

-- Ajouter la contrainte pour payment_status
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'orders_payment_status_check' AND table_name = 'orders'
  ) THEN
    ALTER TABLE orders ADD CONSTRAINT orders_payment_status_check 
      CHECK (payment_status IN ('non_paye', 'partiellement_paye', 'totalement_paye'));
  END IF;
END $$;

-- Créer la table order_payments
CREATE TABLE IF NOT EXISTS order_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  amount decimal(10,2) NOT NULL CHECK (amount > 0),
  payment_method text NOT NULL DEFAULT 'especes',
  payment_reference text,
  payment_date timestamptz NOT NULL DEFAULT now(),
  notes text,
  created_by uuid NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  receipt_number text UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT order_payments_payment_method_check 
    CHECK (payment_method IN ('especes', 'mobile_money', 'virement', 'cheque', 'carte_bancaire'))
);

-- Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_order_payments_order_id ON order_payments(order_id);
CREATE INDEX IF NOT EXISTS idx_order_payments_client_id ON order_payments(client_id);
CREATE INDEX IF NOT EXISTS idx_order_payments_company_id ON order_payments(company_id);
CREATE INDEX IF NOT EXISTS idx_order_payments_payment_date ON order_payments(payment_date);
CREATE INDEX IF NOT EXISTS idx_order_payments_receipt_number ON order_payments(receipt_number);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);

-- Enable Row Level Security
ALTER TABLE order_payments ENABLE ROW LEVEL SECURITY;

-- Policies pour order_payments
CREATE POLICY "Users can view company order payments"
  ON order_payments FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can create company order payments"
  ON order_payments FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins and supervisors can update order payments"
  ON order_payments FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'supervisor')
    )
  );

CREATE POLICY "Admins can delete order payments"
  ON order_payments FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Fonction pour générer automatiquement un numéro de reçu
CREATE OR REPLACE FUNCTION generate_receipt_number()
RETURNS TRIGGER AS $$
DECLARE
  company_prefix text;
  next_number integer;
BEGIN
  -- Récupérer le préfixe de l'entreprise (3 premières lettres du nom)
  SELECT UPPER(SUBSTRING(name, 1, 3)) INTO company_prefix
  FROM companies
  WHERE id = NEW.company_id;
  
  -- Compter le nombre de paiements existants pour cette entreprise
  SELECT COUNT(*) + 1 INTO next_number
  FROM order_payments
  WHERE company_id = NEW.company_id;
  
  -- Générer le numéro de reçu: PREFIX-YYYYMMDD-NNNN
  NEW.receipt_number := company_prefix || '-' || 
                       TO_CHAR(NEW.payment_date, 'YYYYMMDD') || '-' || 
                       LPAD(next_number::text, 4, '0');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour générer automatiquement le numéro de reçu
DROP TRIGGER IF EXISTS generate_receipt_number_trigger ON order_payments;
CREATE TRIGGER generate_receipt_number_trigger
  BEFORE INSERT ON order_payments
  FOR EACH ROW
  WHEN (NEW.receipt_number IS NULL)
  EXECUTE FUNCTION generate_receipt_number();

-- Fonction pour mettre à jour automatiquement le statut de paiement d'une commande
CREATE OR REPLACE FUNCTION update_order_payment_status()
RETURNS TRIGGER AS $$
DECLARE
  order_total decimal(10,2);
  order_paid decimal(10,2);
  target_order_id uuid;
BEGIN
  -- Déterminer l'ID de la commande
  IF TG_OP = 'DELETE' THEN
    target_order_id := OLD.order_id;
  ELSE
    target_order_id := NEW.order_id;
  END IF;
  
  -- Récupérer le montant total de la commande
  SELECT total_amount INTO order_total
  FROM orders
  WHERE id = target_order_id;
  
  -- Calculer le montant total payé
  SELECT COALESCE(SUM(amount), 0) INTO order_paid
  FROM order_payments
  WHERE order_id = target_order_id;
  
  -- Mettre à jour le statut de paiement
  UPDATE orders
  SET 
    total_paid = order_paid,
    payment_status = CASE
      WHEN order_paid = 0 THEN 'non_paye'
      WHEN order_paid >= order_total THEN 'totalement_paye'
      ELSE 'partiellement_paye'
    END,
    updated_at = now()
  WHERE id = target_order_id;
  
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers pour mettre à jour automatiquement le statut de paiement
DROP TRIGGER IF EXISTS update_order_payment_status_on_insert ON order_payments;
CREATE TRIGGER update_order_payment_status_on_insert
  AFTER INSERT ON order_payments
  FOR EACH ROW
  EXECUTE FUNCTION update_order_payment_status();

DROP TRIGGER IF EXISTS update_order_payment_status_on_update ON order_payments;
CREATE TRIGGER update_order_payment_status_on_update
  AFTER UPDATE ON order_payments
  FOR EACH ROW
  EXECUTE FUNCTION update_order_payment_status();

DROP TRIGGER IF EXISTS update_order_payment_status_on_delete ON order_payments;
CREATE TRIGGER update_order_payment_status_on_delete
  AFTER DELETE ON order_payments
  FOR EACH ROW
  EXECUTE FUNCTION update_order_payment_status();