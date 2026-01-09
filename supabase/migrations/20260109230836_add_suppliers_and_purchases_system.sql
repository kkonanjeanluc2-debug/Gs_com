/*
  # Système de Gestion des Fournisseurs et Achats

  ## Nouvelles Tables

  ### 1. suppliers (Fournisseurs)
    - `id` (uuid, primary key)
    - `company_id` (uuid, foreign key vers companies)
    - `name` (text) - Nom du fournisseur
    - `email` (text) - Email du fournisseur
    - `phone` (text) - Téléphone du fournisseur
    - `address` (text) - Adresse
    - `city` (text) - Ville
    - `country` (text) - Pays
    - `notes` (text) - Notes
    - `created_at` (timestamptz)
    - `updated_at` (timestamptz)

  ### 2. purchases (Achats)
    - `id` (uuid, primary key)
    - `company_id` (uuid, foreign key vers companies)
    - `supplier_id` (uuid, foreign key vers suppliers)
    - `purchase_number` (text) - Numéro d'achat unique
    - `purchase_date` (date) - Date de l'achat
    - `status` (text) - Statut (pending, completed, cancelled)
    - `total_amount` (numeric) - Montant total
    - `notes` (text) - Notes
    - `created_by` (uuid, foreign key vers profiles)
    - `created_at` (timestamptz)
    - `updated_at` (timestamptz)

  ### 3. purchase_items (Lignes d'achat)
    - `id` (uuid, primary key)
    - `purchase_id` (uuid, foreign key vers purchases)
    - `product_id` (uuid, foreign key vers products)
    - `quantity` (integer) - Quantité achetée
    - `unit_price` (numeric) - Prix unitaire
    - `total_price` (numeric) - Prix total
    - `created_at` (timestamptz)
    - `updated_at` (timestamptz)

  ## Sécurité
    - Activer RLS sur toutes les tables
    - Les utilisateurs ne peuvent voir que les données de leur entreprise
    - Seuls les admins et superviseurs peuvent gérer les fournisseurs et achats
    - Les achats mettent automatiquement à jour le stock des produits

  ## Fonctions
    - Génération automatique du numéro d'achat
    - Mise à jour automatique du stock lors de la validation d'un achat
*/

-- Table des fournisseurs
CREATE TABLE IF NOT EXISTS suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  email text,
  phone text,
  address text,
  city text,
  country text DEFAULT 'Côte d''Ivoire',
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Table des achats
CREATE TABLE IF NOT EXISTS purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  supplier_id uuid REFERENCES suppliers(id) ON DELETE RESTRICT NOT NULL,
  purchase_number text NOT NULL,
  purchase_date date DEFAULT CURRENT_DATE NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'cancelled')),
  total_amount numeric(12, 2) DEFAULT 0,
  notes text,
  created_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, purchase_number)
);

-- Table des lignes d'achat
CREATE TABLE IF NOT EXISTS purchase_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id uuid REFERENCES purchases(id) ON DELETE CASCADE NOT NULL,
  product_id uuid REFERENCES products(id) ON DELETE RESTRICT NOT NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price numeric(12, 2) NOT NULL CHECK (unit_price >= 0),
  total_price numeric(12, 2) NOT NULL CHECK (total_price >= 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_suppliers_company_id ON suppliers(company_id);
CREATE INDEX IF NOT EXISTS idx_purchases_company_id ON purchases(company_id);
CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON purchases(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchases_status ON purchases(status);
CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON purchase_items(purchase_id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_product_id ON purchase_items(product_id);

-- RLS pour suppliers
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view suppliers of their company"
  ON suppliers FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins and supervisors can insert suppliers"
  ON suppliers FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superviseur')
      AND company_id = suppliers.company_id
    )
  );

CREATE POLICY "Admins and supervisors can update suppliers"
  ON suppliers FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superviseur')
      AND company_id = suppliers.company_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superviseur')
      AND company_id = suppliers.company_id
    )
  );

CREATE POLICY "Admins can delete suppliers"
  ON suppliers FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
      AND company_id = suppliers.company_id
    )
  );

-- RLS pour purchases
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view purchases of their company"
  ON purchases FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins and supervisors can insert purchases"
  ON purchases FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superviseur')
      AND company_id = purchases.company_id
    )
  );

