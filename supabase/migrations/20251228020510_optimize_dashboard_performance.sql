/*
  # Optimisation des Performances du Tableau de Bord

  1. Nouvelles Fonctions SQL Optimisées
    - `get_dashboard_stats_optimized` - Calcule toutes les statistiques du tableau de bord en une seule requête
    - `get_sales_evolution` - Calcule l'évolution des ventes sur N jours

  2. Avantages
    - Une seule requête pour toutes les stats principales
    - Agrégations effectuées en base de données
    - Réduction massive du temps de chargement

  3. Index Ajoutés
    - Index sur orders pour optimiser les requêtes par company_id, status et date
    - Index sur order_items et clients pour les jointures
*/

-- Fonction optimisée pour les statistiques du tableau de bord
CREATE OR REPLACE FUNCTION get_dashboard_stats_optimized(p_company_id uuid)
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

  -- Calcul du CA et nombre de commandes du mois en cours
  SELECT
    COALESCE(SUM(o.total_amount), 0),
    COUNT(*)
  INTO current_revenue, current_orders_count
  FROM orders o
  WHERE o.company_id = p_company_id
    AND o.status = 'delivered'
    AND o.created_at >= current_month_start;

  -- Calcul du CA et nombre de commandes du mois dernier
  SELECT
    COALESCE(SUM(o.total_amount), 0),
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
      SELECT COALESCE(SUM(o.total_amount), 0)
      FROM orders o
      WHERE o.company_id = p_company_id
        AND o.status = 'delivered'
        AND o.created_at >= today_start
        AND o.created_at <= today_end
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Fonction optimisée pour l'évolution des ventes
CREATE OR REPLACE FUNCTION get_sales_evolution(
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
    COALESCE(SUM(o.total_amount), 0) as revenue,
    COUNT(o.id) as orders
  FROM date_series ds
  LEFT JOIN orders o ON DATE(o.created_at) = ds.d
    AND o.company_id = p_company_id
    AND o.status = 'delivered'
  GROUP BY ds.d
  ORDER BY ds.d;
END;
$$ LANGUAGE plpgsql STABLE;

-- Index pour optimiser les requêtes de dashboard
CREATE INDEX IF NOT EXISTS idx_orders_company_status_date
  ON orders(company_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_orders_commercial_company
  ON orders(commercial_id, company_id, status)
  WHERE commercial_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_order_items_product_company
  ON order_items(product_id, company_id);

CREATE INDEX IF NOT EXISTS idx_clients_company_type
  ON clients(company_id, type);
