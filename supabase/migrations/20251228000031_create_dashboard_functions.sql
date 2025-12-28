/*
  # Fonctions d'Agrégation pour le Tableau de Bord

  1. Nouvelles Fonctions SQL
    - `get_top_commercials` - Calcule les meilleurs commerciaux avec agrégation SQL
    - `get_top_products` - Calcule les produits les plus vendus avec agrégation SQL
    - `get_top_clients` - Calcule les meilleurs clients avec agrégation SQL

  2. Avantages
    - Réduction du transfert de données entre la base et le client
    - Agrégations effectuées directement en base de données
    - Amélioration significative des performances du tableau de bord
*/

-- Fonction pour obtenir les meilleurs commerciaux
CREATE OR REPLACE FUNCTION get_top_commercials(
  p_company_id uuid,
  p_limit integer DEFAULT 5
)
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
    COALESCE(SUM(o.total_amount), 0) as total_revenue,
    COUNT(o.id) as total_orders
  FROM profiles p
  LEFT JOIN orders o ON o.commercial_id = p.id 
    AND o.company_id = p_company_id 
    AND o.status = 'delivered'
  WHERE p.company_id = p_company_id
    AND p.role = 'commercial'
  GROUP BY p.id, p.full_name, p.email, p.photo_url
  HAVING COUNT(o.id) > 0
  ORDER BY total_revenue DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Fonction pour obtenir les produits les plus vendus
CREATE OR REPLACE FUNCTION get_top_products(
  p_company_id uuid,
  p_limit integer DEFAULT 5
)
RETURNS TABLE (
  id uuid,
  name text,
  sku text,
  image_url text,
  total_quantity numeric,
  total_revenue numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.sku,
    p.image_url,
    COALESCE(SUM(oi.quantity), 0) as total_quantity,
    COALESCE(SUM(oi.subtotal), 0) as total_revenue
  FROM products p
  LEFT JOIN order_items oi ON oi.product_id = p.id 
    AND oi.company_id = p_company_id
  LEFT JOIN orders o ON o.id = oi.order_id 
    AND o.status = 'delivered'
  WHERE p.company_id = p_company_id
    AND o.id IS NOT NULL
  GROUP BY p.id, p.name, p.sku, p.image_url
  HAVING SUM(oi.quantity) > 0
  ORDER BY total_revenue DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Fonction pour obtenir les meilleurs clients
CREATE OR REPLACE FUNCTION get_top_clients(
  p_company_id uuid,
  p_limit integer DEFAULT 5
)
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
    COALESCE(SUM(o.total_amount), 0) as total_spent
  FROM clients c
  LEFT JOIN orders o ON o.client_id = c.id 
    AND o.company_id = p_company_id 
    AND o.status = 'delivered'
  WHERE c.company_id = p_company_id
  GROUP BY c.id, c.name, c.email, c.phone, c.type
  HAVING COUNT(o.id) > 0
  ORDER BY total_spent DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;