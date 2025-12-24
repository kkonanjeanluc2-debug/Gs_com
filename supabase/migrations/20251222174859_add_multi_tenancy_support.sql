/*
  # Add Multi-Tenancy Support

  ## Overview
  This migration adds multi-tenancy support to allow multiple companies to use the application independently.

  ## 1. New Tables
  
  ### `companies`
  - `id` (uuid, primary key) - Company identifier
  - `name` (text) - Company name
  - `email` (text) - Company contact email
  - `phone` (text) - Company phone
  - `address` (text) - Company address
  - `logo_url` (text) - Company logo URL
  - `website` (text) - Company website
  - `tax_id` (text) - Tax identifier
  - `rccm` (text) - RCCM number
  - `ncc` (text) - NCC number
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ## 2. Schema Changes
  - Add `company_id` to `profiles` table
  - Add `company_id` to `products` table
  - Add `company_id` to `clients` table
  - Add `company_id` to `reports` table
  - Add `company_id` to `categories` table
  - Add `company_id` to `subcategories` table
  - Add `company_id` to `orders` table
  - Add `company_id` to `order_items` table
  - Add `company_id` to `stock_movements` table

  ## 3. Data Migration
  - Migrate existing `company_settings` data to new `companies` table
  - Assign all existing data to the first company

  ## 4. Security Updates
  - Update RLS policies to filter by company_id
  - Ensure data isolation between companies
  - Prevent cross-company data access

  ## 5. Important Notes
  - All existing data will be assigned to a single company
  - New users must be associated with a company
  - Admins can only manage data within their company
*/

-- Create companies table
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text,
  phone text,
  address text,
  logo_url text,
  website text,
  tax_id text,
  rccm text,
  ncc text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Migrate data from company_settings to companies
INSERT INTO companies (id, name, email, phone, address, logo_url, website, tax_id, rccm, ncc, created_at, updated_at)
SELECT id, company_name, email, phone, address, logo_url, website, tax_id, rccm, ncc, created_at, updated_at
FROM company_settings
WHERE NOT EXISTS (SELECT 1 FROM companies LIMIT 1);

-- Store the first company ID for data migration
DO $$
DECLARE
  first_company_id uuid;
BEGIN
  SELECT id INTO first_company_id FROM companies LIMIT 1;
  
  -- If no company exists, create a default one
  IF first_company_id IS NULL THEN
    INSERT INTO companies (name) VALUES ('Mon Entreprise') RETURNING id INTO first_company_id;
  END IF;
END $$;

-- Add company_id to profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE profiles ADD COLUMN company_id uuid REFERENCES companies(id) ON DELETE CASCADE;
    
    -- Assign all existing profiles to the first company
    UPDATE profiles SET company_id = (SELECT id FROM companies LIMIT 1) WHERE company_id IS NULL;
    
    -- Make company_id required for new records
    ALTER TABLE profiles ALTER COLUMN company_id SET NOT NULL;
    
    CREATE INDEX idx_profiles_company_id ON profiles(company_id);
  END IF;
END $$;

-- Add company_id to products
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE products ADD COLUMN company_id uuid REFERENCES companies(id) ON DELETE CASCADE;
    
    UPDATE products SET company_id = (SELECT id FROM companies LIMIT 1) WHERE company_id IS NULL;
    
    ALTER TABLE products ALTER COLUMN company_id SET NOT NULL;
    
    CREATE INDEX idx_products_company_id ON products(company_id);
  END IF;
END $$;

-- Add company_id to clients
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'clients' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE clients ADD COLUMN company_id uuid REFERENCES companies(id) ON DELETE CASCADE;
    
    UPDATE clients SET company_id = (SELECT id FROM companies LIMIT 1) WHERE company_id IS NULL;
    
    ALTER TABLE clients ALTER COLUMN company_id SET NOT NULL;
    
    CREATE INDEX idx_clients_company_id ON clients(company_id);
  END IF;
END $$;

-- Add company_id to reports
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'reports' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE reports ADD COLUMN company_id uuid REFERENCES companies(id) ON DELETE CASCADE;
    
    UPDATE reports SET company_id = (SELECT id FROM companies LIMIT 1) WHERE company_id IS NULL;
    
    ALTER TABLE reports ALTER COLUMN company_id SET NOT NULL;
    
    CREATE INDEX idx_reports_company_id ON reports(company_id);
  END IF;
END $$;

-- Add company_id to categories
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'categories' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE categories ADD COLUMN company_id uuid REFERENCES companies(id) ON DELETE CASCADE;
    
    UPDATE categories SET company_id = (SELECT id FROM companies LIMIT 1) WHERE company_id IS NULL;
    
    ALTER TABLE categories ALTER COLUMN company_id SET NOT NULL;
    
    CREATE INDEX idx_categories_company_id ON categories(company_id);
  END IF;
END $$;

