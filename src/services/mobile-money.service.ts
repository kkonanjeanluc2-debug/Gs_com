import { supabase, getCurrentUserCompanyId } from './supabase';

export type MobileMoneyProvider = 'orange_money' | 'mtn_money' | 'moov_money';

export interface MobileMoneyPaymentRequest {
  provider: MobileMoneyProvider;
  amount: number;
  currency: string;
  customerPhone: string;
  customerName: string;
  orderId: string;
  description: string;
}

export interface MobileMoneyPaymentResponse {
  success: boolean;
  transactionId?: string;
  message?: string;
  error?: string;
  paymentReference?: string;
}

export interface MobileMoneyPaymentStatus {
  status: 'pending' | 'success' | 'failed' | 'cancelled';
  transactionId: string;
  amount: number;
  currency: string;
  customerPhone: string;
}

class MobileMoneyService {
  private async getConfig(provider: MobileMoneyProvider) {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('payment_configurations')
      .select('*')
      .eq('company_id', company_id)
      .eq('provider', provider)
      .eq('is_enabled', true)
      .maybeSingle();

    if (error || !data) {
      throw new Error(`Configuration ${provider} non trouvée ou désactivée`);
    }

    return data;
  }

  private getProviderLabel(provider: MobileMoneyProvider): string {
    const labels: Record<MobileMoneyProvider, string> = {
      'orange_money': 'Orange Money',
      'mtn_money': 'MTN Mobile Money',
      'moov_money': 'Moov Money'
    };
    return labels[provider];
  }

  async initiatePayment(request: MobileMoneyPaymentRequest): Promise<MobileMoneyPaymentResponse> {
    try {
      const config = await this.getConfig(request.provider);

      const cleanPhone = request.customerPhone.replace(/\s+/g, '').replace(/^\+225/, '');

      const payload = {
        amount: request.amount,
        currency: request.currency || 'XOF',
        customer_phone: cleanPhone,
        customer_name: request.customerName,
        description: request.description,
        reference: request.orderId,
        merchant_id: config.merchant_id,
        callback_url: `${window.location.origin}/api/webhooks/mobile-money/${request.provider}`
      };

      let apiUrl = '';
      let apiKey = config.api_key;

      switch (request.provider) {
        case 'orange_money':
          apiUrl = config.test_mode
            ? 'https://api.orange.com/orange-money-webpay/ci/v1/webpayment'
            : 'https://api.orange.com/orange-money-webpay/ci/v1/webpayment';
          break;
        case 'mtn_money':
          apiUrl = config.test_mode
            ? 'https://sandbox.momodeveloper.mtn.com/collection/v1_0/requesttopay'
            : 'https://proxy.momoapi.mtn.com/collection/v1_0/requesttopay';
          break;
        case 'moov_money':
          apiUrl = config.test_mode
            ? 'https://test-payment.moov-africa.ci/api/payment'
            : 'https://payment.moov-africa.ci/api/payment';
          break;
      }

      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
          'X-Reference-Id': request.orderId
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const error = await response.json();
        return {
          success: false,
          error: error.message || `Erreur lors de l'initialisation du paiement ${this.getProviderLabel(request.provider)}`
        };
      }

      const data = await response.json();

      return {
        success: true,
        transactionId: data.transaction_id || data.id || request.orderId,
        paymentReference: data.payment_token || data.reference,
        message: `Paiement ${this.getProviderLabel(request.provider)} initié. Composez le code USSD sur votre téléphone pour valider.`
      };

    } catch (error: any) {
      console.error('Mobile Money payment error:', error);
      return {
        success: false,
        error: error.message || 'Erreur lors de la connexion au service de paiement'
      };
    }
  }

  async checkPaymentStatus(provider: MobileMoneyProvider, transactionId: string): Promise<MobileMoneyPaymentStatus> {
    try {
      const config = await this.getConfig(provider);

      let apiUrl = '';

      switch (provider) {
        case 'orange_money':
          apiUrl = `https://api.orange.com/orange-money-webpay/ci/v1/transactionstatus/${transactionId}`;
          break;
        case 'mtn_money':
          apiUrl = config.test_mode
            ? `https://sandbox.momodeveloper.mtn.com/collection/v1_0/requesttopay/${transactionId}`
            : `https://proxy.momoapi.mtn.com/collection/v1_0/requesttopay/${transactionId}`;
          break;
        case 'moov_money':
          apiUrl = config.test_mode
            ? `https://test-payment.moov-africa.ci/api/payment/${transactionId}/status`
            : `https://payment.moov-africa.ci/api/payment/${transactionId}/status`;
          break;
      }

      const response = await fetch(apiUrl, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${config.api_key}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors de la vérification du statut');
      }

      const data = await response.json();

      let status: 'pending' | 'success' | 'failed' | 'cancelled' = 'pending';

      const statusValue = (data.status || data.state || '').toLowerCase();

      if (statusValue === 'successful' || statusValue === 'success' || statusValue === 'completed') {
        status = 'success';
      } else if (statusValue === 'failed' || statusValue === 'error') {
        status = 'failed';
      } else if (statusValue === 'cancelled' || statusValue === 'canceled') {
        status = 'cancelled';
      }

      return {
        status,
        transactionId: data.transaction_id || data.id || transactionId,
        amount: data.amount || 0,
        currency: data.currency || 'XOF',
        customerPhone: data.customer_phone || data.payer || ''
      };

    } catch (error: any) {
      console.error('Mobile Money status check error:', error);
      throw error;
    }
  }
}

export const mobileMoneyService = new MobileMoneyService();
