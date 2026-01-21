/*
  # Mettre à jour le CA Mensuel pour Inclure les Paiements Réels

  1. Modification de la fonction get_dashboard_stats_optimized
    - Le CA mensuel (total_revenue) utilisera désormais:
      * Les paiements de commandes effectués ce mois (order_payments avec payment_date du mois en cours)
      * Les ventes payées ce mois (sales avec payment_status = 'paye' et created_at du mois en cours)
    
    - Le CA du mois dernier (pour calculer la croissance) utilisera:
      * Les paiements de commandes effectués le mois dernier
      * Les ventes payées le mois dernier

  2. Logique cohérente
    - CA mensuel = Paiements encaissés ce mois
    - Recette du jour = Paiements encaissés aujourd'hui
    - Tout est basé sur les encaissements réels (quand l'argent entre)

  3. Notes importantes
    - Les statistiques reflètent maintenant l'argent réellement encaissé
    - Un paiement effectué ce mois sur une commande du mois dernier sera comptabilisé ce mois
    - Cela donne une vision précise de la trésorerie
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

  -- Calcul du CA du mois en cours = Paiements encaissés ce mois + Ventes payées ce mois
  SELECT
    -- Somme des paiements de commandes effectués ce mois
    COALESCE(
      (SELECT SUM(op.amount)
       FROM order_payments op
       WHERE op.company_id = p_company_id
       AND op.payment_date >= current_month_start),
      0
    )
    +
    -- Somme des ventes payées ce mois
    COALESCE(
      (SELECT SUM(s.final_amount)
       FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= current_month_start),
      0
    ),
    -- Nombre de commandes livrées ce mois + Nombre de ventes payées ce mois
    (SELECT COUNT(*) FROM orders WHERE company_id = p_company_id AND status = 'delivered' AND created_at >= current_month_start)
    +
    COALESCE(
      (SELECT COUNT(*) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= current_month_start),
      0
    )
  INTO current_revenue, current_orders_count;

  -- Calcul du CA du mois dernier = Paiements encaissés le mois dernier + Ventes payées le mois dernier
  SELECT
    -- Somme des paiements de commandes effectués le mois dernier
    COALESCE(
      (SELECT SUM(op.amount)
       FROM order_payments op
       WHERE op.company_id = p_company_id
       AND op.payment_date >= last_month_start
       AND op.payment_date <= last_month_end),
      0
    )
    +
    -- Somme des ventes payées le mois dernier
    COALESCE(
      (SELECT SUM(s.final_amount)
       FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= last_month_start
       AND s.created_at <= last_month_end),
      0
    ),
    -- Nombre de commandes livrées le mois dernier + Nombre de ventes payées le mois dernier
    (SELECT COUNT(*) FROM orders WHERE company_id = p_company_id AND status = 'delivered' AND created_at >= last_month_start AND created_at <= last_month_end)
    +
    COALESCE(
      (SELECT COUNT(*) FROM sales s
       WHERE s.company_id = p_company_id
       AND s.payment_status = 'paye'
       AND s.created_at >= last_month_start
       AND s.created_at <= last_month_end),
      0
    )
  INTO last_revenue, last_orders_count;

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
    -- Recette du jour = Paiements effectués aujourd'hui + Ventes payées aujourd'hui
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
    );
END;
$$ LANGUAGE plpgsql STABLE;
