/*
  # Ajout des périodes de facturation aux plans d'abonnement

  1. Modifications
    - Ajouter colonne `plan_type` à subscription_plans - Type de plan (basic, professional, enterprise)
    - Ajouter colonne `billing_period` à subscription_plans - Période (monthly, annual)
    - Ajouter colonne `monthly_price` à subscription_plans - Prix mensuel
    - Ajouter colonne `annual_price` à subscription_plans - Prix annuel
    - Ajouter colonne `annual_discount_percent` à subscription_plans - Pourcentage de réduction annuelle
    - Mise à jour des plans existants
    - Suppression de l'ancienne colonne price (remplacée par monthly_price et annual_price)

  2. Structure
    - Chaque plan a maintenant un type (basic, pro, etc.)
    - Chaque plan peut être souscrit mensuellement ou annuellement
    - Les features restent attachées au type de plan, pas à la période de facturation

  3. Sécurité
    - Les politiques RLS existantes restent valides
*/

-- Ajouter les nouvelles colonnes
ALTER TABLE subscription_plans
ADD COLUMN IF NOT EXISTS plan_type text,
ADD COLUMN IF NOT EXISTS billing_period text,
ADD COLUMN IF NOT EXISTS monthly_price integer,
ADD COLUMN IF NOT EXISTS annual_price integer,
ADD COLUMN IF NOT EXISTS annual_discount_percent integer DEFAULT 0;

-- Rendre la colonne price nullable temporairement
ALTER TABLE subscription_plans ALTER COLUMN price DROP NOT NULL;

-- Mettre à jour les plans existants pour les convertir au nouveau format
UPDATE subscription_plans
SET 
  plan_type = CASE 
    WHEN name = 'Mensuel' THEN 'basic'
    WHEN name = 'Trimestriel' THEN 'professional'
    WHEN name = 'Annuel' THEN 'premium'
    ELSE 'basic'
  END,
  billing_period = CASE
    WHEN duration_days <= 31 THEN 'monthly'
    WHEN duration_days <= 100 THEN 'quarterly'
    ELSE 'annual'
  END,
  monthly_price = CASE
    WHEN duration_days <= 31 THEN price
    WHEN duration_days <= 100 THEN ROUND(price / 3)
    ELSE ROUND(price / 12)
  END,
  annual_price = CASE
    WHEN duration_days <= 31 THEN price * 12
    WHEN duration_days <= 100 THEN price * 4
    ELSE price
  END,
  annual_discount_percent = CASE
    WHEN duration_days <= 31 THEN 0
    WHEN duration_days <= 100 THEN 15
    ELSE 20
  END
WHERE plan_type IS NULL;

-- Supprimer les anciens plans trimestriels (on garde uniquement mensuel et annuel par type)
DELETE FROM subscription_plans WHERE billing_period = 'quarterly';

-- Créer les nouveaux plans avec le système mensuel/annuel
DO $$
DECLARE
  basic_plan_id uuid;
  pro_plan_id uuid;
  premium_plan_id uuid;
