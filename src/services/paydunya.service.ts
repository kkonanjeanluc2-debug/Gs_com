import { supabase } from './supabase';

export interface PayDunyaPaymentRequest {
  amount: number;
  currency: string;
  customerName: string;
  customerEmail?: string;
  customerPhone: string;
  orderId: string;
  description: string;
}

export interface PayDunyaPaymentResponse {
  success: boolean;
  paymentUrl?: string;
  transactionId?: string;
  error?: string;
  message?: string;
}

export interface PayDunyaStatusResponse {
  status: 'pending' | 'success' | 'failed' | 'cancelled';
  transactionId: string;
  amount?: number;
  message?: string;
}

class PayDunyaService {
  private async getConfiguration() {
    const { data: config, error } = await supabase
      .from('payment_configurations')
      .select('*')
      .eq('provider', 'paydunya')
      .eq('is_enabled', true)
      .maybeSingle();

    if (error) throw error;
    if (!config) throw new Error('PayDunya n\'est pas configuré');

    return config;
  }

  async initiatePayment(request: PayDunyaPaymentRequest): Promise<PayDunyaPaymentResponse> {
    try {
      const config = await this.getConfiguration();

      const apiUrl = config.is_test_mode
        ? 'https://app.paydunya.com/sandbox-api/v1'
        : 'https://app.paydunya.com/api/v1';

      const payload = {
        invoice: {
          total_amount: request.amount,
          description: request.description
        },
        store: {
          name: config.merchant_name || 'Mon Commerce',
        },
        custom_data: {
          order_id: request.orderId
        },
        actions: {
          cancel_url: `${window.location.origin}/payment/cancel`,
          return_url: `${window.location.origin}/payment/success`,
          callback_url: `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/paydunya-webhook`
        }
      };

      const response = await fetch(`${apiUrl}/checkout-invoice/create`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'PAYDUNYA-MASTER-KEY': config.api_key,
          'PAYDUNYA-PRIVATE-KEY': config.api_secret,
          'PAYDUNYA-TOKEN': config.merchant_id
        },
        body: JSON.stringify(payload)
      });

      const data = await response.json();

      if (data.response_code === '00') {
        const transactionId = data.token;

        await supabase
          .from('payment_transactions')
          .insert({
            transaction_id: transactionId,
            provider: 'paydunya',
            order_id: request.orderId,
            amount: request.amount,
            currency: request.currency,
            status: 'pending',
            customer_phone: request.customerPhone,
            customer_name: request.customerName,
            metadata: { invoice_token: data.token }
          });

        return {
          success: true,
          paymentUrl: data.response_text,
          transactionId: transactionId,
          message: 'Transaction initiée avec succès'
        };
      } else {
        return {
          success: false,
          error: data.response_text || 'Erreur lors de l\'initialisation du paiement'
        };
      }
    } catch (error: any) {
      console.error('PayDunya initiation error:', error);
      return {
        success: false,
        error: error.message || 'Erreur lors de l\'initialisation du paiement'
      };
    }
  }

  async checkPaymentStatus(transactionId: string): Promise<PayDunyaStatusResponse> {
    try {
      const config = await this.getConfiguration();

      const apiUrl = config.is_test_mode
        ? 'https://app.paydunya.com/sandbox-api/v1'
        : 'https://app.paydunya.com/api/v1';

      const response = await fetch(`${apiUrl}/checkout-invoice/confirm/${transactionId}`, {
        method: 'GET',
        headers: {
          'PAYDUNYA-MASTER-KEY': config.api_key,
          'PAYDUNYA-PRIVATE-KEY': config.api_secret,
          'PAYDUNYA-TOKEN': config.merchant_id
        }
      });

      const data = await response.json();

      let status: 'pending' | 'success' | 'failed' | 'cancelled' = 'pending';

      if (data.response_code === '00') {
        if (data.status === 'completed') {
          status = 'success';
        } else if (data.status === 'cancelled') {
          status = 'cancelled';
        } else if (data.status === 'failed') {
          status = 'failed';
        }
      }

      return {
        status,
        transactionId,
        amount: data.invoice?.total_amount,
        message: data.response_text
      };
    } catch (error: any) {
      console.error('PayDunya status check error:', error);
      return {
        status: 'pending',
        transactionId,
        message: 'Erreur lors de la vérification du statut'
      };
    }
  }

  getProviderLabel(): string {
    return 'PayDunya';
  }

  getProviderDescription(): string {
    return 'Paiements par Mobile Money, Carte bancaire et autres moyens de paiement africains';
  }
}

export const paydunyaService = new PayDunyaService();
