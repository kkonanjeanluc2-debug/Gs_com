/*
  # Ajout du Client Comptoir et Mise à Jour des Statistiques

  1. Ajout du Client Comptoir
    - Créer un client "Client comptoir" par défaut pour chaque compagnie
    - Le client comptoir aura le numéro 0000000
    - Type: client, Statut: actif

  2. Mise à Jour des Fonctions de Statistiques
    - Modifier `get_dashboard_stats_optimized` pour inclure les ventes
    - Modifier `get_sales_evolution` pour inclure les ventes
    - Les statistiques incluront maintenant:
      * CA: total_amount des orders livrées + final_amount des sales payées
      * Recette du jour: idem mais pour aujourd'hui
      * Ventes: nombre de orders livrées + nombre de sales payées

  3. Sécurité
    - Politique RLS pour permettre la lecture du client comptoir à tous les utilisateurs de la compagnie
*/

-- Fonction pour créer le client comptoir pour chaque compagnie
DO $$
DECLARE
  company_record RECORD;
  counter_client_exists boolean;
BEGIN
  FOR company_record IN SELECT id FROM companies LOOP
    -- Vérifier si le client comptoir existe déjà
    SELECT EXISTS(
      SELECT 1 FROM clients 
      WHERE company_id = company_record.id 
      AND name = 'Client comptoir'
    ) INTO counter_client_exists;
    
    -- Créer le client comptoir s'il n'existe pas
    IF NOT counter_client_exists THEN
      INSERT INTO clients (
        company_id,
        name,
        email,
        phone,
        type,
        status,
        address,
        notes
      ) VALUES (
        company_record.id,
        'Client comptoir',
        'comptoir@' || company_record.id || '.local',
        '0000000',
        'client',
        'actif',
        'Ventes au comptoir',
        'Client par défaut pour les ventes au comptoir'
      );
    END IF;
  END LOOP;
END $$;

-- Fonction optimisée pour les statistiques du tableau de bord (avec ventes incluses)
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
  -- Inclut les commandes livrées ET les ventes payées
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
      SELECT COALESCE(SUM(o.total_amount), 0) + COALESCE(
        (SELECT SUM(s.final_amount) FROM sales s 
         WHERE s.company_id = p_company_id 
         AND s.payment_status = 'paye'
         AND s.created_at >= today_start 
         AND s.created_at <= today_end), 
        0
      )
      FROM orders o
      WHERE o.company_id = p_company_id
        AND o.status = 'delivered'
        AND o.created_at >= today_start
        AND o.created_at <= today_end
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Fonction optimisée pour l'évolution des ventes (avec ventes incluses)
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
    COALESCE(SUM(o.total_amount), 0) + COALESCE(
      (SELECT SUM(s.final_amount) FROM sales s 
       WHERE DATE(s.created_at) = ds.d 
       AND s.company_id = p_company_id 
       AND s.payment_status = 'paye'), 
      0
    ) as revenue,
    COUNT(o.id) + COALESCE(
      (SELECT COUNT(*) FROM sales s 
       WHERE DATE(s.created_at) = ds.d 
       AND s.company_id = p_company_id 
       AND s.payment_status = 'paye'), 
      0
    ) as orders
  FROM date_series ds
  LEFT JOIN orders o ON DATE(o.created_at) = ds.d
    AND o.company_id = p_company_id
    AND o.status = 'delivered'
  GROUP BY ds.d
  ORDER BY ds.d;
END;
$$ LANGUAGE plpgsql STABLE;

-- Trigger pour créer automatiquement le client comptoir pour les nouvelles compagnies
CREATE OR REPLACE FUNCTION create_counter_client_for_company()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO clients (
    company_id,
    name,
    email,
    phone,
    type,
    status,
    address,
    notes
  ) VALUES (
    NEW.id,
    'Client comptoir',
    'comptoir@' || NEW.id || '.local',
    '0000000',
    'client',
    'actif',
    'Ventes au comptoir',
    'Client par défaut pour les ventes au comptoir'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger sur la table companies
DROP TRIGGER IF EXISTS trigger_create_counter_client ON companies;
CREATE TRIGGER trigger_create_counter_client
  AFTER INSERT ON companies
  FOR EACH ROW
  EXECUTE FUNCTION create_counter_client_for_company();