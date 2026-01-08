import { supabase } from './supabase';

export interface SubscriptionPlan {
  id: string;
  name: string;
  duration_days: number;
  price: number;
  description: string | null;
  is_active: boolean;
  created_at: string;
}

export interface Payment {
  id: string;
  company_id: string;
  plan_id: string | null;
  amount: number;
  currency: string;
  payment_method: string;
  transaction_id: string | null;
  payment_token: string | null;
  status: 'pending' | 'completed' | 'failed' | 'cancelled';
  cinetpay_data: any;
  created_at: string;
  completed_at: string | null;
}

export interface CinetPayConfig {
  apiKey: string;
  siteId: string;
  notifyUrl: string;
  returnUrl: string;
}

export interface CinetPayPaymentData {
  transaction_id: string;
  amount: number;
  currency: string;
  customer_name: string;
  customer_surname: string;
  customer_email: string;
  customer_phone_number: string;
  description: string;
  notify_url: string;
  return_url: string;
  channels: string;
  metadata?: string;
}

export class CinetPayService {
  private readonly API_URL = 'https://api-checkout.cinetpay.com/v2/payment';
  private readonly CHECK_URL = 'https://api-checkout.cinetpay.com/v2/payment/check';

  private config: CinetPayConfig = {
    apiKey: import.meta.env.VITE_CINETPAY_API_KEY || '',
    siteId: import.meta.env.VITE_CINETPAY_SITE_ID || '',
    notifyUrl: `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/cinetpay-webhook`,
    returnUrl: window.location.origin + '/dashboard',
  };

  async getPlans(): Promise<SubscriptionPlan[]> {
    const { data, error } = await supabase
      .from('subscription_plans')
      .select('*')
      .eq('is_active', true)
      .order('duration_days', { ascending: true });

    if (error) throw error;
    return data || [];
  }

  async initiatePayment(
    planId: string,
    companyId: string,
    paymentMethod: string,
    customerInfo: {
      name: string;
      surname: string;
      email: string;
      phone: string;
    }
  ): Promise<{ paymentUrl: string; transactionId: string; paymentId: string }> {
    const { data: plan, error: planError } = await supabase
      .from('subscription_plans')
      .select('*')
      .eq('id', planId)
      .maybeSingle();

    if (planError) throw planError;
    if (!plan) throw new Error('Plan non trouvé');

    const transactionId = `TXN_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    const { data: payment, error: paymentError } = await supabase
      .from('payments')
      .insert({
        company_id: companyId,
        plan_id: planId,
        amount: plan.price,
        currency: 'XOF',
        payment_method: paymentMethod,
        transaction_id: transactionId,
        status: 'pending',
      })
      .select()
      .single();

    if (paymentError) throw paymentError;

    const paymentData: CinetPayPaymentData = {
      transaction_id: transactionId,
      amount: plan.price,
      currency: 'XOF',
      customer_name: customerInfo.name,
      customer_surname: customerInfo.surname,
      customer_email: customerInfo.email,
      customer_phone_number: customerInfo.phone,
      description: `Abonnement ${plan.name}`,
      notify_url: this.config.notifyUrl,
      return_url: this.config.returnUrl,
      channels: paymentMethod,
      metadata: JSON.stringify({
        payment_id: payment.id,
        company_id: companyId,
        plan_id: planId,
      }),
    };

    try {
      const response = await fetch(this.API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          apikey: this.config.apiKey,
          site_id: this.config.siteId,
          ...paymentData,
        }),
      });

      const result = await response.json();

      if (result.code !== '201') {
        throw new Error(result.message || 'Erreur lors de l\'initialisation du paiement');
      }

      await supabase
        .from('payments')
        .update({
          payment_token: result.data.payment_token,
          cinetpay_data: result,
        })
        .eq('id', payment.id);

      return {
        paymentUrl: result.data.payment_url,
        transactionId: transactionId,
        paymentId: payment.id,
      };
    } catch (error: any) {
      await supabase
        .from('payments')
        .update({ status: 'failed' })
        .eq('id', payment.id);

      throw error;
    }
  }

  async checkPaymentStatus(transactionId: string): Promise<Payment | null> {
    const { data: payment, error } = await supabase
      .from('payments')
      .select('*')
      .eq('transaction_id', transactionId)
      .maybeSingle();

    if (error) throw error;
    return payment;
  }

  async verifyPaymentWithCinetPay(transactionId: string): Promise<any> {
    try {
      const response = await fetch(this.CHECK_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          apikey: this.config.apiKey,
          site_id: this.config.siteId,
          transaction_id: transactionId,
        }),
      });

      const result = await response.json();
      return result;
    } catch (error) {
      console.error('Error verifying payment with CinetPay:', error);
      throw error;
    }
  }

  async getPaymentHistory(companyId: string): Promise<Payment[]> {
    const { data, error } = await supabase
      .from('payments')
      .select(`
        *,
        plan:subscription_plans(name, duration_days, price)
      `)
      .eq('company_id', companyId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async getAllPayments(): Promise<Payment[]> {
    const { data, error } = await supabase
      .from('payments')
      .select(`
        *,
        company:companies(name),
        plan:subscription_plans(name, duration_days, price)
      `)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  getPaymentMethodLabel(method: string): string {
    const labels: Record<string, string> = {
      MOBILE_MONEY: 'Mobile Money',
      WAVE: 'Wave',
      ORANGE_MONEY: 'Orange Money',
      MTN_MONEY: 'MTN Money',
      MOOV_MONEY: 'Moov Money',
    };
    return labels[method] || method;
  }

  getStatusLabel(status: string): string {
    const labels: Record<string, string> = {
      pending: 'En attente',
      completed: 'Complété',
      failed: 'Échoué',
      cancelled: 'Annulé',
    };
    return labels[status] || status;
  }

  formatAmount(amount: number): string {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF',
      minimumFractionDigits: 0,
    }).format(amount);
  }
}

export const cinetPayService = new CinetPayService();
