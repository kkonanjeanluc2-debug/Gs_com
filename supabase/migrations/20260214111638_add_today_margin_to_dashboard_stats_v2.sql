/*
  # Ajout de la marge journalière aux statistiques du tableau de bord

  1. Modifications
    - Ajouter le champ `today_margin` aux fonctions de statistiques
    - Calcule la marge = (prix de vente - prix d'achat) * quantité
    - Inclut les ventes comptoir et les commandes livrées

  2. Calcul de la marge
    - Pour les ventes comptoir: utilise sales_items avec purchase_price des produits
    - Pour les commandes: utilise order_items avec purchase_price des produits
    - Somme toutes les marges du jour

  3. Notes
    - La marge journalière permet de suivre la rentabilité en temps réel
    - Calcul basé sur le prix d'achat actuel du produit
*/

-- Supprimer les anciennes fonctions
DROP FUNCTION IF EXISTS get_dashboard_stats_optimized_with_period(uuid, timestamptz, timestamptz);
DROP FUNCTION IF EXISTS get_dashboard_stats_optimized(uuid);

-- Créer get_dashboard_stats_optimized_with_period avec today_margin
CREATE OR REPLACE FUNCTION get_dashboard_stats_optimized_with_period(
  p_company_id uuid,
  p_start_date timestamptz,
  p_end_date timestamptz
)
RETURNS TABLE (
  total_revenue numeric,
  total_orders bigint,
  total_clients bigint,
  total_products bigint,
  revenue_growth numeric,
  orders_growth numeric,
  today_revenue numeric,
  today_margin numeric
) AS $$
DECLARE
  period_start timestamptz;
  period_end timestamptz;
  prev_period_start timestamptz;
  prev_period_end timestamptz;
  today_start timestamptz;
  today_end timestamptz;
  current_revenue numeric;
  prev_revenue numeric;
  current_orders_count bigint;
  prev_orders_count bigint;
  period_duration interval;
