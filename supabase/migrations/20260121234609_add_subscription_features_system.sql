/*
  # Système de fonctionnalités pour les plans d'abonnement

  1. Nouvelles tables
    - `features` - Fonctionnalités disponibles dans l'application
      - `id` (uuid, primary key)
      - `code` (text, unique) - Code unique de la fonctionnalité (ex: "sales_management", "inventory_tracking")
      - `name` (text) - Nom de la fonctionnalité
      - `description` (text) - Description détaillée
      - `category` (text) - Catégorie (core, advanced, premium)
      - `is_active` (boolean) - Fonctionnalité active ou non
      - `display_order` (integer) - Ordre d'affichage
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `subscription_plan_features` - Liaison entre plans et fonctionnalités
      - `id` (uuid, primary key)
      - `plan_id` (uuid, foreign key) - Référence au plan
      - `feature_id` (uuid, foreign key) - Référence à la fonctionnalité
      - `is_included` (boolean) - Feature incluse dans le plan
      - `created_at` (timestamptz)

  2. Modifications
    - Ajouter colonne features (jsonb) à subscription_plans pour stockage rapide
    - Créer trigger pour synchroniser les features avec subscription_plans

  3. Sécurité
    - RLS pour les features (public en lecture, super admin en modification)
    - RLS pour subscription_plan_features (public en lecture, super admin en modification)
*/

-- Créer la table features
CREATE TABLE IF NOT EXISTS features (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  name text NOT NULL,
  description text,
  category text DEFAULT 'core' NOT NULL,
  is_active boolean DEFAULT true,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE features ENABLE ROW LEVEL SECURITY;

-- Contrainte pour les catégories
ALTER TABLE features
ADD CONSTRAINT features_category_check
CHECK (category IN ('core', 'advanced', 'premium', 'enterprise'));

-- Tout le monde peut voir les features actives
CREATE POLICY "Anyone can view active features"
  ON features FOR SELECT
  USING (is_active = true);

-- Super admin peut gérer les features
CREATE POLICY "Super admin can manage features"
  ON features FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );

-- Créer la table subscription_plan_features
CREATE TABLE IF NOT EXISTS subscription_plan_features (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL REFERENCES subscription_plans(id) ON DELETE CASCADE,
  feature_id uuid NOT NULL REFERENCES features(id) ON DELETE CASCADE,
  is_included boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  UNIQUE(plan_id, feature_id)
);

ALTER TABLE subscription_plan_features ENABLE ROW LEVEL SECURITY;

-- Index pour accélération des requêtes
CREATE INDEX IF NOT EXISTS idx_subscription_plan_features_plan_id ON subscription_plan_features(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscription_plan_features_feature_id ON subscription_plan_features(feature_id);

-- Tout le monde peut voir les features des plans
CREATE POLICY "Anyone can view plan features"
  ON subscription_plan_features FOR SELECT
  USING (true);

-- Super admin peut gérer les features des plans
CREATE POLICY "Super admin can manage plan features"
  ON subscription_plan_features FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );

-- Ajouter colonne features à subscription_plans pour cache
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'subscription_plans' AND column_name = 'features'
  ) THEN
    ALTER TABLE subscription_plans ADD COLUMN features jsonb DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- Fonction pour mettre à jour le cache features dans subscription_plans
CREATE OR REPLACE FUNCTION sync_plan_features_cache()
RETURNS TRIGGER AS $$
BEGIN
  -- Mettre à jour le cache des features du plan concerné
  UPDATE subscription_plans
  SET features = (
    SELECT COALESCE(jsonb_agg(
      jsonb_build_object(
        'id', f.id,
        'code', f.code,
        'name', f.name,
        'description', f.description,
        'category', f.category,
        'is_included', spf.is_included
      ) ORDER BY f.display_order, f.name
    ), '[]'::jsonb)
    FROM subscription_plan_features spf
    JOIN features f ON f.id = spf.feature_id
    WHERE spf.plan_id = COALESCE(NEW.plan_id, OLD.plan_id)
    AND f.is_active = true
  )
  WHERE id = COALESCE(NEW.plan_id, OLD.plan_id);

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger pour synchroniser le cache
DROP TRIGGER IF EXISTS trigger_sync_plan_features_cache ON subscription_plan_features;
CREATE TRIGGER trigger_sync_plan_features_cache
  AFTER INSERT OR UPDATE OR DELETE ON subscription_plan_features
  FOR EACH ROW
  EXECUTE FUNCTION sync_plan_features_cache();

-- Trigger pour mettre à jour updated_at sur features
CREATE OR REPLACE FUNCTION update_features_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_features_updated_at ON features;
CREATE TRIGGER trigger_update_features_updated_at
  BEFORE UPDATE ON features
  FOR EACH ROW
  EXECUTE FUNCTION update_features_updated_at();

