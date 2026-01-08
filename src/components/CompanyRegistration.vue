<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-blue-100 p-4">
    <div class="max-w-md w-full">
      <div class="mb-4">
        <a href="#/" class="inline-flex items-center text-sm text-gray-600 hover:text-primary transition-colors">
          <span class="mr-1">←</span> Retour à l'accueil
        </a>
      </div>

      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold text-primary mb-2">Inscription Entreprise</h1>
        <p class="text-gray-600">Créez votre compte entreprise et commencez à gérer votre activité</p>
      </div>

      <div class="bg-white rounded-2xl shadow-xl p-8">
        <form @submit.prevent="handleSubmit" class="space-y-6">
          <div class="border-b pb-4 mb-4">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Informations de l'entreprise</h3>

            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Nom de l'entreprise *
                </label>
                <input
                  v-model="formData.companyName"
                  type="text"
                  required
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Mon Entreprise SARL"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Email de l'entreprise *
                </label>
                <input
                  v-model="formData.companyEmail"
                  type="email"
                  required
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="contact@entreprise.com"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Téléphone WhatsApp de l'entreprise
                </label>
                <input
                  v-model="formData.companyPhone"
                  type="tel"
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Numéro de téléphone"
                />
              </div>
            </div>
          </div>

          <div>
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Compte administrateur</h3>

            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Nom complet *
                </label>
                <input
                  v-model="formData.adminName"
                  type="text"
                  required
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Jean Dupont"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Email administrateur *
                </label>
                <input
                  v-model="formData.adminEmail"
                  type="email"
                  required
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="admin@entreprise.com"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Mot de passe *
                </label>
                <input
                  v-model="formData.adminPassword"
                  type="password"
                  required
                  minlength="6"
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Minimum 6 caractères"
                />
                <p class="text-xs text-gray-500 mt-1">Le mot de passe doit contenir au moins 6 caractères</p>
              </div>
            </div>
          </div>

          <div v-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
            {{ error }}
          </div>

          <div v-if="success" class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg">
            {{ success }}
          </div>

          <button
            type="submit"
            :disabled="loading"
            class="w-full bg-primary text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <span v-if="loading">Inscription en cours...</span>
            <span v-else>Créer mon entreprise</span>
          </button>
        </form>

        <div class="mt-6 text-center">
          <p class="text-sm text-gray-600">
            Vous avez déjà un compte ?
            <a href="#/login" class="text-primary font-medium hover:underline">Se connecter</a>
          </p>
        </div>
      </div>

      <div class="mt-6 text-center text-xs text-gray-500">
        En créant un compte, vous acceptez nos conditions d'utilisation
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { companiesService } from '../services/companies.service';

const formData = ref({
  companyName: '',
  companyEmail: '',
  companyPhone: '',
  adminName: '',
  adminEmail: '',
  adminPassword: '',
});

const loading = ref(false);
const error = ref('');
const success = ref('');

const handleSubmit = async () => {
  error.value = '';
  success.value = '';
  loading.value = true;

  try {
    await companiesService.registerCompany({
      companyName: formData.value.companyName,
      companyEmail: formData.value.companyEmail,
      companyPhone: formData.value.companyPhone || undefined,
      adminEmail: formData.value.adminEmail,
      adminPassword: formData.value.adminPassword,
      adminName: formData.value.adminName,
    });

    success.value = 'Entreprise créée avec succès ! Vous bénéficiez d\'une période d\'essai gratuite de 30 jours. Vous allez être redirigé vers la page de connexion...';

    setTimeout(() => {
      window.location.hash = '#/login';
    }, 2000);
  } catch (err: any) {
    console.error('Registration error:', err);
    if (err.details) {
      error.value = `${err.message}: ${err.details}`;
    } else {
      error.value = err.message || 'Erreur lors de l\'inscription de l\'entreprise';
    }
  } finally {
    loading.value = false;
  }
};
</script>
