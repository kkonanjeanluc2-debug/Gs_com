<template>
  <div class="commercial-visit-history">
    <div class="header-section">
      <h2 class="text-2xl font-bold text-gray-800 mb-4">Historique des Visites et Statistiques</h2>

      <div class="filters-section bg-white p-4 rounded-lg shadow-sm mb-6">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div v-if="canViewAllCommercials">
            <label class="block text-sm font-medium text-gray-700 mb-2">Commercial</label>
            <select
              v-model="selectedCommercialId"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              @change="loadData"
            >
              <option :value="currentUserId">Moi</option>
              <option
                v-for="commercial in commercials"
                :key="commercial.id"
                :value="commercial.id"
              >
                {{ commercial.full_name }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Date début</label>
            <input
              type="date"
              v-model="startDate"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              @change="loadData"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Date fin</label>
            <input
              type="date"
              v-model="endDate"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              @change="loadData"
            />
          </div>

          <div class="flex items-end">
            <button
              @click="loadData"
              class="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              :disabled="loading"
            >
              <span v-if="loading">Chargement...</span>
              <span v-else>Actualiser</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="loading" class="flex justify-center items-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else>
      <div class="stats-grid grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div class="stat-card bg-gradient-to-br from-blue-500 to-blue-600 text-white p-6 rounded-lg shadow-lg">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-blue-100 text-sm font-medium">Total Visites</p>
              <p class="text-3xl font-bold mt-2">{{ commercialStats?.total_visits || 0 }}</p>
            </div>
            <div class="text-4xl opacity-50">📍</div>
          </div>
        </div>

        <div class="stat-card bg-gradient-to-br from-green-500 to-green-600 text-white p-6 rounded-lg shadow-lg">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-green-100 text-sm font-medium">Clients Visités</p>
              <p class="text-3xl font-bold mt-2">{{ commercialStats?.unique_clients_visited || 0 }}</p>
            </div>
            <div class="text-4xl opacity-50">👥</div>
          </div>
        </div>

        <div class="stat-card bg-gradient-to-br from-purple-500 to-purple-600 text-white p-6 rounded-lg shadow-lg">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-purple-100 text-sm font-medium">Zones Couvertes</p>
              <p class="text-3xl font-bold mt-2">{{ commercialStats?.zones_covered || 0 }}</p>
            </div>
            <div class="text-4xl opacity-50">🗺️</div>
          </div>
        </div>

        <div class="stat-card bg-gradient-to-br from-orange-500 to-orange-600 text-white p-6 rounded-lg shadow-lg">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-orange-100 text-sm font-medium">Distance Totale</p>
              <p class="text-3xl font-bold mt-2">{{ commercialStats?.total_distance_km.toFixed(1) || 0 }} km</p>
            </div>
            <div class="text-4xl opacity-50">🚗</div>
          </div>
        </div>
      </div>

      <div class="tabs mb-6">
        <div class="flex space-x-2 border-b border-gray-200">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="activeTab = tab.id"
            :class="[
              'px-4 py-2 font-medium text-sm transition-colors',
              activeTab === tab.id
                ? 'text-blue-600 border-b-2 border-blue-600'
                : 'text-gray-600 hover:text-gray-800'
            ]"
          >
            {{ tab.label }}
          </button>
        </div>
      </div>

      <div v-show="activeTab === 'visits'" class="tab-content">
        <div class="bg-white rounded-lg shadow-sm overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-800">Historique des Visites Clients</h3>
            <p class="text-sm text-gray-600 mt-1">{{ clientVisits.length }} visite(s) détectée(s)</p>
          </div>

          <div v-if="clientVisits.length === 0" class="p-8 text-center text-gray-500">
            Aucune visite client détectée pour cette période
          </div>

          <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Client</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Adresse</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date/Heure</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Distance</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Statut</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <tr v-for="visit in clientVisits" :key="`${visit.client_id}-${visit.visit_date}`" class="hover:bg-gray-50">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="font-medium text-gray-900">{{ visit.client_name }}</div>
                  </td>
                  <td class="px-6 py-4">
                    <div class="text-sm text-gray-600">{{ visit.client_address || 'N/A' }}</div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {{ formatDateTime(visit.visit_date) }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {{ (visit.distance_km * 1000).toFixed(0) }}m
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800">
                      Visite confirmée
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div v-show="activeTab === 'transactions'" class="tab-content">
        <div class="bg-white rounded-lg shadow-sm overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-800">Statistiques de Transactions par Client</h3>
            <p class="text-sm text-gray-600 mt-1">{{ transactionStats.length }} client(s) avec transactions</p>
          </div>

          <div v-if="transactionStats.length === 0" class="p-8 text-center text-gray-500">
            Aucune transaction pour cette période
          </div>

          <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Client</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Commandes</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ventes</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Chiffre d'affaires</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Panier Moyen</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Dernière Transaction</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <tr v-for="stat in transactionStats" :key="stat.client_id" class="hover:bg-gray-50">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="font-medium text-gray-900">{{ stat.client_name }}</div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {{ stat.total_orders }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {{ stat.total_sales }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-semibold text-gray-900">
                    {{ formatCurrency(stat.total_revenue) }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {{ formatCurrency(stat.avg_order_value) }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {{ stat.last_transaction_date ? formatDate(stat.last_transaction_date) : 'N/A' }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div v-show="activeTab === 'zones'" class="tab-content">
        <div class="bg-white rounded-lg shadow-sm overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-800">Zones Géographiques Couvertes</h3>
            <p class="text-sm text-gray-600 mt-1">{{ zoneCoverage.length }} zone(s) visitée(s)</p>
          </div>

          <div v-if="zoneCoverage.length === 0" class="p-8 text-center text-gray-500">
            Aucune zone visitée pour cette période
          </div>

          <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Zone</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Commune</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nombre de Visites</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Clients Uniques</th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Dernière Visite</th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <tr v-for="zone in zoneCoverage" :key="zone.zone_name" class="hover:bg-gray-50">
                  <td class="px-6 py-4">
                    <div class="font-medium text-gray-900">{{ zone.zone_name }}</div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {{ zone.commune }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="px-3 py-1 text-sm font-semibold rounded-full bg-blue-100 text-blue-800">
                      {{ zone.visit_count }}
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {{ zone.unique_clients }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {{ formatDate(zone.last_visit_date) }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { supabase } from '../services/supabase';
import { commercialTrackingService } from '../services/commercial-tracking.service';
import type { ClientVisit, ClientTransactionStats, ZoneCoverage, CommercialStats } from '../services/commercial-tracking.service';

const loading = ref(false);
const activeTab = ref('visits');
const currentUserId = ref('');
const selectedCommercialId = ref('');
const startDate = ref('');
const endDate = ref('');

const clientVisits = ref<ClientVisit[]>([]);
const transactionStats = ref<ClientTransactionStats[]>([]);
const zoneCoverage = ref<ZoneCoverage[]>([]);
const commercialStats = ref<CommercialStats | null>(null);

const commercials = ref<Array<{ id: string; full_name: string }>>([]);
const userRole = ref('');

const tabs = [
  { id: 'visits', label: 'Visites Clients' },
  { id: 'transactions', label: 'Transactions' },
  { id: 'zones', label: 'Zones Couvertes' },
];

const canViewAllCommercials = computed(() => {
  return userRole.value === 'admin' || userRole.value === 'superviseur';
});

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'XOF',
    minimumFractionDigits: 0,
  }).format(value);
};

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('fr-FR', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};

const formatDateTime = (dateString: string) => {
  return new Date(dateString).toLocaleString('fr-FR', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const loadCommercials = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id, role')
      .eq('id', user.id)
      .maybeSingle();

    if (!profile) return;

    userRole.value = profile.role;

    if (profile.role === 'admin' || profile.role === 'superviseur') {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, full_name')
        .eq('company_id', profile.company_id)
        .eq('role', 'commercial')
        .order('full_name');

      if (!error && data) {
        commercials.value = data;
      }
    }
  } catch (error) {
    console.error('Error loading commercials:', error);
  }
};

const loadData = async () => {
  loading.value = true;
  try {
    const commercialId = selectedCommercialId.value || undefined;
    const start = startDate.value || undefined;
    const end = endDate.value || undefined;

    const [visits, transactions, zones, stats] = await Promise.all([
      commercialTrackingService.getClientVisitHistory(commercialId, start, end),
      commercialTrackingService.getClientTransactionStats(commercialId, start, end),
      commercialTrackingService.getZonesCoverage(commercialId, start, end),
      commercialTrackingService.getCommercialStats(commercialId, start, end),
    ]);

    clientVisits.value = visits;
    transactionStats.value = transactions;
    zoneCoverage.value = zones;
    commercialStats.value = stats;
  } catch (error) {
    console.error('Error loading tracking data:', error);
  } finally {
    loading.value = false;
  }
};

onMounted(async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    currentUserId.value = user.id;
    selectedCommercialId.value = user.id;

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    startDate.value = thirtyDaysAgo.toISOString().split('T')[0];
    endDate.value = new Date().toISOString().split('T')[0];

    await loadCommercials();
    await loadData();
  }
});
</script>

<style scoped>
.commercial-visit-history {
  padding: 1.5rem;
  max-width: 1400px;
  margin: 0 auto;
}

.stat-card {
  transition: transform 0.2s, box-shadow 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
}
</style>
