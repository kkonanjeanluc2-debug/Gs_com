<script setup lang="ts">
import { ref } from 'vue';
import { authService } from '../services/auth';

const email = ref('');
const error = ref('');
const success = ref(false);
const loading = ref(false);

const handleSubmit = async () => {
  if (!email.value) {
    error.value = 'Veuillez entrer votre adresse email';
    return;
  }

  loading.value = true;
  error.value = '';
  success.value = false;

  try {
    await authService.resetPassword(email.value);
    success.value = true;
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
        <h1 class="text-3xl font-bold text-primary mb-2">Mot de passe oublié</h1>
        <p class="text-gray-600">Entrez votre email pour recevoir un lien de réinitialisation</p>
      </div>

      <div v-if="success" class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-6">
        <p class="font-medium mb-1">Email envoyé !</p>
        <p class="text-sm">Vérifiez votre boîte mail et cliquez sur le lien pour réinitialiser votre mot de passe.</p>
      </div>

      <form v-else @submit.prevent="handleSubmit" class="space-y-4">
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

        <div v-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {{ error }}
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="btn-primary w-full"
        >
          {{ loading ? 'Envoi en cours...' : 'Envoyer le lien' }}
        </button>
      </form>

      <div class="mt-6 text-center">
        <a href="#/login" class="text-primary font-medium hover:underline">
          Retour à la connexion
        </a>
      </div>
    </div>
  </div>
</template>
