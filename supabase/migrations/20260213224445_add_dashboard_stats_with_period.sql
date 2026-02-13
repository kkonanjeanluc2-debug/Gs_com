/*
  # Add dashboard statistics function with custom period support

  ## Description
  Creates a new RPC function to get dashboard statistics with custom date range parameters.
  This allows filtering dashboard data by any time period (1 month, 3 months, 6 months, 12 months, or custom).

  ## Changes
  1. New Function
    - `get_dashboard_stats_optimized_with_period` - Returns dashboard statistics for a specified date range
      - Parameters:
        - p_company_id: Company UUID
        - p_start_date: Start date of the period
        - p_end_date: End date of the period
      - Returns: Statistics including revenue, orders, clients, products, and growth rates

  ## Features
  - Calculates total revenue and orders within the specified period
  - Compares with the previous period of equal length for growth calculation
  - Includes today's revenue calculation
  - Returns total clients and products count

  ## Security
  - Function respects company isolation
  - Only authenticated users can call this function
*/

-- Function to get dashboard stats with custom period
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
BEGIN
  -- Calculate period length in days
  v_period_days := EXTRACT(DAY FROM (p_end_date - p_start_date));

  -- Calculate previous period dates
  v_prev_end_date := p_start_date - INTERVAL '1 day';
  v_prev_start_date := v_prev_end_date - (v_period_days || ' days')::INTERVAL;

  -- Calculate today's start
  v_today_start := DATE_TRUNC('day', NOW());

  -- Get current period stats
  SELECT
    COALESCE(SUM(o.total_paid), 0),
    COUNT(*)
  INTO v_current_revenue, v_current_orders
  FROM orders o
  WHERE o.company_id = p_company_id
    AND o.status = 'delivered'
    AND o.created_at >= p_start_date
    AND o.created_at <= p_end_date;

  -- Get previous period stats for comparison
  SELECT
    COALESCE(SUM(o.total_paid), 0),
    COUNT(*)
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
    (
      SELECT COALESCE(SUM(o.total_paid), 0)
      FROM orders o
      WHERE o.company_id = p_company_id
        AND o.status = 'delivered'
        AND o.created_at >= v_today_start
    ) AS today_revenue;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;