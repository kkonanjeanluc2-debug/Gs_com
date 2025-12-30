<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { supabase } from '../services/supabase';
import type { Profile } from '../services/supabase';
import { communesCoteIvoire } from '../data/communes-cote-ivoire';

const users = ref<Profile[]>([]);
const loading = ref(false);
const showForm = ref(false);
const editingUser = ref<Profile | null>(null);
const currentUser = ref<Profile | null>(null);

const formData = ref({
  email: '',
  password: '',
  full_name: '',
  role: 'commercial' as 'admin' | 'superviseur' | 'commercial' | 'super_admin',
  phone: '',
  zone_affectation: '',
});

const error = ref('');

onMounted(async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .maybeSingle();
    currentUser.value = data;
  }
  await loadUsers();
});

const loadUsers = async () => {
  loading.value = true;
  try {
    const { data, error: fetchError } = await supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false });

    if (fetchError) throw fetchError;
    users.value = data || [];
  } catch (err) {
    console.error('Error loading users:', err);
    alert('Erreur lors du chargement des utilisateurs');
  } finally {
    loading.value = false;
  }
};

const openForm = (user?: Profile) => {
  if (user) {
    editingUser.value = user;
    formData.value = {
      email: user.email,
      password: '',
      full_name: user.full_name,
      role: user.role,
      phone: user.phone || '',
      zone_affectation: user.zone_affectation || '',
    };
  } else {
    editingUser.value = null;
    formData.value = {
      email: '',
      password: '',
      full_name: '',
      role: 'commercial',
      phone: '',
      zone_affectation: '',
    };
  }
  error.value = '';
  showForm.value = true;
};

const closeForm = () => {
  showForm.value = false;
  editingUser.value = null;
  error.value = '';
};

const isValidEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

const handleSubmit = async () => {
  error.value = '';

  if (!formData.value.email || !formData.value.full_name) {
    error.value = 'Veuillez remplir tous les champs obligatoires';
    return;
  }

  if (!isValidEmail(formData.value.email)) {
    error.value = 'Veuillez entrer une adresse email valide';
    return;
  }

  if (!editingUser.value && !formData.value.password) {
    error.value = 'Le mot de passe est obligatoire pour créer un utilisateur';
    return;
  }

  if (formData.value.password && formData.value.password.length < 6) {
    error.value = 'Le mot de passe doit contenir au moins 6 caractères';
    return;
  }

  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      error.value = 'Session expirée. Veuillez vous reconnecter.';
      return;
    }

    if (editingUser.value) {
      const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/update-user`;

      const updatePayload: any = {
        userId: editingUser.value.id,
        email: formData.value.email,
        full_name: formData.value.full_name,
        role: formData.value.role,
        phone: formData.value.phone || null,
        zone_affectation: formData.value.zone_affectation || null,
      };

      if (formData.value.password) {
        updatePayload.password = formData.value.password;
      }

      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${session.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(updatePayload),
      });

      const result = await response.json();

      if (!response.ok) {
        error.value = result.error || 'Erreur lors de la modification de l\'utilisateur';
        return;
      }

      await loadUsers();
      closeForm();
      alert('Utilisateur modifié avec succès');
    } else {
      const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/create-user`;

      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${session.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: formData.value.email,
          password: formData.value.password,
          full_name: formData.value.full_name,
          role: formData.value.role,
          phone: formData.value.phone || null,
          zone_affectation: formData.value.zone_affectation || null,
        }),
      });

      const result = await response.json();

      if (!response.ok) {
        if (result.error && result.error.includes('already registered')) {
          error.value = 'Cet email est déjà utilisé';
        } else {
          error.value = result.error || 'Erreur lors de la création de l\'utilisateur';
        }
        return;
      }

      await loadUsers();
      closeForm();
      alert('Utilisateur créé avec succès');
    }
  } catch (err: any) {
    console.error('Error saving user:', err);
    error.value = editingUser.value
      ? 'Erreur lors de la modification de l\'utilisateur'
      : 'Erreur lors de la création de l\'utilisateur';
  }
};

