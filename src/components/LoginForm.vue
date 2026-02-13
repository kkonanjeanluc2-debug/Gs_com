<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { authService } from '../services/auth';
import { companyService } from '../services/company.service';

const emit = defineEmits<{
  success: [];
}>();

const email = ref('');
const password = ref('');
const error = ref('');
const loading = ref(false);
const companyLogo = ref('');
const companyName = ref('Gestion commerciale');
const showPassword = ref(false);

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

onMounted(async () => {
  try {
    const settings = await companyService.getPublicSettings();
    if (settings?.logo_url) {
      companyLogo.value = settings.logo_url;
    }
  } catch (err) {
    console.log('No company settings found, using defaults');
  }
});
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-white px-4">
    <div class="card w-full max-w-md">
      <div class="mb-4">
        <a href="#/" class="inline-flex items-center text-sm text-gray-600 hover:text-primary transition-colors">
          <span class="mr-1">←</span> Retour à l'accueil
        </a>
      </div>

      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-primary mb-2">{{ companyName }}</h1>
        <p class="text-gray-600 mb-4">Connectez-vous pour continuer</p>
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
          <div class="relative">
            <input
              v-model="password"
              :type="showPassword ? 'text' : 'password'"
              placeholder="••••••••"
              class="input-field pr-10"
              :disabled="loading"
              required
            />
            <button
              type="button"
              @click="showPassword = !showPassword"
              class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
              :disabled="loading"
            >
              {{ showPassword ? '👁️' : '👁️‍🗨️' }}
            </button>
          </div>
          <div class="text-right mt-2">
            <a href="#/forgot-password" class="text-sm text-primary hover:underline">
              Mot de passe oublié ?
            </a>
          </div>
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
