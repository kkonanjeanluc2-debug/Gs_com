import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export interface Profile {
  id: string;
  email: string;
  full_name: string;
  role: 'admin' | 'superviseur' | 'commercial' | 'super_admin';
  phone: string | null;
  zone_affectation: string | null;
  company_id: string;
  created_at: string;
  updated_at: string;
}

export async function getCurrentUserCompanyId(): Promise<string> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('User not authenticated');

  const { data: profile, error } = await supabase
    .from('profiles')
    .select('company_id')
    .eq('id', user.id)
    .maybeSingle();

  if (error) throw error;
  if (!profile) throw new Error('Profile not found');

  return profile.company_id;
}

export interface Product {
  id: string;
  name: string;
  description: string | null;
  sku: string;
  price: number;
  stock_quantity: number;
  min_stock: number;
  image_url: string | null;
  category_id: string | null;
  subcategory_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface Client {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  address: string | null;
  type: 'prospect' | 'client';
  status: 'actif' | 'inactif' | 'en_negociation';
  assigned_to: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface ReportDB {
  id: string;
  user_id: string;
  date: string;
  prospects: number;
  nouveaux_prospects: number;
  comm_prospects: string | null;
  commandes: number;
  ca: number;
  comm_commandes: string | null;
  status: 'envoye' | 'brouillon' | 'archive';
  created_at: string;
  updated_at: string;
  commercial?: {
    full_name: string;
    email: string;
    phone?: string;
  };
}

export interface StockMovement {
  id: string;
  product_id: string;
  user_id: string;
  type: 'entree' | 'sortie' | 'ajustement';
  quantity: number;
  reason: string | null;
  created_at: string;
}
