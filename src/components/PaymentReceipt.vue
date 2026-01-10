<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { orderPaymentsService } from '../services/order-payments.service';
import { supabase } from '../services/supabase';
import Icon from './Icon.vue';

const props = defineProps<{
  paymentId: string;
}>();

const emit = defineEmits(['close']);

const payment = ref<any>(null);
const companySettings = ref<any>(null);
const loading = ref(true);

const remainingAmount = computed(() => {
  if (!payment.value?.order) return 0;
  const total = Number(payment.value.order.total_amount);
  const paid = Number(payment.value.order.total_paid);
  return total - paid;
});

onMounted(async () => {
  await loadPaymentData();
});

const loadPaymentData = async () => {
  try {
    loading.value = true;
    payment.value = await orderPaymentsService.getPaymentById(props.paymentId);

    if (payment.value?.company_id) {
      const { data: company } = await supabase
        .from('companies')
        .select('*')
        .eq('id', payment.value.company_id)
        .maybeSingle();

      companySettings.value = company;
    }
  } catch (error) {
    console.error('Error loading payment:', error);
    alert('Erreur lors du chargement du paiement');
  } finally {
    loading.value = false;
  }
};

const printReceipt = () => {
  window.print();
};

const sendToWhatsApp = () => {
  if (!payment.value?.client?.phone) {
    alert('Aucun numéro de téléphone disponible pour ce client');
    return;
  }

  const clientName = payment.value.client.entity_type === 'entreprise'
    ? payment.value.client.company_name
    : payment.value.client.name;

  const message = `
🧾 *REÇU DE PAIEMENT*

📋 Reçu N°: ${payment.value.receipt_number}
📅 Date: ${new Date(payment.value.payment_date).toLocaleDateString('fr-FR')}

👤 Client: ${clientName}
📝 Commande N°: ${payment.value.order?.order_number}

💰 *DÉTAILS DU PAIEMENT*
Montant payé: ${Number(payment.value.amount).toLocaleString('fr-FR')} FCFA
Mode de paiement: ${orderPaymentsService.getPaymentMethodLabel(payment.value.payment_method)}
${payment.value.payment_reference ? `Référence: ${payment.value.payment_reference}` : ''}

📊 *RÉSUMÉ COMMANDE*
Montant total: ${Number(payment.value.order?.total_amount).toLocaleString('fr-FR')} FCFA
Total payé: ${Number(payment.value.order?.total_paid).toLocaleString('fr-FR')} FCFA
Reste à payer: ${remainingAmount.value.toLocaleString('fr-FR')} FCFA

---
${companySettings.value?.name || 'Votre entreprise'}
${companySettings.value?.phone || ''}
`.trim();

  const cleanPhone = payment.value.client.phone.replace(/\s+/g, '');
  const url = `https://wa.me/${cleanPhone}?text=${encodeURIComponent(message)}`;
  window.open(url, '_blank');
};

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('fr-FR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

const getClientDisplayName = () => {
  if (!payment.value?.client) return '';
  return payment.value.client.entity_type === 'entreprise'
    ? payment.value.client.company_name
    : payment.value.client.name;
};
</script>

<template>
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto">
      <div class="print:hidden sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex justify-between items-center">
        <h2 class="text-xl font-bold text-gray-800">Reçu de paiement</h2>
        <div class="flex gap-2">
          <button
            @click="printReceipt"
            class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 inline-flex items-center gap-2"
          >
            <Icon name="printer" class="w-5 h-5" />
            <span>Imprimer</span>
          </button>
          <button
            v-if="payment?.client?.phone"
            @click="sendToWhatsApp"
            class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 inline-flex items-center gap-2"
          >
            <Icon name="phone" class="w-5 h-5" />
            <span>WhatsApp</span>
          </button>
          <button
            @click="emit('close')"
            class="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <Icon name="x" class="w-6 h-6" />
          </button>
        </div>
      </div>

      <div v-if="loading" class="p-8 text-center">
        <p class="text-gray-600">Chargement...</p>
      </div>

      <div v-else-if="payment" class="p-8 print:p-0">
        <div class="max-w-3xl mx-auto bg-white print:shadow-none shadow-lg rounded-lg p-8">
          <div class="text-center mb-8 border-b-2 border-gray-800 pb-6">
            <h1 class="text-3xl font-bold text-gray-800 mb-2">REÇU DE PAIEMENT</h1>
            <p class="text-lg font-bold text-gray-800">{{ companySettings?.name || 'Votre entreprise' }}</p>
            <p v-if="companySettings?.address" class="text-sm text-gray-600">{{ companySettings.address }}</p>
            <p v-if="companySettings?.phone" class="text-sm text-gray-600">Tél: {{ companySettings.phone }}</p>
            <p v-if="companySettings?.email" class="text-sm text-gray-600">Email: {{ companySettings.email }}</p>
          </div>

          <div class="grid grid-cols-2 gap-6 mb-8">
            <div>
              <h3 class="text-sm font-semibold text-gray-500 uppercase mb-2">Informations du reçu</h3>
              <p class="text-lg"><span class="font-semibold">N° Reçu:</span> {{ payment.receipt_number }}</p>
              <p><span class="font-semibold">Date:</span> {{ formatDate(payment.payment_date) }}</p>
              <p><span class="font-semibold">Commande:</span> {{ payment.order?.order_number }}</p>
            </div>
            <div>
              <h3 class="text-sm font-semibold text-gray-500 uppercase mb-2">Client</h3>
              <p class="text-lg font-semibold">{{ getClientDisplayName() }}</p>
              <p v-if="payment.client?.entity_type === 'entreprise' && payment.client?.contact_person" class="text-sm text-gray-600">
                Contact: {{ payment.client.contact_person }}
              </p>
              <p v-if="payment.client?.phone">Tél: {{ payment.client.phone }}</p>
              <p v-if="payment.client?.email" class="text-sm">{{ payment.client.email }}</p>
              <p v-if="payment.client?.address" class="text-sm text-gray-600">{{ payment.client.address }}</p>
            </div>
          </div>

          <div class="bg-gray-50 rounded-lg p-6 mb-8">
            <h3 class="text-lg font-semibold text-gray-800 mb-4">Détails du paiement</h3>
            <div class="space-y-2">
              <div class="flex justify-between">
                <span class="text-gray-600">Montant payé:</span>
                <span class="text-xl font-bold text-green-600">{{ Number(payment.amount).toLocaleString('fr-FR') }} FCFA</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600">Mode de paiement:</span>
                <span class="font-semibold">{{ orderPaymentsService.getPaymentMethodLabel(payment.payment_method) }}</span>
              </div>
              <div v-if="payment.payment_reference" class="flex justify-between">
                <span class="text-gray-600">Référence:</span>
                <span class="font-mono">{{ payment.payment_reference }}</span>
              </div>
            </div>
          </div>

          <div class="bg-blue-50 border-2 border-blue-200 rounded-lg p-6 mb-8">
            <h3 class="text-lg font-semibold text-gray-800 mb-4">Résumé de la commande</h3>
            <div class="space-y-3">
              <div class="flex justify-between text-lg">
                <span class="text-gray-700">Montant total de la commande:</span>
                <span class="font-bold">{{ Number(payment.order?.total_amount).toLocaleString('fr-FR') }} FCFA</span>
              </div>
              <div class="flex justify-between text-lg">
                <span class="text-gray-700">Total payé à ce jour:</span>
                <span class="font-bold text-green-600">{{ Number(payment.order?.total_paid).toLocaleString('fr-FR') }} FCFA</span>
              </div>
              <div class="border-t-2 border-blue-300 pt-3"></div>
              <div class="flex justify-between text-xl">
                <span class="font-semibold text-gray-800">Reste à payer:</span>
                <span :class="[
                  'font-bold',
                  remainingAmount > 0 ? 'text-red-600' : 'text-green-600'
                ]">
                  {{ remainingAmount.toLocaleString('fr-FR') }} FCFA
                </span>
              </div>
            </div>
          </div>

          <div v-if="payment.notes" class="mb-8">
            <h3 class="text-sm font-semibold text-gray-500 uppercase mb-2">Notes</h3>
            <p class="text-gray-700">{{ payment.notes }}</p>
          </div>

          <div class="border-t-2 border-gray-200 pt-6 text-center">
            <p class="text-sm text-gray-600 mb-2">Merci pour votre confiance!</p>
            <p class="text-xs text-gray-500">
              Ce reçu a été généré le {{ new Date().toLocaleDateString('fr-FR') }} à {{ new Date().toLocaleTimeString('fr-FR') }}
            </p>
            <p v-if="payment.creator" class="text-xs text-gray-500 mt-1">
              Émis par: {{ payment.creator.full_name }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@media print {
  .fixed {
    position: relative;
  }

  .bg-black {
    background: white;
  }

  .rounded-lg {
    border-radius: 0;
  }

  .shadow-lg {
    box-shadow: none;
  }

  .max-h-\[90vh\] {
    max-height: none;
  }

  button {
    display: none !important;
  }
}
</style>
