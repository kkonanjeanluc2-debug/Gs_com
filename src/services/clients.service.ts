import { supabase, type Client, getCurrentUserCompanyId } from './supabase';
import { offlineCreate, offlineUpdate, offlineDelete, offlineQuery } from './offline-wrapper.service';

export type { Client };

export class ClientsService {
  async createClient(client: Omit<Client, 'id' | 'created_at' | 'updated_at'>) {
    const company_id = await getCurrentUserCompanyId();
    const clientData = { ...client, company_id };

    return await offlineCreate<Client>(
      'clients',
      clientData as any,
      async () => {
        const { data, error } = await supabase
          .from('clients')
          .insert(clientData)
          .select()
          .single();
        return { data, error };
      }
    );
  }

  async updateClient(id: string, updates: Partial<Client>) {
    const updateData = { ...updates, updated_at: new Date().toISOString() };

    await offlineUpdate<Client>(
      'clients',
      id,
      updateData,
      async () => {
        const { data, error } = await supabase
          .from('clients')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
        return { data, error };
      }
    );

    return this.getClient(id);
  }

  async deleteClient(id: string) {
    await offlineDelete(
      'clients',
      id,
      async () => {
        const { error } = await supabase
          .from('clients')
          .delete()
          .eq('id', id);
        return { error };
      }
    );
  }

  async getClient(id: string) {
    const companyId = await getCurrentUserCompanyId();

    const clients = await offlineQuery<Client>(
      'clients',
      async () => {
        const { data, error } = await supabase
          .from('clients')
          .select('*')
          .eq('id', id)
          .eq('company_id', companyId);
        return { data, error };
      }
    );

    return clients.length > 0 ? clients[0] : null;
  }

  async getAllClients() {
    const companyId = await getCurrentUserCompanyId();

    return await offlineQuery<Client>(
      'clients',
      async () => {
        const { data, error } = await supabase
          .from('clients')
          .select('*')
          .eq('company_id', companyId)
          .order('created_at', { ascending: false });
        return { data, error };
      }
    );
  }

  async getMyClients(userId: string) {
    const companyId = await getCurrentUserCompanyId();

    return await offlineQuery<Client>(
      'clients',
      async () => {
        const { data, error } = await supabase
          .from('clients')
          .select('*')
          .eq('assigned_to', userId)
          .eq('company_id', companyId)
          .order('created_at', { ascending: false });
        return { data, error };
      }
    );
  }

  async getClientsByType(type: 'prospect' | 'client') {
    const companyId = await getCurrentUserCompanyId();

    return await offlineQuery<Client>(
      'clients',
      async () => {
        const { data, error } = await supabase
          .from('clients')
          .select('*')
          .eq('type', type)
          .eq('company_id', companyId)
          .order('created_at', { ascending: false });
        return { data, error };
      }
    );
  }

  async convertProspectToClient(id: string) {
    return this.updateClient(id, { type: 'client', status: 'actif' });
  }
}

export const clientsService = new ClientsService();
