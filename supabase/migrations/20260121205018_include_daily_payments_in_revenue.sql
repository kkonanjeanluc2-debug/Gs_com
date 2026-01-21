/*
  # Inclure les Paiements du Jour dans la Recette Journalière

  1. Modification de la fonction get_dashboard_stats_optimized
    - La recette du jour (today_revenue) inclura désormais:
      * Les paiements de commandes effectués aujourd'hui (order_payments avec payment_date = aujourd'hui)
      * Les ventes payées aujourd'hui (sales avec payment_status = 'paye' et created_at = aujourd'hui)

  2. Logique de calcul
    - Au lieu d'utiliser total_amount des commandes livrées aujourd'hui
    - On utilise la somme des paiements effectués aujourd'hui depuis order_payments
    - Cela permet de comptabiliser les paiements même si la commande a été créée un autre jour

  3. Notes importantes
    - Pour le CA mensuel (total_revenue), on continue d'utiliser total_amount des commandes livrées
    - Seule la recette du jour (today_revenue) utilise la date des paiements
    - Cela permet de suivre l'argent réellement encaissé chaque jour
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
  -- Utilise total_amount pour les commandes livrées et final_amount pour les ventes payées
  SELECT
    COALESCE(SUM(o.total_amount), 0) + COALESCE(
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
    COALESCE(SUM(o.total_amount), 0) + COALESCE(
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
  -- LA RECETTE DU JOUR utilise maintenant les paiements effectués aujourd'hui
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
    -- NOUVELLE LOGIQUE: Recette du jour = Paiements effectués aujourd'hui + Ventes payées aujourd'hui
    (
      -- Somme des paiements de commandes effectués aujourd'hui (quelle que soit la date de la commande)
      COALESCE(
        (SELECT SUM(op.amount)
         FROM order_payments op
         WHERE op.company_id = p_company_id
         AND op.payment_date >= today_start
         AND op.payment_date <= today_end),
        0
      )
      +
      -- Somme des ventes payées aujourd'hui
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
