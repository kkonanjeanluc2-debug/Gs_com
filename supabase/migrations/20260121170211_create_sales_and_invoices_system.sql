/*
  # Création du système de ventes et factures

  ## 1. Nouvelles Tables
  
  ### `sales` (Ventes)
  - `id` (uuid, primary key)
  - `sale_number` (text, unique) - Numéro de vente auto-généré
  - `client_id` (uuid) - Client
  - `commercial_id` (uuid) - Commercial qui a effectué la vente
  - `company_id` (uuid) - Entreprise
  - `total_amount` (numeric) - Montant total
  - `discount_amount` (numeric) - Montant de la remise
  - `final_amount` (numeric) - Montant final après remise
  - `payment_method` (text) - Mode de paiement
  - `payment_status` (text) - Statut du paiement
  - `notes` (text) - Notes
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)
  
  ### `sale_items` (Articles de vente)
  - `id` (uuid, primary key)
  - `sale_id` (uuid) - Vente associée
  - `product_id` (uuid) - Produit
  - `company_id` (uuid) - Entreprise
  - `quantity` (integer) - Quantité
  - `unit_price` (numeric) - Prix unitaire
  - `discount_percentage` (numeric) - Pourcentage de remise
  - `discount_amount` (numeric) - Montant de la remise
  - `subtotal` (numeric) - Sous-total (après remise)
  - `created_at` (timestamptz)
  
  ### `invoices` (Factures)
  - `id` (uuid, primary key)
  - `invoice_number` (text, unique) - Numéro de facture auto-généré
  - `order_id` (uuid, nullable) - Commande associée (si facture générée depuis commande)
  - `sale_id` (uuid, nullable) - Vente associée (si facture générée depuis vente)
  - `client_id` (uuid) - Client
  - `commercial_id` (uuid) - Commercial
  - `company_id` (uuid) - Entreprise
  - `total_amount` (numeric) - Montant total
  - `tax_amount` (numeric) - Montant de la taxe
  - `discount_amount` (numeric) - Montant de la remise
  - `final_amount` (numeric) - Montant final
  - `status` (text) - 'payee', 'en_attente', 'annulee'
  - `due_date` (date) - Date d'échéance
  - `payment_date` (date, nullable) - Date de paiement
  - `notes` (text)
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)
  
  ### `invoice_items` (Articles de facture)
  - `id` (uuid, primary key)
  - `invoice_id` (uuid) - Facture associée
  - `product_id` (uuid) - Produit
  - `company_id` (uuid) - Entreprise
  - `description` (text) - Description
  - `quantity` (integer) - Quantité
  - `unit_price` (numeric) - Prix unitaire
  - `discount_percentage` (numeric) - Pourcentage de remise
  - `subtotal` (numeric) - Sous-total
  - `created_at` (timestamptz)

  ## 2. Fonctions automatiques
  - Génération automatique des numéros de vente (SALE-YYYYMM-XXXX)
  - Génération automatique des numéros de facture (INV-YYYYMM-XXXX)
  - Mise à jour automatique du stock lors d'une vente
  
  ## 3. Sécurité
  - Enable RLS sur toutes les tables
  - Politiques basées sur company_id et rôles utilisateur
*/

-- Table des ventes
CREATE TABLE IF NOT EXISTS sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_number text UNIQUE NOT NULL,
  client_id uuid NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
  commercial_id uuid NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  total_amount numeric(12, 2) NOT NULL DEFAULT 0,
  discount_amount numeric(12, 2) NOT NULL DEFAULT 0,
  final_amount numeric(12, 2) NOT NULL DEFAULT 0,
  payment_method text NOT NULL CHECK (payment_method IN ('especes', 'mobile_money', 'virement', 'cheque', 'carte_bancaire', 'wave', 'orange_money', 'mtn_money', 'moov_money')),
  payment_status text NOT NULL CHECK (payment_status IN ('paye', 'en_attente', 'partiellement_paye')) DEFAULT 'paye',
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

