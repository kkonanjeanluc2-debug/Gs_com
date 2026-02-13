<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue';
import { analyticsService, type CommercialMonthlyRevenue } from '../services/analytics.service';
import { companyService, type CompanySettings } from '../services/company.service';
import { superAdminService, type SuperAdminStats } from '../services/super-admin.service';
import type { Profile } from '../services/supabase';
import Icon from './Icon.vue';
import type {
  DashboardStats,
  TopCommercial,
  TopProduct,
  TopClient,
  RecentOrder,
  RecentProspect,
  SalesEvolution,
} from '../services/analytics.service';

const props = defineProps<{
  profile?: Profile;
}>();

type PeriodType = '1month' | '3months' | '6months' | '12months' | 'custom';

const selectedPeriod = ref<PeriodType>('1month');
const customStartDate = ref('');
const customEndDate = ref('');
const showCustomDatePicker = ref(false);

const getDateRange = (): { startDate: Date; endDate: Date } => {
  const endDate = new Date();
  const startDate = new Date();

  if (selectedPeriod.value === 'custom' && customStartDate.value && customEndDate.value) {
    return {
      startDate: new Date(customStartDate.value),
      endDate: new Date(customEndDate.value)
    };
  }

  switch (selectedPeriod.value) {
    case '1month':
      startDate.setDate(1);
      startDate.setHours(0, 0, 0, 0);
      break;
    case '3months':
      startDate.setMonth(startDate.getMonth() - 2);
      startDate.setDate(1);
      startDate.setHours(0, 0, 0, 0);
      break;
    case '6months':
      startDate.setMonth(startDate.getMonth() - 5);
      startDate.setDate(1);
      startDate.setHours(0, 0, 0, 0);
      break;
    case '12months':
      startDate.setMonth(startDate.getMonth() - 11);
      startDate.setDate(1);
      startDate.setHours(0, 0, 0, 0);
      break;
  }

  return { startDate, endDate };
};

const periodLabel = computed(() => {
  const labels: Record<PeriodType, string> = {
    '1month': 'le mois en cours',
    '3months': 'les 3 derniers mois',
    '6months': 'les 6 derniers mois',
    '12months': 'les 12 derniers mois',
    'custom': 'la période personnalisée'
  };
  return labels[selectedPeriod.value];
});

const stats = ref<DashboardStats>({
  totalRevenue: 0,
  totalOrders: 0,
  totalClients: 0,
  totalProducts: 0,
  revenueGrowth: 0,
  ordersGrowth: 0,
  todayRevenue: 0,
});

const todayRevenue = ref(0);
const topCommercials = ref<TopCommercial[]>([]);
const topProducts = ref<TopProduct[]>([]);
const topClients = ref<TopClient[]>([]);
const recentOrders = ref<RecentOrder[]>([]);
const recentProspects = ref<RecentProspect[]>([]);
const salesEvolution = ref<SalesEvolution[]>([]);
const isLoading = ref(true);
const commercialRevenue = ref<CommercialMonthlyRevenue | null>(null);
const companySettings = ref<CompanySettings | null>(null);
const superAdminStats = ref<SuperAdminStats | null>(null);

const isCommercial = computed(() => {
  return props.profile?.role === 'commercial';
});

const isSuperAdmin = computed(() => {
  return props.profile?.role === 'super_admin';
});

const commercialCommission = computed(() => {
  if (!commercialRevenue.value || !companySettings.value?.commission_rate) return 0;

  const monthlyRevenue = commercialRevenue.value.monthly_revenue || 0;
  const commissionRate = companySettings.value.commission_rate || 0;

  return (monthlyRevenue * commissionRate) / 100;
});

const maxCommercialRevenue = computed(() => {
  return Math.max(...topCommercials.value.map((c) => c.total_revenue), 1);
});

const maxProductRevenue = computed(() => {
  return Math.max(...topProducts.value.map((p) => p.total_revenue), 1);
});

const getBarWidth = (value: number, max: number) => {
  return `${(value / max) * 100}%`;
};

