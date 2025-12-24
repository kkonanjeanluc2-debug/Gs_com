/*
  # Create Company Settings System

  1. New Tables
    - `company_settings`
      - `id` (uuid, primary key) - Single row for company info
      - `company_name` (text) - Company name
      - `email` (text) - Company email
      - `phone` (text) - Company phone
      - `address` (text) - Company address
      - `logo_url` (text) - Company logo URL
      - `website` (text) - Company website
      - `tax_id` (text) - Tax identification number
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Storage
    - Create bucket for company logos
    - Public access for logos

  3. Security
    - Enable RLS on company_settings table
    - All authenticated users can read settings
    - Only admins can update settings

  4. Initial Data
    - Insert default company settings row
*/

-- Create company_settings table
CREATE TABLE IF NOT EXISTS company_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name text NOT NULL DEFAULT 'Mon Entreprise',
  email text,
  phone text,
  address text,
  logo_url text,
  website text,
  tax_id text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create storage bucket for company logos
INSERT INTO storage.buckets (id, name, public)
VALUES ('company-logos', 'company-logos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for company logos
CREATE POLICY "Public can view company logos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'company-logos');

CREATE POLICY "Admins can upload company logos"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'company-logos'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can update company logos"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'company-logos'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can delete company logos"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'company-logos'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Enable RLS
ALTER TABLE company_settings ENABLE ROW LEVEL SECURITY;

-- Company settings policies
CREATE POLICY "All authenticated users can view company settings"
  ON company_settings FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can update company settings"
  ON company_settings FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can insert company settings"
  ON company_settings FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create trigger to update updated_at
CREATE TRIGGER trigger_update_company_settings_updated_at
BEFORE UPDATE ON company_settings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- Insert default company settings (only if table is empty)
INSERT INTO company_settings (company_name)
SELECT 'Mon Entreprise'
WHERE NOT EXISTS (SELECT 1 FROM company_settings);