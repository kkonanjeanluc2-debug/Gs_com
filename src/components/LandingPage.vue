<script setup lang="ts">
import Icon from './Icon.vue';

const emit = defineEmits<{
  navigateToLogin: [];
  navigateToRegister: [];
}>();

const features = [
  {
    icon: 'chart-bar',
    title: 'Tableau de bord intelligent',
    description: 'Visualisez vos performances en temps réel avec des graphiques et indicateurs clés'
  },
  {
    icon: 'package',
    title: 'Gestion du stock',
    description: 'Gérez votre inventaire facilement avec import Excel et suivi des mouvements'
  },
  {
    icon: 'users',
    title: 'CRM complet',
    description: 'Gérez vos clients et prospects avec géolocalisation et suivi WhatsApp'
  },
  {
    icon: 'shopping-cart',
    title: 'Gestion des commandes',
    description: 'Créez et suivez vos commandes avec génération automatique de factures'
  },
  {
    icon: 'document',
    title: 'Rapports d\'activité',
    description: 'Créez et envoyez vos rapports quotidiens directement sur WhatsApp'
  },
  {
    icon: 'users-group',
    title: 'Multi-utilisateurs',
    description: 'Gérez votre équipe commerciale avec rôles et permissions'
  }
];

const scrollToContact = () => {
  const contactSection = document.getElementById('contact-section');
  if (contactSection) {
    contactSection.scrollIntoView({ behavior: 'smooth' });
  }
};

const openWhatsApp = () => {
  window.open('https://wa.me/22507088645227', '_blank');
};

