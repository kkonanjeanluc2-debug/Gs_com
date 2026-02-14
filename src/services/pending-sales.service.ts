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
    console.log('createPendingSale service called with:', pendingSaleData);

    const { data: userData } = await supabase.auth.getUser();
    console.log('User data:', userData?.user?.id);
    if (!userData?.user) throw new Error('Non authentifié');

    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id')
      .eq('id', userData.user.id)
      .maybeSingle();

    console.log('Profile data:', profile);
    if (!profile?.company_id) throw new Error('Entreprise non trouvée');

    const insertData = {
      company_id: profile.company_id,
      created_by: userData.user.id,
      client_id: pendingSaleData.client_id || null,
      sale_data: pendingSaleData.sale_data,
      name: pendingSaleData.name || `Vente en attente ${new Date().toLocaleString('fr-FR')}`,
    };
    console.log('Inserting pending sale:', insertData);

    const { data, error } = await supabase
      .from('pending_sales')
      .insert(insertData)
      .select(`
        *,
        client:clients(id, name, phone, email)
      `)
      .single();

    if (error) {
      console.error('Supabase error:', error);
      console.error('Error code:', error.code);
      console.error('Error message:', error.message);
      console.error('Error details:', error.details);
      throw new Error(`Erreur lors de la création: ${error.message}`);
    }
    console.log('Pending sale created:', data);
    return data;
  }

  async updatePendingSale(id: string, pendingSaleData: CreatePendingSaleData): Promise<PendingSale> {
    console.log('updatePendingSale service called with:', id, pendingSaleData);

    const updateData = {
      client_id: pendingSaleData.client_id || null,
      sale_data: pendingSaleData.sale_data,
      name: pendingSaleData.name,
      updated_at: new Date().toISOString(),
    };
    console.log('Updating pending sale with:', updateData);

    const { data, error } = await supabase
      .from('pending_sales')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Supabase error:', error);
      throw error;
    }
    console.log('Pending sale updated:', data);
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
