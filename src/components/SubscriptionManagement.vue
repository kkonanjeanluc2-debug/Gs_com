<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-2xl font-bold text-gray-900 mb-2">Gestion des abonnements</h2>
      <p class="text-gray-600">Gérez les périodes d'essai et les abonnements des entreprises</p>
    </div>

    <div v-if="loading" class="flex justify-center py-8">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else class="bg-white rounded-lg shadow-sm border border-gray-200">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Entreprise</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Statut</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Période d'essai</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Abonnement</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="company in companies" :key="company.id">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-medium text-gray-900">{{ company.name }}</div>
                <div v-if="!company.is_approved" class="text-xs text-orange-600">En attente d'approbation</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                  :class="{
                    'bg-blue-100 text-blue-800': company.subscription_status === 'trial',
                    'bg-green-100 text-green-800': company.subscription_status === 'active',
                    'bg-red-100 text-red-800': company.subscription_status === 'expired',
                    'bg-gray-100 text-gray-800': company.subscription_status === 'suspended',
                  }"
                >
                  {{ getStatusLabel(company.subscription_status) }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                <div v-if="company.trial_end_date">
                  {{ company.trial_days }} jours
                  <div class="text-xs text-gray-500">
                    Expire le {{ formatDate(company.trial_end_date) }}
                  </div>
                  <div v-if="isExpired(company.trial_end_date)" class="text-xs text-red-600 font-medium">
                    Expiré
                  </div>
                </div>
                <div v-else class="text-gray-400">Non défini</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                <div v-if="company.subscription_end_date">
                  Expire le {{ formatDate(company.subscription_end_date) }}
                  <div v-if="isExpired(company.subscription_end_date)" class="text-xs text-red-600 font-medium">
                    Expiré
                  </div>
                </div>
                <div v-else class="text-gray-400">Non défini</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <button
                  @click="openModal(company, 'trial')"
                  class="text-blue-600 hover:text-blue-900 mr-3"
                  title="Accorder période d'essai"
                >
                  Essai
                </button>
                <button
                  @click="openModal(company, 'activate')"
                  class="text-green-600 hover:text-green-900 mr-3"
                  title="Activer abonnement"
                >
                  Activer
                </button>
                <button
                  v-if="company.subscription_status !== 'suspended'"
                  @click="openModal(company, 'suspend')"
                  class="text-orange-600 hover:text-orange-900 mr-3"
                  title="Suspendre"
                >
                  Suspendre
                </button>
                <button
                  v-if="company.subscription_status === 'suspended'"
                  @click="handleReactivate(company.id)"
                  class="text-green-600 hover:text-green-900"
                  title="Réactiver"
                >
                  Réactiver
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-if="showModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50" @click="closeModal">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white" @click.stop>
        <div class="mt-3">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">
            {{ getModalTitle() }}
          </h3>

          <form @submit.prevent="handleSubmit">
            <div v-if="modalAction === 'trial'" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Nombre de jours d'essai *</label>
                <input
                  v-model.number="modalForm.days"
                  type="number"
                  min="1"
                  max="365"
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  placeholder="Ex: 7, 14, 30"
                />
                <p class="text-xs text-gray-500 mt-1">Durée de la période d'essai gratuite</p>
              </div>
            </div>

            <div v-if="modalAction === 'activate'" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Durée de l'abonnement (jours) *</label>
                <input
                  v-model.number="modalForm.days"
                  type="number"
                  min="1"
                  max="3650"
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  placeholder="Ex: 30, 90, 365"
                />
                <p class="text-xs text-gray-500 mt-1">
                  Raccourcis: 30 jours (1 mois), 90 jours (3 mois), 365 jours (1 an)
                </p>
              </div>
            </div>

            <div v-if="modalAction === 'suspend'" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Raison de la suspension *</label>
                <textarea
                  v-model="modalForm.reason"
                  required
                  rows="3"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  placeholder="Expliquez la raison de la suspension..."
                ></textarea>
              </div>
            </div>

            <div v-if="error" class="mt-4 bg-red-50 text-red-600 px-4 py-2 rounded-lg text-sm">
              {{ error }}
            </div>

            <div v-if="success" class="mt-4 bg-green-50 text-green-600 px-4 py-2 rounded-lg text-sm">
              {{ success }}
            </div>

            <div class="flex justify-end gap-3 mt-6">
              <button
                type="button"
                @click="closeModal"
                class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
              >
                Annuler
              </button>
              <button
                type="submit"
                :disabled="submitting"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
              >
                {{ submitting ? 'Traitement...' : 'Confirmer' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { subscriptionService } from '../services/subscription.service';

interface Company {
  id: string;
  name: string;
  trial_days: number;
  trial_end_date: string | null;
  subscription_status: 'trial' | 'active' | 'expired' | 'suspended';
  subscription_end_date: string | null;
  blocked_reason: string | null;
  is_approved: boolean;
}

const companies = ref<Company[]>([]);
const loading = ref(true);
const showModal = ref(false);
const modalAction = ref<'trial' | 'activate' | 'suspend'>('trial');
const selectedCompany = ref<Company | null>(null);
const submitting = ref(false);
const error = ref('');
const success = ref('');

const modalForm = ref({
  days: 7,
  reason: '',
});

const loadCompanies = async () => {
  try {
    loading.value = true;
    const data = await subscriptionService.getAllCompaniesSubscriptionStatus();
    companies.value = data;
  } catch (err: any) {
    console.error('Error loading companies:', err);
  } finally {
    loading.value = false;
  }
};

const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    trial: 'Essai',
    active: 'Actif',
    expired: 'Expiré',
    suspended: 'Suspendu',
  };
  return labels[status] || status;
};

const formatDate = (dateStr: string) => {
  const date = new Date(dateStr);
  return date.toLocaleDateString('fr-FR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
};

const isExpired = (dateStr: string) => {
  return new Date(dateStr) < new Date();
};

const openModal = (company: Company, action: 'trial' | 'activate' | 'suspend') => {
  selectedCompany.value = company;
  modalAction.value = action;
  modalForm.value.days = action === 'trial' ? 7 : 30;
  modalForm.value.reason = '';
  error.value = '';
  success.value = '';
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  selectedCompany.value = null;
  error.value = '';
  success.value = '';
};

const getModalTitle = () => {
  const titles = {
    trial: 'Accorder une période d\'essai',
    activate: 'Activer l\'abonnement',
    suspend: 'Suspendre l\'entreprise',
  };
  return titles[modalAction.value];
};

const handleSubmit = async () => {
  if (!selectedCompany.value) return;

  error.value = '';
  success.value = '';
  submitting.value = true;

  try {
    switch (modalAction.value) {
      case 'trial':
        await subscriptionService.grantTrial(selectedCompany.value.id, modalForm.value.days);
        success.value = 'Période d\'essai accordée avec succès';
        break;
      case 'activate':
        await subscriptionService.activateSubscription(selectedCompany.value.id, modalForm.value.days);
        success.value = 'Abonnement activé avec succès';
        break;
      case 'suspend':
        await subscriptionService.suspendCompany(selectedCompany.value.id, modalForm.value.reason);
        success.value = 'Entreprise suspendue avec succès';
        break;
    }

    setTimeout(() => {
      closeModal();
      loadCompanies();
    }, 1500);
  } catch (err: any) {
    console.error('Error:', err);
    error.value = err.message || 'Une erreur est survenue';
  } finally {
    submitting.value = false;
  }
};

const handleReactivate = async (companyId: string) => {
  if (!confirm('Êtes-vous sûr de vouloir réactiver cette entreprise ?')) {
    return;
  }

  try {
    await subscriptionService.reactivateCompany(companyId);
    await loadCompanies();
  } catch (err: any) {
    console.error('Error reactivating company:', err);
    alert('Erreur lors de la réactivation: ' + err.message);
  }
};

onMounted(() => {
  loadCompanies();
});
</script>
