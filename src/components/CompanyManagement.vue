<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { superAdminService, type CompanyWithStats, type SubscriptionPlan } from '../services/super-admin.service';

const companies = ref<CompanyWithStats[]>([]);
const subscriptionPlans = ref<SubscriptionPlan[]>([]);
const isLoading = ref(true);
const error = ref('');
const searchQuery = ref('');
const filterStatus = ref<'all' | 'approved' | 'pending'>('all');
const showSubscriptionModal = ref(false);
const selectedCompany = ref<CompanyWithStats | null>(null);
const selectedPlanId = ref('');

const loadCompanies = async () => {
  isLoading.value = true;
  error.value = '';
  try {
    companies.value = await superAdminService.getAllCompanies();
  } catch (e: any) {
    error.value = e.message || 'Erreur lors du chargement des entreprises';
    console.error('Error loading companies:', e);
  } finally {
    isLoading.value = false;
  }
};

const loadSubscriptionPlans = async () => {
  try {
    subscriptionPlans.value = await superAdminService.getSubscriptionPlans();
  } catch (e: any) {
    console.error('Error loading subscription plans:', e);
  }
};

const approveCompany = async (companyId: string) => {
  if (!confirm('Voulez-vous approuver cette entreprise ?')) return;

  try {
    await superAdminService.approveCompany(companyId);
    await loadCompanies();
  } catch (e: any) {
    alert('Erreur: ' + (e.message || 'Impossible d\'approuver l\'entreprise'));
  }
};

const revokeApproval = async (companyId: string) => {
  if (!confirm('Voulez-vous révoquer l\'approbation de cette entreprise ? Les utilisateurs ne pourront plus se connecter.')) return;

  try {
    await superAdminService.revokeCompanyApproval(companyId);
    await loadCompanies();
  } catch (e: any) {
    alert('Erreur: ' + (e.message || 'Impossible de révoquer l\'approbation'));
  }
};

const deleteCompany = async (companyId: string, companyName: string) => {
  if (!confirm(`⚠️ ATTENTION : Êtes-vous sûr de vouloir supprimer l'entreprise "${companyName}" ?\n\nCette action est IRRÉVERSIBLE et supprimera :\n- Tous les utilisateurs de l'entreprise\n- Tous les produits\n- Toutes les commandes\n- Tous les clients\n- Toutes les données liées\n\nTapez OUI pour confirmer la suppression.`)) return;

  const confirmation = prompt(`Pour confirmer, tapez le nom de l'entreprise : "${companyName}"`);
  if (confirmation !== companyName) {
    alert('Le nom ne correspond pas. Suppression annulée.');
    return;
  }

  try {
    await superAdminService.deleteCompany(companyId);
    alert(`L'entreprise "${companyName}" a été supprimée avec succès.`);
    await loadCompanies();
  } catch (e: any) {
    alert('Erreur: ' + (e.message || 'Impossible de supprimer l\'entreprise'));
  }
};

const filteredCompanies = () => {
  let filtered = companies.value;

  if (filterStatus.value === 'approved') {
    filtered = filtered.filter(c => c.is_approved);
  } else if (filterStatus.value === 'pending') {
    filtered = filtered.filter(c => !c.is_approved);
  }

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    filtered = filtered.filter(c =>
      c.name.toLowerCase().includes(query) ||
      c.email?.toLowerCase().includes(query) ||
      c.phone?.includes(query)
    );
  }

  return filtered;
};

