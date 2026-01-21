import { supabase } from './supabase';
import { geolocationService } from './geolocation.service';

export interface ClientVisit {
  client_id: string;
  client_name: string;
  client_address?: string;
  client_latitude?: number;
  client_longitude?: number;
  visit_date: string;
  commercial_id: string;
  commercial_name: string;
  distance_km: number;
  activity_type: string;
}

export interface ClientTransactionStats {
  client_id: string;
  client_name: string;
  total_orders: number;
  total_sales: number;
  total_revenue: number;
  last_transaction_date?: string;
  avg_order_value: number;
}

export interface ZoneCoverage {
  zone_name: string;
  commune: string;
  visit_count: number;
  unique_clients: number;
  last_visit_date: string;
}

export interface CommercialStats {
  commercial_id: string;
  commercial_name: string;
  total_visits: number;
  unique_clients_visited: number;
  zones_covered: number;
  total_distance_km: number;
  avg_visits_per_day: number;
}

class CommercialTrackingService {
  async getClientVisitHistory(
    commercialId?: string,
    startDate?: string,
    endDate?: string
  ): Promise<ClientVisit[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const targetCommercialId = commercialId || user.id;

    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id')
      .eq('id', user.id)
      .maybeSingle();

    if (!profile?.company_id) throw new Error('Company not found');

    let locQuery = supabase
      .from('commercial_locations')
      .select(`
        *,
        profile:profiles!commercial_locations_user_id_fkey(
          full_name
        )
      `)
      .eq('user_id', targetCommercialId)
      .eq('company_id', profile.company_id)
      .eq('activity_type', 'en_visite')
      .order('timestamp', { ascending: false });

    if (startDate) {
      locQuery = locQuery.gte('timestamp', startDate);
    }
    if (endDate) {
      locQuery = locQuery.lte('timestamp', endDate);
    }

    const { data: locations, error: locError } = await locQuery.limit(500);
    if (locError) throw locError;

    const { data: clients, error: clientsError } = await supabase
      .from('clients')
      .select('*')
      .eq('company_id', profile.company_id)
      .not('latitude', 'is', null)
      .not('longitude', 'is', null);

    if (clientsError) throw clientsError;

    const visits: ClientVisit[] = [];

    for (const location of locations || []) {
      let nearestClient = null;
      let minDistance = Infinity;

      for (const client of clients || []) {
        if (client.latitude && client.longitude) {
          const distance = geolocationService.calculateDistance(
            location.latitude,
            location.longitude,
            client.latitude,
            client.longitude
          );

          if (distance < 0.5 && distance < minDistance) {
            minDistance = distance;
            nearestClient = client;
          }
        }
      }

      if (nearestClient) {
        visits.push({
          client_id: nearestClient.id,
          client_name: nearestClient.name,
          client_address: nearestClient.address,
          client_latitude: nearestClient.latitude,
          client_longitude: nearestClient.longitude,
          visit_date: location.timestamp,
          commercial_id: location.user_id,
          commercial_name: (location as any).profile?.full_name || '',
          distance_km: minDistance,
          activity_type: location.activity_type,
        });
      }
    }

    return visits;
  }

  async getClientTransactionStats(
    commercialId?: string,
    startDate?: string,
    endDate?: string
  ): Promise<ClientTransactionStats[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const targetCommercialId = commercialId || user.id;

    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id')
      .eq('id', user.id)
      .maybeSingle();

    if (!profile?.company_id) throw new Error('Company not found');

    let ordersQuery = supabase
      .from('orders')
      .select('client_id, total_amount, created_at, client:clients(name)')
      .eq('commercial_id', targetCommercialId)
      .eq('company_id', profile.company_id);

    if (startDate) ordersQuery = ordersQuery.gte('created_at', startDate);
    if (endDate) ordersQuery = ordersQuery.lte('created_at', endDate);

    const { data: orders, error: ordersError } = await ordersQuery;
    if (ordersError) throw ordersError;

    let salesQuery = supabase
      .from('sales')
      .select('client_id, final_amount, created_at, client:clients(name)')
      .eq('commercial_id', targetCommercialId)
      .eq('company_id', profile.company_id);

    if (startDate) salesQuery = salesQuery.gte('created_at', startDate);
    if (endDate) salesQuery = salesQuery.lte('created_at', endDate);

    const { data: sales, error: salesError } = await salesQuery;
    if (salesError) throw salesError;

    const clientStatsMap = new Map<string, ClientTransactionStats>();

    for (const order of orders || []) {
      const clientId = order.client_id;
      if (!clientStatsMap.has(clientId)) {
        clientStatsMap.set(clientId, {
          client_id: clientId,
          client_name: (order as any).client?.name || 'Client inconnu',
          total_orders: 0,
          total_sales: 0,
          total_revenue: 0,
          avg_order_value: 0,
        });
      }

      const stats = clientStatsMap.get(clientId)!;
      stats.total_orders++;
      stats.total_revenue += order.total_amount || 0;
      stats.last_transaction_date = order.created_at;
    }

    for (const sale of sales || []) {
      const clientId = sale.client_id;
      if (!clientStatsMap.has(clientId)) {
        clientStatsMap.set(clientId, {
          client_id: clientId,
          client_name: (sale as any).client?.name || 'Client inconnu',
          total_orders: 0,
          total_sales: 0,
          total_revenue: 0,
          avg_order_value: 0,
        });
      }

      const stats = clientStatsMap.get(clientId)!;
      stats.total_sales++;
      stats.total_revenue += sale.final_amount || 0;

      if (!stats.last_transaction_date || sale.created_at > stats.last_transaction_date) {
        stats.last_transaction_date = sale.created_at;
      }
    }

    const result = Array.from(clientStatsMap.values());
    result.forEach(stats => {
      const totalTransactions = stats.total_orders + stats.total_sales;
      stats.avg_order_value = totalTransactions > 0
        ? stats.total_revenue / totalTransactions
        : 0;
    });

    return result.sort((a, b) => b.total_revenue - a.total_revenue);
  }

