import { supabase, getCurrentUserCompanyId } from './supabase';

export interface InvoiceItem {
  id?: string;
  invoice_id?: string;
  product_id?: string;
  description: string;
  quantity: number;
  unit_price: number;
  discount_percentage: number;
  subtotal: number;
  product?: {
    name: string;
    sku: string;
  };
}

export interface Invoice {
  id?: string;
  invoice_number?: string;
  order_id?: string;
  sale_id?: string;
  client_id: string;
  commercial_id: string;
  company_id?: string;
  total_amount: number;
  tax_amount: number;
  discount_amount: number;
  final_amount: number;
  status: 'payee' | 'en_attente' | 'annulee';
  due_date: string;
  payment_date?: string;
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
  invoice_items?: InvoiceItem[];
  order?: {
    order_number: string;
    status: string;
  };
  sale?: {
    sale_number: string;
    payment_status: string;
  };
}

export interface CreateInvoiceData {
  client_id: string;
  items: {
    product_id?: string;
    description: string;
    quantity: number;
    unit_price: number;
    discount_percentage?: number;
  }[];
  tax_percentage?: number;
  due_date: string;
  notes?: string;
}

export const invoicesService = {
  async getInvoices(filters?: { startDate?: string; endDate?: string; clientId?: string; status?: string }) {
    const companyId = await getCurrentUserCompanyId();

    let query = supabase
      .from('invoices')
      .select(`
        *,
        client:clients(name, email, phone, address, type),
        commercial:profiles(full_name, email, phone),
        order:orders(order_number, status),
        sale:sales(sale_number, payment_status),
        invoice_items(
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
    if (filters?.status) {
      query = query.eq('status', filters.status);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data as Invoice[];
  },

  async getInvoiceById(id: string) {
    const companyId = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('invoices')
      .select(`
        *,
        client:clients(name, email, phone, address, type),
        commercial:profiles(full_name, email, phone),
        order:orders(order_number, status),
        sale:sales(sale_number, payment_status),
        invoice_items(
          *,
          product:products(name, sku)
        )
      `)
      .eq('id', id)
      .eq('company_id', companyId)
      .maybeSingle();

    if (error) throw error;
    return data as Invoice | null;
  },

  async createInvoice(invoiceData: CreateInvoiceData) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const company_id = await getCurrentUserCompanyId();

    const tax_percentage = invoiceData.tax_percentage || 0;

    let total_amount = 0;
    let total_discount = 0;

    const itemsWithCalculations = invoiceData.items.map(item => {
      const discount_percentage = item.discount_percentage || 0;
      const item_total = item.quantity * item.unit_price;
      const discount_amount = (item_total * discount_percentage) / 100;
      const subtotal = item_total - discount_amount;

      total_amount += item_total;
      total_discount += discount_amount;

      return {
        product_id: item.product_id || null,
        description: item.description,
        quantity: item.quantity,
        unit_price: item.unit_price,
        discount_percentage,
        subtotal,
      };
    });

    const amount_after_discount = total_amount - total_discount;
    const tax_amount = (amount_after_discount * tax_percentage) / 100;
    const final_amount = amount_after_discount + tax_amount;

    const { data: invoice, error: invoiceError } = await supabase
      .from('invoices')
      .insert({
        client_id: invoiceData.client_id,
        commercial_id: user.id,
        total_amount,
        tax_amount,
        discount_amount: total_discount,
        final_amount,
        status: 'en_attente',
        due_date: invoiceData.due_date,
        notes: invoiceData.notes,
        company_id,
      })
      .select()
      .single();

    if (invoiceError) throw invoiceError;

    const invoiceItems = itemsWithCalculations.map(item => ({
      invoice_id: invoice.id,
      ...item,
      company_id,
    }));

    const { error: itemsError } = await supabase
      .from('invoice_items')
      .insert(invoiceItems);

    if (itemsError) throw itemsError;

    return await this.getInvoiceById(invoice.id);
  },

  async createInvoiceFromOrder(orderId: string, tax_percentage: number = 0, due_date: string) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const company_id = await getCurrentUserCompanyId();

    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select(`
        *,
        order_items(
          *,
          product:products(name, sku)
        )
      `)
      .eq('id', orderId)
      .eq('company_id', company_id)
      .maybeSingle();

    if (orderError) throw orderError;
    if (!order) throw new Error('Commande introuvable');

    const existingInvoice = await supabase
      .from('invoices')
      .select('id')
      .eq('order_id', orderId)
      .maybeSingle();

    if (existingInvoice.data) {
      throw new Error('Une facture existe déjà pour cette commande');
    }

    const total_amount = order.total_amount;
    const tax_amount = (total_amount * tax_percentage) / 100;
    const final_amount = total_amount + tax_amount;

    const { data: invoice, error: invoiceError } = await supabase
      .from('invoices')
      .insert({
        order_id: orderId,
        client_id: order.client_id,
        commercial_id: order.commercial_id,
        total_amount,
        tax_amount,
        discount_amount: 0,
        final_amount,
        status: order.payment_status === 'totalement_paye' ? 'payee' : 'en_attente',
        due_date,
        payment_date: order.payment_status === 'totalement_paye' ? new Date().toISOString().split('T')[0] : null,
        notes: `Facture générée depuis la commande ${order.order_number}`,
        company_id,
      })
      .select()
      .single();

    if (invoiceError) throw invoiceError;

    const invoiceItems = order.order_items.map((item: any) => ({
      invoice_id: invoice.id,
      product_id: item.product_id,
      description: item.product?.name || 'Produit',
      quantity: item.quantity,
      unit_price: item.unit_price,
      discount_percentage: 0,
      subtotal: item.subtotal,
      company_id,
    }));

    const { error: itemsError } = await supabase
      .from('invoice_items')
      .insert(invoiceItems);

    if (itemsError) throw itemsError;

    return await this.getInvoiceById(invoice.id);
  },

  async createInvoiceFromSale(saleId: string, tax_percentage: number = 0, due_date: string) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const company_id = await getCurrentUserCompanyId();

    const { data: sale, error: saleError } = await supabase
      .from('sales')
      .select(`
        *,
        sale_items(
          *,
          product:products(name, sku)
        )
      `)
      .eq('id', saleId)
      .eq('company_id', company_id)
      .maybeSingle();

    if (saleError) throw saleError;
    if (!sale) throw new Error('Vente introuvable');

    const existingInvoice = await supabase
      .from('invoices')
      .select('id')
      .eq('sale_id', saleId)
      .maybeSingle();

    if (existingInvoice.data) {
      throw new Error('Une facture existe déjà pour cette vente');
    }

    const total_amount = sale.final_amount;
    const tax_amount = (total_amount * tax_percentage) / 100;
    const final_amount = total_amount + tax_amount;

    const { data: invoice, error: invoiceError } = await supabase
      .from('invoices')
      .insert({
        sale_id: saleId,
        client_id: sale.client_id,
        commercial_id: sale.commercial_id,
        total_amount,
        tax_amount,
        discount_amount: sale.discount_amount,
        final_amount,
        status: sale.payment_status === 'paye' ? 'payee' : 'en_attente',
        due_date,
        payment_date: sale.payment_status === 'paye' ? new Date().toISOString().split('T')[0] : null,
        notes: `Facture générée depuis la vente ${sale.sale_number}`,
        company_id,
      })
      .select()
      .single();

    if (invoiceError) throw invoiceError;

    const invoiceItems = sale.sale_items.map((item: any) => ({
      invoice_id: invoice.id,
      product_id: item.product_id,
      description: item.product?.name || 'Produit',
      quantity: item.quantity,
      unit_price: item.unit_price,
      discount_percentage: item.discount_percentage,
      subtotal: item.subtotal,
      company_id,
    }));

    const { error: itemsError } = await supabase
      .from('invoice_items')
      .insert(invoiceItems);

    if (itemsError) throw itemsError;

    return await this.getInvoiceById(invoice.id);
  },

  async updateInvoiceStatus(invoiceId: string, status: Invoice['status'], payment_date?: string) {
    const updates: any = { status };

    if (status === 'payee' && payment_date) {
      updates.payment_date = payment_date;
    }

    const { error } = await supabase
      .from('invoices')
      .update(updates)
      .eq('id', invoiceId);

    if (error) throw error;
  },

  async deleteInvoice(invoiceId: string) {
    const { error } = await supabase
      .from('invoices')
      .delete()
      .eq('id', invoiceId);

    if (error) throw error;
  },

  async getInvoiceStats(startDate?: string, endDate?: string) {
    const companyId = await getCurrentUserCompanyId();

    let query = supabase
      .from('invoices')
      .select('final_amount, status, created_at')
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
      total_invoices: data?.length || 0,
      total_amount: data?.reduce((sum, inv) => sum + parseFloat(inv.final_amount.toString()), 0) || 0,
      paid_invoices: data?.filter(i => i.status === 'payee').length || 0,
      pending_invoices: data?.filter(i => i.status === 'en_attente').length || 0,
      cancelled_invoices: data?.filter(i => i.status === 'annulee').length || 0,
    };

    return stats;
  },
};
