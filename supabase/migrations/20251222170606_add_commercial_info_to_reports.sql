/*
  # Add Commercial Info to Reports

  1. Changes
    - Add foreign key constraint between reports.user_id and profiles.id
    - This ensures data integrity when commercials are deleted
    - The constraint is added with ON DELETE CASCADE to remove reports when a commercial is deleted

  2. Security
    - No changes to RLS policies needed (already in place)
    - Each commercial can only see their own reports
    - Admins and supervisors can see all reports
*/

-- Add foreign key constraint if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'reports_user_id_fkey'
    AND table_name = 'reports'
  ) THEN
    ALTER TABLE reports
    ADD CONSTRAINT reports_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES profiles(id)
    ON DELETE CASCADE;
  END IF;
END $$;