BEGIN
  period_start := p_start_date;
  period_end := p_end_date;
  period_duration := period_end - period_start;
  prev_period_start := period_start - period_duration;
  prev_period_end := period_start - INTERVAL '1 second';
  today_start := date_trunc('day', CURRENT_TIMESTAMP);
  today_end := today_start + INTERVAL '1 day' - INTERVAL '1 second';

  -- CA et nombre de commandes/ventes de la période actuelle
  SELECT
    COALESCE(SUM(o.total_paid), 0) + COALESCE(
      (SELECT SUM(s.final_amount) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= period_start
       AND s.created_at <= period_end),
      0
    ),
    COUNT(*) + COALESCE(
      (SELECT COUNT(*) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= period_start
       AND s.created_at <= period_end),
      0
    )
  INTO current_revenue, current_orders_count
  FROM orders o
  WHERE o.company_id = p_company_id
    AND o.status = 'delivered'
    AND o.created_at >= period_start
    AND o.created_at <= period_end;

  -- CA et nombre de commandes/ventes de la période précédente
  SELECT
    COALESCE(SUM(o.total_paid), 0) + COALESCE(
      (SELECT SUM(s.final_amount) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= prev_period_start
       AND s.created_at <= prev_period_end),
      0
    ),
    COUNT(*) + COALESCE(
      (SELECT COUNT(*) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= prev_period_start
       AND s.created_at <= prev_period_end),
      0
    )
  INTO prev_revenue, prev_orders_count
  FROM orders o
  WHERE o.company_id = p_company_id
    AND o.status = 'delivered'
    AND o.created_at >= prev_period_start
    AND o.created_at <= prev_period_end;

  RETURN QUERY
  SELECT
    current_revenue,
    current_orders_count,
    (SELECT COUNT(*) FROM clients WHERE company_id = p_company_id AND type = 'client')::bigint,
    (SELECT COUNT(*) FROM products WHERE company_id = p_company_id)::bigint,
    CASE
      WHEN prev_revenue > 0 THEN ((current_revenue - prev_revenue) / prev_revenue * 100)
      ELSE 0
    END,
    CASE
      WHEN prev_orders_count > 0 THEN ((current_orders_count - prev_orders_count)::numeric / prev_orders_count * 100)
      ELSE 0
    END,
    -- RECETTE DU JOUR
    (
      COALESCE(
        (SELECT SUM(op.amount)
         FROM order_payments op
         WHERE op.company_id = p_company_id
         AND op.payment_date >= today_start
         AND op.payment_date <= today_end),
        0
      )
      +
      COALESCE(
        (SELECT SUM(s.final_amount)
         FROM sales s
         WHERE s.company_id = p_company_id
         AND s.payment_status = 'paye'
         AND s.created_at >= today_start
         AND s.created_at <= today_end),
        0
      )
    ),
    -- MARGE DU JOUR
    (
      -- Marge des ventes comptoir du jour
      COALESCE(
        (SELECT SUM(si.quantity * (si.unit_price - COALESCE(p.purchase_price, 0)))
         FROM sales s
         JOIN sales_items si ON s.id = si.sale_id
         JOIN products p ON si.product_id = p.id
         WHERE s.company_id = p_company_id
         AND s.payment_status = 'paye'
         AND s.created_at >= today_start
         AND s.created_at <= today_end),
        0
      )
      +
      -- Marge des commandes livrées aujourd'hui
      COALESCE(
        (SELECT SUM(oi.quantity * (oi.unit_price - COALESCE(p.purchase_price, 0)))
         FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE o.company_id = p_company_id
         AND o.status = 'delivered'
         AND o.updated_at >= today_start
         AND o.updated_at <= today_end),
        0
      )
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Créer get_dashboard_stats_optimized avec today_margin
CREATE OR REPLACE FUNCTION get_dashboard_stats_optimized(p_company_id uuid)
RETURNS TABLE (
  total_revenue numeric,
  total_orders bigint,
  total_clients bigint,
  total_products bigint,
  revenue_growth numeric,
  orders_growth numeric,
  today_revenue numeric,
  today_margin numeric
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

  -- CA et nombre de commandes/ventes du mois en cours
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

  -- CA et nombre de commandes/ventes du mois dernier
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
    -- RECETTE DU JOUR
    (
      COALESCE(
        (SELECT SUM(op.amount)
         FROM order_payments op
         WHERE op.company_id = p_company_id
         AND op.payment_date >= today_start
         AND op.payment_date <= today_end),
        0
      )
      +
      COALESCE(
        (SELECT SUM(s.final_amount)
         FROM sales s
         WHERE s.company_id = p_company_id
         AND s.payment_status = 'paye'
         AND s.created_at >= today_start
         AND s.created_at <= today_end),
        0
      )
    ),
    -- MARGE DU JOUR
    (
      -- Marge des ventes comptoir du jour
      COALESCE(
        (SELECT SUM(si.quantity * (si.unit_price - COALESCE(p.purchase_price, 0)))
         FROM sales s
         JOIN sales_items si ON s.id = si.sale_id
         JOIN products p ON si.product_id = p.id
         WHERE s.company_id = p_company_id
         AND s.payment_status = 'paye'
         AND s.created_at >= today_start
         AND s.created_at <= today_end),
        0
      )
      +
      -- Marge des commandes livrées aujourd'hui
      COALESCE(
        (SELECT SUM(oi.quantity * (oi.unit_price - COALESCE(p.purchase_price, 0)))
         FROM orders o
         JOIN order_items oi ON o.id = oi.order_id
         JOIN products p ON oi.product_id = p.id
         WHERE o.company_id = p_company_id
         AND o.status = 'delivered'
         AND o.updated_at >= today_start
         AND o.updated_at <= today_end),
        0
      )
    );
END;
$$ LANGUAGE plpgsql STABLE;
