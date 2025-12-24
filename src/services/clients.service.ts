import { supabase, type Client, getCurrentUserCompanyId } from './supabase';

export type { Client };

export class ClientsService {
  async createClient(client: Omit<Client, 'id' | 'created_at' | 'updated_at'>) {
    const company_id = await getCurrentUserCompanyId();
    const { data, error } = await supabase
      .from('clients')
      .insert({ ...client, company_id })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updateClient(id: string, updates: Partial<Client>) {
    const { data, error } = await supabase
      .from('clients')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async deleteClient(id: string) {
    const { error } = await supabase
      .from('clients')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }

  async getClient(id: string) {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  async getAllClients() {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async getMyClients(userId: string) {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('assigned_to', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async getClientsByType(type: 'prospect' | 'client') {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('type', type)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async convertProspectToClient(id: string) {
    return this.updateClient(id, { type: 'client', status: 'actif' });
  }
}

export const clientsService = new ClientsService();
