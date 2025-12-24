/*
  # Système de Gestion des Tâches

  1. Nouvelles Tables
    - `tasks`
      - `id` (uuid, clé primaire)
      - `company_id` (uuid, identifiant de l'entreprise)
      - `title` (text, titre de la tâche)
      - `description` (text, description détaillée)
      - `assigned_to` (uuid, référence vers profiles - utilisateur assigné)
      - `assigned_by` (uuid, référence vers profiles - qui a créé la tâche)
      - `priority` (text, priorité: low, medium, high, urgent)
      - `status` (text, statut: pending, in_progress, completed, cancelled)
      - `due_date` (date, date d'échéance)
      - `completed_at` (timestamptz, date de complétion)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Sécurité
    - Activer RLS sur la table `tasks`
    - Les admins et superviseurs peuvent voir toutes les tâches de leur entreprise
    - Les commerciaux peuvent voir uniquement leurs tâches assignées
    - Seuls les admins et superviseurs peuvent créer des tâches
    - Les utilisateurs peuvent mettre à jour le statut de leurs propres tâches
*/

CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  title text NOT NULL,
  description text DEFAULT '',
  assigned_to uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  assigned_by uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  due_date date,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins and supervisors can view all company tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'superviseur')
    )
  );

CREATE POLICY "Users can view their assigned tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (
    assigned_to = auth.uid()
  );

CREATE POLICY "Admins and supervisors can create tasks"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'superviseur')
    )
  );

CREATE POLICY "Admins and supervisors can update all company tasks"
  ON tasks FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'superviseur')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'superviseur')
    )
  );

CREATE POLICY "Users can update status of their assigned tasks"
  ON tasks FOR UPDATE
  TO authenticated
  USING (assigned_to = auth.uid())
  WITH CHECK (assigned_to = auth.uid());

CREATE POLICY "Admins and supervisors can delete tasks"
  ON tasks FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'superviseur')
    )
  );

CREATE INDEX IF NOT EXISTS idx_tasks_company_id ON tasks(company_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
