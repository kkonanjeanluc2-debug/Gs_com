<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-2xl font-bold text-gray-900 mb-2">Plans d'abonnement</h2>
      <p class="text-gray-600">Choisissez le plan qui correspond à vos besoins</p>
    </div>

    <div v-if="subscriptionInfo" class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
      <h3 class="text-sm font-semibold text-blue-900 mb-3">Votre abonnement actuel</h3>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
        <div>
          <span class="text-blue-700 font-medium">Statut:</span>
          <span class="ml-2" :class="{
            'text-blue-800 font-semibold': subscriptionInfo.subscription_status === 'trial',
            'text-green-800 font-semibold': subscriptionInfo.subscription_status === 'active',
            'text-red-800 font-semibold': subscriptionInfo.subscription_status === 'expired',
            'text-gray-800 font-semibold': subscriptionInfo.subscription_status === 'suspended'
          }">
            {{ getStatusLabel(subscriptionInfo.subscription_status) }}
          </span>
        </div>
        <div v-if="subscriptionInfo.trial_end_date">
          <span class="text-blue-700 font-medium">Fin période d'essai:</span>
          <span class="ml-2 text-blue-900">{{ formatDate(subscriptionInfo.trial_end_date) }}</span>
        </div>
        <div v-if="subscriptionInfo.subscription_end_date">
          <span class="text-blue-700 font-medium">Fin d'abonnement:</span>
          <span class="ml-2 text-blue-900">{{ formatDate(subscriptionInfo.subscription_end_date) }}</span>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-lg border border-gray-200 p-4 flex items-center justify-center gap-4 mb-6">
      <span class="text-sm font-medium text-gray-700">Période de facturation:</span>
      <div class="flex rounded-lg border border-gray-300 overflow-hidden">
        <button
          @click="billingCycle = 'monthly'"
          :class="[
            'px-6 py-2 text-sm font-medium transition-colors',
            billingCycle === 'monthly'
              ? 'bg-blue-600 text-white'
              : 'bg-white text-gray-700 hover:bg-gray-50'
          ]"
        >
          Mensuel
        </button>
        <button
          @click="billingCycle = 'annual'"
          :class="[
            'px-6 py-2 text-sm font-medium transition-colors',
            billingCycle === 'annual'
              ? 'bg-blue-600 text-white'
              : 'bg-white text-gray-700 hover:bg-gray-50'
          ]"
        >
          Annuel
        </button>
      </div>
      <div v-if="billingCycle === 'annual'" class="bg-green-100 text-green-800 text-xs font-semibold px-3 py-1 rounded-full">
        Économisez jusqu'à 20%
      </div>
    </div>

    <div v-if="loading" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div
        v-for="(plansOfType, planType) in plansByType"
        :key="planType"
        class="bg-white rounded-lg shadow-lg border-2 hover:border-blue-500 transition-all relative overflow-hidden"
        :class="{ 'border-blue-500 ring-2 ring-blue-200': planType === 'professional' }"
      >
        <div v-if="planType === 'professional'" class="absolute top-0 right-0 bg-blue-500 text-white text-xs font-bold px-4 py-1">
          RECOMMANDÉ
        </div>

        <div class="p-6">
          <h3 class="text-2xl font-bold text-gray-900 mb-2">{{ getPlanTypeLabel(planType) }}</h3>

          <div class="mb-4">
            <div class="text-4xl font-bold text-gray-900">
              {{ formatAmount(getCurrentPrice(plansOfType)) }}
            </div>
            <div class="text-sm text-gray-500 mt-1">
              {{ billingCycle === 'monthly' ? 'par mois' : 'par an' }}
            </div>
            <div v-if="billingCycle === 'annual' && getAnnualDiscount(plansOfType) > 0" class="text-xs text-green-600 font-semibold mt-2">
              Économisez {{ getAnnualDiscount(plansOfType) }}% par rapport au mensuel
            </div>
          </div>

          <p class="text-gray-600 text-sm mb-4">{{ getCurrentPlan(plansOfType)?.description || '' }}</p>

          <div class="mb-6">
            <div class="text-xs font-semibold text-gray-700 mb-2">Fonctionnalités incluses:</div>
            <div class="space-y-2">
              <div
                v-for="feature in getCurrentPlan(plansOfType)?.features?.slice(0, 6)"
                :key="feature.id"
                class="flex items-start gap-2 text-sm text-gray-700"
              >
                <svg class="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
                <span>{{ feature.name }}</span>
              </div>
              <div v-if="getCurrentPlan(plansOfType)?.features && getCurrentPlan(plansOfType).features.length > 6" class="text-xs text-gray-500 pl-7">
                +{{ getCurrentPlan(plansOfType).features.length - 6 }} autres fonctionnalités
              </div>
            </div>
          </div>

          <button
            @click="selectPlan(getCurrentPlan(plansOfType))"
            class="w-full bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 transition-colors font-semibold"
          >
            Choisir ce plan
          </button>
        </div>
      </div>
    </div>

    <div v-if="paymentHistory.length > 0" class="mt-12">
      <h3 class="text-xl font-bold text-gray-900 mb-4">Historique des paiements</h3>
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Plan</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Montant</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Méthode</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="payment in paymentHistory" :key="payment.id">
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {{ formatDate(payment.created_at) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {{ payment.plan?.name || 'N/A' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-semibold">
                {{ formatAmount(payment.amount) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                {{ getPaymentMethodLabel(payment.payment_method) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                  :class="{
                    'bg-yellow-100 text-yellow-800': payment.status === 'pending',
                    'bg-green-100 text-green-800': payment.status === 'completed',
                    'bg-red-100 text-red-800': payment.status === 'failed',
                    'bg-gray-100 text-gray-800': payment.status === 'cancelled',
                  }"
                >
                  {{ getStatusLabel(payment.status) }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-if="showPaymentModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50" @click="closeModal">
      <div class="relative top-20 mx-auto p-5 border w-full max-w-md shadow-lg rounded-md bg-white" @click.stop>
        <div class="mt-3">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">
            Paiement - {{ selectedPlan?.name }}
          </h3>

          <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
            <div class="text-sm text-blue-900">
              <div class="font-semibold mb-2">Récapitulatif</div>
              <div class="flex justify-between mb-1">
                <span>Plan:</span>
                <span class="font-semibold">{{ selectedPlan?.name }}</span>
              </div>
              <div class="flex justify-between mb-1">
                <span>Durée:</span>
                <span class="font-semibold">{{ selectedPlan?.duration_days }} jours</span>
              </div>
              <div class="flex justify-between text-lg font-bold mt-3 pt-3 border-t border-blue-300">
                <span>Total:</span>
                <span>{{ formatAmount(getSelectedPlanPrice()) }} FCFA</span>
              </div>
            </div>
          </div>

          <form @submit.prevent="handlePayment" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Méthode de paiement *</label>
              <select
                v-model="paymentForm.paymentMethod"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Sélectionnez une méthode</option>
                <option value="DEXCHANGE">Dexchange</option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Nom *</label>
              <input
                v-model="paymentForm.name"
                type="text"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="Votre nom"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Prénom *</label>
              <input
                v-model="paymentForm.surname"
                type="text"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="Votre prénom"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Email *</label>
              <input
                v-model="paymentForm.email"
                type="email"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="votre@email.com"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Téléphone *</label>
              <input
                v-model="paymentForm.phone"
                type="tel"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="+225 XX XX XX XX XX"
              />
              <p class="text-xs text-gray-500 mt-1">Format: +225XXXXXXXXXX</p>
            </div>

            <div v-if="error" class="bg-red-50 text-red-600 px-4 py-2 rounded-lg text-sm">
              {{ error }}
            </div>

            <div class="flex justify-end gap-3 mt-6">
              <button
                type="button"
                @click="closeModal"
                :disabled="processing"
                class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 disabled:opacity-50"
              >
                Annuler
              </button>
              <button
                type="submit"
                :disabled="processing"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 font-semibold"
              >
                {{ processing ? 'Traitement...' : 'Procéder au paiement' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { cinetPayService, type Payment } from '../services/cinetpay.service';
import { subscriptionService, type SubscriptionInfo, type SubscriptionPlan } from '../services/subscription.service';
import { companyService } from '../services/company.service';

interface PaymentWithPlan extends Payment {
  plan?: {
    name: string;
    duration_days: number;
    price: number;
  };
}

const plans = ref<SubscriptionPlan[]>([]);
const paymentHistory = ref<PaymentWithPlan[]>([]);
const subscriptionInfo = ref<SubscriptionInfo | null>(null);
const loading = ref(true);
const showPaymentModal = ref(false);
const selectedPlan = ref<SubscriptionPlan | null>(null);
const processing = ref(false);
const error = ref('');
const companyId = ref('');
const billingCycle = ref<'monthly' | 'annual'>('monthly');

const paymentForm = ref({
  paymentMethod: '',
  name: '',
  surname: '',
  email: '',
  phone: '',
});

const plansByType = computed(() => {
  const grouped: Record<string, SubscriptionPlan[]> = {};
  plans.value.forEach(plan => {
    if (!grouped[plan.plan_type]) {
      grouped[plan.plan_type] = [];
    }
    grouped[plan.plan_type].push(plan);
  });
  return grouped;
});

const getPlanTypeLabel = (type: string) => {
  const labels: Record<string, string> = {
    basic: 'Basic',
    professional: 'Professional',
    premium: 'Premium',
    enterprise: 'Enterprise',
  };
  return labels[type] || type;
};

const getCurrentPlan = (plansOfType: SubscriptionPlan[]) => {
  return plansOfType.find(p => p.billing_period === billingCycle.value) || plansOfType[0];
};

const getCurrentPrice = (plansOfType: SubscriptionPlan[]) => {
  const plan = getCurrentPlan(plansOfType);
  if (!plan) return 0;
  return billingCycle.value === 'monthly' ? plan.monthly_price : plan.annual_price;
};

const getAnnualDiscount = (plansOfType: SubscriptionPlan[]) => {
  const plan = getCurrentPlan(plansOfType);
  return plan?.annual_discount_percent || 0;
};

const getSelectedPlanPrice = () => {
  if (!selectedPlan.value) return 0;
  return selectedPlan.value.billing_period === 'monthly'
    ? selectedPlan.value.monthly_price
    : selectedPlan.value.annual_price;
};

const loadData = async () => {
  try {
    loading.value = true;
    const [plansData, currentCompanyId] = await Promise.all([
      subscriptionService.getAllSubscriptionPlans(),
      companyService.getCurrentCompanyId(),
    ]);

    plans.value = plansData;

    if (currentCompanyId) {
      companyId.value = currentCompanyId;
      const [history, subInfo] = await Promise.all([
        cinetPayService.getPaymentHistory(currentCompanyId),
        subscriptionService.getSubscriptionInfo(currentCompanyId),
      ]);
      paymentHistory.value = history;
      subscriptionInfo.value = subInfo;
    }
  } catch (err: any) {
    console.error('Error loading data:', err);
  } finally {
    loading.value = false;
  }
};

const formatAmount = (amount: number) => {
  return cinetPayService.formatAmount(amount);
};

const formatDate = (dateStr: string) => {
  const date = new Date(dateStr);
  return date.toLocaleDateString('fr-FR', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};

const getStatusLabel = (status: string) => {
  return cinetPayService.getStatusLabel(status);
};

const getPaymentMethodLabel = (method: string) => {
  return cinetPayService.getPaymentMethodLabel(method);
};

const selectPlan = (plan: SubscriptionPlan | null) => {
  if (!plan) return;
  selectedPlan.value = plan;
  error.value = '';
  showPaymentModal.value = true;
};

const closeModal = () => {
  showPaymentModal.value = false;
  selectedPlan.value = null;
  error.value = '';
  paymentForm.value = {
    paymentMethod: '',
    name: '',
    surname: '',
    email: '',
    phone: '',
  };
};

const handlePayment = async () => {
  if (!selectedPlan.value || !companyId.value) return;

  error.value = '';
  processing.value = true;

  try {
    const result = await cinetPayService.initiatePayment(
      selectedPlan.value.id,
      companyId.value,
      paymentForm.value.paymentMethod,
      {
        name: paymentForm.value.name,
        surname: paymentForm.value.surname,
        email: paymentForm.value.email,
        phone: paymentForm.value.phone,
      }
    );

    window.location.href = result.paymentUrl;
  } catch (err: any) {
    console.error('Payment error:', err);
    error.value = err.message || 'Erreur lors du paiement';
    processing.value = false;
  }
};

onMounted(() => {
  loadData();
});
</script>
