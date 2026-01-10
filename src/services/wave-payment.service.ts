import { supabase, getCurrentUserCompanyId } from './supabase';

export interface WavePaymentRequest {
  amount: number;
  currency: string;
  customerPhone: string;
  customerName: string;
  orderId: string;
  description: string;
}

export interface WavePaymentResponse {
  success: boolean;
  transactionId?: string;
  paymentUrl?: string;
  error?: string;
  checkoutId?: string;
}

export interface WavePaymentStatus {
  status: 'pending' | 'success' | 'failed' | 'cancelled';
  transactionId: string;
  amount: number;
  currency: string;
}

class WavePaymentService {
  private async getConfig() {
    const company_id = await getCurrentUserCompanyId();

    const { data, error } = await supabase
      .from('payment_configurations')
      .select('*')
      .eq('company_id', company_id)
      .eq('provider', 'wave')
      .eq('is_enabled', true)
      .maybeSingle();

    if (error || !data) {
      throw new Error('Configuration Wave non trouvée ou désactivée');
    }

    return data;
  }

  async initiatePayment(request: WavePaymentRequest): Promise<WavePaymentResponse> {
    try {
      const config = await this.getConfig();

      const payload = {
        amount: request.amount,
        currency: request.currency || 'XOF',
        error_url: `${window.location.origin}/payment/error`,
        success_url: `${window.location.origin}/payment/success`,
        metadata: {
          order_id: request.orderId,
          customer_name: request.customerName,
          customer_phone: request.customerPhone
        }
      };

      const response = await fetch('https://api.wave.com/v1/checkout/sessions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${config.api_key}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const error = await response.json();
        return {
          success: false,
          error: error.message || 'Erreur lors de l\'initialisation du paiement Wave'
        };
      }

      const data = await response.json();

      return {
        success: true,
        checkoutId: data.id,
        paymentUrl: data.wave_launch_url,
        transactionId: data.id
      };

    } catch (error: any) {
      console.error('Wave payment error:', error);
      return {
        success: false,
        error: error.message || 'Erreur lors de la connexion à Wave'
      };
    }
  }

  async checkPaymentStatus(transactionId: string): Promise<WavePaymentStatus> {
    try {
      const config = await this.getConfig();

      const response = await fetch(`https://api.wave.com/v1/checkout/sessions/${transactionId}`, {
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

      if (data.status === 'complete') {
        status = 'success';
      } else if (data.status === 'cancelled') {
        status = 'cancelled';
      } else if (data.status === 'failed') {
        status = 'failed';
      }

      return {
        status,
        transactionId: data.id,
        amount: data.amount,
        currency: data.currency
      };

    } catch (error: any) {
      console.error('Wave status check error:', error);
      throw error;
    }
  }
}

export const wavePaymentService = new WavePaymentService();
