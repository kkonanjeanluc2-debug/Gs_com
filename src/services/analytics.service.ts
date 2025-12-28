import { supabase, getCurrentUserCompanyId } from './supabase';

export interface DashboardStats {
  totalRevenue: number;
  totalOrders: number;
  totalClients: number;
  totalProducts: number;
  revenueGrowth: number;
  ordersGrowth: number;
  todayRevenue: number;
}

export interface TopCommercial {
  id: string;
  full_name: string;
  email: string;
  total_revenue: number;
  total_orders: number;
  photo_url?: string;
}

export interface CommercialMonthlyRevenue {
  id: string;
  full_name: string;
  email: string;
  phone?: string;
  photo_url?: string;
  monthly_revenue: number;
  monthly_orders: number;
}

export interface TopProduct {
  id: string;
  name: string;
  sku: string;
  total_quantity: number;
  total_revenue: number;
  image_url?: string;
}

export interface TopClient {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  total_orders: number;
  total_spent: number;
  type: string;
}

export interface RecentOrder {
  id: string;
  order_number: string;
  client_name: string;
  commercial_name: string;
  total_amount: number;
  status: string;
  created_at: string;
}

export interface RecentProspect {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  assigned_to_name: string;
  status: string;
  created_at: string;
}

export interface SalesEvolution {
  date: string;
  revenue: number;
  orders: number;
}

export class AnalyticsService {
  async getDashboardStats(): Promise<DashboardStats> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase.rpc('get_dashboard_stats_optimized', {
      p_company_id: company_id
    });

    if (error) throw error;

    const stats = data?.[0];
    if (!stats) {
      return {
        totalRevenue: 0,
        totalOrders: 0,
        totalClients: 0,
        totalProducts: 0,
        revenueGrowth: 0,
        ordersGrowth: 0,
        todayRevenue: 0,
      };
    }

