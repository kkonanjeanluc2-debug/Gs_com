<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { subscriptionService, type Feature, type SubscriptionPlan } from '../services/subscription.service';
import Icon from './Icon.vue';

const features = ref<Feature[]>([]);
const plans = ref<SubscriptionPlan[]>([]);
const isLoading = ref(true);
const error = ref('');
const activeTab = ref<'features' | 'plans'>('plans');

const editingFeature = ref<Feature | null>(null);
const showFeatureModal = ref(false);
const featureForm = ref({
  code: '',
  name: '',
  description: '',
  category: 'core' as 'core' | 'advanced' | 'premium' | 'enterprise',
  display_order: 0,
  is_active: true,
});

const editingPlanType = ref<string | null>(null);
const showPlanModal = ref(false);
const planForm = ref({
  plan_type: 'basic' as 'basic' | 'professional' | 'premium' | 'enterprise',
  name: '',
  monthly_price: 0,
  annual_price: 0,
  annual_discount_percent: 20,
  description: '',
  is_active: true,
  selectedFeatures: [] as string[],
});

const loadData = async () => {
  isLoading.value = true;
  error.value = '';
  try {
    const [featuresData, plansData] = await Promise.all([
      subscriptionService.getAllFeatures(),
      subscriptionService.getAllSubscriptionPlans(),
    ]);
    features.value = featuresData;
    plans.value = plansData;
  } catch (e: any) {
    error.value = e.message || 'Erreur lors du chargement des données';
    console.error('Error loading data:', e);
  } finally {
    isLoading.value = false;
  }
};

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

const planTypeLabel = (type: string) => {
  const labels: Record<string, string> = {
    basic: 'Basic',
    professional: 'Professional',
    premium: 'Premium',
    enterprise: 'Enterprise',
  };
  return labels[type] || type;
};

const billingPeriodLabel = (period: string) => {
  const labels: Record<string, string> = {
    monthly: 'Mensuel',
    annual: 'Annuel',
  };
  return labels[period] || period;
};

const categoryLabel = (category: string) => {
  const labels: Record<string, string> = {
    core: 'Essentiel',
    advanced: 'Avancé',
    premium: 'Premium',
    enterprise: 'Enterprise',
  };
  return labels[category] || category;
};

const categoryColor = (category: string) => {
  const colors: Record<string, string> = {
    core: 'bg-blue-100 text-blue-800',
    advanced: 'bg-green-100 text-green-800',
    premium: 'bg-orange-100 text-orange-800',
    enterprise: 'bg-red-100 text-red-800',
  };
  return colors[category] || 'bg-gray-100 text-gray-800';
};

const planTypeColor = (type: string) => {
  const colors: Record<string, string> = {
    basic: 'from-blue-500 to-blue-600',
    professional: 'from-green-500 to-green-600',
    premium: 'from-orange-500 to-orange-600',
    enterprise: 'from-red-500 to-red-600',
  };
  return colors[type] || 'from-gray-500 to-gray-600';
};