const getStatusColor = (status: string) => {
  const colors: Record<string, string> = {
    pending: 'bg-yellow-100 text-yellow-800',
    confirmed: 'bg-blue-100 text-blue-800',
    delivered: 'bg-green-100 text-green-800',
    cancelled: 'bg-red-100 text-red-800',
    actif: 'bg-green-100 text-green-800',
    inactif: 'bg-gray-100 text-gray-800',
    en_negociation: 'bg-orange-100 text-orange-800',
  };
  return colors[status] || 'bg-gray-100 text-gray-800';
};

const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    pending: 'En attente',
    confirmed: 'Confirmée',
    delivered: 'Livrée',
    cancelled: 'Annulée',
    actif: 'Actif',
    inactif: 'Inactif',
    en_negociation: 'En négociation',
  };
  return labels[status] || status;
};

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'decimal',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
};

const formatDate = (dateStr: string) => {
  return new Date(dateStr).toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const loadDashboardData = async () => {
  isLoading.value = true;
  try {
    if (isSuperAdmin.value) {
      superAdminStats.value = await superAdminService.getSuperAdminStats();
    } else {
      const { startDate, endDate } = getDateRange();
      const daysCount = Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));

      const [
        statsData,
        commercialsData,
        productsData,
        clientsData,
        ordersData,
        prospectsData,
        evolutionData,
        settings,
      ] = await Promise.all([
        analyticsService.getDashboardStats(startDate, endDate),
        analyticsService.getTopCommercials(5, startDate, endDate),
        analyticsService.getTopProducts(5, startDate, endDate),
        analyticsService.getTopClients(5, startDate, endDate),
        analyticsService.getRecentOrders(5, startDate, endDate),
        analyticsService.getRecentProspects(5, startDate, endDate),
        analyticsService.getSalesEvolution(Math.min(daysCount, 30), startDate, endDate),
        companyService.getSettings(),
      ]);

      stats.value = statsData;
      todayRevenue.value = statsData.todayRevenue;
      topCommercials.value = commercialsData;
      topProducts.value = productsData;
      topClients.value = clientsData;
      recentOrders.value = ordersData;
      recentProspects.value = prospectsData;
      salesEvolution.value = evolutionData;
      companySettings.value = settings;

      if (isCommercial.value && props.profile?.id) {
        const revenues = await analyticsService.getCommercialsMonthlyRevenue(startDate, endDate);
        commercialRevenue.value = revenues.find(r => r.id === props.profile?.id) || null;
      }
    }
  } catch (error) {
    console.error('Error loading dashboard data:', error);
  } finally {
    isLoading.value = false;
  }
};

const applyCustomPeriod = () => {
  if (customStartDate.value && customEndDate.value) {
    showCustomDatePicker.value = false;
    loadDashboardData();
  }
};

watch([selectedPeriod, customStartDate, customEndDate], () => {
  if (selectedPeriod.value !== 'custom' || (customStartDate.value && customEndDate.value)) {
    loadDashboardData();
  }
});

onMounted(() => {
  loadDashboardData();
});
</script>