    return {
      totalRevenue: Number(stats.total_revenue),
      totalOrders: Number(stats.total_orders),
      totalClients: Number(stats.total_clients),
      totalProducts: Number(stats.total_products),
      revenueGrowth: Number(stats.revenue_growth),
      ordersGrowth: Number(stats.orders_growth),
      todayRevenue: Number(stats.today_revenue),
    };
  }

  async getTopCommercials(limit: number = 5): Promise<TopCommercial[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase.rpc('get_top_commercials', {
      p_company_id: company_id,
      p_limit: limit
    });

    if (error) {
      const fallbackData = await supabase
        .from('orders')
        .select(`
          commercial_id,
          total_amount,
          commercial:profiles!orders_commercial_id_fkey(id, full_name, email, photo_url)
        `)
        .eq('company_id', company_id)
        .eq('status', 'delivered')
        .not('commercial_id', 'is', null);

      if (fallbackData.error) throw fallbackData.error;

      const commercialsMap = new Map<string, TopCommercial>();

      fallbackData.data?.forEach((order: any) => {
        if (!order.commercial) return;

        const id = order.commercial.id;
        if (!commercialsMap.has(id)) {
          commercialsMap.set(id, {
            id,
            full_name: order.commercial.full_name,
            email: order.commercial.email,
            photo_url: order.commercial.photo_url,
            total_revenue: 0,
            total_orders: 0,
          });
        }

        const commercial = commercialsMap.get(id)!;
        commercial.total_revenue += Number(order.total_amount);
        commercial.total_orders += 1;
      });

      return Array.from(commercialsMap.values())
        .sort((a, b) => b.total_revenue - a.total_revenue)
        .slice(0, limit);
    }

    return data || [];
  }

  async getTopProducts(limit: number = 5): Promise<TopProduct[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase.rpc('get_top_products', {
      p_company_id: company_id,
      p_limit: limit
    });

    if (error) {
      const fallbackData = await supabase
        .from('order_items')
        .select(`
          product_id,
          quantity,
          subtotal,
          product:products!order_items_product_id_fkey(id, name, sku, image_url),
          order:orders!order_items_order_id_fkey(status)
        `)
        .eq('company_id', company_id);

      if (fallbackData.error) throw fallbackData.error;

      const productsMap = new Map<string, TopProduct>();

      fallbackData.data?.forEach((item: any) => {
        if (!item.product || !item.order || item.order.status !== 'delivered') return;

        const id = item.product.id;
        if (!productsMap.has(id)) {
          productsMap.set(id, {
            id,
            name: item.product.name,
            sku: item.product.sku,
            image_url: item.product.image_url,
            total_quantity: 0,
            total_revenue: 0,
          });
        }

        const product = productsMap.get(id)!;
        product.total_quantity += item.quantity;
        product.total_revenue += Number(item.subtotal);
      });

      return Array.from(productsMap.values())
        .sort((a, b) => b.total_revenue - a.total_revenue)
        .slice(0, limit);
    }

    return data || [];
  }

  async getTopClients(limit: number = 5): Promise<TopClient[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase.rpc('get_top_clients', {
      p_company_id: company_id,
      p_limit: limit
    });

    if (error) {
      const fallbackData = await supabase
        .from('orders')
        .select(`
          client_id,
          total_amount,
          client:clients!orders_client_id_fkey(id, name, email, phone, type)
        `)
        .eq('company_id', company_id)
        .eq('status', 'delivered');

      if (fallbackData.error) throw fallbackData.error;

      const clientsMap = new Map<string, TopClient>();

      fallbackData.data?.forEach((order: any) => {
        if (!order.client) return;

        const id = order.client.id;
        if (!clientsMap.has(id)) {
          clientsMap.set(id, {
            id,
            name: order.client.name,
            email: order.client.email,
            phone: order.client.phone,
            type: order.client.type,
            total_orders: 0,
            total_spent: 0,
          });
        }

        const client = clientsMap.get(id)!;
        client.total_orders += 1;
        client.total_spent += Number(order.total_amount);
      });

      return Array.from(clientsMap.values())
        .sort((a, b) => b.total_spent - a.total_spent)
        .slice(0, limit);
    }

    return data || [];
  }

  async getRecentOrders(limit: number = 5): Promise<RecentOrder[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('orders')
      .select(`
        id,
        order_number,
        total_amount,
        status,
        created_at,
        client:clients!orders_client_id_fkey(name),
        commercial:profiles!orders_commercial_id_fkey(full_name)
      `)
      .eq('company_id', company_id)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;

    return (data || []).map((order: any) => ({
      id: order.id,
      order_number: order.order_number,
      client_name: order.client?.name || 'N/A',
      commercial_name: order.commercial?.full_name || 'N/A',
      total_amount: Number(order.total_amount),
      status: order.status,
      created_at: order.created_at,
    }));
  }

  async getRecentProspects(limit: number = 5): Promise<RecentProspect[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('clients')
      .select(`
        id,
        name,
        email,
        phone,
        status,
        created_at,
        assigned:profiles!clients_assigned_to_fkey(full_name)
      `)
      .eq('company_id', company_id)
      .eq('type', 'prospect')
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;

    return (data || []).map((prospect: any) => ({
      id: prospect.id,
      name: prospect.name,
      email: prospect.email,
      phone: prospect.phone,
      assigned_to_name: prospect.assigned?.full_name || 'Non assigné',
      status: prospect.status,
      created_at: prospect.created_at,
    }));
  }

  async getSalesEvolution(days: number = 7): Promise<SalesEvolution[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase.rpc('get_sales_evolution', {
      p_company_id: company_id,
      p_days: days
    });

    if (error) throw error;

    return (data || []).map((row: any) => ({
      date: row.date,
      revenue: Number(row.revenue),
      orders: Number(row.orders),
    }));
  }

  async getCommercialsMonthlyRevenue(): Promise<CommercialMonthlyRevenue[]> {
    const company_id = await getCurrentUserCompanyId();

    const now = new Date();
    const currentMonthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

    const { data: commercials, error: commercialsError } = await supabase
      .from('profiles')
      .select('id, full_name, email, phone, photo_url')
      .eq('company_id', company_id)
      .eq('role', 'commercial');

    if (commercialsError) throw commercialsError;

    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('commercial_id, total_amount')
      .eq('company_id', company_id)
      .eq('status', 'delivered')
      .gte('created_at', currentMonthStart)
      .not('commercial_id', 'is', null);

    if (ordersError) throw ordersError;

    const revenueMap = new Map<string, { monthly_revenue: number; monthly_orders: number }>();

    orders?.forEach((order: any) => {
      if (!order.commercial_id) return;

      if (!revenueMap.has(order.commercial_id)) {
        revenueMap.set(order.commercial_id, { monthly_revenue: 0, monthly_orders: 0 });
      }

      const stats = revenueMap.get(order.commercial_id)!;
      stats.monthly_revenue += Number(order.total_amount);
      stats.monthly_orders += 1;
    });

    return (commercials || []).map((commercial: any) => ({
      id: commercial.id,
      full_name: commercial.full_name,
      email: commercial.email,
      phone: commercial.phone,
      photo_url: commercial.photo_url,
      monthly_revenue: revenueMap.get(commercial.id)?.monthly_revenue || 0,
      monthly_orders: revenueMap.get(commercial.id)?.monthly_orders || 0,
    }));
  }

  async getTodayRevenue(): Promise<number> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase.rpc('get_dashboard_stats_optimized', {
      p_company_id: company_id
    });

    if (error) throw error;

    return Number(data?.[0]?.today_revenue || 0);
  }
}

export const analyticsService = new AnalyticsService();