-- Add company_id to subcategories
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subcategories' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE subcategories ADD COLUMN company_id uuid REFERENCES companies(id) ON DELETE CASCADE;
    
    UPDATE subcategories SET company_id = (SELECT id FROM companies LIMIT 1) WHERE company_id IS NULL;
    
    ALTER TABLE subcategories ALTER COLUMN company_id SET NOT NULL;
    
    CREATE INDEX idx_subcategories_company_id ON subcategories(company_id);
  END IF;
END $$;

-- Add company_id to orders
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE orders ADD COLUMN company_id uuid REFERENCES companies(id) ON DELETE CASCADE;
    
    UPDATE orders SET company_id = (SELECT id FROM companies LIMIT 1) WHERE company_id IS NULL;
    
    ALTER TABLE orders ALTER COLUMN company_id SET NOT NULL;
    
    CREATE INDEX idx_orders_company_id ON orders(company_id);
  END IF;
END $$;

-- Add company_id to order_items
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'order_items' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE order_items ADD COLUMN company_id uuid REFERENCES companies(id) ON DELETE CASCADE;
    
    UPDATE order_items SET company_id = (SELECT id FROM companies LIMIT 1) WHERE company_id IS NULL;
    
    ALTER TABLE order_items ALTER COLUMN company_id SET NOT NULL;
    
    CREATE INDEX idx_order_items_company_id ON order_items(company_id);
  END IF;
END $$;

-- Add company_id to stock_movements
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stock_movements' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE stock_movements ADD COLUMN company_id uuid REFERENCES companies(id) ON DELETE CASCADE;
    
    UPDATE stock_movements SET company_id = (SELECT id FROM companies LIMIT 1) WHERE company_id IS NULL;
    
    ALTER TABLE stock_movements ALTER COLUMN company_id SET NOT NULL;
    
    CREATE INDEX idx_stock_movements_company_id ON stock_movements(company_id);
  END IF;
END $$;

-- Update get_user_role function to include company context
CREATE OR REPLACE FUNCTION get_user_role(user_id uuid)
RETURNS text AS $$
  SELECT role FROM profiles WHERE id = user_id;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Create helper function to get user's company
CREATE OR REPLACE FUNCTION get_user_company(user_id uuid)
RETURNS uuid AS $$
  SELECT company_id FROM profiles WHERE id = user_id;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Drop existing policies to recreate them with company filtering
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Everyone can view products" ON products;
DROP POLICY IF EXISTS "Admins and superviseurs can manage products" ON products;
DROP POLICY IF EXISTS "Commercials can view assigned clients" ON clients;
DROP POLICY IF EXISTS "Commercials can update assigned clients" ON clients;
DROP POLICY IF EXISTS "Commercials can create clients" ON clients;
DROP POLICY IF EXISTS "Admins can delete clients" ON clients;
DROP POLICY IF EXISTS "Commercials can view own reports" ON reports;
DROP POLICY IF EXISTS "Commercials can create own reports" ON reports;
DROP POLICY IF EXISTS "Commercials can update own reports" ON reports;
DROP POLICY IF EXISTS "Commercials can delete own reports" ON reports;
DROP POLICY IF EXISTS "Everyone can view stock movements" ON stock_movements;
DROP POLICY IF EXISTS "Admins and superviseurs can create stock movements" ON stock_movements;

-- RLS Policies for companies
CREATE POLICY "Users can view own company"
  ON companies FOR SELECT
  TO authenticated
  USING (id = get_user_company(auth.uid()));

CREATE POLICY "Admins can update own company"
  ON companies FOR UPDATE
  TO authenticated
  USING (
    id = get_user_company(auth.uid()) 
    AND get_user_role(auth.uid()) = 'admin'
  )
  WITH CHECK (
    id = get_user_company(auth.uid()) 
    AND get_user_role(auth.uid()) = 'admin'
  );

-- RLS Policies for profiles (with company filtering)
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id AND company_id = get_user_company(auth.uid()));

CREATE POLICY "Admins can view company profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    get_user_role(auth.uid()) = 'admin' 
    AND company_id = get_user_company(auth.uid())
  );

CREATE POLICY "Admins can insert company profiles"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role(auth.uid()) = 'admin' 
    AND company_id = get_user_company(auth.uid())
  );

CREATE POLICY "Admins can update company profiles"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    get_user_role(auth.uid()) = 'admin' 
    AND company_id = get_user_company(auth.uid())
  )
  WITH CHECK (
    get_user_role(auth.uid()) = 'admin' 
    AND company_id = get_user_company(auth.uid())
  );

-- RLS Policies for products (with company filtering)
CREATE POLICY "Users can view company products"
  ON products FOR SELECT
  TO authenticated
  USING (company_id = get_user_company(auth.uid()));

