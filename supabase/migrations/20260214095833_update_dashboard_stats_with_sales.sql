/*
  # Mise à jour des statistiques du dashboard pour inclure les ventes comptoir

  ## Description
  Met à jour la fonction get_dashboard_stats_optimized_with_period pour inclure les ventes comptoir
  dans tous les calculs de statistiques (revenu total, recette du jour, croissance).

  ## Modifications
  1. Revenu de la période actuelle
    - Inclut les ventes comptoir payées (sales avec payment_status = 'paye')
    - Utilise la somme de final_amount pour les ventes

  2. Revenu de la période précédente
    - Inclut également les ventes comptoir pour le calcul de la croissance

  3. Recette du jour (today_revenue)
    - Inclut les paiements de commandes effectués aujourd'hui (order_payments)
    - Inclut les ventes comptoir payées aujourd'hui (sales)

  ## Notes
  - Les ventes comptoir sont comptabilisées uniquement si payment_status = 'paye'
  - La date de création (created_at) est utilisée pour filtrer les ventes
*/

-- Remplacer la fonction get_dashboard_stats_optimized_with_period
CREATE OR REPLACE FUNCTION get_dashboard_stats_optimized_with_period(
  p_company_id UUID,
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
  total_revenue NUMERIC,
  total_orders BIGINT,
  total_clients BIGINT,
  total_products BIGINT,
  revenue_growth NUMERIC,
  orders_growth NUMERIC,
  today_revenue NUMERIC
) AS $$
DECLARE
  v_period_days INTEGER;
  v_prev_start_date TIMESTAMP WITH TIME ZONE;
  v_prev_end_date TIMESTAMP WITH TIME ZONE;
  v_current_revenue NUMERIC;
  v_current_orders BIGINT;
  v_prev_revenue NUMERIC;
  v_prev_orders BIGINT;
  v_today_start TIMESTAMP WITH TIME ZONE;
  v_today_end TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Calculate period length in days
  v_period_days := EXTRACT(DAY FROM (p_end_date - p_start_date));

  -- Calculate previous period dates
  v_prev_end_date := p_start_date - INTERVAL '1 day';
  v_prev_start_date := v_prev_end_date - (v_period_days || ' days')::INTERVAL;

  -- Calculate today's start and end
  v_today_start := DATE_TRUNC('day', NOW());
  v_today_end := v_today_start + INTERVAL '1 day' - INTERVAL '1 second';

  -- Get current period stats (commandes livrées + ventes comptoir payées)
  SELECT
    COALESCE(SUM(o.total_paid), 0) + COALESCE(
      (SELECT SUM(s.final_amount) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= p_start_date
       AND s.created_at <= p_end_date),
      0
    ),
    COUNT(*) + COALESCE(
      (SELECT COUNT(*) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= p_start_date
       AND s.created_at <= p_end_date),
      0
    )
  INTO v_current_revenue, v_current_orders
  FROM orders o
  WHERE o.company_id = p_company_id
    AND o.status = 'delivered'
    AND o.created_at >= p_start_date
    AND o.created_at <= p_end_date;

  -- Get previous period stats for comparison (commandes livrées + ventes comptoir payées)
  SELECT
    COALESCE(SUM(o.total_paid), 0) + COALESCE(
      (SELECT SUM(s.final_amount) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= v_prev_start_date
       AND s.created_at <= v_prev_end_date),
      0
    ),
    COUNT(*) + COALESCE(
      (SELECT COUNT(*) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= v_prev_start_date
       AND s.created_at <= v_prev_end_date),
      0
    )
  INTO v_prev_revenue, v_prev_orders
  FROM orders o
  WHERE o.company_id = p_company_id
    AND o.status = 'delivered'
    AND o.created_at >= v_prev_start_date
    AND o.created_at <= v_prev_end_date;

  -- Return results
  RETURN QUERY
  SELECT
    v_current_revenue AS total_revenue,
    v_current_orders AS total_orders,
    (SELECT COUNT(*) FROM clients WHERE company_id = p_company_id) AS total_clients,
    (SELECT COUNT(*) FROM products WHERE company_id = p_company_id) AS total_products,
    CASE
      WHEN v_prev_revenue > 0 THEN
        ROUND(((v_current_revenue - v_prev_revenue) / v_prev_revenue * 100)::NUMERIC, 2)
      ELSE 0
    END AS revenue_growth,
    CASE
      WHEN v_prev_orders > 0 THEN
        ROUND(((v_current_orders - v_prev_orders)::NUMERIC / v_prev_orders * 100)::NUMERIC, 2)
      ELSE 0
    END AS orders_growth,
    -- RECETTE DU JOUR: Paiements de commandes effectués aujourd'hui + Ventes comptoir payées aujourd'hui
    (
      -- Somme des paiements de commandes effectués aujourd'hui
      COALESCE(
        (SELECT SUM(op.amount)
         FROM order_payments op
         WHERE op.company_id = p_company_id
         AND op.payment_date >= v_today_start
         AND op.payment_date <= v_today_end),
        0
      )
      +
      -- Somme des ventes comptoir payées aujourd'hui
      COALESCE(
        (SELECT SUM(s.final_amount)
         FROM sales s
         WHERE s.company_id = p_company_id
         AND s.payment_status = 'paye'
         AND s.created_at >= v_today_start
         AND s.created_at <= v_today_end),
        0
      )
    ) AS today_revenue;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;