import { supabase } from './supabase';

export interface Supplier {
  id: string;
  company_id: string;
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  city?: string;
  country?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
}

export interface CreateSupplierData {
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  city?: string;
  country?: string;
  notes?: string;
}

export interface UpdateSupplierData {
  name?: string;
  email?: string;
  phone?: string;
  address?: string;
  city?: string;
  country?: string;
  notes?: string;
}

class SuppliersService {
  async getSuppliers(): Promise<Supplier[]> {
    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id')
      .eq('id', (await supabase.auth.getUser()).data.user?.id)
      .maybeSingle();

    if (!profile?.company_id) {
      throw new Error('Company not found');
    }

    const { data, error } = await supabase
      .from('suppliers')
      .select('*')
      .eq('company_id', profile.company_id)
      .order('name', { ascending: true });

    if (error) throw error;
    return data || [];
  }

  async getSupplier(id: string): Promise<Supplier> {
    const { data, error } = await supabase
      .from('suppliers')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    if (!data) throw new Error('Supplier not found');
    return data;
  }

  async createSupplier(supplierData: CreateSupplierData): Promise<Supplier> {
    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id')
      .eq('id', (await supabase.auth.getUser()).data.user?.id)
      .maybeSingle();

    if (!profile?.company_id) {
      throw new Error('Company not found');
    }

    const { data, error } = await supabase
      .from('suppliers')
      .insert({
        ...supplierData,
        company_id: profile.company_id,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updateSupplier(id: string, supplierData: UpdateSupplierData): Promise<Supplier> {
    const { data, error } = await supabase
      .from('suppliers')
      .update(supplierData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async deleteSupplier(id: string): Promise<void> {
    const { error } = await supabase
      .from('suppliers')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
}

export const suppliersService = new SuppliersService();