const formatDate = (dateStr: string) => {
  return new Date(dateStr).toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

const openSubscriptionModal = (company: CompanyWithStats) => {
  selectedCompany.value = company;
  selectedPlanId.value = '';
  showSubscriptionModal.value = true;
};

const closeSubscriptionModal = () => {
  showSubscriptionModal.value = false;
  selectedCompany.value = null;
  selectedPlanId.value = '';
};

const assignSubscription = async () => {
  if (!selectedCompany.value || !selectedPlanId.value) {
    alert('Veuillez sélectionner un plan d\'abonnement');
    return;
  }

  try {
    await superAdminService.assignSubscription(selectedCompany.value.id, selectedPlanId.value);
    alert('Abonnement attribué avec succès');
    closeSubscriptionModal();
    await loadCompanies();
  } catch (e: any) {
    alert('Erreur: ' + (e.message || 'Impossible d\'attribuer l\'abonnement'));
  }
};

const formatPrice = (price: number) => {
  return new Intl.NumberFormat('fr-FR').format(price) + ' FCFA';
};

const getSubscriptionStatusLabel = (status?: string) => {
  const labels: Record<string, string> = {
    trial: 'Essai',
    active: 'Actif',
    expired: 'Expiré',
    suspended: 'Suspendu'
  };
  return labels[status || ''] || 'Non défini';
};

const getSubscriptionStatusColor = (status?: string) => {
  const colors: Record<string, string> = {
    trial: 'bg-blue-100 text-blue-800',
    active: 'bg-green-100 text-green-800',
    expired: 'bg-red-100 text-red-800',
    suspended: 'bg-gray-100 text-gray-800'
  };
  return colors[status || ''] || 'bg-gray-100 text-gray-800';
};

onMounted(() => {
  loadCompanies();
  loadSubscriptionPlans();
});
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">Gestion des Entreprises</h2>
        <p class="text-gray-600 mt-1">Gérez les entreprises inscrites et leur accès</p>
      </div>
    </div>

    <div v-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
      {{ error }}
    </div>

    <div class="bg-white rounded-xl shadow-md p-6">
      <div class="flex flex-col sm:flex-row gap-4 mb-6">
        <div class="flex-1">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Rechercher une entreprise..."
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
          />
        </div>
        <div>
          <select
            v-model="filterStatus"
            class="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
          >
            <option value="all">Toutes</option>
            <option value="approved">Approuvées</option>
            <option value="pending">En attente</option>
          </select>
        </div>
      </div>

      <div v-if="isLoading" class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>

      <div v-else-if="filteredCompanies().length === 0" class="text-center py-12 text-gray-500">
        <p class="text-lg">Aucune entreprise trouvée</p>
      </div>

      <div v-else class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Entreprise
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Contact
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Utilisateurs
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Statut
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Abonnement
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Date d'inscription
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="company in filteredCompanies()" :key="company.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <div v-if="company.logo_url" class="flex-shrink-0 h-10 w-10">
                    <img :src="company.logo_url" :alt="company.name" class="h-10 w-10 rounded-full object-cover" />
                  </div>
                  <div v-else class="flex-shrink-0 h-10 w-10 bg-primary rounded-full flex items-center justify-center">
                    <span class="text-white font-bold text-sm">{{ company.name.charAt(0).toUpperCase() }}</span>
                  </div>
                  <div class="ml-4">
                    <div class="text-sm font-medium text-gray-900">{{ company.name }}</div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm text-gray-900">{{ company.email || '-' }}</div>
                <div class="text-sm text-gray-500">{{ company.phone || '-' }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {{ company.user_count }} utilisateur{{ company.user_count > 1 ? 's' : '' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  v-if="company.is_approved"
                  class="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800"
                >
                  Approuvée
                </span>
                <span
                  v-else
                  class="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800"
                >
                  En attente
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  :class="getSubscriptionStatusColor(company.subscription_status)"
                  class="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full"
                >
                  {{ getSubscriptionStatusLabel(company.subscription_status) }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ formatDate(company.created_at) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <div class="flex items-center gap-3">
                  <button
                    v-if="!company.is_approved"
                    @click="approveCompany(company.id)"
                    class="text-green-600 hover:text-green-900"
                  >
                    Approuver
                  </button>
                  <button
                    v-else
                    @click="revokeApproval(company.id)"
                    class="text-orange-600 hover:text-orange-900"
                  >
                    Révoquer
                  </button>
                  <button
                    @click="openSubscriptionModal(company)"
                    class="text-blue-600 hover:text-blue-900"
                    title="Attribuer un abonnement"
                  >
                    Abonnement
                  </button>
                  <button
                    @click="deleteCompany(company.id, company.name)"
                    class="text-red-600 hover:text-red-900 font-semibold"
                    title="Supprimer l'entreprise"
                  >
                    Supprimer
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
      <h3 class="text-sm font-semibold text-blue-800 mb-2">Information</h3>
      <ul class="text-sm text-blue-700 space-y-1">
        <li>• Les entreprises en attente ne peuvent pas se connecter à l'application</li>
        <li>• Approuver une entreprise permet à tous ses utilisateurs de se connecter</li>
        <li>• Révoquer une entreprise bloque immédiatement l'accès pour tous ses utilisateurs</li>
      </ul>
    </div>

    <div class="bg-red-50 border border-red-200 rounded-lg p-4">
      <h3 class="text-sm font-semibold text-red-800 mb-2">⚠️ Suppression d'entreprise</h3>
      <ul class="text-sm text-red-700 space-y-1">
        <li>• La suppression est IRRÉVERSIBLE et supprime toutes les données de l'entreprise</li>
        <li>• Tous les utilisateurs, produits, commandes et clients seront définitivement supprimés</li>
        <li>• Une double confirmation est requise pour éviter les suppressions accidentelles</li>
      </ul>
    </div>

    <div v-if="showSubscriptionModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50" @click="closeSubscriptionModal">
      <div class="relative top-20 mx-auto p-5 border w-full max-w-2xl shadow-lg rounded-md bg-white" @click.stop>
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-2xl font-bold text-gray-900">
            Attribuer un abonnement
          </h3>
          <button @click="closeSubscriptionModal" class="text-gray-400 hover:text-gray-600">
            <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div v-if="selectedCompany" class="mb-6">
          <div class="bg-gray-50 p-4 rounded-lg">
            <div class="flex items-center gap-4">
              <div v-if="selectedCompany.logo_url" class="flex-shrink-0 h-16 w-16">
                <img :src="selectedCompany.logo_url" :alt="selectedCompany.name" class="h-16 w-16 rounded-full object-cover" />
              </div>
              <div v-else class="flex-shrink-0 h-16 w-16 bg-primary rounded-full flex items-center justify-center">
                <span class="text-white font-bold text-2xl">{{ selectedCompany.name.charAt(0).toUpperCase() }}</span>
              </div>
              <div>
                <h4 class="text-lg font-semibold text-gray-900">{{ selectedCompany.name }}</h4>
                <p class="text-sm text-gray-500">{{ selectedCompany.email }}</p>
                <p class="text-xs text-gray-400 mt-1">
                  Abonnement actuel:
                  <span :class="getSubscriptionStatusColor(selectedCompany.subscription_status)" class="px-2 py-0.5 rounded-full">
                    {{ getSubscriptionStatusLabel(selectedCompany.subscription_status) }}
                  </span>
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="mb-6">
          <label class="block text-sm font-medium text-gray-700 mb-3">
            Sélectionnez un plan d'abonnement
          </label>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div
              v-for="plan in subscriptionPlans"
              :key="plan.id"
              @click="selectedPlanId = plan.id"
              :class="[
                'border-2 rounded-lg p-4 cursor-pointer transition-all',
                selectedPlanId === plan.id
                  ? 'border-primary bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              ]"
            >
              <div class="flex items-start justify-between">
                <div class="flex-1">
                  <h5 class="font-semibold text-gray-900">{{ plan.name }}</h5>
                  <p class="text-xs text-gray-500 mt-1">{{ plan.plan_type }} - {{ plan.billing_period === 'monthly' ? 'Mensuel' : 'Annuel' }}</p>
                </div>
                <div
                  :class="[
                    'w-5 h-5 rounded-full border-2 flex items-center justify-center',
                    selectedPlanId === plan.id
                      ? 'border-primary bg-primary'
                      : 'border-gray-300'
                  ]"
                >
                  <svg v-if="selectedPlanId === plan.id" class="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                  </svg>
                </div>
              </div>
              <div class="mt-3">
                <p class="text-2xl font-bold text-primary">
                  {{ formatPrice(plan.billing_period === 'monthly' ? plan.monthly_price : plan.annual_price) }}
                </p>
                <p class="text-xs text-gray-500">{{ plan.duration_days }} jours</p>
              </div>
            </div>
          </div>
        </div>

        <div class="flex gap-3 justify-end">
          <button
            @click="closeSubscriptionModal"
            class="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
          >
            Annuler
          </button>
          <button
            @click="assignSubscription"
            :disabled="!selectedPlanId"
            :class="[
              'px-6 py-2 rounded-lg text-white transition-colors',
              selectedPlanId
                ? 'bg-primary hover:bg-blue-700'
                : 'bg-gray-300 cursor-not-allowed'
            ]"
          >
            Attribuer l'abonnement
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
