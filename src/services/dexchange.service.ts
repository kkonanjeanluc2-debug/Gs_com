import { supabase } from './supabase';

export interface DexchangePaymentRequest {
  amount: number;
  currency: string;
  customerName: string;
  customerEmail?: string;
  customerPhone: string;
  orderId: string;
  description: string;
  serviceCode?: string;
}

export interface DexchangePaymentResponse {
  success: boolean;
  paymentUrl?: string;
  transactionId?: string;
  error?: string;
  message?: string;
}

export interface DexchangeStatusResponse {
  status: 'pending' | 'success' | 'failed' | 'cancelled';
  transactionId: string;
  amount?: number;
  message?: string;
}

class DexchangeService {
  private async getConfiguration() {
    const { data: config, error } = await supabase
      .from('payment_configurations')
      .select('*')
      .eq('provider', 'dexchange')
      .eq('is_enabled', true)
      .maybeSingle();

    if (error) throw error;
    if (!config) throw new Error('Dexchange n\'est pas configuré');

    return config;
  }

  async initiatePayment(request: DexchangePaymentRequest): Promise<DexchangePaymentResponse> {
    try {
      const config = await this.getConfiguration();

      const apiUrl = config.is_test_mode
        ? 'https://api-m.dexchange.sn/api/v1'
        : 'https://api-m.dexchange.sn/api/v1';

      const externalTransactionId = `${request.orderId}-${Date.now()}`;

      const serviceCode = request.serviceCode || config.config_data?.default_service_code || 'OM_CI_CASHOUT';

      const payload = {
        externalTransactionId,
        serviceCode,
        amount: request.amount,
        number: request.customerPhone,
        callBackURL: `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/dexchange-webhook`,
        successUrl: `${window.location.origin}/payment/success`,
        failureUrl: `${window.location.origin}/payment/cancel`
      };

      const response = await fetch(`${apiUrl}/transaction/init`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${config.api_key}`
        },
        body: JSON.stringify(payload)
      });

      const data = await response.json();

      if (data.success && data.transaction) {
        const transactionId = data.transaction.transactionId;

        await supabase
          .from('payment_transactions')
          .insert({
            transaction_id: transactionId,
            provider: 'dexchange',
            order_id: request.orderId,
            amount: request.amount,
            currency: request.currency,
            status: 'pending',
            customer_phone: request.customerPhone,
            customer_name: request.customerName,
            metadata: {
              externalTransactionId,
              serviceCode,
              dexchange_data: data.transaction
            }
          });

        return {
          success: true,
          paymentUrl: data.transaction.cashout_url || data.transaction.successUrl,
          transactionId: transactionId,
          message: data.message || 'Transaction initiée avec succès'
        };
      } else {
        return {
          success: false,
          error: data.message || 'Erreur lors de l\'initialisation du paiement'
        };
      }
    } catch (error: any) {
      console.error('Dexchange initiation error:', error);
      return {
        success: false,
        error: error.message || 'Erreur lors de l\'initialisation du paiement'
      };
    }
  }

  async checkPaymentStatus(transactionId: string): Promise<DexchangeStatusResponse> {
    try {
      const config = await this.getConfiguration();

      const apiUrl = config.is_test_mode
        ? 'https://api-m.dexchange.sn/api/v1'
        : 'https://api-m.dexchange.sn/api/v1';

      const response = await fetch(`${apiUrl}/transaction/${transactionId}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${config.api_key}`
        }
      });

      const data = await response.json();

      let status: 'pending' | 'success' | 'failed' | 'cancelled' = 'pending';

      if (data.success && data.transaction) {
        const txStatus = data.transaction.Status || data.transaction.STATUS;

        if (txStatus === 'SUCCESS' || txStatus === 'COMPLETED') {
          status = 'success';
        } else if (txStatus === 'CANCELLED') {
          status = 'cancelled';
        } else if (txStatus === 'FAILED') {
          status = 'failed';
        }
      }

      return {
        status,
        transactionId,
        amount: data.transaction?.transactionAmount || data.transaction?.AMOUNT,
        message: data.message
      };
    } catch (error: any) {
      console.error('Dexchange status check error:', error);
      return {
        status: 'pending',
        transactionId,
        message: 'Erreur lors de la vérification du statut'
      };
    }
  }

  getProviderLabel(): string {
    return 'Dexchange';
  }

  getProviderDescription(): string {
    return 'Paiements par Mobile Money (Orange, MTN, Moov, Wave) et autres moyens de paiement africains';
  }
}

export const dexchangeService = new DexchangeService();
