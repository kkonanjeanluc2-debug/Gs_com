<script setup lang="ts">
import { ref } from 'vue';
import { authService } from '../services/auth';

const emit = defineEmits<{
  success: [];
}>();

const newPassword = ref('');
const confirmPassword = ref('');
const error = ref('');
const success = ref(false);
const loading = ref(false);

const handleSubmit = async () => {
  if (!newPassword.value || !confirmPassword.value) {
    error.value = 'Veuillez remplir tous les champs';
    return;
  }

  if (newPassword.value.length < 6) {
    error.value = 'Le mot de passe doit contenir au moins 6 caractères';
    return;
  }

  if (newPassword.value !== confirmPassword.value) {
    error.value = 'Les mots de passe ne correspondent pas';
    return;
  }

  loading.value = true;
  error.value = '';

  try {
    await authService.updatePassword(newPassword.value);
    success.value = true;
    setTimeout(() => {
      emit('success');
    }, 2000);
  } catch (err: any) {
    error.value = err.message || 'Erreur lors de la réinitialisation';
  } finally {
    loading.value = false;
  }
};
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-white px-4">
    <div class="card w-full max-w-md">
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-primary mb-2">Nouveau mot de passe</h1>
        <p class="text-gray-600">Choisissez votre nouveau mot de passe</p>
      </div>

      <div v-if="success" class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-6">
        <p class="font-medium mb-1">Mot de passe modifié !</p>
        <p class="text-sm">Redirection en cours...</p>
      </div>

      <form v-else @submit.prevent="handleSubmit" class="space-y-4">
        <div>
          <label class="label">Nouveau mot de passe</label>
          <input
            v-model="newPassword"
            type="password"
            placeholder="Minimum 6 caractères"
            class="input-field"
            :disabled="loading"
            required
            minlength="6"
          />
        </div>

        <div>
          <label class="label">Confirmer le mot de passe</label>
          <input
            v-model="confirmPassword"
            type="password"
            placeholder="Confirmer le mot de passe"
            class="input-field"
            :disabled="loading"
            required
            minlength="6"
          />
        </div>

        <div v-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {{ error }}
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="btn-primary w-full"
        >
          {{ loading ? 'Modification...' : 'Modifier le mot de passe' }}
        </button>
      </form>
    </div>
  </div>
</template>
