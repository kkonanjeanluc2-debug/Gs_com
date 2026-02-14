/*
  # Mise à jour de get_dashboard_stats_optimized pour inclure les ventes comptoir

  ## Description
  Met à jour la fonction get_dashboard_stats_optimized (utilisée comme fallback)
  pour inclure les ventes comptoir dans tous les calculs.

  ## Modifications
  - CA du mois en cours inclut les ventes comptoir payées
  - CA du mois dernier inclut les ventes comptoir payées
  - Recette du jour inclut les ventes comptoir payées aujourd'hui
  - Nombre total de commandes inclut les ventes comptoir

  ## Notes
  - Utilise les mêmes critères que get_dashboard_stats_optimized_with_period
  - Assure la cohérence entre les deux fonctions
*/

-- Remplacer la fonction get_dashboard_stats_optimized
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

  -- Calcul du CA et nombre de commandes/ventes du mois en cours
  SELECT
    COALESCE(SUM(o.total_paid), 0) + COALESCE(
      (SELECT SUM(s.final_amount) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= current_month_start),
      0
    ),
    COUNT(*) + COALESCE(
      (SELECT COUNT(*) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= current_month_start),
      0
    )
  INTO current_revenue, current_orders_count
  FROM orders o
  WHERE o.company_id = p_company_id
    AND o.status = 'delivered'
    AND o.created_at >= current_month_start;

  -- Calcul du CA et nombre de commandes/ventes du mois dernier
  SELECT
    COALESCE(SUM(o.total_paid), 0) + COALESCE(
      (SELECT SUM(s.final_amount) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= last_month_start
       AND s.created_at <= last_month_end),
      0
    ),
    COUNT(*) + COALESCE(
      (SELECT COUNT(*) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= last_month_start
       AND s.created_at <= last_month_end),
      0
    )
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
    -- RECETTE DU JOUR: Paiements de commandes + Ventes comptoir payées aujourd'hui
    (
      -- Somme des paiements de commandes effectués aujourd'hui
      COALESCE(
        (SELECT SUM(op.amount)
         FROM order_payments op
         WHERE op.company_id = p_company_id
         AND op.payment_date >= today_start
         AND op.payment_date <= today_end),
        0
      )
      +
      -- Somme des ventes comptoir payées aujourd'hui
      COALESCE(
        (SELECT SUM(s.final_amount)
         FROM sales s
         WHERE s.company_id = p_company_id
         AND s.payment_status = 'paye'
         AND s.created_at >= today_start
         AND s.created_at <= today_end),
        0
      )
    );
END;
$$ LANGUAGE plpgsql STABLE;