<template>
  <div class="space-y-6">
    <div v-if="!isSuperAdmin" class="bg-white rounded-xl shadow-md p-4">
      <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h3 class="text-sm font-semibold text-gray-700">Période d'analyse</h3>
          <p class="text-xs text-gray-500 mt-1">Sélectionnez la période pour visualiser les données</p>
        </div>
        <div class="flex flex-wrap gap-2">
          <button
            @click="selectedPeriod = '1month'"
            :class="[
              'px-4 py-2 rounded-lg text-sm font-medium transition-all',
              selectedPeriod === '1month'
                ? 'bg-primary text-white shadow-md'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            Mois en cours
          </button>
          <button
            @click="selectedPeriod = '3months'"
            :class="[
              'px-4 py-2 rounded-lg text-sm font-medium transition-all',
              selectedPeriod === '3months'
                ? 'bg-primary text-white shadow-md'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            3 mois
          </button>
          <button
            @click="selectedPeriod = '6months'"
            :class="[
              'px-4 py-2 rounded-lg text-sm font-medium transition-all',
              selectedPeriod === '6months'
                ? 'bg-primary text-white shadow-md'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            6 mois
          </button>
          <button
            @click="selectedPeriod = '12months'"
            :class="[
              'px-4 py-2 rounded-lg text-sm font-medium transition-all',
              selectedPeriod === '12months'
                ? 'bg-primary text-white shadow-md'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            12 mois
          </button>
          <button
            @click="showCustomDatePicker = !showCustomDatePicker"
            :class="[
              'px-4 py-2 rounded-lg text-sm font-medium transition-all',
              selectedPeriod === 'custom'
                ? 'bg-primary text-white shadow-md'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            <Icon name="calendar" size="w-4 h-4 inline mr-1" />
            Personnalisée
          </button>
        </div>
      </div>

      <div v-if="showCustomDatePicker" class="mt-4 pt-4 border-t border-gray-200">
        <div class="flex flex-col md:flex-row gap-4">
          <div class="flex-1">
            <label class="block text-xs font-medium text-gray-700 mb-1">Date de début</label>
            <input
              v-model="customStartDate"
              type="date"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent text-sm"
            />
          </div>
          <div class="flex-1">
            <label class="block text-xs font-medium text-gray-700 mb-1">Date de fin</label>
            <input
              v-model="customEndDate"
              type="date"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent text-sm"
            />
          </div>
          <div class="flex items-end">
            <button
              @click="applyCustomPeriod"
              :disabled="!customStartDate || !customEndDate"
              class="px-6 py-2 bg-primary text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
            >
              Appliquer
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
    </div>

    <template v-else>
      <div v-if="isSuperAdmin" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div class="bg-gradient-to-br from-blue-500 to-blue-600 text-white rounded-xl p-6 shadow-lg">
          <div class="flex items-center justify-between mb-2">
            <span class="text-blue-100 text-sm font-medium">Total Entreprises</span>
            <div class="bg-blue-400 bg-opacity-30 p-2 rounded-lg">
              <Icon name="buildings" size="w-6 h-6" />
            </div>
          </div>
          <div class="text-3xl font-bold mb-1">{{ superAdminStats?.total_companies || 0 }}</div>
          <div class="text-blue-100 text-xs">{{ superAdminStats?.active_companies || 0 }} actives, {{ superAdminStats?.pending_companies || 0 }} en attente</div>
        </div>

        <div class="bg-gradient-to-br from-green-500 to-green-600 text-white rounded-xl p-6 shadow-lg">
          <div class="flex items-center justify-between mb-2">
            <span class="text-green-100 text-sm font-medium">Total Abonnements</span>
            <div class="bg-green-400 bg-opacity-30 p-2 rounded-lg">
              <Icon name="credit-card" size="w-6 h-6" />
            </div>
          </div>
          <div class="text-3xl font-bold mb-1">{{ superAdminStats?.total_subscriptions || 0 }}</div>
          <div class="text-green-100 text-xs">{{ superAdminStats?.active_subscriptions || 0 }} actifs</div>
        </div>

        <div class="bg-gradient-to-br from-emerald-500 to-emerald-600 text-white rounded-xl p-6 shadow-lg">
          <div class="flex items-center justify-between mb-2">
            <span class="text-emerald-100 text-sm font-medium">Revenus Totaux</span>
            <div class="bg-emerald-400 bg-opacity-30 p-2 rounded-lg">
              <Icon name="money-bag" size="w-6 h-6" />
            </div>
          </div>
          <div class="text-3xl font-bold mb-1">{{ formatCurrency(superAdminStats?.total_revenue || 0) }}</div>
          <div class="text-emerald-100 text-xs">FCFA total</div>
        </div>

        <div class="bg-gradient-to-br from-teal-500 to-teal-600 text-white rounded-xl p-6 shadow-lg">
          <div class="flex items-center justify-between mb-2">
            <span class="text-teal-100 text-sm font-medium">Revenus ce Mois</span>
            <div class="bg-teal-400 bg-opacity-30 p-2 rounded-lg">
              <Icon name="money" size="w-6 h-6" />
            </div>
          </div>
          <div class="text-3xl font-bold mb-1">{{ formatCurrency(superAdminStats?.monthly_revenue || 0) }}</div>
          <div class="text-teal-100 text-xs">FCFA ce mois</div>
        </div>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
        <div class="bg-gradient-to-br from-emerald-500 to-emerald-600 text-white rounded-xl p-6 shadow-lg">
          <div class="flex items-center justify-between mb-2">
            <span class="text-emerald-100 text-sm font-medium">Recette du jour</span>
            <div class="bg-emerald-400 bg-opacity-30 p-2 rounded-lg">
              <Icon name="money" size="w-6 h-6" />
            </div>
          </div>
          <div class="text-3xl font-bold mb-1">{{ formatCurrency(todayRevenue) }}</div>
          <div class="text-emerald-100 text-xs">FCFA aujourd'hui</div>
        </div>

        <div class="bg-gradient-to-br from-blue-500 to-blue-600 text-white rounded-xl p-6 shadow-lg">
          <div class="flex items-center justify-between mb-2">
            <span class="text-blue-100 text-sm font-medium">Chiffre d'affaires</span>
            <div class="bg-blue-400 bg-opacity-30 p-2 rounded-lg">
              <Icon name="money-bag" size="w-6 h-6" />
            </div>
          </div>
          <div class="text-3xl font-bold mb-1">{{ formatCurrency(stats.totalRevenue) }}</div>
          <div class="text-blue-100 text-xs">FCFA sur {{ periodLabel }}</div>
          <div class="mt-3 flex items-center gap-1 text-sm">
            <span v-if="stats.revenueGrowth > 0" class="text-green-300">↗ +{{ stats.revenueGrowth.toFixed(1) }}%</span>
            <span v-else-if="stats.revenueGrowth < 0" class="text-red-300">↘ {{ stats.revenueGrowth.toFixed(1) }}%</span>
            <span v-else class="text-blue-200">→ 0%</span>
            <span class="text-blue-200 text-xs">vs période précédente</span>
          </div>
        </div>

        <div class="bg-gradient-to-br from-green-500 to-green-600 text-white rounded-xl p-6 shadow-lg">
          <div class="flex items-center justify-between mb-2">
            <span class="text-green-100 text-sm font-medium">Ventes</span>
            <div class="bg-green-400 bg-opacity-30 p-2 rounded-lg">
              <Icon name="shopping-cart" size="w-6 h-6" />
            </div>
          </div>
          <div class="text-3xl font-bold mb-1">{{ stats.totalOrders }}</div>
          <div class="text-green-100 text-xs">sur {{ periodLabel }}</div>
          <div class="mt-3 flex items-center gap-1 text-sm">
            <span v-if="stats.ordersGrowth > 0" class="text-green-300">↗ +{{ stats.ordersGrowth.toFixed(1) }}%</span>
            <span v-else-if="stats.ordersGrowth < 0" class="text-red-300">↘ {{ stats.ordersGrowth.toFixed(1) }}%</span>
            <span v-else class="text-green-200">→ 0%</span>
            <span class="text-green-200 text-xs">vs période précédente</span>
          </div>
        </div>

        <div v-if="isCommercial && companySettings?.commission_rate" class="bg-gradient-to-br from-teal-500 to-teal-600 text-white rounded-xl p-6 shadow-lg">
          <div class="flex items-center justify-between mb-2">
            <span class="text-teal-100 text-sm font-medium">Ma Commission</span>
            <div class="bg-teal-400 bg-opacity-30 p-2 rounded-lg">
              <Icon name="gem" size="w-6 h-6" />
            </div>
          </div>
          <div class="text-3xl font-bold mb-1">{{ formatCurrency(commercialCommission) }}</div>
          <div class="text-teal-100 text-xs">FCFA sur {{ periodLabel }} ({{ companySettings.commission_rate }}%)</div>
          <div class="mt-3 flex items-center gap-1 text-sm">
            <span class="text-teal-200 text-xs">
              CA: {{ formatCurrency(commercialRevenue?.monthly_revenue || 0) }} FCFA
            </span>
          </div>
        </div>

        <div v-else class="bg-gradient-to-br from-purple-500 to-purple-600 text-white rounded-xl p-6 shadow-lg">
          <div class="flex items-center justify-between mb-2">
            <span class="text-purple-100 text-sm font-medium">Clients</span>
            <div class="bg-purple-400 bg-opacity-30 p-2 rounded-lg">
              <Icon name="users-group" size="w-6 h-6" />
            </div>
          </div>
          <div class="text-3xl font-bold mb-1">{{ stats.totalClients }}</div>
          <div class="text-purple-100 text-xs">clients actifs</div>
        </div>

        <div class="bg-gradient-to-br from-orange-500 to-orange-600 text-white rounded-xl p-6 shadow-lg">
          <div class="flex items-center justify-between mb-2">
            <span class="text-orange-100 text-sm font-medium">Produits</span>
            <div class="bg-orange-400 bg-opacity-30 p-2 rounded-lg">
              <Icon name="package" size="w-6 h-6" />
            </div>
          </div>
          <div class="text-3xl font-bold mb-1">{{ stats.totalProducts }}</div>
          <div class="text-orange-100 text-xs">en catalogue</div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div v-if="!isCommercial" class="bg-white rounded-xl shadow-md p-6">
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center gap-2">
              <div class="bg-yellow-100 p-2 rounded-lg">
                <Icon name="trophy" size="w-5 h-5" class="text-yellow-600" />
              </div>
              <div>
                <h3 class="text-lg font-bold text-gray-800">Meilleurs Commerciaux</h3>
                <p class="text-xs text-gray-500 mt-1">Top 5 sur {{ periodLabel }}</p>
              </div>
            </div>
            <span class="text-xs font-medium text-blue-600 bg-blue-50 px-3 py-1 rounded-full">Par CA réalisé</span>
          </div>
          <div v-if="topCommercials.length === 0" class="text-center py-8 text-gray-500">
            Aucune donnée disponible
          </div>
          <div v-else class="space-y-4">
            <div
              v-for="(commercial, index) in topCommercials"
              :key="commercial.id"
              class="flex items-center gap-4 p-3 rounded-lg hover:bg-gray-50 transition-colors"
              :class="{
                'bg-yellow-50 border border-yellow-200': index === 0,
                'bg-gray-50 border border-gray-200': index === 1,
                'bg-orange-50 border border-orange-200': index === 2
              }"
            >
              <div
                class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm"
                :class="{
                  'bg-yellow-500 text-white shadow-md': index === 0,
                  'bg-gray-400 text-white shadow-md': index === 1,
                  'bg-orange-600 text-white shadow-md': index === 2,
                  'bg-blue-500 text-white': index > 2
                }"
              >
                {{ index + 1 }}
              </div>
              <div class="flex-shrink-0">
                <div
                  v-if="commercial.photo_url"
                  class="w-10 h-10 rounded-full bg-gray-200 bg-cover bg-center"
                  :style="{ backgroundImage: `url(${commercial.photo_url})` }"
                ></div>
                <div
                  v-else
                  class="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center text-gray-600 font-semibold"
                >
                  {{ commercial.full_name.charAt(0).toUpperCase() }}
                </div>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2">
                  <div class="text-sm font-semibold text-gray-800 truncate">
                    {{ commercial.full_name }}
                  </div>
                </div>
                <div class="flex items-center gap-3 mt-1">
                  <div class="flex-1 bg-gray-200 rounded-full h-2 overflow-hidden">
                    <div
                      class="bg-gradient-to-r from-blue-500 to-blue-600 h-full rounded-full transition-all duration-500"
                      :style="{ width: getBarWidth(commercial.total_revenue, maxCommercialRevenue) }"
                    ></div>
                  </div>
                </div>
                <div class="text-xs text-gray-500 mt-1">
                  {{ formatCurrency(commercial.total_revenue) }} FCFA • {{ commercial.total_orders }} commandes
                </div>
                <div v-if="companySettings?.commission_rate" class="text-xs text-green-600 font-medium mt-1">
                  Commission: {{ formatCurrency((commercial.total_revenue * (companySettings.commission_rate || 0)) / 100) }} FCFA
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-md p-6" :class="{ 'lg:col-span-2': isCommercial }">
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center gap-2">
              <div class="bg-blue-100 p-2 rounded-lg">
                <Icon name="chart-bar" size="w-5 h-5" class="text-blue-600" />
              </div>
              <h3 class="text-lg font-bold text-gray-800">Produits les Plus Vendus</h3>
            </div>
            <span class="text-xs text-gray-500">Top 5</span>
          </div>
          <div v-if="topProducts.length === 0" class="text-center py-8 text-gray-500">
            Aucune donnée disponible
          </div>
          <div v-else class="space-y-4">
            <div
              v-for="(product, index) in topProducts"
              :key="product.id"
              class="flex items-center gap-4"
            >
              <div class="flex-shrink-0 w-8 h-8 rounded-full bg-green-500 text-white flex items-center justify-center font-bold text-sm">
                {{ index + 1 }}
              </div>
              <div class="flex-shrink-0">
                <div
                  v-if="product.image_url"
                  class="w-10 h-10 rounded-lg bg-gray-100 bg-cover bg-center"
                  :style="{ backgroundImage: `url(${product.image_url})` }"
                ></div>
                <div
                  v-else
                  class="w-10 h-10 rounded-lg bg-gray-100 flex items-center justify-center text-gray-400"
                >
                  <Icon name="package" size="w-5 h-5" />
                </div>
              </div>
              <div class="flex-1 min-w-0">
                <div class="text-sm font-semibold text-gray-800 truncate">
                  {{ product.name }}
                </div>
                <div class="flex items-center gap-3 mt-1">
                  <div class="flex-1 bg-gray-200 rounded-full h-2 overflow-hidden">
                    <div
                      class="bg-gradient-to-r from-green-500 to-green-600 h-full rounded-full transition-all duration-500"
                      :style="{ width: getBarWidth(product.total_revenue, maxProductRevenue) }"
                    ></div>
                  </div>
                </div>
                <div class="text-xs text-gray-500 mt-1">
                  {{ product.total_quantity }} unités • {{ formatCurrency(product.total_revenue) }} FCFA
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="bg-white rounded-xl shadow-md p-6">
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center gap-2">
              <div class="bg-purple-100 p-2 rounded-lg">
                <Icon name="diamond" size="w-5 h-5" class="text-purple-600" />
              </div>
              <h3 class="text-lg font-bold text-gray-800">Meilleurs Clients</h3>
            </div>
            <span class="text-xs text-gray-500">Top 5</span>
          </div>
          <div v-if="topClients.length === 0" class="text-center py-8 text-gray-500">
            Aucune donnée disponible
          </div>
          <div v-else class="space-y-3">
            <div
              v-for="(client, index) in topClients"
              :key="client.id"
              class="flex items-start gap-3 p-3 rounded-lg hover:bg-gray-50 transition-colors"
            >
              <div class="flex-shrink-0 w-8 h-8 rounded-full bg-purple-500 text-white flex items-center justify-center font-bold text-sm">
                {{ index + 1 }}
              </div>
              <div class="flex-1 min-w-0">
                <div class="text-sm font-semibold text-gray-800 truncate">
                  {{ client.name }}
                </div>
                <div class="text-xs text-gray-500 mt-1">
                  {{ client.total_orders }} commandes
                </div>
                <div class="text-sm font-bold text-primary mt-1">
                  {{ formatCurrency(client.total_spent) }} FCFA
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-md p-6">
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center gap-2">
              <div class="bg-green-100 p-2 rounded-lg">
                <Icon name="shopping-bags" size="w-5 h-5" class="text-green-600" />
              </div>
              <h3 class="text-lg font-bold text-gray-800">Commandes Récentes</h3>
            </div>
            <span class="text-xs text-gray-500">5 dernières</span>
          </div>
          <div v-if="recentOrders.length === 0" class="text-center py-8 text-gray-500">
            Aucune commande récente
          </div>
          <div v-else class="space-y-3">
            <div
              v-for="order in recentOrders"
              :key="order.id"
              class="p-3 rounded-lg border border-gray-100 hover:border-gray-200 transition-colors"
            >
              <div class="flex items-center justify-between mb-2">
                <span class="text-xs font-mono text-gray-600">{{ order.order_number }}</span>
                <span
                  class="text-xs px-2 py-1 rounded-full"
                  :class="getStatusColor(order.status)"
                >
                  {{ getStatusLabel(order.status) }}
                </span>
              </div>
              <div class="text-sm font-semibold text-gray-800 truncate">
                {{ order.client_name }}
              </div>
              <div class="text-xs text-gray-500 mt-1 truncate">
                Commercial: {{ order.commercial_name }}
              </div>
              <div class="flex items-center justify-between mt-2">
                <span class="text-sm font-bold text-primary">
                  {{ formatCurrency(order.total_amount) }} FCFA
                </span>
                <span class="text-xs text-gray-400">
                  {{ formatDate(order.created_at) }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-md p-6">
          <div class="flex items-center justify-between mb-6">
            <div class="flex items-center gap-2">
              <div class="bg-orange-100 p-2 rounded-lg">
                <Icon name="target" size="w-5 h-5" class="text-orange-600" />
              </div>
              <h3 class="text-lg font-bold text-gray-800">Prospects Récents</h3>
            </div>
            <span class="text-xs text-gray-500">5 derniers</span>
          </div>
          <div v-if="recentProspects.length === 0" class="text-center py-8 text-gray-500">
            Aucun prospect récent
          </div>
          <div v-else class="space-y-3">
            <div
              v-for="prospect in recentProspects"
              :key="prospect.id"
              class="p-3 rounded-lg border border-gray-100 hover:border-gray-200 transition-colors"
            >
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-semibold text-gray-800 truncate">
                  {{ prospect.name }}
                </span>
                <span
                  class="text-xs px-2 py-1 rounded-full"
                  :class="getStatusColor(prospect.status)"
                >
                  {{ getStatusLabel(prospect.status) }}
                </span>
              </div>
              <div class="text-xs text-gray-500 truncate" v-if="prospect.email">
                {{ prospect.email }}
              </div>
              <div class="text-xs text-gray-500 truncate" v-if="prospect.phone">
                {{ prospect.phone }}
              </div>
              <div class="flex items-center justify-between mt-2">
                <span class="text-xs text-gray-600 truncate">
                  {{ prospect.assigned_to_name }}
                </span>
                <span class="text-xs text-gray-400">
                  {{ formatDate(prospect.created_at) }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-md p-6">
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-lg font-bold text-gray-800">📈 Évolution des Ventes</h3>
          <span class="text-xs text-gray-500">{{ periodLabel }}</span>
        </div>
        <div v-if="salesEvolution.length === 0" class="text-center py-12 text-gray-500">
          Aucune donnée disponible
        </div>
        <div v-else class="flex items-end justify-between gap-2 h-64">
          <div
            v-for="day in salesEvolution"
            :key="day.date"
            class="flex-1 flex flex-col items-center justify-end gap-2"
          >
            <div class="text-xs font-semibold text-primary">
              {{ formatCurrency(day.revenue) }}
            </div>
            <div
              class="w-full bg-gradient-to-t from-blue-500 to-blue-400 rounded-t-lg transition-all duration-500 hover:from-blue-600 hover:to-blue-500"
              :style="{
                height: `${Math.max((day.revenue / Math.max(...salesEvolution.map(d => d.revenue), 1)) * 100, 5)}%`,
                minHeight: day.revenue > 0 ? '20px' : '4px'
              }"
            ></div>
            <div class="text-xs text-gray-500 text-center">
              {{ new Date(day.date).toLocaleDateString('fr-FR', { weekday: 'short', day: 'numeric' }) }}
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
