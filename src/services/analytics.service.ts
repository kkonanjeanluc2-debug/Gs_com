import { supabase, getCurrentUserCompanyId } from './supabase';

export interface DashboardStats {
  totalRevenue: number;
  totalOrders: number;
  totalClients: number;
  totalProducts: number;
  revenueGrowth: number;
  ordersGrowth: number;
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

    const now = new Date();
    const currentMonthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
    const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString();
    const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59).toISOString();

    const { data: currentMonthOrders } = await supabase
      .from('orders')
      .select('total_amount')
      .eq('company_id', company_id)
      .eq('status', 'livree')
      .gte('created_at', currentMonthStart);

    const { data: lastMonthOrders } = await supabase
      .from('orders')
      .select('total_amount')
      .eq('company_id', company_id)
      .eq('status', 'livree')
      .gte('created_at', lastMonthStart)
      .lte('created_at', lastMonthEnd);

    const currentRevenue = currentMonthOrders?.reduce((sum, o) => sum + Number(o.total_amount), 0) || 0;
    const lastRevenue = lastMonthOrders?.reduce((sum, o) => sum + Number(o.total_amount), 0) || 0;
    const revenueGrowth = lastRevenue > 0 ? ((currentRevenue - lastRevenue) / lastRevenue) * 100 : 0;

    const currentOrdersCount = currentMonthOrders?.length || 0;
    const lastOrdersCount = lastMonthOrders?.length || 0;
    const ordersGrowth = lastOrdersCount > 0 ? ((currentOrdersCount - lastOrdersCount) / lastOrdersCount) * 100 : 0;

    const { count: clientsCount } = await supabase
      .from('clients')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', company_id)
      .eq('type', 'client');

    const { count: productsCount } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', company_id);

    return {
      totalRevenue: currentRevenue,
      totalOrders: currentOrdersCount,
      totalClients: clientsCount || 0,
      totalProducts: productsCount || 0,
      revenueGrowth,
      ordersGrowth,
    };
  }

  async getTopCommercials(limit: number = 5): Promise<TopCommercial[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('orders')
      .select(`
        commercial_id,
        total_amount,
        commercial:profiles!orders_commercial_id_fkey(id, full_name, email, photo_url)
      `)
      .eq('company_id', company_id)
      .eq('status', 'livree')
      .not('commercial_id', 'is', null);

    if (error) throw error;

    const commercialsMap = new Map<string, TopCommercial>();

    data?.forEach((order: any) => {
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

  async getTopProducts(limit: number = 5): Promise<TopProduct[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('order_items')
      .select(`
        product_id,
        quantity,
        subtotal,
        product:products!order_items_product_id_fkey(id, name, sku, image_url),
        order:orders!order_items_order_id_fkey(status)
      `)
      .eq('company_id', company_id);

    if (error) throw error;

    const productsMap = new Map<string, TopProduct>();

    data?.forEach((item: any) => {
      if (!item.product || !item.order || item.order.status !== 'livree') return;

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

  async getTopClients(limit: number = 5): Promise<TopClient[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('orders')
      .select(`
        client_id,
        total_amount,
        client:clients!orders_client_id_fkey(id, name, email, phone, type)
      `)
      .eq('company_id', company_id)
      .eq('status', 'livree');

    if (error) throw error;

    const clientsMap = new Map<string, TopClient>();

    data?.forEach((order: any) => {
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

    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const { data, error } = await supabase
      .from('orders')
      .select('created_at, total_amount')
      .eq('company_id', company_id)
      .eq('status', 'livree')
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString())
      .order('created_at', { ascending: true });

    if (error) throw error;

    const dailyStats = new Map<string, SalesEvolution>();

    for (let i = 0; i < days; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      const dateStr = date.toISOString().split('T')[0];
      dailyStats.set(dateStr, {
        date: dateStr,
        revenue: 0,
        orders: 0,
      });
    }

    data?.forEach((order: any) => {
      const dateStr = order.created_at.split('T')[0];
      if (dailyStats.has(dateStr)) {
        const stats = dailyStats.get(dateStr)!;
        stats.revenue += Number(order.total_amount);
        stats.orders += 1;
      }
    });

    return Array.from(dailyStats.values());
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
      .eq('status', 'livree')
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

    const today = new Date();
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString();
    const todayEnd = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59).toISOString();

    const { data, error } = await supabase
      .from('orders')
      .select('total_amount')
      .eq('company_id', company_id)
      .eq('status', 'livree')
      .gte('created_at', todayStart)
      .lte('created_at', todayEnd);

    if (error) throw error;

    return data?.reduce((sum, order) => sum + Number(order.total_amount), 0) || 0;
  }
}

export const analyticsService = new AnalyticsService();
