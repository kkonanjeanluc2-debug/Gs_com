<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { geolocationService, type CommercialLocationWithProfile } from '../services/geolocation.service';
import type { Profile } from '../services/supabase';
import Icon from './Icon.vue';

const props = defineProps<{
  profile: Profile;
  companyId: string;
}>();

const locations = ref<CommercialLocationWithProfile[]>([]);
const selectedCommercial = ref<CommercialLocationWithProfile | null>(null);
const loading = ref(false);
const autoRefresh = ref(true);
const refreshInterval = ref<NodeJS.Timeout | null>(null);
const isTracking = ref(false);
const currentActivity = ref<'en_visite' | 'en_deplacement' | 'pause' | 'inactif'>('en_deplacement');
const mapCenter = ref({ lat: 5.3600, lng: -4.0083 });
const mapZoom = ref(12);

const canViewAllLocations = computed(() => {
  return ['admin', 'superviseur'].includes(props.profile.role);
});

const isCommercial = computed(() => {
  return props.profile.role === 'commercial';
});

const activityColors = {
  en_visite: 'bg-blue-500',
  en_deplacement: 'bg-green-500',
  pause: 'bg-yellow-500',
  inactif: 'bg-gray-500',
};

const activityLabels = {
  en_visite: 'En visite',
  en_deplacement: 'En déplacement',
  pause: 'En pause',
  inactif: 'Inactif',
};

const loadLocations = async () => {
  if (!canViewAllLocations.value) return;

  try {
    loading.value = true;
    locations.value = await geolocationService.getActiveLocations(props.companyId);
  } catch (error) {
    console.error('Erreur lors du chargement des positions:', error);
  } finally {
    loading.value = false;
  }
};

const startTracking = async () => {
  try {
    isTracking.value = true;
    geolocationService.startTracking(
      props.profile.id,
      props.companyId,
      5,
      currentActivity.value
    );
  } catch (error) {
    console.error('Erreur lors du démarrage du suivi:', error);
    alert('Impossible de démarrer le suivi GPS');
    isTracking.value = false;
  }
};

const stopTracking = () => {
  geolocationService.stopTracking();
  isTracking.value = false;
};

const updateActivity = async (activity: 'en_visite' | 'en_deplacement' | 'pause' | 'inactif') => {
  currentActivity.value = activity;
  if (isTracking.value) {
    stopTracking();
    await startTracking();
  }
};

const centerOnCommercial = (location: CommercialLocationWithProfile) => {
  selectedCommercial.value = location;
  mapCenter.value = {
    lat: Number(location.latitude),
    lng: Number(location.longitude)
  };
  mapZoom.value = 15;
};

const getTimeSince = (timestamp: string): string => {
  const now = new Date();
  const time = new Date(timestamp);
  const diffMinutes = Math.floor((now.getTime() - time.getTime()) / 60000);

  if (diffMinutes < 1) return 'À l\'instant';
  if (diffMinutes < 60) return `Il y a ${diffMinutes} min`;
  const diffHours = Math.floor(diffMinutes / 60);
  if (diffHours < 24) return `Il y a ${diffHours}h`;
  const diffDays = Math.floor(diffHours / 24);
  return `Il y a ${diffDays}j`;
};

const getGoogleMapsLink = (lat: number, lng: number): string => {
  return `https://www.google.com/maps?q=${lat},${lng}`;
};

onMounted(async () => {
  if (canViewAllLocations.value) {
    await loadLocations();

    if (autoRefresh.value) {
      refreshInterval.value = setInterval(loadLocations, 30000);
    }
  }
});

onUnmounted(() => {
  if (refreshInterval.value) {
    clearInterval(refreshInterval.value);
  }
  if (isTracking.value) {
    stopTracking();
  }
});
</script>

