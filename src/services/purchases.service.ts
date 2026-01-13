import { supabase } from './supabase';
import type { Supplier } from './suppliers.service';

export interface PurchaseItem {
  id: string;
  purchase_id: string;
  product_id: string;
  quantity: number;
  unit_price: number;
  total_price: number;
  product?: {
    name: string;
    reference: string;
  };
  created_at: string;
  updated_at: string;
}

export interface Purchase {
  id: string;
  company_id: string;
  supplier_id: string;
  purchase_number: string;
  purchase_date: string;
  status: 'pending' | 'completed' | 'cancelled';
  total_amount: number;
  notes?: string;
  payment_method?: 'cash' | 'mobile_money' | 'bank_transfer' | 'check';
  payment_status: 'unpaid' | 'partial' | 'paid';
  payment_date?: string;
  payment_reference?: string;
  paid_amount: number;
  created_by: string;
  supplier?: Supplier;
  items?: PurchaseItem[];
  created_at: string;
  updated_at: string;
}

export interface CreatePurchaseData {
  supplier_id: string;
  purchase_date: string;
  notes?: string;
  payment_method?: 'cash' | 'mobile_money' | 'bank_transfer' | 'check';
  payment_status?: 'unpaid' | 'partial' | 'paid';
  payment_date?: string;
  payment_reference?: string;
  paid_amount?: number;
  items: {
    product_id: string;
    quantity: number;
    unit_price: number;
  }[];
}

export interface UpdatePurchaseData {
  supplier_id?: string;
  purchase_date?: string;
  status?: 'pending' | 'completed' | 'cancelled';
  notes?: string;
  payment_method?: 'cash' | 'mobile_money' | 'bank_transfer' | 'check';
  payment_status?: 'unpaid' | 'partial' | 'paid';
  payment_date?: string;
  payment_reference?: string;
  paid_amount?: number;
}

class PurchasesService {
  async getPurchases(): Promise<Purchase[]> {
    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id')
      .eq('id', (await supabase.auth.getUser()).data.user?.id)
      .maybeSingle();

    if (!profile?.company_id) {
      throw new Error('Company not found');
    }

    const { data, error } = await supabase
      .from('purchases')
      .select(`
        *,
        supplier:suppliers(*)
      `)
      .eq('company_id', profile.company_id)
      .order('purchase_date', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async getPurchase(id: string): Promise<Purchase> {
    const { data, error } = await supabase
      .from('purchases')
      .select(`
        *,
        supplier:suppliers(*),
        items:purchase_items(
          *,
          product:products(name, reference)
        )
      `)
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    if (!data) throw new Error('Purchase not found');
    return data as Purchase;
  }

  async createPurchase(purchaseData: CreatePurchaseData): Promise<Purchase> {
    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id, id')
      .eq('id', (await supabase.auth.getUser()).data.user?.id)
      .maybeSingle();

    if (!profile?.company_id) {
      throw new Error('Company not found');
    }

    const totalAmount = purchaseData.items.reduce(
      (sum, item) => sum + item.quantity * item.unit_price,
      0
    );

    const { data: purchase, error: purchaseError } = await supabase
      .from('purchases')
      .insert({
        company_id: profile.company_id,
        supplier_id: purchaseData.supplier_id,
        purchase_date: purchaseData.purchase_date,
        total_amount: totalAmount,
        notes: purchaseData.notes,
        payment_method: purchaseData.payment_method,
        payment_status: purchaseData.payment_status || 'unpaid',
        payment_date: purchaseData.payment_date,
        payment_reference: purchaseData.payment_reference,
        paid_amount: purchaseData.paid_amount || 0,
        created_by: profile.id,
        status: 'pending',
      })
      .select()
      .single();

    if (purchaseError) throw purchaseError;

    const items = purchaseData.items.map(item => ({
      purchase_id: purchase.id,
      product_id: item.product_id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      total_price: item.quantity * item.unit_price,
    }));

    const { error: itemsError } = await supabase
      .from('purchase_items')
      .insert(items);

    if (itemsError) throw itemsError;

    return this.getPurchase(purchase.id);
  }

  async updatePurchase(id: string, purchaseData: UpdatePurchaseData): Promise<Purchase> {
    const { error } = await supabase
      .from('purchases')
      .update(purchaseData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return this.getPurchase(id);
  }

  async deletePurchase(id: string): Promise<void> {
    const { error } = await supabase
      .from('purchases')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }

  async completePurchase(id: string): Promise<Purchase> {
    return this.updatePurchase(id, { status: 'completed' });
  }

  async cancelPurchase(id: string): Promise<Purchase> {
    return this.updatePurchase(id, { status: 'cancelled' });
  }

  async updatePurchaseItems(purchaseId: string, items: { product_id: string; quantity: number; unit_price: number }[]): Promise<void> {
    await supabase
      .from('purchase_items')
      .delete()
      .eq('purchase_id', purchaseId);

    const purchaseItems = items.map(item => ({
      purchase_id: purchaseId,
      product_id: item.product_id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      total_price: item.quantity * item.unit_price,
    }));

    const { error } = await supabase
      .from('purchase_items')
      .insert(purchaseItems);

    if (error) throw error;

    const totalAmount = items.reduce((sum, item) => sum + item.quantity * item.unit_price, 0);

    const { error: updateError } = await supabase
      .from('purchases')
      .update({ total_amount: totalAmount })
      .eq('id', purchaseId);

    if (updateError) throw updateError;
  }
}

export const purchasesService = new PurchasesService();
