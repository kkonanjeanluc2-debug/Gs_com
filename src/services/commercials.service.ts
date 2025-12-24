import { supabase, getCurrentUserCompanyId } from './supabase';

export interface Commercial {
  id: string;
  email: string;
  full_name: string;
  role: string;
  phone?: string;
  photo_url?: string;
  created_at?: string;
  updated_at?: string;
}

export interface CreateCommercialData {
  email: string;
  password: string;
  full_name: string;
  phone?: string;
  photo_url?: string;
}

export interface UpdateCommercialData {
  full_name?: string;
  phone?: string;
  photo_url?: string;
}

export const commercialsService = {
  async getAllCommercials(): Promise<Commercial[]> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'commercial')
      .eq('company_id', company_id)
      .order('full_name');

    if (error) throw error;
    return data || [];
  },

  async getCommercialById(id: string): Promise<Commercial | null> {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', id)
      .eq('role', 'commercial')
      .eq('company_id', company_id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async createCommercial(commercialData: CreateCommercialData): Promise<void> {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      throw new Error('No active session');
    }

    const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/create-user`;
    const headers = {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    };

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        email: commercialData.email,
        password: commercialData.password,
        full_name: commercialData.full_name,
        phone: commercialData.phone,
        photo_url: commercialData.photo_url,
        role: 'commercial',
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to create commercial');
    }
  },

  async updateCommercial(id: string, updates: UpdateCommercialData): Promise<void> {
    const company_id = await getCurrentUserCompanyId();

    const { error } = await supabase
      .from('profiles')
      .update({
        ...updates,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .eq('role', 'commercial')
      .eq('company_id', company_id);

    if (error) throw error;
  },

  async deleteCommercial(id: string): Promise<void> {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      throw new Error('No active session');
    }

    const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/delete-user`;
    const headers = {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    };

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify({ userId: id }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to delete commercial');
    }
  },

  async getCommercialClients(commercialId: string) {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('assigned_to', commercialId)
      .order('name');

    if (error) throw error;
    return data || [];
  },
};