CREATE POLICY "Admins and supervisors can update purchases"
  ON purchases FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superviseur')
      AND company_id = purchases.company_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superviseur')
      AND company_id = purchases.company_id
    )
  );

CREATE POLICY "Admins can delete purchases"
  ON purchases FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
      AND company_id = purchases.company_id
    )
  );

-- RLS pour purchase_items
ALTER TABLE purchase_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view purchase items of their company"
  ON purchase_items FOR SELECT
  TO authenticated
  USING (
    purchase_id IN (
      SELECT id FROM purchases
      WHERE company_id IN (
        SELECT company_id FROM profiles WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Admins and supervisors can insert purchase items"
  ON purchase_items FOR INSERT
  TO authenticated
  WITH CHECK (
    purchase_id IN (
      SELECT p.id FROM purchases p
      INNER JOIN profiles pr ON pr.company_id = p.company_id
      WHERE pr.id = auth.uid()
      AND pr.role IN ('admin', 'superviseur')
    )
  );

CREATE POLICY "Admins and supervisors can update purchase items"
  ON purchase_items FOR UPDATE
  TO authenticated
  USING (
    purchase_id IN (
      SELECT p.id FROM purchases p
      INNER JOIN profiles pr ON pr.company_id = p.company_id
      WHERE pr.id = auth.uid()
      AND pr.role IN ('admin', 'superviseur')
    )
  )
  WITH CHECK (
    purchase_id IN (
      SELECT p.id FROM purchases p
      INNER JOIN profiles pr ON pr.company_id = p.company_id
      WHERE pr.id = auth.uid()
      AND pr.role IN ('admin', 'superviseur')
    )
  );

CREATE POLICY "Admins can delete purchase items"
  ON purchase_items FOR DELETE
  TO authenticated
  USING (
    purchase_id IN (
      SELECT p.id FROM purchases p
      INNER JOIN profiles pr ON pr.company_id = p.company_id
      WHERE pr.id = auth.uid()
      AND pr.role = 'admin'
    )
  );

-- Fonction pour générer le numéro d'achat
CREATE OR REPLACE FUNCTION generate_purchase_number(p_company_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count integer;
  v_number text;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM purchases
  WHERE company_id = p_company_id
  AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM CURRENT_DATE);
  
  v_number := 'ACH-' || TO_CHAR(CURRENT_DATE, 'YYYY') || '-' || LPAD((v_count + 1)::text, 5, '0');
  
  RETURN v_number;
END;
$$;

-- Trigger pour auto-générer le numéro d'achat
CREATE OR REPLACE FUNCTION set_purchase_number()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.purchase_number IS NULL OR NEW.purchase_number = '' THEN
    NEW.purchase_number := generate_purchase_number(NEW.company_id);
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_set_purchase_number
  BEFORE INSERT ON purchases
  FOR EACH ROW
  EXECUTE FUNCTION set_purchase_number();

-- Fonction pour mettre à jour le stock lors de la validation d'un achat
CREATE OR REPLACE FUNCTION update_stock_on_purchase_completion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Si l'achat passe au statut 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- Mettre à jour le stock de tous les produits de l'achat
    UPDATE products p
    SET 
      quantity = p.quantity + pi.quantity,
      updated_at = now()
    FROM purchase_items pi
    WHERE pi.purchase_id = NEW.id
    AND pi.product_id = p.id;
    
    -- Enregistrer les mouvements de stock
    INSERT INTO stock_movements (product_id, movement_type, quantity, reference, notes, created_at)
    SELECT 
      pi.product_id,
      'purchase'::text,
      pi.quantity,
      NEW.purchase_number,
      'Achat validé - Fournisseur: ' || s.name,
      now()
    FROM purchase_items pi
    INNER JOIN suppliers s ON s.id = NEW.supplier_id
    WHERE pi.purchase_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_stock_on_purchase_completion
  AFTER UPDATE ON purchases
  FOR EACH ROW
  EXECUTE FUNCTION update_stock_on_purchase_completion();

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_suppliers_updated_at
  BEFORE UPDATE ON suppliers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_purchases_updated_at
  BEFORE UPDATE ON purchases
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_purchase_items_updated_at
  BEFORE UPDATE ON purchase_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
