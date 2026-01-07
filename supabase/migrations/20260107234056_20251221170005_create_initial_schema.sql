/*
  # Schéma initial - Gestion Commerciale avec Authentification

  ## 1. Nouvelles Tables
  
  ### `profiles`
  - `id` (uuid, primary key) - Lié à auth.users
  - `email` (text) - Email de l'utilisateur
  - `full_name` (text) - Nom complet
  - `role` (text) - Rôle: 'admin', 'superviseur', 'commercial'
  - `phone` (text) - Numéro de téléphone
  - `created_at` (timestamptz) - Date de création
  - `updated_at` (timestamptz) - Date de mise à jour

  ### `products`
  - `id` (uuid, primary key)
  - `name` (text) - Nom du produit
  - `description` (text) - Description
  - `sku` (text) - Référence produit
  - `price` (numeric) - Prix unitaire
  - `stock_quantity` (integer) - Quantité en stock
  - `min_stock` (integer) - Stock minimum
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### `clients`
  - `id` (uuid, primary key)
  - `name` (text) - Nom du client
  - `email` (text) - Email
  - `phone` (text) - Téléphone
  - `address` (text) - Adresse
  - `type` (text) - 'prospect' ou 'client'
  - `status` (text) - 'actif', 'inactif', 'en_negociation'
  - `assigned_to` (uuid) - Commercial assigné
  - `notes` (text) - Notes
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### `reports`
  - `id` (uuid, primary key)
  - `user_id` (uuid) - Utilisateur qui a créé le rapport
  - `date` (date) - Date du rapport
  - `prospects` (integer) - Nombre de prospects rencontrés
  - `nouveaux_prospects` (integer) - Nouveaux prospects
  - `comm_prospects` (text) - Commentaires prospects
  - `commandes` (integer) - Nombre de commandes
  - `ca` (numeric) - Chiffre d'affaires
  - `comm_commandes` (text) - Commentaires commandes
  - `status` (text) - 'envoye', 'brouillon', 'archive'
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### `stock_movements`
  - `id` (uuid, primary key)
  - `product_id` (uuid) - Produit concerné
  - `user_id` (uuid) - Utilisateur qui a effectué le mouvement
  - `type` (text) - 'entree', 'sortie', 'ajustement'
  - `quantity` (integer) - Quantité
  - `reason` (text) - Raison du mouvement
  - `created_at` (timestamptz)

  ## 2. Sécurité
  - Enable RLS sur toutes les tables
  - Politiques basées sur les rôles utilisateur
  
  ## 3. Notes importantes
  - Les admins ont accès complet
  - Les superviseurs peuvent voir tous les rapports et gérer le stock
  - Les commerciaux ne voient que leurs propres données
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text NOT NULL,
  role text NOT NULL CHECK (role IN ('admin', 'superviseur', 'commercial')),
  phone text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text,
  sku text UNIQUE NOT NULL,
  price numeric(10, 2) NOT NULL DEFAULT 0,
  stock_quantity integer NOT NULL DEFAULT 0,
  min_stock integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Clients table
CREATE TABLE IF NOT EXISTS clients (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  email text,
  phone text,
  address text,
  type text NOT NULL CHECK (type IN ('prospect', 'client')) DEFAULT 'prospect',
  status text NOT NULL CHECK (status IN ('actif', 'inactif', 'en_negociation')) DEFAULT 'actif',
  assigned_to uuid REFERENCES profiles(id) ON DELETE SET NULL,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Reports table
CREATE TABLE IF NOT EXISTS reports (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date date NOT NULL DEFAULT CURRENT_DATE,
  prospects integer NOT NULL DEFAULT 0,
  nouveaux_prospects integer NOT NULL DEFAULT 0,
  comm_prospects text,
  commandes integer NOT NULL DEFAULT 0,
  ca numeric(12, 2) NOT NULL DEFAULT 0,
  comm_commandes text,
  status text NOT NULL CHECK (status IN ('envoye', 'brouillon', 'archive')) DEFAULT 'brouillon',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Stock movements table
CREATE TABLE IF NOT EXISTS stock_movements (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('entree', 'sortie', 'ajustement')),
  quantity integer NOT NULL,
  reason text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;

-- Function to get user role
CREATE OR REPLACE FUNCTION get_user_role(user_id uuid)
RETURNS text AS $$
  SELECT role FROM profiles WHERE id = user_id;
$$ LANGUAGE sql SECURITY DEFINER;

-- RLS Policies for profiles
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Admins can insert profiles"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Admins can update all profiles"
  ON profiles FOR UPDATE
  TO authenticated
  USING (get_user_role(auth.uid()) = 'admin');

-- RLS Policies for products
CREATE POLICY "Everyone can view products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins and superviseurs can manage products"
  ON products FOR ALL
  TO authenticated
  USING (get_user_role(auth.uid()) IN ('admin', 'superviseur'))
  WITH CHECK (get_user_role(auth.uid()) IN ('admin', 'superviseur'));

-- RLS Policies for clients
CREATE POLICY "Commercials can view assigned clients"
  ON clients FOR SELECT
  TO authenticated
  USING (
    get_user_role(auth.uid()) IN ('admin', 'superviseur') 
    OR assigned_to = auth.uid()
  );

CREATE POLICY "Commercials can update assigned clients"
  ON clients FOR UPDATE
  TO authenticated
  USING (
    get_user_role(auth.uid()) IN ('admin', 'superviseur') 
    OR assigned_to = auth.uid()
  )
  WITH CHECK (
    get_user_role(auth.uid()) IN ('admin', 'superviseur') 
    OR assigned_to = auth.uid()
  );

CREATE POLICY "Commercials can create clients"
  ON clients FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role(auth.uid()) IN ('admin', 'superviseur', 'commercial')
  );

CREATE POLICY "Admins can delete clients"
  ON clients FOR DELETE
  TO authenticated
  USING (get_user_role(auth.uid()) = 'admin');

-- RLS Policies for reports
CREATE POLICY "Commercials can view own reports"
  ON reports FOR SELECT
  TO authenticated
  USING (
    get_user_role(auth.uid()) IN ('admin', 'superviseur') 
    OR user_id = auth.uid()
  );

CREATE POLICY "Commercials can create own reports"
  ON reports FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Commercials can update own reports"
  ON reports FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Commercials can delete own reports"
  ON reports FOR DELETE
  TO authenticated
  USING (
    get_user_role(auth.uid()) IN ('admin', 'superviseur') 
    OR user_id = auth.uid()
  );

-- RLS Policies for stock_movements
CREATE POLICY "Everyone can view stock movements"
  ON stock_movements FOR SELECT
  TO authenticated
  USING (
    get_user_role(auth.uid()) IN ('admin', 'superviseur', 'commercial')
  );

CREATE POLICY "Admins and superviseurs can create stock movements"
  ON stock_movements FOR INSERT
  TO authenticated
  WITH CHECK (get_user_role(auth.uid()) IN ('admin', 'superviseur'));

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_reports_user_id ON reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_date ON reports(date);
CREATE INDEX IF NOT EXISTS idx_clients_assigned_to ON clients(assigned_to);
CREATE INDEX IF NOT EXISTS idx_stock_movements_product_id ON stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);