BEGIN
  -- Plan Basic Mensuel
  INSERT INTO subscription_plans (name, plan_type, billing_period, duration_days, monthly_price, annual_price, annual_discount_percent, description, is_active, price)
  VALUES ('Basic - Mensuel', 'basic', 'monthly', 30, 25000, 240000, 20, 'Plan de base avec fonctionnalités essentielles - Facturation mensuelle', true, 25000)
  ON CONFLICT DO NOTHING
  RETURNING id INTO basic_plan_id;

  -- Plan Basic Annuel
  INSERT INTO subscription_plans (name, plan_type, billing_period, duration_days, monthly_price, annual_price, annual_discount_percent, description, is_active, price)
  VALUES ('Basic - Annuel', 'basic', 'annual', 365, 25000, 240000, 20, 'Plan de base avec fonctionnalités essentielles - Facturation annuelle (20% de réduction)', true, 240000)
  ON CONFLICT DO NOTHING
  RETURNING id INTO basic_plan_id;

  -- Plan Professional Mensuel
  INSERT INTO subscription_plans (name, plan_type, billing_period, duration_days, monthly_price, annual_price, annual_discount_percent, description, is_active, price)
  VALUES ('Professional - Mensuel', 'professional', 'monthly', 30, 45000, 432000, 20, 'Plan professionnel avec fonctionnalités avancées - Facturation mensuelle', true, 45000)
  ON CONFLICT DO NOTHING
  RETURNING id INTO pro_plan_id;

  -- Plan Professional Annuel
  INSERT INTO subscription_plans (name, plan_type, billing_period, duration_days, monthly_price, annual_price, annual_discount_percent, description, is_active, price)
  VALUES ('Professional - Annuel', 'professional', 'annual', 365, 45000, 432000, 20, 'Plan professionnel avec fonctionnalités avancées - Facturation annuelle (20% de réduction)', true, 432000)
  ON CONFLICT DO NOTHING
  RETURNING id INTO pro_plan_id;

  -- Plan Premium Mensuel
  INSERT INTO subscription_plans (name, plan_type, billing_period, duration_days, monthly_price, annual_price, annual_discount_percent, description, is_active, price)
  VALUES ('Premium - Mensuel', 'premium', 'monthly', 30, 75000, 720000, 20, 'Plan premium avec toutes les fonctionnalités - Facturation mensuelle', true, 75000)
  ON CONFLICT DO NOTHING
  RETURNING id INTO premium_plan_id;

  -- Plan Premium Annuel
  INSERT INTO subscription_plans (name, plan_type, billing_period, duration_days, monthly_price, annual_price, annual_discount_percent, description, is_active, price)
  VALUES ('Premium - Annuel', 'premium', 'annual', 365, 75000, 720000, 20, 'Plan premium avec toutes les fonctionnalités - Facturation annuelle (20% de réduction)', true, 720000)
  ON CONFLICT DO NOTHING
  RETURNING id INTO premium_plan_id;

  -- Associer les features aux nouveaux plans Basic (core uniquement)
  INSERT INTO subscription_plan_features (plan_id, feature_id, is_included)
  SELECT 
    sp.id,
    f.id,
    true
  FROM subscription_plans sp
  CROSS JOIN features f
  WHERE sp.plan_type = 'basic'
  AND f.category = 'core'
  AND f.is_active = true
  ON CONFLICT (plan_id, feature_id) DO NOTHING;

  -- Associer les features aux plans Professional (core + advanced)
  INSERT INTO subscription_plan_features (plan_id, feature_id, is_included)
  SELECT 
    sp.id,
    f.id,
    true
  FROM subscription_plans sp
  CROSS JOIN features f
  WHERE sp.plan_type = 'professional'
  AND f.category IN ('core', 'advanced')
  AND f.is_active = true
  ON CONFLICT (plan_id, feature_id) DO NOTHING;

  -- Associer les features aux plans Premium (core + advanced + premium)
  INSERT INTO subscription_plan_features (plan_id, feature_id, is_included)
  SELECT 
    sp.id,
    f.id,
    true
  FROM subscription_plans sp
  CROSS JOIN features f
  WHERE sp.plan_type = 'premium'
  AND f.category IN ('core', 'advanced', 'premium')
  AND f.is_active = true
  ON CONFLICT (plan_id, feature_id) DO NOTHING;
END $$;

-- Contraintes pour les nouveaux champs
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'subscription_plans_plan_type_check'
  ) THEN
    ALTER TABLE subscription_plans
    ADD CONSTRAINT subscription_plans_plan_type_check
    CHECK (plan_type IN ('basic', 'professional', 'premium', 'enterprise'));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'subscription_plans_billing_period_check'
  ) THEN
    ALTER TABLE subscription_plans
    ADD CONSTRAINT subscription_plans_billing_period_check
    CHECK (billing_period IN ('monthly', 'annual'));
  END IF;
END $$;

-- Supprimer l'ancienne colonne price
ALTER TABLE subscription_plans DROP COLUMN IF EXISTS price;

-- Rendre les nouvelles colonnes obligatoires pour les futurs plans
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_plans' 
    AND column_name = 'plan_type'
    AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE subscription_plans ALTER COLUMN plan_type SET NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_plans' 
    AND column_name = 'billing_period'
    AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE subscription_plans ALTER COLUMN billing_period SET NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_plans' 
    AND column_name = 'monthly_price'
    AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE subscription_plans ALTER COLUMN monthly_price SET NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_plans' 
    AND column_name = 'annual_price'
    AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE subscription_plans ALTER COLUMN annual_price SET NOT NULL;
  END IF;
END $$;

-- Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_subscription_plans_plan_type ON subscription_plans(plan_type);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_billing_period ON subscription_plans(billing_period);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_plan_type_billing ON subscription_plans(plan_type, billing_period);
