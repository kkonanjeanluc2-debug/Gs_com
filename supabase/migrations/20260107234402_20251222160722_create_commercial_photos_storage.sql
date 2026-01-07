/*
  # Create storage bucket for commercial photos

  1. New Bucket
    - `commercial-photos` - Public bucket for storing commercial profile photos
  
  2. Security
    - Enable public access for reading photos
    - Only authenticated admins can upload/delete photos
*/

INSERT INTO storage.buckets (id, name, public)
VALUES ('commercial-photos', 'commercial-photos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public read access for commercial photos"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'commercial-photos');

CREATE POLICY "Admins can upload commercial photos"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'commercial-photos' 
    AND (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  );

CREATE POLICY "Admins can update commercial photos"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'commercial-photos' 
    AND (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  )
  WITH CHECK (
    bucket_id = 'commercial-photos' 
    AND (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  );

CREATE POLICY "Admins can delete commercial photos"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'commercial-photos' 
    AND (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  );