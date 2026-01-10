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
const mapUrl = ref('');

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

const updateMapUrl = () => {
  if (locations.value.length === 0) {
    mapUrl.value = '';
    return;
  }

  const markers = locations.value.map((loc, index) => {
    const color = loc.activity_type === 'en_visite' ? 'blue' :
                  loc.activity_type === 'en_deplacement' ? 'green' :
                  loc.activity_type === 'pause' ? 'yellow' : 'red';
    return `markers=color:${color}%7Clabel:${index + 1}%7C${loc.latitude},${loc.longitude}`;
  }).join('&');

  const center = locations.value.length > 0
    ? `${locations.value[0].latitude},${locations.value[0].longitude}`
    : '5.3600,-4.0083';

  mapUrl.value = `https://maps.googleapis.com/maps/api/staticmap?center=${center}&zoom=12&size=800x600&${markers}&key=YOUR_API_KEY`;
};

const loadLocations = async () => {
  if (!canViewAllLocations.value) return;

  try {
    loading.value = true;
    locations.value = await geolocationService.getActiveLocations(props.companyId);
    updateMapUrl();
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
  geolocationService.updateTrackingActivity(activity);
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
  // Restore tracking status from service
  if (isCommercial.value) {
    const status = geolocationService.getTrackingStatus();
    isTracking.value = status.isActive;
    currentActivity.value = status.activity as any;
  }

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
  // Don't stop tracking on unmount - let it persist
});
</script>

