import { supabase } from './supabase';
import { offlineCreate, offlineUpdate, offlineDelete, offlineQuery } from './offline-wrapper.service';

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

    return await offlineQuery<Supplier>(
      'suppliers',
      async () => {
        const { data, error } = await supabase
          .from('suppliers')
          .select('*')
          .eq('company_id', profile.company_id)
          .order('name', { ascending: true });
        return { data, error };
      }
    );
  }

  async getSupplier(id: string): Promise<Supplier> {
    const suppliers = await offlineQuery<Supplier>(
      'suppliers',
      async () => {
        const { data, error } = await supabase
          .from('suppliers')
          .select('*')
          .eq('id', id);
        return { data, error };
      }
    );

    if (suppliers.length === 0) throw new Error('Supplier not found');
    return suppliers[0];
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

    const dataToInsert = {
      ...supplierData,
      company_id: profile.company_id,
    };

    return await offlineCreate<Supplier>(
      'suppliers',
      dataToInsert as any,
      async () => {
        const { data, error } = await supabase
          .from('suppliers')
          .insert(dataToInsert)
          .select()
          .single();
        return { data, error };
      }
    );
  }

  async updateSupplier(id: string, supplierData: UpdateSupplierData): Promise<Supplier> {
    await offlineUpdate<Supplier>(
      'suppliers',
      id,
      supplierData,
      async () => {
        const { data, error } = await supabase
          .from('suppliers')
          .update(supplierData)
          .eq('id', id)
          .select()
          .single();
        return { data, error };
      }
    );

    return this.getSupplier(id);
  }

  async deleteSupplier(id: string): Promise<void> {
    await offlineDelete(
      'suppliers',
      id,
      async () => {
        const { error } = await supabase
          .from('suppliers')
          .delete()
          .eq('id', id);
        return { error };
      }
    );
  }
}

export const suppliersService = new SuppliersService();
