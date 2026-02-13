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
  async getDashboardStats(startDate?: Date, endDate?: Date): Promise<DashboardStats> {
    const company_id = await getCurrentUserCompanyId();

    const start = startDate || new Date(new Date().setMonth(new Date().getMonth() - 1));
    const end = endDate || new Date();

    const { data, error } = await supabase.rpc('get_dashboard_stats_optimized_with_period', {
      p_company_id: company_id,
      p_start_date: start.toISOString(),
      p_end_date: end.toISOString()
    });

    if (error) {
      console.error('Error calling get_dashboard_stats_optimized_with_period:', error);

      const { data: fallbackData, error: fallbackError } = await supabase.rpc('get_dashboard_stats_optimized', {
        p_company_id: company_id
      });

      if (fallbackError) throw fallbackError;

      const stats = fallbackData?.[0];
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

  async getTopCommercials(limit: number = 5, startDate?: Date, endDate?: Date): Promise<TopCommercial[]> {
    const company_id = await getCurrentUserCompanyId();

    const start = startDate || new Date(new Date().setMonth(new Date().getMonth() - 1));
    const end = endDate || new Date();

    let query = supabase
      .from('orders')
      .select(`
        commercial_id,
        total_amount,
        created_at,
        commercial:profiles!orders_commercial_id_fkey(id, full_name, email, photo_url)
      `)
      .eq('company_id', company_id)
      .eq('status', 'delivered')
      .gte('created_at', start.toISOString())
      .lte('created_at', end.toISOString())
      .not('commercial_id', 'is', null);

    const { data: fallbackData, error } = await query;

    if (error) throw error;

    const commercialsMap = new Map<string, TopCommercial>();

    fallbackData?.forEach((order: any) => {
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

  async getTopProducts(limit: number = 5, startDate?: Date, endDate?: Date): Promise<TopProduct[]> {
    const company_id = await getCurrentUserCompanyId();

    const start = startDate || new Date(new Date().setMonth(new Date().getMonth() - 1));
    const end = endDate || new Date();

    const { data: fallbackData, error } = await supabase
      .from('order_items')
      .select(`
        product_id,
        quantity,
        subtotal,
        product:products!order_items_product_id_fkey(id, name, sku, image_url),
        order:orders!order_items_order_id_fkey(status, created_at)
      `)
      .eq('company_id', company_id)
      .gte('order.created_at', start.toISOString())
      .lte('order.created_at', end.toISOString());

    if (error) throw error;

    const productsMap = new Map<string, TopProduct>();

    fallbackData?.forEach((item: any) => {
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

  async getTopClients(limit: number = 5, startDate?: Date, endDate?: Date): Promise<TopClient[]> {
    const company_id = await getCurrentUserCompanyId();

    const start = startDate || new Date(new Date().setMonth(new Date().getMonth() - 1));
    const end = endDate || new Date();

    const { data: fallbackData, error } = await supabase
      .from('orders')
      .select(`
        client_id,
        total_amount,
        created_at,
        client:clients!orders_client_id_fkey(id, name, email, phone, type)
      `)
      .eq('company_id', company_id)
      .eq('status', 'delivered')
      .gte('created_at', start.toISOString())
      .lte('created_at', end.toISOString());

    if (error) throw error;

    const clientsMap = new Map<string, TopClient>();

    fallbackData?.forEach((order: any) => {
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

  async getRecentOrders(limit: number = 5, startDate?: Date, endDate?: Date): Promise<RecentOrder[]> {
    const company_id = await getCurrentUserCompanyId();

    const start = startDate || new Date(new Date().setMonth(new Date().getMonth() - 1));
    const end = endDate || new Date();

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
      .gte('created_at', start.toISOString())
      .lte('created_at', end.toISOString())
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

  async getRecentProspects(limit: number = 5, startDate?: Date, endDate?: Date): Promise<RecentProspect[]> {
    const company_id = await getCurrentUserCompanyId();

    const start = startDate || new Date(new Date().setMonth(new Date().getMonth() - 1));
    const end = endDate || new Date();

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
      .gte('created_at', start.toISOString())
      .lte('created_at', end.toISOString())
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

  async getSalesEvolution(days: number = 7, startDate?: Date, endDate?: Date): Promise<SalesEvolution[]> {
    const company_id = await getCurrentUserCompanyId();

    const start = startDate || new Date(new Date().setDate(new Date().getDate() - days));
    const end = endDate || new Date();

    const { data, error } = await supabase
      .from('orders')
      .select('total_amount, created_at, status')
      .eq('company_id', company_id)
      .eq('status', 'delivered')
      .gte('created_at', start.toISOString())
      .lte('created_at', end.toISOString())
      .order('created_at', { ascending: true });

    if (error) throw error;

    const evolutionMap = new Map<string, { revenue: number; orders: number }>();

    data?.forEach((order: any) => {
      const orderDate = new Date(order.created_at);
      const monthKey = `${orderDate.getFullYear()}-${String(orderDate.getMonth() + 1).padStart(2, '0')}`;

      if (!evolutionMap.has(monthKey)) {
        evolutionMap.set(monthKey, { revenue: 0, orders: 0 });
      }
      const stats = evolutionMap.get(monthKey)!;
      stats.revenue += Number(order.total_amount);
      stats.orders += 1;
    });

    const result: SalesEvolution[] = [];
    const currentDate = new Date(start.getFullYear(), start.getMonth(), 1);
    const endMonth = new Date(end.getFullYear(), end.getMonth(), 1);

    while (currentDate <= endMonth) {
      const monthKey = `${currentDate.getFullYear()}-${String(currentDate.getMonth() + 1).padStart(2, '0')}`;
      const stats = evolutionMap.get(monthKey) || { revenue: 0, orders: 0 };
      result.push({
        date: monthKey + '-01',
        revenue: stats.revenue,
        orders: stats.orders,
      });
      currentDate.setMonth(currentDate.getMonth() + 1);
    }

    return result;
  }

  async getCommercialsMonthlyRevenue(startDate?: Date, endDate?: Date): Promise<CommercialMonthlyRevenue[]> {
    const company_id = await getCurrentUserCompanyId();

    const start = startDate || new Date(new Date().setMonth(new Date().getMonth() - 1));
    const end = endDate || new Date();

    const { data: commercials, error: commercialsError } = await supabase
      .from('profiles')
      .select('id, full_name, email, phone, photo_url')
      .eq('company_id', company_id)
      .eq('role', 'commercial');

    if (commercialsError) throw commercialsError;

    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('commercial_id, total_paid, created_at')
      .eq('company_id', company_id)
      .eq('status', 'delivered')
      .gte('created_at', start.toISOString())
      .lte('created_at', end.toISOString())
      .not('commercial_id', 'is', null);

    if (ordersError) throw ordersError;

    const revenueMap = new Map<string, { monthly_revenue: number; monthly_orders: number }>();

    orders?.forEach((order: any) => {
      if (!order.commercial_id) return;

      if (!revenueMap.has(order.commercial_id)) {
        revenueMap.set(order.commercial_id, { monthly_revenue: 0, monthly_orders: 0 });
      }

      const stats = revenueMap.get(order.commercial_id)!;
      stats.monthly_revenue += Number(order.total_paid);
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
