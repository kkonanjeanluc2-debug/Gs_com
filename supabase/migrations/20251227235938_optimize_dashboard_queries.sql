/*
  # Optimisation des Requêtes du Tableau de Bord

  1. Nouveaux Index Composés
    - Index sur orders(company_id, status, created_at) pour filtrer efficacement les commandes livrées
    - Index sur orders(company_id, commercial_id, status) pour les statistiques par commercial
    - Index sur order_items(company_id, product_id) pour les statistiques produits
    - Index sur clients(company_id, type) pour compter les clients et prospects

  2. Amélioration des Performances
    - Ces index composés accélèrent les requêtes du tableau de bord
    - Réduction du temps de chargement des statistiques
    - Optimisation des agrégations et filtres
*/

-- Index composé pour les requêtes de commandes par statut et date
CREATE INDEX IF NOT EXISTS idx_orders_company_status_date
  ON orders(company_id, status, created_at DESC);

-- Index composé pour les statistiques par commercial
CREATE INDEX IF NOT EXISTS idx_orders_company_commercial_status
  ON orders(company_id, commercial_id, status)
  WHERE commercial_id IS NOT NULL;

-- Index composé pour les items de commande avec company_id
CREATE INDEX IF NOT EXISTS idx_order_items_company_product
  ON order_items(company_id, product_id);

-- Index composé pour les clients par type
CREATE INDEX IF NOT EXISTS idx_clients_company_type
  ON clients(company_id, type);

-- Index pour les prospects récents
CREATE INDEX IF NOT EXISTS idx_clients_company_type_date
  ON clients(company_id, type, created_at DESC);

-- Index pour les commandes récentes avec client et commercial
CREATE INDEX IF NOT EXISTS idx_orders_company_date
  ON orders(company_id, created_at DESC);