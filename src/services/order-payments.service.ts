import { supabase, getCurrentUserCompanyId } from './supabase';
import type { OrderPayment } from './orders.service';

export class OrderPaymentsService {
  async createPayment(payment: Omit<OrderPayment, 'id' | 'created_at' | 'updated_at' | 'receipt_number'>) {
    const company_id = await getCurrentUserCompanyId();
    const { data, error } = await supabase
      .from('order_payments')
      .insert({ ...payment, company_id })
      .select()
      .single();

    if (error) throw error;
    return data as OrderPayment;
  }

  async getPaymentsByOrder(orderId: string) {
    const company_id = await getCurrentUserCompanyId();
    const { data, error } = await supabase
      .from('order_payments')
      .select('*')
      .eq('order_id', orderId)
      .eq('company_id', company_id)
      .order('payment_date', { ascending: false });

    if (error) throw error;
    return data as OrderPayment[];
  }

  async getPaymentsByClient(clientId: string) {
    const company_id = await getCurrentUserCompanyId();
    const { data, error } = await supabase
      .from('order_payments')
      .select('*')
      .eq('client_id', clientId)
      .eq('company_id', company_id)
      .order('payment_date', { ascending: false });

    if (error) throw error;
    return data as OrderPayment[];
  }

  async getAllPayments() {
    const company_id = await getCurrentUserCompanyId();
    const { data, error } = await supabase
      .from('order_payments')
      .select(`
        *,
        order:orders(order_number, total_amount),
        client:clients(name, entity_type, company_name),
        creator:profiles!order_payments_created_by_fkey(full_name)
      `)
      .eq('company_id', company_id)
      .order('payment_date', { ascending: false });

    if (error) throw error;
    return data;
  }

  async getPaymentById(id: string) {
    const company_id = await getCurrentUserCompanyId();
    const { data, error } = await supabase
      .from('order_payments')
      .select(`
        *,
        order:orders(
          order_number,
          total_amount,
          total_paid,
          client:clients(name, email, phone, address, entity_type, company_name, contact_person)
        ),
        client:clients(name, email, phone, address, entity_type, company_name, contact_person),
        creator:profiles!order_payments_created_by_fkey(full_name)
      `)
      .eq('id', id)
      .eq('company_id', company_id)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  async updatePayment(id: string, updates: Partial<OrderPayment>) {
    const { data, error } = await supabase
      .from('order_payments')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data as OrderPayment;
  }

  async deletePayment(id: string) {
    const { error } = await supabase
      .from('order_payments')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }

  getPaymentMethodLabel(method: string): string {
    const labels: Record<string, string> = {
      especes: 'Espèces',
      mobile_money: 'Mobile Money',
      virement: 'Virement bancaire',
      cheque: 'Chèque',
      carte_bancaire: 'Carte bancaire'
    };
    return labels[method] || method;
  }

  getPaymentStatusLabel(status: string): string {
    const labels: Record<string, string> = {
      non_paye: 'Non payé',
      partiellement_paye: 'Partiellement payé',
      totalement_paye: 'Totalement payé'
    };
    return labels[status] || status;
  }
}

export const orderPaymentsService = new OrderPaymentsService();