const callPhone = () => {
  window.location.href = 'tel:+22507088645227';
};
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
    <!-- Header -->
    <header class="fixed top-0 left-0 right-0 z-50 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
      <div class="container mx-auto px-4">
        <div class="flex items-center justify-between h-20">
          <!-- Logo -->
          <div class="flex items-center gap-3">
            <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg">
              <Icon name="shopping-cart" class="w-7 h-7 text-white" />
            </div>
            <span class="text-2xl font-bold text-white">Ges-com</span>
          </div>

          <!-- Navigation Desktop -->
          <nav class="hidden md:flex items-center gap-8">
            <a href="#solutions" class="text-gray-300 hover:text-white transition-colors font-medium">Solutions</a>
            <a href="#contact-section" @click.prevent="scrollToContact" class="text-gray-300 hover:text-white transition-colors font-medium">Contact</a>
          </nav>

          <!-- Auth Buttons -->
          <div class="flex items-center gap-3">
            <button
              @click="emit('navigateToLogin')"
              class="px-6 py-2.5 rounded-lg font-medium text-white border-2 border-blue-500 hover:bg-blue-500 transition-all duration-200"
            >
              Se connecter
            </button>
            <button
              @click="emit('navigateToRegister')"
              class="px-6 py-2.5 rounded-lg font-medium text-white bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 transition-all duration-200 shadow-lg hover:shadow-xl"
            >
              S'inscrire
            </button>
          </div>
        </div>
      </div>
    </header>

    <!-- Hero Section -->
    <section id="accueil" class="pt-32 pb-20 px-4">
      <div class="container mx-auto">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <!-- Left Content -->
          <div class="text-white space-y-8">
            <h1 class="text-5xl md:text-6xl font-bold leading-tight">
              Ges-com
            </h1>

            <p class="text-xl text-gray-300 leading-relaxed">
              La solution complète de suivi des commerciaux moderne pour votre entreprise. Gérez votre entreprise comme un professionnel avec nos outils intelligents.
            </p>

            <!-- Contact Buttons -->
            <div class="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
              <button
                @click="callPhone"
                class="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-xl font-semibold text-white bg-blue-600 hover:bg-blue-700 transition-all duration-200 shadow-lg hover:shadow-xl"
              >
                <Icon name="phone" class="w-5 h-5" />
                <span>Appelez-nous : 07 08 86 45 27</span>
              </button>

              <button
                @click="openWhatsApp"
                class="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-xl font-semibold text-white bg-emerald-600 hover:bg-emerald-700 transition-all duration-200 shadow-lg hover:shadow-xl"
              >
                <Icon name="phone" class="w-5 h-5" />
                <span>WhatsApp</span>
              </button>
            </div>
          </div>

          <!-- Right Image/Dashboard Preview -->
          <div class="relative">
            <div class="relative rounded-2xl overflow-hidden shadow-2xl border-4 border-slate-700 bg-slate-800">
              <img
                src="/image copy copy copy copy copy copy.png"
                alt="Dashboard Ges-com"
                class="w-full h-auto"
              />
            </div>

            <!-- Floating elements -->
            <div class="absolute -top-6 -left-6 w-24 h-24 bg-blue-500/20 rounded-full blur-2xl"></div>
            <div class="absolute -bottom-6 -right-6 w-32 h-32 bg-emerald-500/20 rounded-full blur-2xl"></div>
          </div>
        </div>
      </div>
    </section>

    <!-- Features Section -->
    <section id="solutions" class="py-20 px-4 bg-slate-800/50">
      <div class="container mx-auto">
        <div class="text-center mb-16">
          <h2 class="text-4xl font-bold text-white mb-4">
            Fonctionnalités puissantes
          </h2>
          <p class="text-xl text-gray-400">
            Tout ce dont vous avez besoin pour gérer votre business efficacement
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <div
            v-for="feature in features"
            :key="feature.title"
            class="bg-slate-800/80 rounded-2xl p-8 border border-slate-700 hover:border-blue-500/50 transition-all duration-300 hover:shadow-xl hover:shadow-blue-500/10"
          >
            <div class="w-14 h-14 rounded-xl bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg mb-6">
              <Icon :name="feature.icon" class="w-7 h-7 text-white" />
            </div>
            <h3 class="text-xl font-bold text-white mb-3">{{ feature.title }}</h3>
            <p class="text-gray-400 leading-relaxed">{{ feature.description }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Contact Section -->
    <section id="contact-section" class="py-20 px-4">
      <div class="container mx-auto max-w-4xl">
        <div class="bg-gradient-to-br from-slate-800 to-slate-900 rounded-3xl p-12 border border-slate-700 shadow-2xl">
          <div class="text-center mb-12">
            <h2 class="text-4xl font-bold text-white mb-4">
              Contactez-nous
            </h2>
            <p class="text-xl text-gray-400">
              Notre équipe est là pour répondre à toutes vos questions
            </p>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <button
              @click="callPhone"
              class="flex flex-col items-center gap-4 p-6 rounded-xl bg-slate-700/50 border border-slate-600 hover:border-blue-500 transition-all duration-200 group"
            >
              <div class="w-16 h-16 rounded-full bg-blue-500/20 flex items-center justify-center group-hover:bg-blue-500 transition-all duration-200">
                <Icon name="phone" class="w-8 h-8 text-blue-400 group-hover:text-white transition-all duration-200" />
              </div>
              <div class="text-center">
                <div class="text-sm text-gray-400 mb-1">Téléphone</div>
                <div class="text-white font-semibold">07 08 86 45 27</div>
              </div>
            </button>

            <button
              @click="openWhatsApp"
              class="flex flex-col items-center gap-4 p-6 rounded-xl bg-slate-700/50 border border-slate-600 hover:border-emerald-500 transition-all duration-200 group"
            >
              <div class="w-16 h-16 rounded-full bg-emerald-500/20 flex items-center justify-center group-hover:bg-emerald-500 transition-all duration-200">
                <Icon name="phone" class="w-8 h-8 text-emerald-400 group-hover:text-white transition-all duration-200" />
              </div>
              <div class="text-center">
                <div class="text-sm text-gray-400 mb-1">WhatsApp</div>
                <div class="text-white font-semibold">07 08 86 45 27</div>
              </div>
            </button>
          </div>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="py-12 px-4 bg-slate-900/80 border-t border-slate-800">
      <div class="container mx-auto">
        <div class="flex flex-col md:flex-row justify-between items-center gap-6">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg">
              <Icon name="shopping-cart" class="w-6 h-6 text-white" />
            </div>
            <span class="text-xl font-bold text-white">Ges-com</span>
          </div>

          <div class="text-gray-400 text-sm">
            © 2025 Ges-com. Tous droits réservés.
          </div>

          <div class="flex gap-4">
            <button
              @click="openWhatsApp"
              class="w-10 h-10 rounded-lg bg-slate-800 border border-slate-700 flex items-center justify-center hover:border-emerald-500 transition-colors"
            >
              <Icon name="phone" class="w-5 h-5 text-emerald-400" />
            </button>
          </div>
        </div>
      </div>
    </footer>
  </div>
</template>
