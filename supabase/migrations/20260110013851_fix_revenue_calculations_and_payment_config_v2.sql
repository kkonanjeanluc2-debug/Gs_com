/*
  # Correction des Calculs de Revenus et Configuration des Moyens de Paiement

  1. Modifications des Calculs de Revenus
    - Mise à jour de `get_dashboard_stats_optimized` pour utiliser les montants réellement payés (order_payments)
    - Mise à jour de `get_sales_evolution` pour utiliser les montants réellement payés
    - Mise à jour de `get_top_commercials` pour utiliser les montants réellement payés
    - Mise à jour de `get_top_products` pour utiliser les montants réellement payés
    - Mise à jour de `get_top_clients` pour utiliser les montants réellement payés

  2. Configuration des Moyens de Paiement
    - Création de la table `payment_configurations` pour stocker les configs par entreprise
    - Support pour Wave, Mobile Money, Orange Money, MTN Mobile Money, Moov Money

  3. Sécurité
    - RLS activé sur payment_configurations
    - Seuls les admins peuvent gérer les configurations de paiement
*/

-- Table pour stocker les configurations de paiement par entreprise
CREATE TABLE IF NOT EXISTS payment_configurations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('wave', 'orange_money', 'mtn_money', 'moov_money', 'cinetpay')),
  is_enabled boolean DEFAULT false,
  api_key text,
  api_secret text,
  merchant_id text,
  webhook_url text,
  test_mode boolean DEFAULT true,
  config_data jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, provider)
);

-- Index pour les recherches rapides
CREATE INDEX IF NOT EXISTS idx_payment_configurations_company ON payment_configurations(company_id);
CREATE INDEX IF NOT EXISTS idx_payment_configurations_enabled ON payment_configurations(company_id, is_enabled) WHERE is_enabled = true;

-- Activer RLS
ALTER TABLE payment_configurations ENABLE ROW LEVEL SECURITY;

-- Politique: Admins et superviseurs peuvent voir les configs de leur entreprise
CREATE POLICY "Admins can view payment configs"
  ON payment_configurations FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'superviseur')
    )
  );

-- Politique: Seuls les admins peuvent créer des configs
CREATE POLICY "Admins can create payment configs"
  ON payment_configurations FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Politique: Seuls les admins peuvent modifier des configs
CREATE POLICY "Admins can update payment configs"
  ON payment_configurations FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Politique: Seuls les admins peuvent supprimer des configs
CREATE POLICY "Admins can delete payment configs"
  ON payment_configurations FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Supprimer les anciennes fonctions
DROP FUNCTION IF EXISTS get_dashboard_stats_optimized(uuid);
DROP FUNCTION IF EXISTS get_sales_evolution(uuid, integer);
DROP FUNCTION IF EXISTS get_top_commercials(uuid, integer);
DROP FUNCTION IF EXISTS get_top_products(uuid, integer);
DROP FUNCTION IF EXISTS get_top_clients(uuid, integer);

-- Fonction mise à jour pour les statistiques du tableau de bord (utilise les paiements réels)
CREATE FUNCTION get_dashboard_stats_optimized(p_company_id uuid)
RETURNS TABLE (
  total_revenue numeric,
  total_orders bigint,
  total_clients bigint,
  total_products bigint,
  revenue_growth numeric,
  orders_growth numeric,
  today_revenue numeric
) AS $$
DECLARE
  current_month_start timestamptz;
  last_month_start timestamptz;
  last_month_end timestamptz;
  today_start timestamptz;
  today_end timestamptz;
  current_revenue numeric;
  last_revenue numeric;
  current_orders_count bigint;
  last_orders_count bigint;
