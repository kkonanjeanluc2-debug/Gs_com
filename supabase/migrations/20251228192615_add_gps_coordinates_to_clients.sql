/*
  # Add GPS Coordinates to Clients

  1. Changes
    - Add `latitude` column to `clients` table (decimal type for precision)
    - Add `longitude` column to `clients` table (decimal type for precision)
    - These fields are optional and will be used to store GPS location of clients/prospects
  
  2. Notes
    - Coordinates are stored as NUMERIC(10,8) for latitude (range: -90 to +90)
    - Coordinates are stored as NUMERIC(11,8) for longitude (range: -180 to +180)
    - Both fields are nullable as GPS location is optional
*/

-- Add GPS coordinates columns to clients table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'clients' AND column_name = 'latitude'
  ) THEN
    ALTER TABLE clients ADD COLUMN latitude NUMERIC(10,8);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'clients' AND column_name = 'longitude'
  ) THEN
    ALTER TABLE clients ADD COLUMN longitude NUMERIC(11,8);
  END IF;
END $$;