<template>
  <div class="h-full flex flex-col bg-gray-50">
    <div class="bg-white border-b border-gray-200 p-3 md:p-6">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-4">
        <div class="flex-1">
          <h2 class="text-lg sm:text-xl md:text-2xl font-bold text-gray-900 flex items-center gap-2">
            <Icon name="location" class="w-5 h-5 md:w-6 md:h-6 text-blue-600" />
            Suivi GPS
          </h2>
          <p class="text-gray-600 text-xs md:text-sm mt-1">Positions en temps réel</p>
        </div>
        <div class="flex gap-2">
          <button
            v-if="canViewAllLocations"
            @click="loadLocations"
            :disabled="loading"
            class="px-3 py-2 md:px-4 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center gap-2 text-sm"
          >
            <Icon name="refresh" class="w-4 h-4 md:w-5 md:h-5" />
            <span class="hidden sm:inline">Actualiser</span>
          </button>
        </div>
      </div>

      <div v-if="isCommercial" class="bg-blue-50 border border-blue-200 rounded-lg p-3 md:p-4">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-3">
          <div class="flex-1">
            <h3 class="font-semibold text-gray-900 text-sm md:text-base">Mon suivi GPS</h3>
            <p class="text-xs md:text-sm text-gray-600">Partagez votre position</p>
          </div>
          <button
            v-if="!isTracking"
            @click="startTracking"
            class="px-3 py-2 md:px-4 bg-green-600 text-white rounded-lg hover:bg-green-700 flex items-center justify-center gap-2 text-sm whitespace-nowrap"
          >
            <Icon name="location" class="w-4 h-4 md:w-5 md:h-5" />
            Activer le suivi
          </button>
          <button
            v-else
            @click="stopTracking"
            class="px-3 py-2 md:px-4 bg-red-600 text-white rounded-lg hover:bg-red-700 flex items-center justify-center gap-2 text-sm whitespace-nowrap"
          >
            <Icon name="x" class="w-4 h-4 md:w-5 md:h-5" />
            Arrêter
          </button>
        </div>

        <div v-if="isTracking" class="grid grid-cols-2 md:flex gap-2">
          <button
            v-for="(label, activity) in activityLabels"
            :key="activity"
            @click="updateActivity(activity as any)"
            :class="[
              'flex-1 px-2 py-2 rounded-lg text-xs md:text-sm font-medium transition-all',
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

    <div v-if="canViewAllLocations" class="flex-1 flex flex-col md:flex-row overflow-hidden">
      <div class="md:w-80 lg:w-96 bg-white border-b md:border-b-0 md:border-r border-gray-200 overflow-y-auto max-h-64 md:max-h-none">
        <div class="p-3 md:p-4 border-b border-gray-200 sticky top-0 bg-white z-10">
          <h3 class="font-semibold text-gray-900 text-sm md:text-base">
            Commerciaux actifs ({{ locations.length }})
          </h3>
        </div>

        <div v-if="loading" class="p-6 md:p-8 text-center text-gray-500 text-sm">
          Chargement...
        </div>

        <div v-else-if="locations.length === 0" class="p-6 md:p-8 text-center text-gray-500 text-sm">
          Aucun commercial actif
        </div>

        <div v-else class="divide-y divide-gray-200">
          <button
            v-for="location in locations"
            :key="location.id"
            @click="centerOnCommercial(location)"
            :class="[
              'w-full p-3 md:p-4 text-left hover:bg-gray-50 transition-colors',
              selectedCommercial?.id === location.id ? 'bg-blue-50' : ''
            ]"
          >
            <div class="flex items-start gap-2 md:gap-3">
              <div v-if="location.profile.photo_url" class="w-10 h-10 md:w-12 md:h-12 rounded-full overflow-hidden flex-shrink-0">
                <img :src="location.profile.photo_url" :alt="location.profile.full_name" class="w-full h-full object-cover" />
              </div>
              <div v-else class="w-10 h-10 md:w-12 md:h-12 rounded-full bg-blue-600 text-white flex items-center justify-center flex-shrink-0">
                <span class="text-base md:text-lg font-bold">
                  {{ location.profile.full_name.split(' ').map(n => n[0]).join('').slice(0, 2) }}
                </span>
              </div>

              <div class="flex-1 min-w-0">
                <div class="flex items-center justify-between mb-1">
                  <h4 class="font-semibold text-gray-900 truncate text-sm md:text-base">
                    {{ location.profile.full_name }}
                  </h4>
                  <span :class="[
                    'w-2 h-2 rounded-full flex-shrink-0',
                    activityColors[location.activity_type]
                  ]"></span>
                </div>

                <p class="text-xs md:text-sm text-gray-600 mb-1">
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

      <div class="flex-1 relative bg-white overflow-hidden">
        <div v-if="locations.length === 0" class="absolute inset-0 flex items-center justify-center bg-gray-50">
          <div class="text-center p-4">
            <Icon name="location" class="w-12 h-12 md:w-16 md:h-16 text-gray-400 mx-auto mb-4" />
            <p class="text-gray-600 mb-2 text-sm md:text-base">Aucun commercial actif</p>
            <p class="text-xs md:text-sm text-gray-500">Les positions GPS s'afficheront ici</p>
          </div>
        </div>

        <div v-else class="h-full overflow-auto">
          <div class="grid grid-cols-1 md:grid-cols-1 lg:grid-cols-2 gap-3 md:gap-4 p-3 md:p-4">
            <div
              v-for="location in locations"
              :key="location.id"
              class="bg-white border border-gray-200 rounded-lg shadow-sm hover:shadow-md transition-shadow overflow-hidden"
            >
              <div class="p-3 md:p-4 border-b border-gray-200 bg-gradient-to-r from-blue-50 to-white">
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2 md:gap-3 min-w-0">
                    <div v-if="location.profile.photo_url" class="w-10 h-10 md:w-12 md:h-12 rounded-full overflow-hidden flex-shrink-0">
                      <img :src="location.profile.photo_url" :alt="location.profile.full_name" class="w-full h-full object-cover" />
                    </div>
                    <div v-else class="w-10 h-10 md:w-12 md:h-12 rounded-full bg-blue-600 text-white flex items-center justify-center flex-shrink-0">
                      <span class="text-base md:text-lg font-bold">
                        {{ location.profile.full_name.split(' ').map(n => n[0]).join('').slice(0, 2) }}
                      </span>
                    </div>
                    <div class="min-w-0">
                      <h3 class="font-semibold text-gray-900 text-sm md:text-base truncate">
                        {{ location.profile.full_name }}
                      </h3>
                      <div class="flex items-center gap-2 mt-1 flex-wrap">
                        <span :class="[
                          'px-2 py-0.5 rounded-full text-xs font-medium',
                          activityColors[location.activity_type].replace('bg-', 'bg-opacity-20 bg-'),
                          activityColors[location.activity_type].replace('bg-', 'text-')
                        ]">
                          {{ activityLabels[location.activity_type] }}
                        </span>
                        <span class="text-xs text-gray-500">
                          {{ getTimeSince(location.timestamp) }}
                        </span>
                      </div>
                    </div>
                  </div>
                  <span :class="[
                    'w-3 h-3 rounded-full flex-shrink-0 animate-pulse',
                    activityColors[location.activity_type]
                  ]"></span>
                </div>
              </div>

              <div class="aspect-video relative">
                <iframe
                  :src="`https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d15000!2d${location.longitude}!3d${location.latitude}!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sfr!2sci!4v1234567890`"
                  class="w-full h-full border-0"
                  loading="lazy"
                  referrerpolicy="no-referrer-when-downgrade"
                ></iframe>
              </div>

              <div class="p-3 md:p-4 bg-gray-50">
                <div class="grid grid-cols-2 gap-3 md:gap-4 text-sm mb-3">
                  <div>
                    <p class="text-gray-500 text-xs md:text-sm">Latitude</p>
                    <p class="font-mono font-medium text-gray-900 text-xs md:text-sm">{{ Number(location.latitude).toFixed(6) }}</p>
                  </div>
                  <div>
                    <p class="text-gray-500 text-xs md:text-sm">Longitude</p>
                    <p class="font-mono font-medium text-gray-900 text-xs md:text-sm">{{ Number(location.longitude).toFixed(6) }}</p>
                  </div>
                </div>
                <div v-if="location.accuracy" class="text-xs text-gray-500 mb-3">
                  Précision: ±{{ Math.round(location.accuracy) }} mètres
                </div>
                <a
                  :href="getGoogleMapsLink(Number(location.latitude), Number(location.longitude))"
                  target="_blank"
                  class="w-full flex items-center justify-center gap-2 px-3 py-2 md:px-4 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm"
                >
                  <Icon name="location" class="w-4 h-4" />
                  <span class="hidden sm:inline">Ouvrir dans</span> Google Maps
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
