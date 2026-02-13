import { supabase } from './supabase';

export interface PendingSale {
  id?: string;
  company_id: string;
  created_by: string;
  client_id?: string | null;
  sale_data: any;
  name?: string;
  created_at?: string;
  updated_at?: string;
  client?: {
    id: string;
    name: string;
    phone?: string;
    email?: string;
  };
}

export interface CreatePendingSaleData {
  client_id?: string | null;
  sale_data: any;
  name?: string;
}

class PendingSalesService {
  async getAllPendingSales(): Promise<PendingSale[]> {
    const { data: userData } = await supabase.auth.getUser();
    if (!userData?.user) throw new Error('Non authentifié');

    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id')
      .eq('id', userData.user.id)
      .maybeSingle();

    if (!profile?.company_id) throw new Error('Entreprise non trouvée');

    const { data, error } = await supabase
      .from('pending_sales')
      .select(`
        *,
        client:clients(id, name, phone, email)
      `)
      .eq('company_id', profile.company_id)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async createPendingSale(pendingSaleData: CreatePendingSaleData): Promise<PendingSale> {
    const { data: userData } = await supabase.auth.getUser();
    if (!userData?.user) throw new Error('Non authentifié');

    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id')
      .eq('id', userData.user.id)
      .maybeSingle();

    if (!profile?.company_id) throw new Error('Entreprise non trouvée');

    const { data, error } = await supabase
      .from('pending_sales')
      .insert({
        company_id: profile.company_id,
        created_by: userData.user.id,
        client_id: pendingSaleData.client_id || null,
        sale_data: pendingSaleData.sale_data,
        name: pendingSaleData.name || `Vente en attente ${new Date().toLocaleString('fr-FR')}`,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updatePendingSale(id: string, pendingSaleData: CreatePendingSaleData): Promise<PendingSale> {
    const { data, error } = await supabase
      .from('pending_sales')
      .update({
        client_id: pendingSaleData.client_id || null,
        sale_data: pendingSaleData.sale_data,
        name: pendingSaleData.name,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async deletePendingSale(id: string): Promise<void> {
    const { error } = await supabase
      .from('pending_sales')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }

  async getPendingSale(id: string): Promise<PendingSale> {
    const { data, error } = await supabase
      .from('pending_sales')
      .select(`
        *,
        client:clients(id, name, phone, email)
      `)
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    if (!data) throw new Error('Vente en attente non trouvée');
    return data;
  }
}

export const pendingSalesService = new PendingSalesService();
