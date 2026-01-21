import { supabase, getCurrentUserCompanyId } from './supabase';
import { offlineQuery, offlineUpdate, offlineDelete } from './offline-wrapper.service';

export interface SaleItem {
  id?: string;
  sale_id?: string;
  product_id: string;
  quantity: number;
  unit_price: number;
  discount_percentage: number;
  discount_amount: number;
  subtotal: number;
  product?: {
    name: string;
    sku: string;
  };
}

export interface Sale {
  id?: string;
  sale_number?: string;
  client_id: string;
  commercial_id: string;
  company_id?: string;
  total_amount: number;
  discount_amount: number;
  final_amount: number;
  payment_method: 'especes' | 'mobile_money' | 'virement' | 'cheque' | 'carte_bancaire' | 'wave' | 'orange_money' | 'mtn_money' | 'moov_money';
  payment_status: 'paye' | 'en_attente' | 'partiellement_paye';
  notes?: string;
  created_at?: string;
  updated_at?: string;
  client?: {
    name: string;
    email?: string;
    phone?: string;
    address?: string;
    type?: string;
  };
  commercial?: {
    full_name: string;
    email: string;
    phone?: string;
  };
  sale_items?: SaleItem[];
}

export interface CreateSaleData {
  client_id: string;
  items: {
    product_id: string;
    quantity: number;
    unit_price: number;
    discount_percentage?: number;
  }[];
  payment_method: Sale['payment_method'];
  payment_status?: Sale['payment_status'];
  notes?: string;
}

export const salesService = {
  async getSales(filters?: { startDate?: string; endDate?: string; clientId?: string; productId?: string }) {
    const companyId = await getCurrentUserCompanyId();

    const data = await offlineQuery<Sale>(
      'sales',
      async () => {
        let query = supabase
          .from('sales')
          .select(`
            *,
            client:clients(name, email, phone, address, type),
            commercial:profiles(full_name, email, phone),
            sale_items(
              *,
              product:products(name, sku)
            )
          `)
          .eq('company_id', companyId)
          .order('created_at', { ascending: false });

        if (filters?.startDate) {
          query = query.gte('created_at', filters.startDate);
        }
        if (filters?.endDate) {
          query = query.lte('created_at', filters.endDate);
        }
        if (filters?.clientId) {
          query = query.eq('client_id', filters.clientId);
        }

        const { data, error } = await query;
        return { data, error };
      }
    );

    if (filters?.productId && data) {
      return data.filter(sale =>
        sale.sale_items?.some((item: SaleItem) => item.product_id === filters.productId)
      );
    }

    return data;
  },

  async getSaleById(id: string) {
    const companyId = await getCurrentUserCompanyId();

    const sales = await offlineQuery<Sale>(
      'sales',
      async () => {
        const { data, error } = await supabase
          .from('sales')
          .select(`
            *,
            client:clients(name, email, phone, address, type),
            commercial:profiles(full_name, email, phone),
            sale_items(
              *,
              product:products(name, sku)
            )
          `)
          .eq('id', id)
          .eq('company_id', companyId);

        return { data, error };
      }
    );

    return sales.length > 0 ? sales[0] : null;
  },

  async createSale(saleData: CreateSaleData) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const company_id = await getCurrentUserCompanyId();

    const productIds = saleData.items.map(item => item.product_id);
    const { data: products, error: productsError } = await supabase
      .from('products')
      .select('id, name, sku, stock_quantity')
      .in('id', productIds)
      .eq('company_id', company_id);

    if (productsError) throw productsError;

    const stockErrors: string[] = [];
    for (const item of saleData.items) {
      const product = products?.find(p => p.id === item.product_id);
      if (!product) {
        stockErrors.push(`Produit introuvable`);
        continue;
      }

      if (product.stock_quantity <= 0) {
        stockErrors.push(`${product.name} (${product.sku}): stock épuisé`);
      } else if (product.stock_quantity < item.quantity) {
        stockErrors.push(`${product.name} (${product.sku}): stock insuffisant (disponible: ${product.stock_quantity})`);
      }
    }

    if (stockErrors.length > 0) {
      throw new Error(`Impossible de créer la vente:\n${stockErrors.join('\n')}`);
    }

    let total_amount = 0;
    let total_discount = 0;

    const itemsWithCalculations = saleData.items.map(item => {
      const discount_percentage = item.discount_percentage || 0;
      const item_total = item.quantity * item.unit_price;
      const discount_amount = (item_total * discount_percentage) / 100;
      const subtotal = item_total - discount_amount;

      total_amount += item_total;
      total_discount += discount_amount;

      return {
        product_id: item.product_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
        discount_percentage,
        discount_amount,
        subtotal,
      };
    });

    const final_amount = total_amount - total_discount;

    const { data: sale, error: saleError } = await supabase
      .from('sales')
      .insert({
        client_id: saleData.client_id,
        commercial_id: user.id,
        total_amount,
        discount_amount: total_discount,
        final_amount,
        payment_method: saleData.payment_method,
        payment_status: saleData.payment_status || 'paye',
        notes: saleData.notes,
        company_id,
      })
      .select()
      .single();

    if (saleError) throw saleError;

    const saleItems = itemsWithCalculations.map(item => ({
      sale_id: sale.id,
      ...item,
      company_id,
    }));

    const { error: itemsError } = await supabase
      .from('sale_items')
      .insert(saleItems);

    if (itemsError) throw itemsError;

    return await this.getSaleById(sale.id);
  },

  async updateSalePaymentStatus(saleId: string, payment_status: Sale['payment_status'], payment_date?: string) {
    const updates: any = { payment_status };

    if (payment_date) {
      updates.payment_date = payment_date;
    }

    await offlineUpdate<any>(
      'sales',
      saleId,
      updates,
      async () => {
        const { error } = await supabase
          .from('sales')
          .update(updates)
          .eq('id', saleId);
        return { data: null, error };
      }
    );
  },

  async deleteSale(saleId: string) {
    await offlineDelete(
      'sales',
      saleId,
      async () => {
        const { error } = await supabase
          .from('sales')
          .delete()
          .eq('id', saleId);
        return { error };
      }
    );
  },

  async getSalesStats(startDate?: string, endDate?: string) {
    const companyId = await getCurrentUserCompanyId();

    let query = supabase
      .from('sales')
      .select('final_amount, payment_status, created_at')
      .eq('company_id', companyId);

    if (startDate) {
      query = query.gte('created_at', startDate);
    }
    if (endDate) {
      query = query.lte('created_at', endDate);
    }

    const { data, error } = await query;

    if (error) throw error;

    const stats = {
      total_sales: data?.length || 0,
      total_revenue: data?.reduce((sum, sale) => sum + parseFloat(sale.final_amount.toString()), 0) || 0,
      paid_sales: data?.filter(s => s.payment_status === 'paye').length || 0,
      pending_sales: data?.filter(s => s.payment_status === 'en_attente').length || 0,
    };

    return stats;
  },
};