const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('fr-FR', {
    style: 'decimal',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
};

const openFeatureModal = (feature?: Feature) => {
  if (feature) {
    editingFeature.value = feature;
    featureForm.value = {
      code: feature.code,
      name: feature.name,
      description: feature.description || '',
      category: feature.category,
      display_order: feature.display_order,
      is_active: feature.is_active,
    };
  } else {
    editingFeature.value = null;
    featureForm.value = {
      code: '',
      name: '',
      description: '',
      category: 'core',
      display_order: features.value.length,
      is_active: true,
    };
  }
  showFeatureModal.value = true;
};

const saveFeature = async () => {
  try {
    if (editingFeature.value) {
      await subscriptionService.updateFeature(editingFeature.value.id, featureForm.value);
    } else {
      await subscriptionService.createFeature(featureForm.value);
    }
    showFeatureModal.value = false;
    await loadData();
  } catch (e: any) {
    alert('Erreur: ' + (e.message || 'Impossible de sauvegarder la fonctionnalité'));
  }
};

const deleteFeature = async (feature: Feature) => {
  if (!confirm(`Voulez-vous vraiment supprimer la fonctionnalité "${feature.name}" ?`)) return;

  try {
    await subscriptionService.deleteFeature(feature.id);
    await loadData();
  } catch (e: any) {
    alert('Erreur: ' + (e.message || 'Impossible de supprimer la fonctionnalité'));
  }
};

const openPlanModal = (planType?: string) => {
  if (planType) {
    editingPlanType.value = planType;
    const existingPlans = plansByType.value[planType] || [];
    const monthlyPlan = existingPlans.find(p => p.billing_period === 'monthly');

    if (monthlyPlan) {
      planForm.value = {
        plan_type: monthlyPlan.plan_type,
        name: planTypeLabel(monthlyPlan.plan_type),
        monthly_price: monthlyPlan.monthly_price,
        annual_price: monthlyPlan.annual_price,
        annual_discount_percent: monthlyPlan.annual_discount_percent,
        description: monthlyPlan.description || '',
        is_active: monthlyPlan.is_active,
        selectedFeatures: monthlyPlan.features?.map(f => f.id) || [],
      };
    }
  } else {
    editingPlanType.value = null;
    planForm.value = {
      plan_type: 'basic',
      name: '',
      monthly_price: 0,
      annual_price: 0,
      annual_discount_percent: 20,
      description: '',
      is_active: true,
      selectedFeatures: [],
    };
  }
  showPlanModal.value = true;
};

const savePlan = async () => {
  try {
    const baseName = planForm.value.name || planTypeLabel(planForm.value.plan_type);

    if (editingPlanType.value) {
      const existingPlans = plansByType.value[editingPlanType.value] || [];

      for (const plan of existingPlans) {
        await subscriptionService.deleteSubscriptionPlan(plan.id);
      }
    }

    const monthlyPlanData = {
      name: `${baseName} - Mensuel`,
      plan_type: planForm.value.plan_type,
      billing_period: 'monthly' as const,
      duration_days: 30,
      monthly_price: planForm.value.monthly_price,
      annual_price: planForm.value.annual_price,
      annual_discount_percent: planForm.value.annual_discount_percent,
      description: `${planForm.value.description} - Facturation mensuelle`,
      is_active: planForm.value.is_active,
    };

    const annualPlanData = {
      name: `${baseName} - Annuel`,
      plan_type: planForm.value.plan_type,
      billing_period: 'annual' as const,
      duration_days: 365,
      monthly_price: planForm.value.monthly_price,
      annual_price: planForm.value.annual_price,
      annual_discount_percent: planForm.value.annual_discount_percent,
      description: `${planForm.value.description} - Facturation annuelle (${planForm.value.annual_discount_percent}% de réduction)`,
      is_active: planForm.value.is_active,
    };

    const monthlyPlan = await subscriptionService.createSubscriptionPlan(monthlyPlanData);
    const annualPlan = await subscriptionService.createSubscriptionPlan(annualPlanData);

    await subscriptionService.updatePlanFeatures(monthlyPlan.id, planForm.value.selectedFeatures);
    await subscriptionService.updatePlanFeatures(annualPlan.id, planForm.value.selectedFeatures);

    showPlanModal.value = false;
    await loadData();
  } catch (e: any) {
    alert('Erreur: ' + (e.message || 'Impossible de sauvegarder le plan'));
  }
};

const deletePlanType = async (planType: string) => {
  if (!confirm(`Voulez-vous vraiment supprimer tous les plans de type "${planTypeLabel(planType)}" ?`)) return;

  try {
    const plansToDelete = plansByType.value[planType] || [];
    for (const plan of plansToDelete) {
      await subscriptionService.deleteSubscriptionPlan(plan.id);
    }
    await loadData();
  } catch (e: any) {
    alert('Erreur: ' + (e.message || 'Impossible de supprimer le plan'));
  }
};

const toggleFeatureSelection = (featureId: string) => {
  const index = planForm.value.selectedFeatures.indexOf(featureId);
  if (index > -1) {
    planForm.value.selectedFeatures.splice(index, 1);
  } else {
    planForm.value.selectedFeatures.push(featureId);
  }
};

const featuresByCategory = computed(() => {
  const grouped: Record<string, Feature[]> = {
    core: [],
    advanced: [],
    premium: [],
    enterprise: [],
  };
  features.value.forEach(f => {
    if (grouped[f.category]) {
      grouped[f.category].push(f);
    }
  });
  return grouped;
});

const calculateAnnualSavings = computed(() => {
  const monthlyTotal = planForm.value.monthly_price * 12;
  const savings = monthlyTotal - planForm.value.annual_price;
  const percent = monthlyTotal > 0 ? Math.round((savings / monthlyTotal) * 100) : 0;
  return { amount: savings, percent };
});

onMounted(() => {
  loadData();
});
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">Gestion des Abonnements</h2>
        <p class="text-gray-600 mt-1">Gérez les plans d'abonnement et leurs fonctionnalités</p>
      </div>
    </div>

    <div v-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
      {{ error }}
    </div>

    <div class="flex gap-4 border-b border-gray-200">
      <button
        @click="activeTab = 'plans'"
        :class="[
          'px-4 py-2 font-medium text-sm border-b-2 transition-colors',
          activeTab === 'plans'
            ? 'border-blue-600 text-blue-600'
            : 'border-transparent text-gray-500 hover:text-gray-700'
        ]"
      >
        Plans d'Abonnement
      </button>
      <button
        @click="activeTab = 'features'"
        :class="[
          'px-4 py-2 font-medium text-sm border-b-2 transition-colors',
          activeTab === 'features'
            ? 'border-blue-600 text-blue-600'
            : 'border-transparent text-gray-500 hover:text-gray-700'
        ]"
      >
        Fonctionnalités
      </button>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
    </div>

    <div v-else>
      <div v-if="activeTab === 'plans'" class="space-y-4">
        <div class="flex justify-between items-center">
          <h3 class="text-lg font-semibold text-gray-900">Plans d'Abonnement</h3>
          <button
            @click="openPlanModal()"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2"
          >
            <Icon name="add" size="w-5 h-5" />
            Nouveau Type de Plan
          </button>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
          <div
            v-for="(plansOfType, planType) in plansByType"
            :key="planType"
            class="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden"
          >
            <div :class="['bg-gradient-to-r text-white p-6', planTypeColor(planType)]">
              <div class="flex items-start justify-between mb-2">
                <h4 class="text-2xl font-bold">{{ planTypeLabel(planType) }}</h4>
                <span
                  :class="[
                    'px-2 py-1 text-xs rounded-full bg-white bg-opacity-20'
                  ]"
                >
                  {{ plansOfType[0]?.is_active ? 'Actif' : 'Inactif' }}
                </span>
              </div>
              <p class="text-white text-opacity-90 text-sm">{{ plansOfType[0]?.description }}</p>
            </div>

            <div class="p-6 space-y-4">
              <div
                v-for="plan in plansOfType"
                :key="plan.id"
                class="border border-gray-200 rounded-lg p-4 hover:border-blue-300 transition-colors"
              >
                <div class="flex items-center justify-between mb-2">
                  <span class="text-sm font-semibold text-gray-700">{{ billingPeriodLabel(plan.billing_period) }}</span>
                  <span class="text-xs text-gray-500">{{ plan.duration_days }} jours</span>
                </div>
                <div class="text-2xl font-bold text-gray-900">
                  {{ formatCurrency(plan.billing_period === 'monthly' ? plan.monthly_price : plan.annual_price) }}
                  <span class="text-sm text-gray-500">FCFA</span>
                </div>
                <div v-if="plan.billing_period === 'annual' && plan.annual_discount_percent > 0" class="text-xs text-green-600 mt-1">
                  Économisez {{ plan.annual_discount_percent }}%
                </div>
              </div>

              <div class="pt-4 border-t border-gray-200">
                <p class="text-xs font-semibold text-gray-700 mb-2">Fonctionnalités incluses:</p>
                <div class="flex flex-wrap gap-1">
                  <span
                    v-for="feature in plansOfType[0]?.features?.slice(0, 5)"
                    :key="feature.id"
                    :class="['px-2 py-1 text-xs rounded-full', categoryColor(feature.category)]"
                  >
                    {{ feature.name }}
                  </span>
                  <span
                    v-if="plansOfType[0]?.features && plansOfType[0].features.length > 5"
                    class="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-600"
                  >
                    +{{ plansOfType[0].features.length - 5 }} autres
                  </span>
                </div>
              </div>

              <div class="flex gap-2 pt-4 border-t border-gray-200">
                <button
                  @click="openPlanModal(planType)"
                  class="flex-1 px-3 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors text-sm font-medium"
                >
                  Modifier
                </button>
                <button
                  @click="deletePlanType(planType)"
                  class="px-3 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors text-sm font-medium"
                >
                  Supprimer
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="activeTab === 'features'" class="space-y-4">
        <div class="flex justify-between items-center">
          <h3 class="text-lg font-semibold text-gray-900">Fonctionnalités</h3>
          <button
            @click="openFeatureModal()"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2"
          >
            <Icon name="add" size="w-5 h-5" />
            Nouvelle Fonctionnalité
          </button>
        </div>

        <div class="bg-white rounded-xl shadow-md border border-gray-200 overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Nom</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Code</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Catégorie</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="feature in features" :key="feature.id" class="hover:bg-gray-50">
                <td class="px-6 py-4">
                  <div class="text-sm font-medium text-gray-900">{{ feature.name }}</div>
                  <div class="text-xs text-gray-500">{{ feature.description }}</div>
                </td>
                <td class="px-6 py-4 text-sm text-gray-500">{{ feature.code }}</td>
                <td class="px-6 py-4">
                  <span :class="['px-2 py-1 text-xs rounded-full', categoryColor(feature.category)]">
                    {{ categoryLabel(feature.category) }}
                  </span>
                </td>
                <td class="px-6 py-4">
                  <span
                    :class="[
                      'px-2 py-1 text-xs rounded-full',
                      feature.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                    ]"
                  >
                    {{ feature.is_active ? 'Actif' : 'Inactif' }}
                  </span>
                </td>
                <td class="px-6 py-4 text-sm">
                  <div class="flex gap-2">
                    <button
                      @click="openFeatureModal(feature)"
                      class="text-blue-600 hover:text-blue-900"
                    >
                      Modifier
                    </button>
                    <button
                      @click="deleteFeature(feature)"
                      class="text-red-600 hover:text-red-900"
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
    </div>

    <div
      v-if="showFeatureModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      @click.self="showFeatureModal = false"
    >
      <div class="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div class="p-6 border-b border-gray-200">
          <h3 class="text-xl font-bold text-gray-900">
            {{ editingFeature ? 'Modifier la Fonctionnalité' : 'Nouvelle Fonctionnalité' }}
          </h3>
        </div>

        <form @submit.prevent="saveFeature" class="p-6 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Code *</label>
            <input
              v-model="featureForm.code"
              type="text"
              required
              :disabled="!!editingFeature"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="sales_management"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Nom *</label>
            <input
              v-model="featureForm.name"
              type="text"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Gestion des Ventes"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
            <textarea
              v-model="featureForm.description"
              rows="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Description détaillée de la fonctionnalité"
            ></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Catégorie *</label>
            <select
              v-model="featureForm.category"
              required
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="core">Essentiel</option>
              <option value="advanced">Avancé</option>
              <option value="premium">Premium</option>
              <option value="enterprise">Enterprise</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Ordre d'affichage</label>
            <input
              v-model.number="featureForm.display_order"
              type="number"
              min="0"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div class="flex items-center gap-2">
            <input
              v-model="featureForm.is_active"
              type="checkbox"
              id="feature-active"
              class="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
            />
            <label for="feature-active" class="text-sm font-medium text-gray-700">Fonctionnalité active</label>
          </div>

          <div class="flex gap-3 pt-4">
            <button
              type="submit"
              class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Enregistrer
            </button>
            <button
              type="button"
              @click="showFeatureModal = false"
              class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
            >
              Annuler
            </button>
          </div>
        </form>
      </div>
    </div>

    <div
      v-if="showPlanModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      @click.self="showPlanModal = false"
    >
      <div class="bg-white rounded-xl shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="p-6 border-b border-gray-200">
          <h3 class="text-xl font-bold text-gray-900">
            {{ editingPlanType ? 'Modifier le Plan' : 'Nouveau Plan' }}
          </h3>
          <p class="text-sm text-gray-600 mt-1">Configurez le prix mensuel et annuel pour ce type de plan</p>
        </div>

        <form @submit.prevent="savePlan" class="p-6 space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Type de plan *</label>
              <select
                v-model="planForm.plan_type"
                required
                :disabled="!!editingPlanType"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="basic">Basic</option>
                <option value="professional">Professional</option>
                <option value="premium">Premium</option>
                <option value="enterprise">Enterprise</option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Nom du plan</label>
              <input
                v-model="planForm.name"
                type="text"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                :placeholder="planTypeLabel(planForm.plan_type)"
              />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
            <textarea
              v-model="planForm.description"
              rows="2"
              class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              placeholder="Description du plan"
            ></textarea>
          </div>

          <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <h4 class="font-semibold text-gray-900 mb-3">Tarification</h4>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Prix Mensuel (FCFA) *</label>
                <input
                  v-model.number="planForm.monthly_price"
                  type="number"
                  required
                  min="0"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Prix Annuel (FCFA) *</label>
                <input
                  v-model.number="planForm.annual_price"
                  type="number"
                  required
                  min="0"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Réduction annuelle (%)</label>
                <input
                  v-model.number="planForm.annual_discount_percent"
                  type="number"
                  min="0"
                  max="100"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            <div v-if="calculateAnnualSavings.amount > 0" class="mt-3 text-sm text-green-700 bg-green-50 px-3 py-2 rounded">
              Économie annuelle: {{ formatCurrency(calculateAnnualSavings.amount) }} FCFA ({{ calculateAnnualSavings.percent }}%)
            </div>
          </div>

          <div class="flex items-center gap-2">
            <input
              v-model="planForm.is_active"
              type="checkbox"
              id="plan-active"
              class="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
            />
            <label for="plan-active" class="text-sm font-medium text-gray-700">Plan actif</label>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-3">Fonctionnalités incluses</label>
            <div class="space-y-3 max-h-64 overflow-y-auto border border-gray-200 rounded-lg p-4">
              <div v-for="(categoryFeatures, category) in featuresByCategory" :key="category">
                <div v-if="categoryFeatures.length > 0">
                  <h4 class="text-sm font-semibold text-gray-700 mb-2">{{ categoryLabel(category) }}</h4>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-2 mb-3">
                    <div
                      v-for="feature in categoryFeatures"
                      :key="feature.id"
                      class="flex items-start gap-2 p-2 border border-gray-200 rounded-lg hover:bg-gray-50"
                    >
                      <input
                        :id="'feature-' + feature.id"
                        type="checkbox"
                        :checked="planForm.selectedFeatures.includes(feature.id)"
                        @change="toggleFeatureSelection(feature.id)"
                        class="mt-1 w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                      />
                      <label :for="'feature-' + feature.id" class="flex-1 cursor-pointer">
                        <div class="text-sm font-medium text-gray-900">{{ feature.name }}</div>
                        <div class="text-xs text-gray-500">{{ feature.description }}</div>
                      </label>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="flex gap-3 pt-4">
            <button
              type="submit"
              class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
            >
              Enregistrer
            </button>
            <button
              type="button"
              @click="showPlanModal = false"
              class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors font-medium"
            >
              Annuler
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
