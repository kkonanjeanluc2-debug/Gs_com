/*
  # Mise à jour de la fonction get_top_commercials pour le mois en cours

  1. Modifications
    - Ajout d'un filtre sur le mois en cours dans la fonction `get_top_commercials`
    - Les statistiques affichent maintenant uniquement les performances du mois actuel
    - Permet de voir tous les commerciaux actifs même avec 0 commande ce mois-ci
  
  2. Objectif
    - Afficher le classement des 5 meilleurs commerciaux du mois en cours
    - Encourager la compétition saine entre les commerciaux
*/

-- Fonction pour obtenir les meilleurs commerciaux du mois en cours
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
    COUNT(o.id) FILTER (WHERE o.id IS NOT NULL) as total_orders
  FROM profiles p
  LEFT JOIN orders o ON o.commercial_id = p.id 
    AND o.company_id = p_company_id 
    AND o.status = 'delivered'
    AND DATE_TRUNC('month', o.created_at) = DATE_TRUNC('month', CURRENT_DATE)
  WHERE p.company_id = p_company_id
    AND p.role = 'commercial'
  GROUP BY p.id, p.full_name, p.email, p.photo_url
  ORDER BY total_revenue DESC, total_orders DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;