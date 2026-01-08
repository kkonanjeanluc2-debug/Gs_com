<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { analyticsService, type CommercialMonthlyRevenue } from '../services/analytics.service';
import { companyService, type CompanySettings } from '../services/company.service';
import type { Profile } from '../services/supabase';
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

const isCommercial = computed(() => {
  return props.profile?.role === 'commercial';
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
      analyticsService.getDashboardStats(),
      analyticsService.getTopCommercials(5),
      analyticsService.getTopProducts(5),
      analyticsService.getTopClients(5),
      analyticsService.getRecentOrders(5),
      analyticsService.getRecentProspects(5),
      analyticsService.getSalesEvolution(7),
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
      const revenues = await analyticsService.getCommercialsMonthlyRevenue();
      commercialRevenue.value = revenues.find(r => r.id === props.profile?.id) || null;
    }
  } catch (error) {
    console.error('Error loading dashboard data:', error);
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  loadDashboardData();
});
</script>

<template>
  <div class="space-y-8">
    <div v-if="profile" class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900">
        Bonjour {{ profile.full_name.split(' ')[0] }} 👋
      </h1>
      <p class="text-gray-500 mt-1">Voici un aperçu de votre activité</p>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <template v-else>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm text-gray-500 mb-2">Recette du jour</p>
              <p class="text-3xl font-bold text-gray-900">{{ formatCurrency(todayRevenue) }} <span class="text-sm font-normal text-gray-500">FCFA</span></p>
            </div>
            <div class="w-12 h-12 bg-emerald-50 rounded-xl flex items-center justify-center text-2xl">
              💵
            </div>
          </div>
        </div>

        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm text-gray-500 mb-2">Chiffre d'affaires</p>
              <p class="text-3xl font-bold text-gray-900">{{ formatCurrency(stats.totalRevenue) }} <span class="text-sm font-normal text-gray-500">FCFA</span></p>
              <div class="mt-2 flex items-center gap-1 text-sm">
                <span v-if="stats.revenueGrowth > 0" class="text-green-600 font-medium">↗ +{{ stats.revenueGrowth.toFixed(1) }}%</span>
                <span v-else-if="stats.revenueGrowth < 0" class="text-red-600 font-medium">↘ {{ stats.revenueGrowth.toFixed(1) }}%</span>
                <span v-else class="text-gray-500">→ 0%</span>
                <span class="text-gray-400 text-xs">vs mois dernier</span>
              </div>
            </div>
            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center text-2xl">
              💰
            </div>
          </div>
        </div>

        <div class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm text-gray-500 mb-2">Commandes</p>
              <p class="text-3xl font-bold text-gray-900">{{ stats.totalOrders }}</p>
              <div class="mt-2 flex items-center gap-1 text-sm">
                <span v-if="stats.ordersGrowth > 0" class="text-green-600 font-medium">↗ +{{ stats.ordersGrowth.toFixed(1) }}%</span>
                <span v-else-if="stats.ordersGrowth < 0" class="text-red-600 font-medium">↘ {{ stats.ordersGrowth.toFixed(1) }}%</span>
                <span v-else class="text-gray-500">→ 0%</span>
                <span class="text-gray-400 text-xs">vs mois dernier</span>
              </div>
            </div>
            <div class="w-12 h-12 bg-green-50 rounded-xl flex items-center justify-center text-2xl">
              🛒
            </div>
          </div>
        </div>

        <div v-if="isCommercial && companySettings?.commission_rate" class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm text-gray-500 mb-2">Ma Commission</p>
              <p class="text-3xl font-bold text-gray-900">{{ formatCurrency(commercialCommission) }} <span class="text-sm font-normal text-gray-500">FCFA</span></p>
              <p class="text-xs text-gray-400 mt-2">{{ companySettings.commission_rate }}% sur {{ formatCurrency(commercialRevenue?.monthly_revenue || 0) }} FCFA</p>
            </div>
            <div class="w-12 h-12 bg-teal-50 rounded-xl flex items-center justify-center text-2xl">
              💎
            </div>
          </div>
        </div>

        <div v-else class="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm text-gray-500 mb-2">Clients actifs</p>
              <p class="text-3xl font-bold text-gray-900">{{ stats.totalClients }}</p>
            </div>
            <div class="w-12 h-12 bg-purple-50 rounded-xl flex items-center justify-center text-2xl">
              👥
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div v-if="!isCommercial" class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h3 class="text-lg font-bold text-gray-900">Meilleurs Commerciaux</h3>
              <p class="text-sm text-gray-500 mt-1">Top 5 du mois en cours</p>
            </div>
            <button class="text-gray-400 hover:text-gray-600">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
              </svg>
            </button>
          </div>
          <div v-if="topCommercials.length === 0" class="text-center py-8 text-gray-500">
            Aucune donnée disponible
          </div>
          <div v-else class="space-y-4">
            <div
              v-for="(commercial, index) in topCommercials"
              :key="commercial.id"
              class="flex items-center gap-4 p-3 rounded-lg hover:bg-gray-50 transition-colors border border-gray-100"
            >
              <div
                class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm"
                :class="{
                  'bg-yellow-500 text-white': index === 0,
                  'bg-gray-400 text-white': index === 1,
                  'bg-orange-600 text-white': index === 2,
                  'bg-blue-500 text-white': index > 2
                }"
              >
                <span v-if="index === 0">🥇</span>
                <span v-else-if="index === 1">🥈</span>
                <span v-else-if="index === 2">🥉</span>
                <span v-else>{{ index + 1 }}</span>
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

        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6" :class="{ 'lg:col-span-2': isCommercial }">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h3 class="text-lg font-bold text-gray-900">Produits les Plus Vendus</h3>
              <p class="text-sm text-gray-500 mt-1">Top 5 du mois</p>
            </div>
            <button class="text-gray-400 hover:text-gray-600">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
              </svg>
            </button>
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
                  class="w-10 h-10 rounded-lg bg-gray-100 flex items-center justify-center text-gray-400 text-xs"
                >
                  📦
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
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h3 class="text-lg font-bold text-gray-900">Meilleurs Clients</h3>
              <p class="text-sm text-gray-500 mt-1">Top 5 par CA</p>
            </div>
            <button class="text-gray-400 hover:text-gray-600">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
              </svg>
            </button>
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

        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h3 class="text-lg font-bold text-gray-900">Commandes Récentes</h3>
              <p class="text-sm text-gray-500 mt-1">5 dernières</p>
            </div>
            <button class="text-gray-400 hover:text-gray-600">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
              </svg>
            </button>
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

        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h3 class="text-lg font-bold text-gray-900">Prospects Récents</h3>
              <p class="text-sm text-gray-500 mt-1">5 derniers</p>
            </div>
            <button class="text-gray-400 hover:text-gray-600">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
              </svg>
            </button>
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

      <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
        <div class="flex items-center justify-between mb-6">
          <div>
            <h3 class="text-lg font-bold text-gray-900">Évolution des Ventes</h3>
            <p class="text-sm text-gray-500 mt-1">7 derniers jours</p>
          </div>
          <button class="text-gray-400 hover:text-gray-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
            </svg>
          </button>
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