-- Table des articles de vente
CREATE TABLE IF NOT EXISTS sale_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price numeric(10, 2) NOT NULL CHECK (unit_price >= 0),
  discount_percentage numeric(5, 2) NOT NULL DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
  discount_amount numeric(10, 2) NOT NULL DEFAULT 0,
  subtotal numeric(12, 2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;

-- Table des factures
CREATE TABLE IF NOT EXISTS invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number text UNIQUE NOT NULL,
  order_id uuid REFERENCES orders(id) ON DELETE SET NULL,
  sale_id uuid REFERENCES sales(id) ON DELETE SET NULL,
  client_id uuid NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
  commercial_id uuid NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  total_amount numeric(12, 2) NOT NULL DEFAULT 0,
  tax_amount numeric(12, 2) NOT NULL DEFAULT 0,
  discount_amount numeric(12, 2) NOT NULL DEFAULT 0,
  final_amount numeric(12, 2) NOT NULL DEFAULT 0,
  status text NOT NULL CHECK (status IN ('payee', 'en_attente', 'annulee')) DEFAULT 'en_attente',
  due_date date NOT NULL,
  payment_date date,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- Table des articles de facture
CREATE TABLE IF NOT EXISTS invoice_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE SET NULL,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  description text NOT NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price numeric(10, 2) NOT NULL CHECK (unit_price >= 0),
  discount_percentage numeric(5, 2) NOT NULL DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
  subtotal numeric(12, 2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;

-- Fonction pour générer un numéro de vente
CREATE OR REPLACE FUNCTION generate_sale_number()
RETURNS text AS $$
DECLARE
  current_month text;
  next_number integer;
  sale_num text;
BEGIN
  current_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
  
  SELECT COALESCE(MAX(CAST(SUBSTRING(sale_number FROM 'SALE-[0-9]{6}-([0-9]{4})') AS integer)), 0) + 1
  INTO next_number
  FROM sales
  WHERE sale_number LIKE 'SALE-' || current_month || '-%';
  
  sale_num := 'SALE-' || current_month || '-' || LPAD(next_number::text, 4, '0');
  
  RETURN sale_num;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour générer un numéro de facture
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS text AS $$
DECLARE
  current_month text;
  next_number integer;
  invoice_num text;
BEGIN
  current_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
  
  SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM 'INV-[0-9]{6}-([0-9]{4})') AS integer)), 0) + 1
  INTO next_number
  FROM invoices
  WHERE invoice_number LIKE 'INV-' || current_month || '-%';
  
  invoice_num := 'INV-' || current_month || '-' || LPAD(next_number::text, 4, '0');
  
  RETURN invoice_num;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour générer automatiquement le numéro de vente
CREATE OR REPLACE FUNCTION set_sale_number()
RETURNS trigger AS $$
BEGIN
  IF NEW.sale_number IS NULL OR NEW.sale_number = '' THEN
    NEW.sale_number := generate_sale_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_sale_number
  BEFORE INSERT ON sales
  FOR EACH ROW
  EXECUTE FUNCTION set_sale_number();

-- Trigger pour générer automatiquement le numéro de facture
CREATE OR REPLACE FUNCTION set_invoice_number()
RETURNS trigger AS $$
BEGIN
  IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
    NEW.invoice_number := generate_invoice_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_invoice_number
  BEFORE INSERT ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION set_invoice_number();

-- Trigger pour mettre à jour le stock après une vente
CREATE OR REPLACE FUNCTION update_stock_after_sale()
RETURNS trigger AS $$
BEGIN
  -- Décrémenter le stock du produit
  UPDATE products
  SET stock_quantity = stock_quantity - NEW.quantity,
      updated_at = now()
  WHERE id = NEW.product_id;
  
  -- Créer un mouvement de stock
  INSERT INTO stock_movements (product_id, user_id, type, quantity, reason, company_id)
  SELECT NEW.product_id, s.commercial_id, 'sortie', NEW.quantity, 
         'Vente ' || s.sale_number, NEW.company_id
  FROM sales s
  WHERE s.id = NEW.sale_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_update_stock_after_sale
  AFTER INSERT ON sale_items
  FOR EACH ROW
  EXECUTE FUNCTION update_stock_after_sale();

-- RLS Policies pour sales
CREATE POLICY "Authenticated users can view sales of their company"
  ON sales FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create sales for their company"
  ON sales FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can update sales of their company"
  ON sales FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins and supervisors can delete sales"
  ON sales FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() AND role IN ('admin', 'superviseur', 'super_admin')
    )
  );

-- RLS Policies pour sale_items
CREATE POLICY "Authenticated users can view sale_items of their company"
  ON sale_items FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create sale_items for their company"
  ON sale_items FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins and supervisors can delete sale_items"
  ON sale_items FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() AND role IN ('admin', 'superviseur', 'super_admin')
    )
  );

-- RLS Policies pour invoices
CREATE POLICY "Authenticated users can view invoices of their company"
  ON invoices FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create invoices for their company"
  ON invoices FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can update invoices of their company"
  ON invoices FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins and supervisors can delete invoices"
  ON invoices FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() AND role IN ('admin', 'superviseur', 'super_admin')
    )
  );

-- RLS Policies pour invoice_items
CREATE POLICY "Authenticated users can view invoice_items of their company"
  ON invoice_items FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create invoice_items for their company"
  ON invoice_items FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins and supervisors can delete invoice_items"
  ON invoice_items FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() AND role IN ('admin', 'superviseur', 'super_admin')
    )
  );

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_sales_company ON sales(company_id);
CREATE INDEX IF NOT EXISTS idx_sales_client ON sales(client_id);
CREATE INDEX IF NOT EXISTS idx_sales_commercial ON sales(commercial_id);
CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items(product_id);
CREATE INDEX IF NOT EXISTS idx_invoices_company ON invoices(company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_client ON invoices(client_id);
CREATE INDEX IF NOT EXISTS idx_invoices_order ON invoices(order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_sale ON invoices(sale_id);
CREATE INDEX IF NOT EXISTS idx_invoices_created_at ON invoices(created_at);
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id);
