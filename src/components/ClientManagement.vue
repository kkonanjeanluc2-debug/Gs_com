<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { clientsService } from '../services/clients.service';
import { authService } from '../services/auth';
import type { Client, Profile } from '../services/supabase';

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
  type: 'prospect' as 'prospect' | 'client',
  status: 'actif' as 'actif' | 'inactif' | 'en_negociation',
  assigned_to: null as string | null,
  notes: '',
});

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
      type: client.type,
      status: client.status,
      assigned_to: client.assigned_to,
      notes: client.notes || '',
    };
  } else {
    editingClient.value = null;
    formData.value = {
      name: '',
      email: '',
      phone: '',
      address: '',
      type: 'prospect',
      status: 'actif',
      assigned_to: currentProfile.value?.id || null,
      notes: '',
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
  if (!confirm(`Supprimer "${client.name}" ?`)) return;

  try {
    await clientsService.deleteClient(client.id);
    await loadClients();
  } catch (error) {
    console.error('Error deleting client:', error);
    alert('Erreur lors de la suppression');
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
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <h2 class="text-2xl font-bold text-secondary">Gestion CRM</h2>
      <button @click="openForm()" class="btn-primary">
        ➕ Nouveau contact
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="card bg-gradient-to-r from-blue-50 to-blue-100">
        <p class="text-sm text-gray-600 mb-1">Total Contacts</p>
        <p class="text-3xl font-bold text-primary">{{ clients.length }}</p>
      </div>
      <div class="card bg-gradient-to-r from-yellow-50 to-yellow-100">
        <p class="text-sm text-gray-600 mb-1">Prospects</p>
        <p class="text-3xl font-bold text-yellow-700">{{ prospects.length }}</p>
      </div>
      <div class="card bg-gradient-to-r from-green-50 to-green-100">
        <p class="text-sm text-gray-600 mb-1">Clients</p>
        <p class="text-3xl font-bold text-green-700">{{ clientsActifs.length }}</p>
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

    <div v-if="showForm" class="card">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-xl font-bold text-primary">
          {{ editingClient ? 'Modifier le contact' : 'Nouveau contact' }}
        </h3>
        <button @click="closeForm" class="text-gray-500 hover:text-gray-700">✕</button>
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
            <label class="label">Téléphone</label>
            <input v-model="formData.phone" type="tel" class="input-field" />
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
          <label class="label">Notes</label>
          <textarea v-model="formData.notes" class="textarea-field" placeholder="Ajoutez des notes..."></textarea>
        </div>

        <div class="flex gap-3">
          <button type="submit" class="btn-primary flex-1">💾 Enregistrer</button>
          <button type="button" @click="closeForm" class="btn-secondary flex-1">Annuler</button>
        </div>
      </form>
    </div>

    <div v-if="loading" class="text-center py-8">
      <p class="text-gray-600">Chargement...</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="client in filteredClients" :key="client.id" class="card">
        <div class="flex justify-between items-start mb-3">
          <div>
            <h3 class="font-bold text-lg">{{ client.name }}</h3>
            <span :class="['inline-block px-2 py-1 rounded text-xs font-semibold mt-1', getStatusColor(client.status)]">
              {{ getStatusLabel(client.status) }}
            </span>
          </div>
          <span :class="[
            'px-2 py-1 rounded text-xs font-semibold',
            client.type === 'client' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
          ]">
            {{ client.type === 'client' ? 'Client' : 'Prospect' }}
          </span>
        </div>

        <div class="space-y-2 text-sm text-gray-600 mb-3">
          <p v-if="client.email">📧 {{ client.email }}</p>
          <p v-if="client.phone">📱 {{ client.phone }}</p>
          <p v-if="client.address">📍 {{ client.address }}</p>
          <p v-if="client.notes" class="text-xs">💬 {{ client.notes }}</p>
        </div>

        <div class="flex flex-wrap gap-2">
          <button
            @click="openForm(client)"
            class="flex-1 px-3 py-2 text-sm bg-blue-50 text-primary rounded-lg hover:bg-blue-100"
          >
            ✏️ Modifier
          </button>
          <button
            v-if="client.type === 'prospect'"
            @click="convertToClient(client)"
            class="flex-1 px-3 py-2 text-sm bg-green-50 text-green-700 rounded-lg hover:bg-green-100"
          >
            ✓ Convertir
          </button>
          <button
            v-if="currentProfile?.role === 'admin'"
            @click="handleDelete(client)"
            class="px-3 py-2 text-sm bg-red-50 text-red-700 rounded-lg hover:bg-red-100"
          >
            🗑️
          </button>
        </div>
      </div>
    </div>

    <div v-if="!loading && filteredClients.length === 0" class="text-center py-12">
      <div class="text-6xl mb-4">👥</div>
      <p class="text-xl text-gray-600">Aucun contact</p>
      <p class="text-gray-500 mt-2">Ajoutez votre premier contact pour commencer</p>
    </div>
  </div>
</template>
