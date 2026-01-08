<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { clientsService } from '../services/clients.service';
import { authService } from '../services/auth';
import type { Client, Profile } from '../services/supabase';
import Icon from './Icon.vue';

const clients = ref<Client[]>([]);
const loading = ref(false);
const showForm = ref(false);
const editingClient = ref<Client | null>(null);
const currentProfile = ref<Profile | null>(null);
const filter = ref<'all' | 'prospect' | 'client'>('all');

const formData = ref({
  name: '',
  email: '',
  phone: '',
  address: '',
  latitude: null as number | null,
  longitude: null as number | null,
  type: 'prospect' as 'prospect' | 'client',
  status: 'actif' as 'actif' | 'inactif' | 'en_negociation',
  assigned_to: null as string | null,
});

const gettingLocation = ref(false);

const filteredClients = computed(() => {
  if (filter.value === 'all') return clients.value;
  return clients.value.filter(c => c.type === filter.value);
});

const prospects = computed(() => clients.value.filter(c => c.type === 'prospect'));
const clientsActifs = computed(() => clients.value.filter(c => c.type === 'client'));

onMounted(async () => {
  currentProfile.value = await authService.getCurrentProfile();
  await loadClients();
});

const loadClients = async () => {
  loading.value = true;
  try {
    if (currentProfile.value?.role === 'commercial') {
      clients.value = await clientsService.getMyClients(currentProfile.value.id);
    } else {
      clients.value = await clientsService.getAllClients();
    }
  } catch (error) {
    console.error('Error loading clients:', error);
    alert('Erreur lors du chargement des clients');
  } finally {
    loading.value = false;
  }
};

const openForm = (client?: Client) => {
  if (client) {
    editingClient.value = client;
    formData.value = {
      name: client.name,
      email: client.email || '',
      phone: client.phone || '',
      address: client.address || '',
      latitude: client.latitude || null,
      longitude: client.longitude || null,
      type: client.type,
      status: client.status,
      assigned_to: client.assigned_to,
    };
  } else {
    editingClient.value = null;
    formData.value = {
      name: '',
      email: '',
      phone: '',
      address: '',
      latitude: null,
      longitude: null,
      type: 'prospect',
      status: 'actif',
      assigned_to: currentProfile.value?.id || null,
    };
  }
  showForm.value = true;
};

const closeForm = () => {
  showForm.value = false;
  editingClient.value = null;
};

const handleSubmit = async () => {
  try {
    if (editingClient.value) {
      await clientsService.updateClient(editingClient.value.id, formData.value);
    } else {
      await clientsService.createClient(formData.value);
    }
    await loadClients();
    closeForm();
  } catch (error) {
    console.error('Error saving client:', error);
    alert('Erreur lors de la sauvegarde');
  }
};

const handleDelete = async (client: Client) => {
  if (!confirm(`Supprimer "${client.name}" ?\n\nAttention : Cette action est irréversible.`)) return;

  try {
    await clientsService.deleteClient(client.id);
    await loadClients();
    alert(`Le client "${client.name}" a été supprimé avec succès.`);
  } catch (error: any) {
    console.error('Error deleting client:', error);

    // Check if error is due to foreign key constraint
    if (error?.message?.includes('violates foreign key constraint') ||
        error?.code === '23503' ||
        error?.message?.includes('orders')) {
      alert(
        `Impossible de supprimer "${client.name}".\n\n` +
        `Ce client a des commandes associées et ne peut pas être supprimé pour préserver l'historique.\n\n` +
        `Vous pouvez plutôt :\n` +
        `• Changer son statut en "Inactif" pour le désactiver\n` +
        `• Le convertir en prospect s'il n'est plus actif`
      );
    } else {
      alert(`Erreur lors de la suppression du client : ${error?.message || 'Erreur inconnue'}`);
    }
  }
};

const convertToClient = async (client: Client) => {
  if (!confirm(`Convertir "${client.name}" en client ?`)) return;

  try {
    await clientsService.convertProspectToClient(client.id);
    await loadClients();
  } catch (error) {
    console.error('Error converting:', error);
    alert('Erreur lors de la conversion');
  }
};

const getStatusColor = (status: string) => {
  switch (status) {
    case 'actif': return 'bg-green-100 text-green-800';
    case 'inactif': return 'bg-gray-100 text-gray-800';
    case 'en_negociation': return 'bg-yellow-100 text-yellow-800';
    default: return 'bg-gray-100 text-gray-800';
  }
};

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'actif': return 'Actif';
    case 'inactif': return 'Inactif';
    case 'en_negociation': return 'En négociation';
    default: return status;
  }
};

