<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { orderPaymentsService } from '../services/order-payments.service';
import { authService } from '../services/auth';
import { paymentConfigService, type PaymentConfiguration } from '../services/payment-config.service';
import { wavePaymentService } from '../services/wave-payment.service';
import { mobileMoneyService, type MobileMoneyProvider } from '../services/mobile-money.service';
import { paydunyaService } from '../services/paydunya.service';
import type { Order } from '../services/orders.service';
import Icon from './Icon.vue';

const props = defineProps<{
  order: Order;
}>();

const emit = defineEmits(['close', 'success']);

const paymentMode = ref<'manual' | 'online'>('manual');
const enabledConfigs = ref<PaymentConfiguration[]>([]);
const selectedProvider = ref<string>('');
const customerPhone = ref('');
const initiatingPayment = ref(false);
const checkingStatus = ref(false);
const paymentStatus = ref<'idle' | 'pending' | 'success' | 'failed'>('idle');
const paymentMessage = ref('');
const transactionId = ref('');

const formData = ref({
  amount: 0,
  payment_method: 'especes' as 'especes' | 'mobile_money' | 'virement' | 'cheque' | 'carte_bancaire' | 'wave' | 'orange_money' | 'mtn_money' | 'moov_money' | 'paydunya',
  payment_reference: '',
  payment_date: new Date().toISOString().split('T')[0],
  notes: ''
});

const submitting = ref(false);

const remainingAmount = computed(() => {
  const total = props.order.total_amount;
  const paid = props.order.total_paid || 0;
  return total - paid;
});

const canSubmit = computed(() => {
  return formData.value.amount > 0 && formData.value.amount <= remainingAmount.value;
});

const canInitiateOnlinePayment = computed(() => {
  return selectedProvider.value &&
         formData.value.amount > 0 &&
         formData.value.amount <= remainingAmount.value &&
         customerPhone.value.trim() !== '';
});

onMounted(async () => {
  try {
    enabledConfigs.value = await paymentConfigService.getEnabledConfigurations();
    if (enabledConfigs.value.length > 0) {
      selectedProvider.value = enabledConfigs.value[0].provider;
    }

    if (props.order.client?.phone) {
      customerPhone.value = props.order.client.phone;
    }
  } catch (error) {
    console.error('Error loading payment configs:', error);
  }
});

const handleSubmit = async () => {
  if (!canSubmit.value) {
    alert('Veuillez entrer un montant valide');
    return;
  }

  try {
    submitting.value = true;
    const currentProfile = await authService.getCurrentProfile();

    if (!currentProfile) {
      throw new Error('Profil utilisateur non trouvé');
    }

    const payment = await orderPaymentsService.createPayment({
      order_id: props.order.id!,
      client_id: props.order.client_id,
      amount: formData.value.amount,
      payment_method: formData.value.payment_method,
      payment_reference: formData.value.payment_reference || undefined,
      payment_date: new Date(formData.value.payment_date).toISOString(),
      notes: formData.value.notes || undefined,
      created_by: currentProfile.id,
      company_id: currentProfile.company_id!
    });

    emit('success', payment);
  } catch (error) {
    console.error('Error creating payment:', error);
    alert('Erreur lors de l\'enregistrement du paiement');
  } finally {
    submitting.value = false;
  }
};

