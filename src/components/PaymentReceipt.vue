<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { orderPaymentsService } from '../services/order-payments.service';
import { supabase } from '../services/supabase';
import { pdfGeneratorService } from '../services/pdf-generator.service';
import Icon from './Icon.vue';

const props = defineProps<{
  paymentId: string;
}>();

const emit = defineEmits(['close']);

const payment = ref<any>(null);
const companySettings = ref<any>(null);
const loading = ref(true);
const generatingPDF = ref(false);

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

const sendToWhatsApp = async () => {
  if (!payment.value?.client?.phone) {
    alert('Aucun numéro de téléphone disponible pour ce client');
    return;
  }

  try {
    generatingPDF.value = true;

    const filename = `Recu_${payment.value.receipt_number}.pdf`;
    const blob = await pdfGeneratorService.generatePDF('receipt-content');

    pdfGeneratorService.downloadPDF(blob, filename);

    await new Promise(resolve => setTimeout(resolve, 500));

    const clientName = payment.value.client.entity_type === 'entreprise'
      ? payment.value.client.company_name
      : payment.value.client.name;

    const message = `Bonjour ${clientName},\n\nVoici le reçu de paiement N°${payment.value.receipt_number}.\n\nMerci de votre confiance!\n\n${companySettings.value?.name || 'Votre entreprise'}`;

    const cleanPhone = payment.value.client.phone.replace(/\s+/g, '');
    const url = `https://wa.me/${cleanPhone}?text=${encodeURIComponent(message)}`;
    window.open(url, '_blank');

  } catch (error) {
    console.error('Error generating PDF:', error);
    alert('Erreur lors de la génération du PDF');
  } finally {
    generatingPDF.value = false;
  }
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
            :disabled="generatingPDF"
            class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 inline-flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Icon name="phone" class="w-5 h-5" />
            <span>{{ generatingPDF ? 'Génération...' : 'Envoyer PDF WhatsApp' }}</span>
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
        <div id="receipt-content" class="max-w-3xl mx-auto bg-white print:shadow-none shadow-lg rounded-lg p-8">
          <div class="text-center mb-6 border-b-2 border-gray-800 pb-4">
            <h1 class="text-2xl font-bold text-gray-800 mb-2">REÇU DE PAIEMENT</h1>
            <p class="text-lg font-bold text-gray-800">{{ companySettings?.name || 'Votre entreprise' }}</p>
            <p v-if="companySettings?.phone" class="text-sm text-gray-600">Tél: {{ companySettings.phone }}</p>
            <p v-if="companySettings?.email" class="text-sm text-gray-600">{{ companySettings.email }}</p>
          </div>

          <div class="grid grid-cols-2 gap-4 mb-6">
            <div>
              <p class="text-sm text-gray-600 mb-1">N° Reçu</p>
              <p class="text-lg font-bold">{{ payment.receipt_number }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-600 mb-1">Date</p>
              <p class="font-semibold">{{ new Date(payment.payment_date).toLocaleDateString('fr-FR') }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-600 mb-1">Client</p>
              <p class="font-semibold">{{ getClientDisplayName() }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-600 mb-1">Commande N°</p>
              <p class="font-semibold">{{ payment.order?.order_number }}</p>
            </div>
          </div>

          <div class="bg-green-50 border border-green-200 rounded-lg p-4 mb-4">
            <div class="flex justify-between items-center mb-2">
              <span class="text-gray-700 font-semibold">Montant payé</span>
              <span class="text-2xl font-bold text-green-600">{{ Number(payment.amount).toLocaleString('fr-FR') }} FCFA</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-600">Mode de paiement:</span>
              <span class="font-semibold">{{ orderPaymentsService.getPaymentMethodLabel(payment.payment_method) }}</span>
            </div>
            <div v-if="payment.payment_reference" class="flex justify-between text-sm mt-1">
              <span class="text-gray-600">Référence:</span>
              <span class="font-mono text-xs">{{ payment.payment_reference }}</span>
            </div>
          </div>

          <div class="border-t-2 border-gray-300 pt-4 space-y-2">
            <div class="flex justify-between">
              <span class="text-gray-700">Total commande:</span>
              <span class="font-bold">{{ Number(payment.order?.total_amount).toLocaleString('fr-FR') }} FCFA</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-700">Total payé:</span>
              <span class="font-bold text-green-600">{{ Number(payment.order?.total_paid).toLocaleString('fr-FR') }} FCFA</span>
            </div>
            <div class="flex justify-between text-lg border-t pt-2">
              <span class="font-bold text-gray-800">Reste à payer:</span>
              <span :class="[
                'font-bold',
                remainingAmount > 0 ? 'text-red-600' : 'text-green-600'
              ]">
                {{ remainingAmount.toLocaleString('fr-FR') }} FCFA
              </span>
            </div>
          </div>

          <div class="border-t border-gray-200 mt-6 pt-4 text-center">
            <p class="text-sm text-gray-600">Merci pour votre confiance!</p>
            <p class="text-xs text-gray-500 mt-2">
              Généré le {{ new Date().toLocaleDateString('fr-FR') }}
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
