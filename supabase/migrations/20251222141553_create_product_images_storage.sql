/*
  # Create Product Images Storage Bucket
  
  1. New Storage Bucket
    - Create 'product-images' bucket for storing product images
    - Public bucket to allow direct image access
  
  2. Security
    - Allow authenticated users to read all images
    - Allow admin and superviseur to upload images
    - Allow admin and superviseur to update/delete images
*/

-- Create the storage bucket for product images
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to read images
CREATE POLICY "Authenticated users can view product images"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'product-images');

-- Allow public access to view images (for public-facing pages)
CREATE POLICY "Public can view product images"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'product-images');

-- Allow admin and superviseur to upload images
CREATE POLICY "Admin and superviseur can upload product images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'product-images'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  );

-- Allow admin and superviseur to update images
CREATE POLICY "Admin and superviseur can update product images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'product-images'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  )
  WITH CHECK (
    bucket_id = 'product-images'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  );

-- Allow admin and superviseur to delete images
CREATE POLICY "Admin and superviseur can delete product images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'product-images'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'superviseur')
    )
  );