const initiateOnlinePayment = async () => {
  if (!canInitiateOnlinePayment.value) {
    alert('Veuillez remplir tous les champs requis');
    return;
  }

  try {
    initiatingPayment.value = true;
    paymentStatus.value = 'idle';
    paymentMessage.value = '';

    if (selectedProvider.value === 'paydunya') {
      const response = await paydunyaService.initiatePayment({
        amount: formData.value.amount,
        currency: 'XOF',
        customerPhone: customerPhone.value,
        customerName: props.order.client?.name || 'Client',
        customerEmail: props.order.client?.email,
        orderId: props.order.id!,
        description: `Paiement commande ${props.order.order_number}`
      });

      if (response.success && response.paymentUrl) {
        paymentStatus.value = 'pending';
        paymentMessage.value = 'Redirection vers PayDunya...';
        transactionId.value = response.transactionId || '';
        window.open(response.paymentUrl, '_blank');
        startStatusCheck();
      } else {
        paymentStatus.value = 'failed';
        paymentMessage.value = response.error || 'Erreur lors de l\'initialisation du paiement';
      }
    } else if (selectedProvider.value === 'wave') {
      const response = await wavePaymentService.initiatePayment({
        amount: formData.value.amount,
        currency: 'XOF',
        customerPhone: customerPhone.value,
        customerName: props.order.client?.name || 'Client',
        orderId: props.order.id!,
        description: `Paiement commande ${props.order.order_number}`
      });

      if (response.success && response.paymentUrl) {
        paymentStatus.value = 'pending';
        paymentMessage.value = 'Redirection vers Wave...';
        transactionId.value = response.transactionId || '';
        window.open(response.paymentUrl, '_blank');
        startStatusCheck();
      } else {
        paymentStatus.value = 'failed';
        paymentMessage.value = response.error || 'Erreur lors de l\'initialisation du paiement';
      }
    } else if (['orange_money', 'mtn_money', 'moov_money'].includes(selectedProvider.value)) {
      const response = await mobileMoneyService.initiatePayment({
        provider: selectedProvider.value as MobileMoneyProvider,
        amount: formData.value.amount,
        currency: 'XOF',
        customerPhone: customerPhone.value,
        customerName: props.order.client?.name || 'Client',
        orderId: props.order.id!,
        description: `Paiement commande ${props.order.order_number}`
      });

      if (response.success) {
        paymentStatus.value = 'pending';
        paymentMessage.value = response.message || 'Paiement initié. Composez le code USSD sur votre téléphone pour valider.';
        transactionId.value = response.transactionId || '';
        startStatusCheck();
      } else {
        paymentStatus.value = 'failed';
        paymentMessage.value = response.error || 'Erreur lors de l\'initialisation du paiement';
      }
    }
  } catch (error: any) {
    console.error('Error initiating payment:', error);
    paymentStatus.value = 'failed';
    paymentMessage.value = error.message || 'Erreur lors de l\'initialisation du paiement';
  } finally {
    initiatingPayment.value = false;
  }
};

let statusCheckInterval: number | null = null;

const startStatusCheck = () => {
  let attempts = 0;
  const maxAttempts = 30;

  statusCheckInterval = window.setInterval(async () => {
    attempts++;

    if (attempts > maxAttempts) {
      stopStatusCheck();
      paymentStatus.value = 'failed';
      paymentMessage.value = 'Délai d\'attente dépassé. Veuillez vérifier manuellement le statut du paiement.';
      return;
    }

    try {
      checkingStatus.value = true;
      let status;

      if (selectedProvider.value === 'paydunya') {
        status = await paydunyaService.checkPaymentStatus(transactionId.value);
      } else if (selectedProvider.value === 'wave') {
        status = await wavePaymentService.checkPaymentStatus(transactionId.value);
      } else if (['orange_money', 'mtn_money', 'moov_money'].includes(selectedProvider.value)) {
        status = await mobileMoneyService.checkPaymentStatus(
          selectedProvider.value as MobileMoneyProvider,
          transactionId.value
        );
      }

      if (status?.status === 'success') {
        stopStatusCheck();
        paymentStatus.value = 'success';
        paymentMessage.value = 'Paiement confirmé avec succès!';

        setTimeout(() => {
          emit('success', { id: transactionId.value });
        }, 2000);
      } else if (status?.status === 'failed' || status?.status === 'cancelled') {
        stopStatusCheck();
        paymentStatus.value = 'failed';
        paymentMessage.value = status.status === 'cancelled'
          ? 'Paiement annulé par le client'
          : 'Le paiement a échoué';
      }
    } catch (error) {
      console.error('Error checking payment status:', error);
    } finally {
      checkingStatus.value = false;
    }
  }, 3000);
};

const stopStatusCheck = () => {
  if (statusCheckInterval) {
    clearInterval(statusCheckInterval);
    statusCheckInterval = null;
  }
};

const setMaxAmount = () => {
  formData.value.amount = remainingAmount.value;
};

const getProviderIcon = (provider: string): string => {
  const icons: Record<string, string> = {
    'wave': 'credit-card',
    'orange_money': 'smartphone',
    'mtn_money': 'smartphone',
    'moov_money': 'smartphone',
  };
  return icons[provider] || 'credit-card';
};