const openWhatsApp = (phone: string) => {
  if (!phone) {
    alert('Aucun numéro de téléphone disponible');
    return;
  }

  const cleanPhone = phone.replace(/\s+/g, '');
  const url = `https://wa.me/${cleanPhone}`;
  window.open(url, '_blank');
};

const getCurrentLocation = () => {
  if (!navigator.geolocation) {
    alert('La géolocalisation n\'est pas supportée par votre navigateur');
    return;
  }

  gettingLocation.value = true;

  const onSuccess = (position: GeolocationPosition) => {
    formData.value.latitude = position.coords.latitude;
    formData.value.longitude = position.coords.longitude;
    gettingLocation.value = false;
  };

  const onError = (error: GeolocationPositionError) => {
    let message = 'Erreur lors de la récupération de la position';

    switch (error.code) {
      case error.PERMISSION_DENIED:
        message = 'Vous devez autoriser l\'accès à votre position';
        gettingLocation.value = false;
        alert(message);
        break;
      case error.POSITION_UNAVAILABLE:
        message = 'Position non disponible. Réessayez avec une précision réduite...';
        navigator.geolocation.getCurrentPosition(
          onSuccess,
          (_fallbackError) => {
            gettingLocation.value = false;
            alert('Impossible d\'obtenir votre position. Vérifiez que la localisation est activée dans votre navigateur.');
          },
          {
            enableHighAccuracy: false,
            timeout: 30000,
            maximumAge: 60000
          }
        );
        break;
      case error.TIMEOUT:
        message = 'Délai expiré. Réessayez avec une précision réduite...';
        navigator.geolocation.getCurrentPosition(
          onSuccess,
          (_fallbackError) => {
            gettingLocation.value = false;
            alert('Impossible d\'obtenir votre position. Réessayez ou vérifiez votre connexion.');
          },
          {
            enableHighAccuracy: false,
            timeout: 30000,
            maximumAge: 60000
          }
        );
        break;
      default:
        gettingLocation.value = false;
        alert(message);
    }
  };

  navigator.geolocation.getCurrentPosition(
    onSuccess,
    onError,
    {
      enableHighAccuracy: false,
      timeout: 15000,
      maximumAge: 30000
    }
  );
};