-- Insérer les fonctionnalités par défaut
INSERT INTO features (code, name, description, category, display_order, is_active) VALUES
  ('sales_management', 'Gestion des Ventes', 'Créer et gérer les ventes et commandes', 'core', 1, true),
  ('client_management', 'Gestion des Clients', 'Gérer la base de données clients', 'core', 2, true),
  ('product_catalog', 'Catalogue Produits', 'Gérer le catalogue de produits', 'core', 3, true),
  ('basic_reports', 'Rapports de Base', 'Rapports de ventes et statistiques de base', 'core', 4, true),
  ('inventory_tracking', 'Suivi des Stocks', 'Gestion avancée des stocks et inventaire', 'advanced', 5, true),
  ('commercial_tracking', 'Suivi Commercial', 'Suivi GPS et gestion des équipes commerciales', 'advanced', 6, true),
  ('purchase_management', 'Gestion des Achats', 'Gérer les fournisseurs et les achats', 'advanced', 7, true),
  ('invoicing', 'Facturation', 'Créer et gérer les factures', 'advanced', 8, true),
  ('payment_tracking', 'Suivi des Paiements', 'Suivi des paiements clients et fournisseurs', 'advanced', 9, true),
  ('advanced_analytics', 'Analytique Avancée', 'Tableaux de bord et analyses approfondies', 'premium', 10, true),
  ('multi_user', 'Multi-Utilisateurs', 'Gestion de plusieurs utilisateurs avec rôles', 'premium', 11, true),
  ('api_access', 'Accès API', 'Accès à l''API pour intégrations externes', 'premium', 12, true),
  ('custom_reports', 'Rapports Personnalisés', 'Créer des rapports personnalisés', 'premium', 13, true),
  ('mobile_app', 'Application Mobile', 'Accès à l''application mobile dédiée', 'premium', 14, true),
  ('white_label', 'White Label', 'Personnalisation complète de la marque', 'enterprise', 15, true),
  ('priority_support', 'Support Prioritaire', 'Support client prioritaire 24/7', 'enterprise', 16, true),
  ('custom_integrations', 'Intégrations Personnalisées', 'Développement d''intégrations sur mesure', 'enterprise', 17, true),
  ('dedicated_server', 'Serveur Dédié', 'Infrastructure dédiée pour performances optimales', 'enterprise', 18, true)
ON CONFLICT (code) DO NOTHING;

-- Associer les features aux plans existants
DO $$
DECLARE
  plan_mensuel_id uuid;
  plan_trimestriel_id uuid;
  plan_annuel_id uuid;
  feature_record RECORD;
BEGIN
  SELECT id INTO plan_mensuel_id FROM subscription_plans WHERE name = 'Mensuel' LIMIT 1;
  SELECT id INTO plan_trimestriel_id FROM subscription_plans WHERE name = 'Trimestriel' LIMIT 1;
  SELECT id INTO plan_annuel_id FROM subscription_plans WHERE name = 'Annuel' LIMIT 1;

  FOR feature_record IN SELECT id FROM features WHERE category = 'core' AND is_active = true
  LOOP
    INSERT INTO subscription_plan_features (plan_id, feature_id, is_included)
    VALUES (plan_mensuel_id, feature_record.id, true)
    ON CONFLICT (plan_id, feature_id) DO NOTHING;
  END LOOP;

  FOR feature_record IN SELECT id FROM features WHERE category IN ('core', 'advanced') AND is_active = true
  LOOP
    INSERT INTO subscription_plan_features (plan_id, feature_id, is_included)
    VALUES (plan_trimestriel_id, feature_record.id, true)
    ON CONFLICT (plan_id, feature_id) DO NOTHING;
  END LOOP;

  FOR feature_record IN SELECT id FROM features WHERE category IN ('core', 'advanced', 'premium') AND is_active = true
  LOOP
    INSERT INTO subscription_plan_features (plan_id, feature_id, is_included)
    VALUES (plan_annuel_id, feature_record.id, true)
    ON CONFLICT (plan_id, feature_id) DO NOTHING;
  END LOOP;
END $$;

-- Fonction pour vérifier si une entreprise a accès à une fonctionnalité
CREATE OR REPLACE FUNCTION company_has_feature(company_uuid uuid, feature_code_param text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  has_access boolean := false;
  company_status text;
  company_sub_end_date timestamptz;
BEGIN
  SELECT subscription_status, subscription_end_date
  INTO company_status, company_sub_end_date
  FROM companies
  WHERE id = company_uuid;

  IF company_status IN ('trial', 'active') THEN
    IF company_sub_end_date IS NULL OR company_sub_end_date > NOW() THEN
      SELECT EXISTS (
        SELECT 1
        FROM subscriptions s
        JOIN subscription_plans sp ON sp.id = s.plan_id
        JOIN subscription_plan_features spf ON spf.plan_id = sp.id
        JOIN features f ON f.id = spf.feature_id
        WHERE s.company_id = company_uuid
        AND s.status = 'active'
        AND f.code = feature_code_param
        AND spf.is_included = true
        AND f.is_active = true
      ) INTO has_access;
    END IF;
  END IF;

  RETURN has_access;
END;
$$;

GRANT EXECUTE ON FUNCTION sync_plan_features_cache() TO authenticated;
GRANT EXECUTE ON FUNCTION update_features_updated_at() TO authenticated;
GRANT EXECUTE ON FUNCTION company_has_feature(uuid, text) TO authenticated;
