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

const editingPlan = ref<SubscriptionPlan | null>(null);
const showPlanModal = ref(false);
const planForm = ref({
  name: '',
  duration_days: 30,
  price: 0,
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

const openPlanModal = (plan?: SubscriptionPlan) => {
  if (plan) {
    editingPlan.value = plan;
    planForm.value = {
      name: plan.name,
      duration_days: plan.duration_days,
      price: plan.price,
      description: plan.description || '',
      is_active: plan.is_active,
      selectedFeatures: plan.features?.map(f => f.id) || [],
    };
  } else {
    editingPlan.value = null;
    planForm.value = {
      name: '',
      duration_days: 30,
      price: 0,
      description: '',
      is_active: true,
      selectedFeatures: [],
    };
  }
  showPlanModal.value = true;
};

const savePlan = async () => {
  try {
    const planData = {
      name: planForm.value.name,
      duration_days: planForm.value.duration_days,
      price: planForm.value.price,
      description: planForm.value.description,
      is_active: planForm.value.is_active,
    };

    let planId: string;

    if (editingPlan.value) {
      await subscriptionService.updateSubscriptionPlan(editingPlan.value.id, planData);
      planId = editingPlan.value.id;
    } else {
      const newPlan = await subscriptionService.createSubscriptionPlan(planData);
      planId = newPlan.id;
    }

    await subscriptionService.updatePlanFeatures(planId, planForm.value.selectedFeatures);

    showPlanModal.value = false;
    await loadData();
  } catch (e: any) {
    alert('Erreur: ' + (e.message || 'Impossible de sauvegarder le plan'));
  }
};

const deletePlan = async (plan: SubscriptionPlan) => {
  if (!confirm(`Voulez-vous vraiment supprimer le plan "${plan.name}" ?`)) return;

  try {
    await subscriptionService.deleteSubscriptionPlan(plan.id);
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
            Nouveau Plan
          </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div
            v-for="plan in plans"
            :key="plan.id"
            class="bg-white rounded-xl shadow-md border border-gray-200 p-6 hover:shadow-lg transition-shadow"
          >
            <div class="flex items-start justify-between mb-4">
              <div>
                <h4 class="text-xl font-bold text-gray-900">{{ plan.name }}</h4>
                <p class="text-sm text-gray-500">{{ plan.duration_days }} jours</p>
              </div>
              <span
                :class="[
                  'px-2 py-1 text-xs rounded-full',
                  plan.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                ]"
              >
                {{ plan.is_active ? 'Actif' : 'Inactif' }}
              </span>
            </div>

            <div class="mb-4">
              <div class="text-3xl font-bold text-gray-900">{{ formatCurrency(plan.price) }} <span class="text-lg text-gray-500">FCFA</span></div>
              <p class="text-sm text-gray-600 mt-2">{{ plan.description }}</p>
            </div>

            <div class="mb-4">
              <p class="text-sm font-semibold text-gray-700 mb-2">Fonctionnalités incluses:</p>
              <div class="flex flex-wrap gap-1">
                <span
                  v-for="feature in plan.features"
                  :key="feature.id"
                  :class="['px-2 py-1 text-xs rounded-full', categoryColor(feature.category)]"
                >
                  {{ feature.name }}
                </span>
              </div>
            </div>

            <div class="flex gap-2 pt-4 border-t border-gray-200">
              <button
                @click="openPlanModal(plan)"
                class="flex-1 px-3 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
              >
                Modifier
              </button>
              <button
                @click="deletePlan(plan)"
                class="px-3 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
              >
                Supprimer
              </button>
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
            {{ editingPlan ? 'Modifier le Plan' : 'Nouveau Plan' }}
          </h3>
        </div>

        <form @submit.prevent="savePlan" class="p-6 space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Nom du plan *</label>
              <input
                v-model="planForm.name"
                type="text"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="Mensuel"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Durée (jours) *</label>
              <input
                v-model.number="planForm.duration_days"
                type="number"
                required
                min="1"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Prix (FCFA) *</label>
              <input
                v-model.number="planForm.price"
                type="number"
                required
                min="0"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
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

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Fonctionnalités incluses</label>
            <div class="space-y-3">
              <div v-for="(categoryFeatures, category) in featuresByCategory" :key="category">
                <div v-if="categoryFeatures.length > 0">
                  <h4 class="text-sm font-semibold text-gray-700 mb-2">{{ categoryLabel(category) }}</h4>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-2">
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
              class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Enregistrer
            </button>
            <button
              type="button"
              @click="showPlanModal = false"
              class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
            >
              Annuler
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