const openGoogleMaps = (latitude: number, longitude: number) => {
  const url = `https://www.google.com/maps?q=${latitude},${longitude}`;
  window.open(url, '_blank');
};
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div class="flex items-center gap-3">
        <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg">
          <Icon name="users" class="w-6 h-6 text-white" />
        </div>
        <div>
          <h2 class="text-2xl font-bold text-gray-800">Gestion CRM</h2>
          <p class="text-sm text-gray-500">Gérez vos clients et prospects</p>
        </div>
      </div>
      <button @click="openForm()" class="btn-primary inline-flex items-center gap-2 shadow-lg hover:shadow-xl transition-shadow">
        <Icon name="plus" class="w-5 h-5" />
        <span>Nouveau contact</span>
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="card hover:shadow-xl transition-shadow bg-gradient-to-br from-blue-50 via-white to-blue-50 border border-blue-100">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600 mb-1">Total Contacts</p>
            <p class="text-3xl font-bold text-blue-600">{{ clients.length }}</p>
          </div>
          <div class="w-14 h-14 rounded-xl bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-md">
            <Icon name="users" class="w-7 h-7 text-white" />
          </div>
        </div>
      </div>
      <div class="card hover:shadow-xl transition-shadow bg-gradient-to-br from-amber-50 via-white to-amber-50 border border-amber-100">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600 mb-1">Prospects</p>
            <p class="text-3xl font-bold text-amber-600">{{ prospects.length }}</p>
          </div>
          <div class="w-14 h-14 rounded-xl bg-gradient-to-br from-amber-500 to-amber-600 flex items-center justify-center shadow-md">
            <Icon name="target" class="w-7 h-7 text-white" />
          </div>
        </div>
      </div>
      <div class="card hover:shadow-xl transition-shadow bg-gradient-to-br from-emerald-50 via-white to-emerald-50 border border-emerald-100">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600 mb-1">Clients</p>
            <p class="text-3xl font-bold text-emerald-600">{{ clientsActifs.length }}</p>
          </div>
          <div class="w-14 h-14 rounded-xl bg-gradient-to-br from-emerald-500 to-emerald-600 flex items-center justify-center shadow-md">
            <Icon name="check-circle" class="w-7 h-7 text-white" />
          </div>
        </div>
      </div>
    </div>

    <div class="flex gap-2">
      <button
        @click="filter = 'all'"
        :class="[
          'px-4 py-2 rounded-lg font-medium transition-all',
          filter === 'all' ? 'bg-primary text-white' : 'bg-gray-100 text-gray-700'
        ]"
      >
        Tous
      </button>
      <button
        @click="filter = 'prospect'"
        :class="[
          'px-4 py-2 rounded-lg font-medium transition-all',
          filter === 'prospect' ? 'bg-primary text-white' : 'bg-gray-100 text-gray-700'
        ]"
      >
        Prospects
      </button>
      <button
        @click="filter = 'client'"
        :class="[
          'px-4 py-2 rounded-lg font-medium transition-all',
          filter === 'client' ? 'bg-primary text-white' : 'bg-gray-100 text-gray-700'
        ]"
      >
        Clients
      </button>
    </div>

    <div v-if="showForm" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-xl font-bold text-gray-800">
            {{ editingClient ? 'Modifier le contact' : 'Nouveau contact' }}
          </h3>
          <button @click="closeForm" class="text-gray-400 hover:text-gray-600 transition-colors">
            <Icon name="x" class="w-6 h-6" />
          </button>
        </div>

        <form @submit.prevent="handleSubmit" class="space-y-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="label">Nom complet</label>
            <input v-model="formData.name" type="text" class="input-field" required />
          </div>
          <div>
            <label class="label">Email</label>
            <input v-model="formData.email" type="email" class="input-field" />
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="label">Téléphone WhatsApp</label>
            <input v-model="formData.phone" type="tel" class="input-field" placeholder="Numéro de téléphone" />
          </div>
          <div>
            <label class="label">Type</label>
            <select v-model="formData.type" class="input-field">
              <option value="prospect">Prospect</option>
              <option value="client">Client</option>
            </select>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="label">Statut</label>
            <select v-model="formData.status" class="input-field">
              <option value="actif">Actif</option>
              <option value="inactif">Inactif</option>
              <option value="en_negociation">En négociation</option>
            </select>
          </div>
          <div>
            <label class="label">Adresse</label>
            <input v-model="formData.address" type="text" class="input-field" />
          </div>
        </div>

        <div>
          <div class="flex justify-between items-center mb-2">
            <label class="label">Position GPS</label>
            <button
              type="button"
              @click="getCurrentLocation"
              :disabled="gettingLocation"
              class="px-3 py-1 text-sm bg-blue-500 text-white rounded hover:bg-blue-600 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              <Icon name="location" class="w-4 h-4" />
              <span>{{ gettingLocation ? 'Obtention...' : 'Ma position' }}</span>
            </button>
          </div>
          <div v-if="formData.latitude && formData.longitude" class="flex items-center gap-2 p-3 bg-emerald-50 border border-emerald-200 rounded-lg">
            <Icon name="location" class="w-5 h-5 text-emerald-600 flex-shrink-0" />
            <span class="text-sm text-emerald-800 font-medium">
              {{ formData.latitude.toFixed(6) }}, {{ formData.longitude.toFixed(6) }}
            </span>
            <button
              type="button"
              @click="openGoogleMaps(formData.latitude!, formData.longitude!)"
              class="px-3 py-1 text-xs bg-green-500 text-white rounded hover:bg-green-600"
            >
              Voir sur la carte
            </button>
            <button
              type="button"
              @click="formData.latitude = null; formData.longitude = null"
              class="px-2 py-1 text-xs bg-red-500 text-white rounded hover:bg-red-600 inline-flex items-center gap-1"
              title="Supprimer la position"
            >
              <Icon name="x" class="w-3 h-3" />
            </button>
          </div>
          <p v-else class="text-sm text-gray-500 mt-1">
            Aucune position GPS enregistrée. Cliquez sur "Obtenir ma position" pour enregistrer votre position actuelle.
          </p>
        </div>

        <div class="flex gap-3 pt-4 border-t">
          <button type="submit" class="btn-primary flex-1 inline-flex items-center justify-center gap-2">
            <Icon name="check-circle" class="w-5 h-5" />
            <span>Enregistrer</span>
          </button>
          <button type="button" @click="closeForm" class="btn-secondary flex-1 inline-flex items-center justify-center gap-2">
            <Icon name="x" class="w-5 h-5" />
            <span>Annuler</span>
          </button>
        </div>
      </form>
      </div>
    </div>

    <div v-if="loading" class="text-center py-8">
      <p class="text-gray-600">Chargement...</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="client in filteredClients" :key="client.id" class="card hover:shadow-xl transition-all duration-200 border border-gray-100">
        <div class="flex justify-between items-start mb-4">
          <div class="flex items-start gap-3">
            <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-md flex-shrink-0">
              <Icon name="user" class="w-5 h-5 text-white" />
            </div>
            <div>
              <h3 class="font-bold text-lg text-gray-800">{{ client.name }}</h3>
              <span :class="['inline-block px-2.5 py-1 rounded-full text-xs font-semibold mt-1', getStatusColor(client.status)]">
                {{ getStatusLabel(client.status) }}
              </span>
            </div>
          </div>
          <span :class="[
            'px-2.5 py-1 rounded-full text-xs font-semibold inline-flex items-center gap-1',
            client.type === 'client' ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'
          ]">
            <Icon :name="client.type === 'client' ? 'check-circle' : 'target'" class="w-3.5 h-3.5" />
            <span>{{ client.type === 'client' ? 'Client' : 'Prospect' }}</span>
          </span>
        </div>

        <div class="space-y-2.5 text-sm text-gray-600 mb-4">
          <div v-if="client.email" class="flex items-center gap-2">
            <Icon name="mail" class="w-4 h-4 text-gray-400 flex-shrink-0" />
            <p class="truncate">{{ client.email }}</p>
          </div>
          <div v-if="client.phone" class="flex items-center gap-2">
            <Icon name="phone" class="w-4 h-4 text-gray-400 flex-shrink-0" />
            <p>{{ client.phone }}</p>
            <button
              @click="openWhatsApp(client.phone)"
              class="ml-auto px-2.5 py-1 bg-emerald-500 text-white rounded-md hover:bg-emerald-600 text-xs font-medium inline-flex items-center gap-1 transition-colors"
              title="Contacter sur WhatsApp"
            >
              <Icon name="phone" class="w-3.5 h-3.5" />
              <span>WhatsApp</span>
            </button>
          </div>
          <div v-if="client.address || (client.latitude && client.longitude)" class="flex items-start gap-2">
            <Icon name="location" class="w-4 h-4 text-gray-400 flex-shrink-0 mt-0.5" />
            <p v-if="client.address" class="flex-1">{{ client.address }}</p>
            <button
              v-if="client.latitude && client.longitude"
              @click="openGoogleMaps(client.latitude, client.longitude)"
              class="px-2.5 py-1 bg-blue-500 text-white rounded-md hover:bg-blue-600 text-xs font-medium inline-flex items-center gap-1 transition-colors"
              title="Voir sur Google Maps"
            >
              <Icon name="location" class="w-3.5 h-3.5" />
              <span>Carte</span>
            </button>
          </div>
        </div>

        <div class="flex flex-wrap gap-2 pt-3 border-t border-gray-100">
          <button
            @click="openForm(client)"
            class="flex-1 px-3 py-2 text-sm bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 inline-flex items-center justify-center gap-1.5 font-medium transition-colors"
          >
            <Icon name="edit" class="w-4 h-4" />
            <span>Modifier</span>
          </button>
          <button
            v-if="client.type === 'prospect'"
            @click="convertToClient(client)"
            class="flex-1 px-3 py-2 text-sm bg-emerald-50 text-emerald-700 rounded-lg hover:bg-emerald-100 inline-flex items-center justify-center gap-1.5 font-medium transition-colors"
          >
            <Icon name="check-circle" class="w-4 h-4" />
            <span>Convertir</span>
          </button>
          <button
            v-if="currentProfile?.role === 'admin'"
            @click="handleDelete(client)"
            class="px-3 py-2 text-sm bg-red-50 text-red-700 rounded-lg hover:bg-red-100 inline-flex items-center justify-center gap-1.5 font-medium transition-colors"
          >
            <Icon name="trash" class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>

    <div v-if="!loading && filteredClients.length === 0" class="text-center py-16">
      <div class="w-20 h-20 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center">
        <Icon name="users" class="w-10 h-10 text-gray-400" />
      </div>
      <p class="text-xl font-semibold text-gray-700 mb-2">Aucun contact</p>
      <p class="text-gray-500">Ajoutez votre premier contact pour commencer</p>
    </div>
  </div>
</template>