  async getZonesCoverage(
    commercialId?: string,
    startDate?: string,
    endDate?: string
  ): Promise<ZoneCoverage[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const targetCommercialId = commercialId || user.id;

    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id, zone_affectation')
      .eq('id', targetCommercialId)
      .maybeSingle();

    if (!profile?.company_id) throw new Error('Company not found');

    const visits = await this.getClientVisitHistory(targetCommercialId, startDate, endDate);

    const zoneMap = new Map<string, {
      visit_count: number;
      unique_clients: Set<string>;
      last_visit: string;
    }>();

    for (const visit of visits) {
      const zoneName = visit.client_address?.split(',').slice(-2).join(',').trim() || 'Zone inconnue';

      if (!zoneMap.has(zoneName)) {
        zoneMap.set(zoneName, {
          visit_count: 0,
          unique_clients: new Set(),
          last_visit: visit.visit_date,
        });
      }

      const zone = zoneMap.get(zoneName)!;
      zone.visit_count++;
      zone.unique_clients.add(visit.client_id);

      if (visit.visit_date > zone.last_visit) {
        zone.last_visit = visit.visit_date;
      }
    }

    const result: ZoneCoverage[] = [];
    zoneMap.forEach((data, zoneName) => {
      const parts = zoneName.split(',');
      result.push({
        zone_name: zoneName,
        commune: parts[parts.length - 1]?.trim() || zoneName,
        visit_count: data.visit_count,
        unique_clients: data.unique_clients.size,
        last_visit_date: data.last_visit,
      });
    });

    return result.sort((a, b) => b.visit_count - a.visit_count);
  }

  async getCommercialStats(
    commercialId?: string,
    startDate?: string,
    endDate?: string
  ): Promise<CommercialStats> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const targetCommercialId = commercialId || user.id;

    const { data: profile } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', targetCommercialId)
      .maybeSingle();

    const visits = await this.getClientVisitHistory(targetCommercialId, startDate, endDate);
    const zones = await this.getZonesCoverage(targetCommercialId, startDate, endDate);

    const uniqueClients = new Set(visits.map(v => v.client_id));
    const totalDistance = visits.reduce((sum, v) => sum + v.distance_km, 0);

    const daysDiff = startDate && endDate
      ? Math.max(1, Math.ceil((new Date(endDate).getTime() - new Date(startDate).getTime()) / (1000 * 60 * 60 * 24)))
      : visits.length > 0
        ? Math.max(1, Math.ceil((new Date().getTime() - new Date(visits[visits.length - 1].visit_date).getTime()) / (1000 * 60 * 60 * 24)))
        : 1;

    return {
      commercial_id: targetCommercialId,
      commercial_name: profile?.full_name || 'Commercial',
      total_visits: visits.length,
      unique_clients_visited: uniqueClients.size,
      zones_covered: zones.length,
      total_distance_km: totalDistance,
      avg_visits_per_day: visits.length / daysDiff,
    };
  }

  async getAllCommercialsStats(
    startDate?: string,
    endDate?: string
  ): Promise<CommercialStats[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id, role')
      .eq('id', user.id)
      .maybeSingle();

    if (!profile?.company_id) throw new Error('Company not found');

    if (profile.role !== 'admin' && profile.role !== 'superviseur') {
      return [await this.getCommercialStats(user.id, startDate, endDate)];
    }

    const { data: commercials, error } = await supabase
      .from('profiles')
      .select('id')
      .eq('company_id', profile.company_id)
      .eq('role', 'commercial');

    if (error) throw error;

    const stats: CommercialStats[] = [];
    for (const commercial of commercials || []) {
      try {
        const stat = await this.getCommercialStats(commercial.id, startDate, endDate);
        stats.push(stat);
      } catch (error) {
        console.error(`Error fetching stats for commercial ${commercial.id}:`, error);
      }
    }

    return stats.sort((a, b) => b.total_visits - a.total_visits);
  }
}

export const commercialTrackingService = new CommercialTrackingService();