const handleDelete = async (user: Profile) => {
  if (user.id === currentUser.value?.id) {
    alert('Vous ne pouvez pas supprimer votre propre compte');
    return;
  }

  if (!confirm(`Supprimer l'utilisateur "${user.full_name}" ?`)) return;

  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      alert('Session expirée. Veuillez vous reconnecter.');
      return;
    }

    const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/delete-user`;

    const response = await fetch(apiUrl, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        userId: user.id,
      }),
    });

    const result = await response.json();

    if (!response.ok) {
      alert(result.error || 'Erreur lors de la suppression');
      return;
    }

    await loadUsers();
    alert('Utilisateur supprimé avec succès');
  } catch (err) {
    console.error('Error deleting user:', err);
    alert('Erreur lors de la suppression. Seul un admin peut supprimer des utilisateurs.');
  }
};

const getRoleLabel = (role: string) => {
  switch (role) {
    case 'admin': return 'Administrateur';
    case 'superviseur': return 'Superviseur';
    case 'commercial': return 'Commercial';
    default: return role;
  }
};

const getRoleColor = (role: string) => {
  switch (role) {
    case 'admin': return 'bg-purple-100 text-purple-800';
    case 'superviseur': return 'bg-blue-100 text-blue-800';
    case 'commercial': return 'bg-green-100 text-green-800';
    default: return 'bg-gray-100 text-gray-800';
  }
};
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h2 class="text-2xl font-bold text-secondary">Gestion des Utilisateurs</h2>
      <button
        v-if="currentUser?.role === 'admin' || currentUser?.role === 'superviseur'"
        @click="openForm()"
        class="btn-primary"
      >
        ➕ Nouvel utilisateur
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="card bg-gradient-to-r from-purple-50 to-purple-100">
        <p class="text-sm text-gray-600 mb-1">Administrateurs</p>
        <p class="text-3xl font-bold text-purple-700">
          {{ users.filter(u => u.role === 'admin').length }}
        </p>
      </div>
      <div class="card bg-gradient-to-r from-blue-50 to-blue-100">
        <p class="text-sm text-gray-600 mb-1">Superviseurs</p>
        <p class="text-3xl font-bold text-blue-700">
          {{ users.filter(u => u.role === 'superviseur').length }}
        </p>
      </div>
      <div class="card bg-gradient-to-r from-green-50 to-green-100">
        <p class="text-sm text-gray-600 mb-1">Commerciaux</p>
        <p class="text-3xl font-bold text-green-700">
          {{ users.filter(u => u.role === 'commercial').length }}
        </p>
      </div>
    </div>

    <div v-if="showForm" class="card">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-xl font-bold text-primary">
          {{ editingUser ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur' }}
        </h3>
        <button @click="closeForm" class="text-gray-500 hover:text-gray-700">✕</button>
      </div>

      <form @submit.prevent="handleSubmit" class="space-y-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="label">Nom complet *</label>
            <input
              v-model="formData.full_name"
              type="text"
              class="input-field"
              placeholder="Jean Dupont"
              required
            />
          </div>
          <div>
            <label class="label">Email *</label>
            <input
              v-model="formData.email"
              type="email"
              class="input-field"
              placeholder="jean@entreprise.ci"
              required
            />
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="label">Mot de passe {{ editingUser ? '' : '*' }}</label>
            <input
              v-model="formData.password"
              type="password"
              class="input-field"
              :placeholder="editingUser ? 'Laissez vide pour ne pas changer' : 'Min. 6 caractères'"
              :required="!editingUser"
              minlength="6"
            />
            <p v-if="editingUser" class="text-xs text-gray-500 mt-1">
              Laissez vide si vous ne souhaitez pas changer le mot de passe
            </p>
          </div>
          <div>
            <label class="label">Téléphone WhatsApp</label>
            <input
              v-model="formData.phone"
              type="tel"
              class="input-field"
              placeholder="Numéro de téléphone"
            />
          </div>
        </div>

        <div>
          <label class="label">Rôle *</label>
          <select v-model="formData.role" class="input-field" required>
            <option value="commercial">Commercial</option>
            <option value="superviseur">Superviseur</option>
            <option value="admin" v-if="currentUser?.role === 'admin'">Administrateur</option>
          </select>
          <p class="text-xs text-gray-500 mt-1">
            Les commerciaux ont accès à leurs données uniquement. Les superviseurs peuvent tout voir et gérer le stock.
          </p>
        </div>

        <div v-if="formData.role === 'commercial'">
          <label class="label">Zone d'affectation *</label>
          <select v-model="formData.zone_affectation" class="input-field" required>
            <option value="">-- Sélectionner une commune --</option>
            <option v-for="commune in communesCoteIvoire" :key="commune" :value="commune">
              {{ commune }}
            </option>
          </select>
          <p class="text-xs text-gray-500 mt-1">
            Commune de Côte d'Ivoire où le commercial est affecté
          </p>
        </div>

        <div v-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {{ error }}
        </div>

        <div class="flex gap-3">
          <button type="submit" class="btn-primary flex-1">
            💾 {{ editingUser ? 'Modifier' : 'Créer l\'utilisateur' }}
          </button>
          <button type="button" @click="closeForm" class="btn-secondary flex-1">
            Annuler
          </button>
        </div>
      </form>
    </div>

    <div v-if="loading" class="text-center py-8">
      <p class="text-gray-600">Chargement...</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="user in users" :key="user.id" class="card">
        <div class="flex justify-between items-start mb-3">
          <div class="flex-1">
            <h3 class="font-bold text-lg">{{ user.full_name }}</h3>
            <p class="text-sm text-gray-600">{{ user.email }}</p>
          </div>
          <span :class="['px-2 py-1 rounded text-xs font-semibold', getRoleColor(user.role)]">
            {{ getRoleLabel(user.role) }}
          </span>
        </div>

        <div class="space-y-1 text-sm text-gray-600 mb-3">
          <p v-if="user.phone">📱 {{ user.phone }}</p>
          <p v-if="user.zone_affectation && user.role === 'commercial'">📍 {{ user.zone_affectation }}</p>
          <p class="text-xs text-gray-400">
            Créé le {{ new Date(user.created_at).toLocaleDateString('fr-FR') }}
          </p>
        </div>

        <div v-if="currentUser?.role === 'admin' || currentUser?.role === 'superviseur'" class="flex gap-2">
          <button
            @click="openForm(user)"
            class="flex-1 px-3 py-2 text-sm bg-blue-50 text-primary rounded-lg hover:bg-blue-100"
          >
            ✏️ Modifier
          </button>
          <button
            v-if="currentUser?.role === 'admin' && user.id !== currentUser.id"
            @click="handleDelete(user)"
            class="flex-1 px-3 py-2 text-sm bg-red-50 text-red-700 rounded-lg hover:bg-red-100"
          >
            🗑️ Supprimer
          </button>
        </div>

        <div v-if="user.id === currentUser?.id" class="text-center text-xs text-blue-600 font-semibold py-2">
          👤 C'est vous
        </div>
      </div>
    </div>

    <div v-if="!loading && users.length === 0" class="text-center py-12">
      <div class="text-6xl mb-4">👥</div>
      <p class="text-xl text-gray-600">Aucun utilisateur</p>
    </div>
  </div>
</template>