CREATE POLICY "Admins and superviseurs can manage company products"
  ON products FOR ALL
  TO authenticated
  USING (
    get_user_role(auth.uid()) IN ('admin', 'superviseur')
    AND company_id = get_user_company(auth.uid())
  )
  WITH CHECK (
    get_user_role(auth.uid()) IN ('admin', 'superviseur')
    AND company_id = get_user_company(auth.uid())
  );

-- RLS Policies for clients (with company filtering)
CREATE POLICY "Commercials can view company clients"
  ON clients FOR SELECT
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND (
      get_user_role(auth.uid()) IN ('admin', 'superviseur') 
      OR assigned_to = auth.uid()
    )
  );

CREATE POLICY "Commercials can update company clients"
  ON clients FOR UPDATE
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND (
      get_user_role(auth.uid()) IN ('admin', 'superviseur') 
      OR assigned_to = auth.uid()
    )
  )
  WITH CHECK (
    company_id = get_user_company(auth.uid())
    AND (
      get_user_role(auth.uid()) IN ('admin', 'superviseur') 
      OR assigned_to = auth.uid()
    )
  );

CREATE POLICY "Commercials can create company clients"
  ON clients FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id = get_user_company(auth.uid())
    AND get_user_role(auth.uid()) IN ('admin', 'superviseur', 'commercial')
  );

CREATE POLICY "Admins can delete company clients"
  ON clients FOR DELETE
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND get_user_role(auth.uid()) = 'admin'
  );

-- RLS Policies for reports (with company filtering)
CREATE POLICY "Commercials can view company reports"
  ON reports FOR SELECT
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND (
      get_user_role(auth.uid()) IN ('admin', 'superviseur') 
      OR user_id = auth.uid()
    )
  );

CREATE POLICY "Commercials can create company reports"
  ON reports FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND company_id = get_user_company(auth.uid())
  );

CREATE POLICY "Commercials can update company reports"
  ON reports FOR UPDATE
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND user_id = auth.uid()
  )
  WITH CHECK (
    company_id = get_user_company(auth.uid())
    AND user_id = auth.uid()
  );

CREATE POLICY "Commercials can delete company reports"
  ON reports FOR DELETE
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND (
      get_user_role(auth.uid()) IN ('admin', 'superviseur') 
      OR user_id = auth.uid()
    )
  );

-- RLS Policies for categories (with company filtering)
CREATE POLICY "Users can view company categories"
  ON categories FOR SELECT
  TO authenticated
  USING (company_id = get_user_company(auth.uid()));

CREATE POLICY "Admins can manage company categories"
  ON categories FOR ALL
  TO authenticated
  USING (
    get_user_role(auth.uid()) = 'admin'
    AND company_id = get_user_company(auth.uid())
  )
  WITH CHECK (
    get_user_role(auth.uid()) = 'admin'
    AND company_id = get_user_company(auth.uid())
  );

-- RLS Policies for subcategories (with company filtering)
CREATE POLICY "Users can view company subcategories"
  ON subcategories FOR SELECT
  TO authenticated
  USING (company_id = get_user_company(auth.uid()));

CREATE POLICY "Admins can manage company subcategories"
  ON subcategories FOR ALL
  TO authenticated
  USING (
    get_user_role(auth.uid()) = 'admin'
    AND company_id = get_user_company(auth.uid())
  )
  WITH CHECK (
    get_user_role(auth.uid()) = 'admin'
    AND company_id = get_user_company(auth.uid())
  );

-- RLS Policies for orders (with company filtering)
CREATE POLICY "Users can view company orders"
  ON orders FOR SELECT
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND (
      get_user_role(auth.uid()) IN ('admin', 'superviseur')
      OR commercial_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage company orders"
  ON orders FOR ALL
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND (
      get_user_role(auth.uid()) IN ('admin', 'superviseur')
      OR commercial_id = auth.uid()
    )
  )
  WITH CHECK (
    company_id = get_user_company(auth.uid())
    AND (
      get_user_role(auth.uid()) IN ('admin', 'superviseur')
      OR commercial_id = auth.uid()
    )
  );

-- RLS Policies for order_items (with company filtering)
CREATE POLICY "Users can view company order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (company_id = get_user_company(auth.uid()));

CREATE POLICY "Users can manage company order items"
  ON order_items FOR ALL
  TO authenticated
  USING (company_id = get_user_company(auth.uid()))
  WITH CHECK (company_id = get_user_company(auth.uid()));

-- RLS Policies for stock_movements (with company filtering)
CREATE POLICY "Users can view company stock movements"
  ON stock_movements FOR SELECT
  TO authenticated
  USING (
    company_id = get_user_company(auth.uid())
    AND get_user_role(auth.uid()) IN ('admin', 'superviseur', 'commercial')
  );

CREATE POLICY "Admins and superviseurs can create company stock movements"
  ON stock_movements FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id = get_user_company(auth.uid())
    AND get_user_role(auth.uid()) IN ('admin', 'superviseur')
  );