<template>
  <div class="h-full flex flex-col bg-gray-50">
    <div class="bg-white border-b border-gray-200 p-6">
      <div class="flex items-center justify-between mb-4">
        <div>
          <h2 class="text-2xl font-bold text-gray-900">Suivi GPS des Commerciaux</h2>
          <p class="text-gray-600 text-sm mt-1">Suivez les positions en temps réel</p>
        </div>
        <div class="flex gap-3">
          <button
            v-if="canViewAllLocations"
            @click="loadLocations"
            :disabled="loading"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center gap-2"
          >
            <Icon name="refresh" class="w-5 h-5" />
            Actualiser
          </button>
        </div>
      </div>

      <div v-if="isCommercial" class="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h3 class="font-semibold text-gray-900">Mon suivi GPS</h3>
            <p class="text-sm text-gray-600">Partagez votre position en temps réel</p>
          </div>
          <button
            v-if="!isTracking"
            @click="startTracking"
            class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 flex items-center gap-2"
          >
            <Icon name="location" class="w-5 h-5" />
            Activer le suivi
          </button>
          <button
            v-else
            @click="stopTracking"
            class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 flex items-center gap-2"
          >
            <Icon name="x" class="w-5 h-5" />
            Arrêter le suivi
          </button>
        </div>

        <div v-if="isTracking" class="flex gap-2">
          <button
            v-for="(label, activity) in activityLabels"
            :key="activity"
            @click="updateActivity(activity as any)"
            :class="[
              'flex-1 px-3 py-2 rounded-lg text-sm font-medium transition-all',
              currentActivity === activity
                ? `${activityColors[activity as keyof typeof activityColors]} text-white`
                : 'bg-white text-gray-700 hover:bg-gray-50 border border-gray-300'
            ]"
          >
            {{ label }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="canViewAllLocations" class="flex-1 flex overflow-hidden">
      <div class="w-96 bg-white border-r border-gray-200 overflow-y-auto">
        <div class="p-4 border-b border-gray-200">
          <h3 class="font-semibold text-gray-900">Commerciaux actifs ({{ locations.length }})</h3>
        </div>

        <div v-if="loading" class="p-8 text-center text-gray-500">
          Chargement...
        </div>

        <div v-else-if="locations.length === 0" class="p-8 text-center text-gray-500">
          Aucun commercial actif
        </div>

        <div v-else class="divide-y divide-gray-200">
          <button
            v-for="location in locations"
            :key="location.id"
            @click="centerOnCommercial(location)"
            :class="[
              'w-full p-4 text-left hover:bg-gray-50 transition-colors',
              selectedCommercial?.id === location.id ? 'bg-blue-50' : ''
            ]"
          >
            <div class="flex items-start gap-3">
              <div v-if="location.profile.photo_url" class="w-12 h-12 rounded-full overflow-hidden flex-shrink-0">
                <img :src="location.profile.photo_url" :alt="location.profile.first_name" class="w-full h-full object-cover" />
              </div>
              <div v-else class="w-12 h-12 rounded-full bg-blue-600 text-white flex items-center justify-center flex-shrink-0">
                <span class="text-lg font-bold">
                  {{ location.profile.first_name[0] }}{{ location.profile.last_name[0] }}
                </span>
              </div>

              <div class="flex-1 min-w-0">
                <div class="flex items-center justify-between mb-1">
                  <h4 class="font-semibold text-gray-900 truncate">
                    {{ location.profile.first_name }} {{ location.profile.last_name }}
                  </h4>
                  <span :class="[
                    'w-2 h-2 rounded-full flex-shrink-0',
                    activityColors[location.activity_type]
                  ]"></span>
                </div>

                <p class="text-sm text-gray-600 mb-1">
                  {{ activityLabels[location.activity_type] }}
                </p>

                <p class="text-xs text-gray-500">
                  {{ getTimeSince(location.timestamp) }}
                </p>

                <div v-if="location.accuracy" class="text-xs text-gray-400 mt-1">
                  Précision: ±{{ Math.round(location.accuracy) }}m
                </div>
              </div>
            </div>
          </button>
        </div>
      </div>

      <div class="flex-1 relative bg-gray-200">
        <div class="absolute inset-0 flex items-center justify-center">
          <div class="text-center">
            <Icon name="location" class="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <p class="text-gray-600 mb-2">Carte interactive</p>
            <p class="text-sm text-gray-500">La carte affichera les positions des commerciaux</p>
            <div class="mt-4 space-y-2">
              <div v-for="location in locations" :key="location.id" class="text-sm text-gray-600">
                <a
                  :href="getGoogleMapsLink(Number(location.latitude), Number(location.longitude))"
                  target="_blank"
                  class="text-blue-600 hover:underline flex items-center justify-center gap-2"
                >
                  <Icon name="location" class="w-4 h-4" />
                  {{ location.profile.first_name }} {{ location.profile.last_name }} - Voir sur Google Maps
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-else class="flex-1 flex items-center justify-center">
      <div class="text-center">
        <Icon name="location" class="w-16 h-16 text-gray-400 mx-auto mb-4" />
        <p class="text-gray-600">Fonctionnalité réservée aux administrateurs et superviseurs</p>
      </div>
    </div>
  </div>
</template>