const handleClose = () => {
  stopStatusCheck();
  emit('close');
};
</script>

<template>
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-lg p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
      <div class="flex justify-between items-center mb-6">
        <div>
          <h3 class="text-xl font-bold text-gray-800">Enregistrer un paiement</h3>
          <p class="text-sm text-gray-600">Commande: {{ order.order_number }}</p>
        </div>
        <button @click="handleClose" class="text-gray-400 hover:text-gray-600 transition-colors">
          <Icon name="x" class="w-6 h-6" />
        </button>
      </div>

      <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
        <div class="grid grid-cols-3 gap-4 text-center">
          <div>
            <p class="text-sm text-gray-600">Montant total</p>
            <p class="text-xl font-bold text-gray-800">{{ order.total_amount.toLocaleString('fr-FR') }} FCFA</p>
          </div>
          <div>
            <p class="text-sm text-gray-600">Déjà payé</p>
            <p class="text-xl font-bold text-green-600">{{ (order.total_paid || 0).toLocaleString('fr-FR') }} FCFA</p>
          </div>
          <div>
            <p class="text-sm text-gray-600">Reste à payer</p>
            <p class="text-xl font-bold text-red-600">{{ remainingAmount.toLocaleString('fr-FR') }} FCFA</p>
          </div>
        </div>
      </div>

      <div v-if="enabledConfigs.length > 0" class="mb-6">
        <div class="flex gap-2 border-b border-gray-200">
          <button
            @click="paymentMode = 'manual'"
            :class="[
              'pb-3 px-4 font-medium text-sm transition-colors border-b-2',
              paymentMode === 'manual'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            ]"
          >
            Paiement manuel
          </button>
          <button
            @click="paymentMode = 'online'"
            :class="[
              'pb-3 px-4 font-medium text-sm transition-colors border-b-2',
              paymentMode === 'online'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            ]"
          >
            Paiement en ligne
          </button>
        </div>
      </div>

      <div v-if="paymentMode === 'manual'">
        <form @submit.prevent="handleSubmit" class="space-y-4">
          <div>
            <label class="label">Montant du paiement (FCFA) <span class="text-red-500">*</span></label>
            <div class="flex gap-2">
              <input
                v-model.number="formData.amount"
                type="number"
                step="0.01"
                min="0"
                :max="remainingAmount"
                class="input-field flex-1"
                required
              />
              <button
                type="button"
                @click="setMaxAmount"
                class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 text-sm font-medium"
              >
                Solde
              </button>
            </div>
            <p v-if="formData.amount > remainingAmount" class="text-sm text-red-600 mt-1">
              Le montant ne peut pas dépasser le reste à payer
            </p>
          </div>

          <div>
            <label class="label">Mode de paiement <span class="text-red-500">*</span></label>
            <select v-model="formData.payment_method" class="input-field" required>
              <option value="especes">Espèces</option>
              <option value="mobile_money">Mobile Money</option>
              <option value="virement">Virement bancaire</option>
              <option value="cheque">Chèque</option>
              <option value="carte_bancaire">Carte bancaire</option>
            </select>
          </div>

          <div>
            <label class="label">Référence de paiement</label>
            <input
              v-model="formData.payment_reference"
              type="text"
              class="input-field"
              placeholder="Numéro de transaction, chèque, etc."
            />
          </div>

          <div>
            <label class="label">Date du paiement <span class="text-red-500">*</span></label>
            <input
              v-model="formData.payment_date"
              type="date"
              class="input-field"
              required
            />
          </div>

          <div>
            <label class="label">Notes</label>
            <textarea
              v-model="formData.notes"
              class="input-field"
              rows="3"
              placeholder="Notes additionnelles..."
            ></textarea>
          </div>

          <div class="flex gap-3 pt-4 border-t">
            <button
              type="submit"
              :disabled="!canSubmit || submitting"
              class="btn-primary flex-1 inline-flex items-center justify-center gap-2 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              <Icon name="check-circle" class="w-5 h-5" />
              <span>{{ submitting ? 'Enregistrement...' : 'Enregistrer le paiement' }}</span>
            </button>
            <button
              type="button"
              @click="handleClose"
              class="btn-secondary flex-1 inline-flex items-center justify-center gap-2"
            >
              <Icon name="x" class="w-5 h-5" />
              <span>Annuler</span>
            </button>
          </div>
        </form>
      </div>

      <div v-else-if="paymentMode === 'online'" class="space-y-4">
        <div v-if="paymentStatus === 'idle' || paymentStatus === 'failed'">
          <div>
            <label class="label">Montant du paiement (FCFA) <span class="text-red-500">*</span></label>
            <div class="flex gap-2">
              <input
                v-model.number="formData.amount"
                type="number"
                step="0.01"
                min="0"
                :max="remainingAmount"
                class="input-field flex-1"
                required
              />
              <button
                type="button"
                @click="setMaxAmount"
                class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 text-sm font-medium"
              >
                Solde
              </button>
            </div>
            <p v-if="formData.amount > remainingAmount" class="text-sm text-red-600 mt-1">
              Le montant ne peut pas dépasser le reste à payer
            </p>
          </div>

          <div>
            <label class="label">Moyen de paiement <span class="text-red-500">*</span></label>
            <div class="grid grid-cols-2 gap-3">
              <button
                v-for="config in enabledConfigs"
                :key="config.provider"
                type="button"
                @click="selectedProvider = config.provider"
                :class="[
                  'p-4 border-2 rounded-lg transition-all',
                  selectedProvider === config.provider
                    ? 'border-blue-500 bg-blue-50'
                    : 'border-gray-200 hover:border-gray-300'
                ]"
              >
                <div class="flex items-center gap-3">
                  <Icon :name="getProviderIcon(config.provider)" class="w-6 h-6" />
                  <span class="font-medium">{{ paymentConfigService.getProviderLabel(config.provider) }}</span>
                </div>
              </button>
            </div>
          </div>

          <div>
            <label class="label">Numéro de téléphone du client <span class="text-red-500">*</span></label>
            <input
              v-model="customerPhone"
              type="tel"
              class="input-field"
              placeholder="+225 0101010101"
              required
            />
            <p class="text-xs text-gray-500 mt-1">
              Format: +225XXXXXXXXXX ou 0XXXXXXXXX
            </p>
          </div>

          <div v-if="paymentStatus === 'failed'" class="bg-red-50 border border-red-200 rounded-lg p-4">
            <div class="flex gap-3">
              <Icon name="alert-circle" class="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
              <div>
                <p class="font-medium text-red-800">Erreur</p>
                <p class="text-sm text-red-600 mt-1">{{ paymentMessage }}</p>
              </div>
            </div>
          </div>

          <div class="flex gap-3 pt-4 border-t">
            <button
              type="button"
              @click="initiateOnlinePayment"
              :disabled="!canInitiateOnlinePayment || initiatingPayment"
              class="btn-primary flex-1 inline-flex items-center justify-center gap-2 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              <Icon name="credit-card" class="w-5 h-5" />
              <span>{{ initiatingPayment ? 'Initialisation...' : 'Initier le paiement' }}</span>
            </button>
            <button
              type="button"
              @click="handleClose"
              class="btn-secondary flex-1 inline-flex items-center justify-center gap-2"
            >
              <Icon name="x" class="w-5 h-5" />
              <span>Annuler</span>
            </button>
          </div>
        </div>

        <div v-else-if="paymentStatus === 'pending'" class="text-center py-8">
          <div class="inline-flex items-center justify-center w-16 h-16 bg-blue-100 rounded-full mb-4">
            <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600"></div>
          </div>
          <h4 class="text-lg font-semibold text-gray-800 mb-2">Paiement en cours...</h4>
          <p class="text-gray-600 mb-4">{{ paymentMessage }}</p>
          <p class="text-sm text-gray-500">Vérification automatique du statut...</p>
        </div>

        <div v-else-if="paymentStatus === 'success'" class="text-center py-8">
          <div class="inline-flex items-center justify-center w-16 h-16 bg-green-100 rounded-full mb-4">
            <Icon name="check-circle" class="w-10 h-10 text-green-600" />
          </div>
          <h4 class="text-lg font-semibold text-gray-800 mb-2">Paiement confirmé!</h4>
          <p class="text-gray-600">{{ paymentMessage }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