BEGIN
  current_month_start := date_trunc('month', CURRENT_DATE);
  last_month_start := date_trunc('month', CURRENT_DATE - INTERVAL '1 month');
  last_month_end := current_month_start - INTERVAL '1 second';
  today_start := date_trunc('day', CURRENT_TIMESTAMP);
  today_end := today_start + INTERVAL '1 day' - INTERVAL '1 second';

  -- Calcul du CA et nombre de commandes du mois en cours (utilise total_paid au lieu de total_amount)
  SELECT
    COALESCE(SUM(o.total_paid), 0),
    COUNT(*)
  INTO current_revenue, current_orders_count
  FROM orders o
  WHERE o.company_id = p_company_id
    AND o.status = 'delivered'
    AND o.created_at >= current_month_start;

  -- Calcul du CA et nombre de commandes du mois dernier
  SELECT
    COALESCE(SUM(o.total_paid), 0),
    COUNT(*)
  INTO last_revenue, last_orders_count
  FROM orders o
  WHERE o.company_id = p_company_id
    AND o.status = 'delivered'
    AND o.created_at >= last_month_start
    AND o.created_at <= last_month_end;

  -- Retourner toutes les statistiques
  RETURN QUERY
  SELECT
    current_revenue,
    current_orders_count,
    (SELECT COUNT(*) FROM clients WHERE company_id = p_company_id AND type = 'client')::bigint,
    (SELECT COUNT(*) FROM products WHERE company_id = p_company_id)::bigint,
    CASE
      WHEN last_revenue > 0 THEN ((current_revenue - last_revenue) / last_revenue * 100)
      ELSE 0
    END,
    CASE
      WHEN last_orders_count > 0 THEN ((current_orders_count - last_orders_count)::numeric / last_orders_count * 100)
      ELSE 0
    END,
    (
      SELECT COALESCE(SUM(o.total_paid), 0)
      FROM orders o
      WHERE o.company_id = p_company_id
        AND o.status = 'delivered'
        AND o.created_at >= today_start
        AND o.created_at <= today_end
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Fonction mise à jour pour l'évolution des ventes (utilise les paiements réels)
CREATE FUNCTION get_sales_evolution(
  p_company_id uuid,
  p_days integer DEFAULT 7
)
RETURNS TABLE (
  date date,
  revenue numeric,
  orders bigint
) AS $$
DECLARE
  start_date date;
  end_date date;
BEGIN
  end_date := CURRENT_DATE;
  start_date := CURRENT_DATE - (p_days - 1);

  RETURN QUERY
  WITH date_series AS (
    SELECT generate_series(start_date, end_date, '1 day'::interval)::date AS d
  )
  SELECT
    ds.d,
    COALESCE(SUM(o.total_paid), 0) as revenue,
    COUNT(o.id) as orders
  FROM date_series ds
  LEFT JOIN orders o ON DATE(o.created_at) = ds.d
    AND o.company_id = p_company_id
    AND o.status = 'delivered'
  GROUP BY ds.d
  ORDER BY ds.d;
END;
$$ LANGUAGE plpgsql STABLE;

-- Fonction mise à jour pour les meilleurs commerciaux (utilise les paiements réels)
CREATE FUNCTION get_top_commercials(p_company_id uuid, p_limit integer DEFAULT 5)
RETURNS TABLE (
  id uuid,
  full_name text,
  email text,
  photo_url text,
  total_revenue numeric,
  total_orders bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.full_name,
    p.email,
    p.photo_url,
    COALESCE(SUM(o.total_paid), 0) as total_revenue,
    COUNT(o.id) as total_orders
  FROM profiles p
  LEFT JOIN orders o ON o.commercial_id = p.id
    AND o.company_id = p_company_id
    AND o.status = 'delivered'
  WHERE p.company_id = p_company_id
    AND p.role = 'commercial'
  GROUP BY p.id, p.full_name, p.email, p.photo_url
  ORDER BY total_revenue DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Fonction mise à jour pour les meilleurs produits (utilise les paiements réels)
CREATE FUNCTION get_top_products(p_company_id uuid, p_limit integer DEFAULT 5)
RETURNS TABLE (
  id uuid,
  name text,
  sku text,
  image_url text,
  total_quantity bigint,
  total_revenue numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pr.id,
    pr.name,
    pr.sku,
    pr.image_url,
    COALESCE(SUM(oi.quantity), 0) as total_quantity,
    COALESCE(SUM(oi.subtotal * (o.total_paid / NULLIF(o.total_amount, 0))), 0) as total_revenue
  FROM products pr
  LEFT JOIN order_items oi ON oi.product_id = pr.id
  LEFT JOIN orders o ON o.id = oi.order_id
    AND o.status = 'delivered'
  WHERE pr.company_id = p_company_id
  GROUP BY pr.id, pr.name, pr.sku, pr.image_url
  HAVING COALESCE(SUM(oi.quantity), 0) > 0
  ORDER BY total_revenue DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Fonction mise à jour pour les meilleurs clients (utilise les paiements réels)
CREATE FUNCTION get_top_clients(p_company_id uuid, p_limit integer DEFAULT 5)
RETURNS TABLE (
  id uuid,
  name text,
  email text,
  phone text,
  type text,
  total_orders bigint,
  total_spent numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.name,
    c.email,
    c.phone,
    c.type,
    COUNT(o.id) as total_orders,
    COALESCE(SUM(o.total_paid), 0) as total_spent
  FROM clients c
  LEFT JOIN orders o ON o.client_id = c.id
    AND o.status = 'delivered'
  WHERE c.company_id = p_company_id
    AND c.type = 'client'
  GROUP BY c.id, c.name, c.email, c.phone, c.type
  HAVING COUNT(o.id) > 0
  ORDER BY total_spent DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;
