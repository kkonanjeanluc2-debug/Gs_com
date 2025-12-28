<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-2xl font-bold text-gray-900 mb-2">Paramètres du compte</h2>
      <p class="text-gray-600">Gérez vos informations de connexion</p>
    </div>

    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Modifier l'email</h3>
      <form @submit.prevent="handleEmailChange" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Email actuel</label>
          <input
            type="email"
            :value="currentEmail"
            disabled
            class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-50 text-gray-500"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Mot de passe actuel *</label>
          <input
            v-model="emailForm.currentPassword"
            type="password"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            placeholder="Votre mot de passe actuel"
          />
          <p class="text-xs text-gray-500 mt-1">Pour des raisons de sécurité, veuillez confirmer votre mot de passe</p>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Nouvel email *</label>
          <input
            v-model="emailForm.newEmail"
            type="email"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            placeholder="nouveau@email.com"
          />
        </div>

        <div v-if="emailError" class="bg-red-50 text-red-600 px-4 py-2 rounded-lg">
          {{ emailError }}
        </div>

        <div v-if="emailSuccess" class="bg-green-50 text-green-600 px-4 py-2 rounded-lg">
          {{ emailSuccess }}
        </div>

        <button
          type="submit"
          :disabled="emailLoading"
          class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
        >
          {{ emailLoading ? 'Modification...' : 'Modifier l\'email' }}
        </button>
      </form>
    </div>

    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Modifier le mot de passe</h3>
      <form @submit.prevent="handlePasswordChange" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Mot de passe actuel *</label>
          <input
            v-model="passwordForm.currentPassword"
            type="password"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            placeholder="Votre mot de passe actuel"
          />
          <p class="text-xs text-gray-500 mt-1">Pour des raisons de sécurité, veuillez confirmer votre mot de passe</p>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Nouveau mot de passe *</label>
          <input
            v-model="passwordForm.newPassword"
            type="password"
            required
            minlength="6"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            placeholder="Minimum 6 caractères"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Confirmer le mot de passe *</label>
          <input
            v-model="passwordForm.confirmPassword"
            type="password"
            required
            minlength="6"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            placeholder="Confirmer le mot de passe"
          />
        </div>

        <div v-if="passwordError" class="bg-red-50 text-red-600 px-4 py-2 rounded-lg">
          {{ passwordError }}
        </div>

        <div v-if="passwordSuccess" class="bg-green-50 text-green-600 px-4 py-2 rounded-lg">
          {{ passwordSuccess }}
        </div>

        <button
          type="submit"
          :disabled="passwordLoading"
          class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
        >
          {{ passwordLoading ? 'Modification...' : 'Modifier le mot de passe' }}
        </button>
      </form>
    </div>

    <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-yellow-800">Important</h3>
          <div class="mt-2 text-sm text-yellow-700">
            <p>La modification de l'email nécessitera une confirmation via un lien envoyé à votre nouvelle adresse email.</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { supabase } from '../services/supabase';

const currentEmail = ref('');
const emailLoading = ref(false);
const emailError = ref('');
const emailSuccess = ref('');
const passwordLoading = ref(false);
const passwordError = ref('');
const passwordSuccess = ref('');

const emailForm = ref({
  currentPassword: '',
  newEmail: '',
});

const passwordForm = ref({
  currentPassword: '',
  newPassword: '',
  confirmPassword: '',
});

const loadCurrentUser = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      currentEmail.value = user.email || '';
    }
  } catch (error) {
    console.error('Error loading user:', error);
  }
};

const handleEmailChange = async () => {
  emailError.value = '';
  emailSuccess.value = '';
  emailLoading.value = true;

  try {
    if (!emailForm.value.currentPassword || !emailForm.value.newEmail) {
      emailError.value = 'Veuillez remplir tous les champs';
      return;
    }

    if (emailForm.value.newEmail === currentEmail.value) {
      emailError.value = 'Le nouvel email est identique à l\'email actuel';
      return;
    }

    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: currentEmail.value,
      password: emailForm.value.currentPassword,
    });

    if (signInError) {
      emailError.value = 'Mot de passe actuel incorrect';
      return;
    }

    const { error } = await supabase.auth.updateUser({
      email: emailForm.value.newEmail,
    });

    if (error) throw error;

    emailSuccess.value = 'Un email de confirmation a été envoyé à votre nouvelle adresse. Veuillez vérifier votre boîte de réception.';
    emailForm.value.newEmail = '';
    emailForm.value.currentPassword = '';
  } catch (err: any) {
    console.error('Error updating email:', err);
    emailError.value = err.message || 'Erreur lors de la modification de l\'email';
  } finally {
    emailLoading.value = false;
  }
};

const handlePasswordChange = async () => {
  passwordError.value = '';
  passwordSuccess.value = '';
  passwordLoading.value = true;

  try {
    if (!passwordForm.value.currentPassword || !passwordForm.value.newPassword || !passwordForm.value.confirmPassword) {
      passwordError.value = 'Veuillez remplir tous les champs';
      return;
    }

    if (passwordForm.value.newPassword.length < 6) {
      passwordError.value = 'Le mot de passe doit contenir au moins 6 caractères';
      return;
    }

    if (passwordForm.value.newPassword !== passwordForm.value.confirmPassword) {
      passwordError.value = 'Les mots de passe ne correspondent pas';
      return;
    }

    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: currentEmail.value,
      password: passwordForm.value.currentPassword,
    });

    if (signInError) {
      passwordError.value = 'Mot de passe actuel incorrect';
      return;
    }

    const { error } = await supabase.auth.updateUser({
      password: passwordForm.value.newPassword,
    });

    if (error) throw error;

    passwordSuccess.value = 'Mot de passe modifié avec succès';
    passwordForm.value.currentPassword = '';
    passwordForm.value.newPassword = '';
    passwordForm.value.confirmPassword = '';
  } catch (err: any) {
    console.error('Error updating password:', err);
    passwordError.value = err.message || 'Erreur lors de la modification du mot de passe';
  } finally {
    passwordLoading.value = false;
  }
};

onMounted(() => {
  loadCurrentUser();
});
</script>
