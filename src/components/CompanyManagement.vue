<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { superAdminService, type CompanyWithStats } from '../services/super-admin.service';

const companies = ref<CompanyWithStats[]>([]);
const isLoading = ref(true);
const error = ref('');
const searchQuery = ref('');
const filterStatus = ref<'all' | 'approved' | 'pending'>('all');

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
    filtered = filtered.filter(c => c.approved);
  } else if (filterStatus.value === 'pending') {
    filtered = filtered.filter(c => !c.approved);
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

onMounted(() => {
  loadCompanies();
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
                  v-if="company.approved"
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
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ formatDate(company.created_at) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <div class="flex items-center gap-3">
                  <button
                    v-if="!company.approved"
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
  </div>
</template>
