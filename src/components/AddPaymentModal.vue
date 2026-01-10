<script setup lang="ts">
import { ref, computed } from 'vue';
import { orderPaymentsService } from '../services/order-payments.service';
import { authService } from '../services/auth';
import type { Order } from '../services/orders.service';
import Icon from './Icon.vue';

const props = defineProps<{
  order: Order;
}>();

const emit = defineEmits(['close', 'success']);

const formData = ref({
  amount: 0,
  payment_method: 'especes' as 'especes' | 'mobile_money' | 'virement' | 'cheque' | 'carte_bancaire',
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

const setMaxAmount = () => {
  formData.value.amount = remainingAmount.value;
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
        <button @click="emit('close')" class="text-gray-400 hover:text-gray-600 transition-colors">
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
            @click="emit('close')"
            class="btn-secondary flex-1 inline-flex items-center justify-center gap-2"
          >
            <Icon name="x" class="w-5 h-5" />
            <span>Annuler</span>
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
