<script setup lang="ts">
import { ref } from 'vue';
import { authService } from '../services/auth';

const emit = defineEmits<{
  success: [];
}>();

const email = ref('');
const password = ref('');
const error = ref('');
const loading = ref(false);

const handleLogin = async () => {
  if (!email.value || !password.value) {
    error.value = 'Veuillez remplir tous les champs';
    return;
  }

  loading.value = true;
  error.value = '';

  try {
    await authService.signIn(email.value, password.value);
    emit('success');
  } catch (err: any) {
    error.value = err.message || 'Erreur de connexion';
  } finally {
    loading.value = false;
  }
};
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-white px-4">
    <div class="card w-full max-w-md">
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-primary mb-2">Gestion commerciale</h1>
        <p class="text-gray-600 mb-4">Connectez-vous pour continuer</p>
        <img
          src="/whatsapp_image_2025-08-07_a_21.31.59_95b113fa.jpg"
          alt="Logo Librairie la Grâce"
          class="mx-auto w-32 h-32 object-contain"
        />
      </div>

      <form @submit.prevent="handleLogin" class="space-y-4">
        <div>
          <label class="label">Email</label>
          <input
            v-model="email"
            type="email"
            placeholder="nom@entreprise.ci"
            class="input-field"
            :disabled="loading"
            required
          />
        </div>

        <div>
          <label class="label">Mot de passe</label>
          <input
            v-model="password"
            type="password"
            placeholder="••••••••"
            class="input-field"
            :disabled="loading"
            required
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
          {{ loading ? 'Connexion...' : 'Se connecter' }}
        </button>
      </form>

      <div class="mt-6 text-center">
        <p class="text-sm text-gray-600">
          Vous n'avez pas encore de compte ?
          <a href="#/register" class="text-primary font-medium hover:underline">Créer mon entreprise</a>
        </p>
      </div>
    </div>
  </div>
</template>
