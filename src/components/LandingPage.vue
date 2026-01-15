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
  window.open('https://wa.me/2250708864527', '_blank');
};

const callPhone = () => {
  window.location.href = 'tel:+2250708864527';
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
            <span class="text-2xl font-bold text-white">Ges-<span class="text-green-500">com</span></span>
          </div>

          <!-- Navigation & Auth Buttons -->
          <div class="flex items-center gap-3 md:gap-8">
            <!-- Navigation Desktop -->
            <nav class="hidden md:flex items-center gap-8">
              <a href="#solutions" class="text-gray-300 hover:text-white transition-colors font-medium">Solutions</a>
              <a href="#contact-section" @click.prevent="scrollToContact" class="text-gray-300 hover:text-white transition-colors font-medium">Contact</a>
            </nav>

            <!-- Auth Buttons -->
            <div class="flex items-center gap-2 md:gap-3">
              <button
                @click="emit('navigateToLogin')"
                class="px-3 py-2 md:px-6 md:py-2.5 rounded-lg text-xs md:text-base font-medium text-white border-2 border-blue-500 hover:bg-blue-500 transition-all duration-200"
              >
                Se connecter
              </button>
              <button
                @click="emit('navigateToRegister')"
                class="px-3 py-2 md:px-6 md:py-2.5 rounded-lg text-xs md:text-base font-medium text-white bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 transition-all duration-200 shadow-lg hover:shadow-xl"
              >
                S'inscrire
              </button>
            </div>
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
              Ges-<span class="text-green-500">com</span>
            </h1>

            <p class="text-xl text-gray-300 leading-relaxed">
              La solution moderne complète de suivi des commerciaux pour votre entreprise. Gérez votre entreprise comme un professionnel avec nos outils intelligents.
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
          <div class="relative w-full">
            <div class="relative rounded-xl md:rounded-2xl overflow-hidden shadow-2xl border-2 md:border-4 border-slate-700 bg-white">
              <!-- Dashboard Mockup -->
              <div class="flex h-[400px] sm:h-[500px] md:h-[550px] lg:h-[600px]">
                <!-- Sidebar -->
                <div class="w-16 sm:w-32 md:w-44 lg:w-56 bg-blue-700 text-white p-2 sm:p-3 md:p-4 flex flex-col flex-shrink-0">
                  <!-- Logo/Company -->
                  <div class="flex items-center gap-1 sm:gap-2 md:gap-3 mb-4 sm:mb-6 md:mb-8 bg-blue-800 p-1.5 sm:p-2 md:p-3 rounded-lg">
                    <div class="w-6 h-6 sm:w-8 sm:h-8 md:w-10 md:h-10 bg-white rounded-lg flex items-center justify-center flex-shrink-0">
                      <Icon name="shopping-cart" class="w-3 h-3 sm:w-4 sm:h-4 md:w-6 md:h-6 text-blue-700" />
                    </div>
                    <div class="hidden sm:block">
                      <div class="font-bold text-[10px] sm:text-xs md:text-sm truncate">Ges-<span class="text-green-500">com</span></div>
                      <div class="text-[8px] sm:text-[10px] md:text-xs text-blue-200 truncate">Gestion Pro</div>
                    </div>
                  </div>

                  <!-- Menu Items -->
                  <nav class="space-y-0.5 sm:space-y-1 flex-1">
                    <div class="bg-green-500 text-white px-1.5 sm:px-2 md:px-3 py-1.5 sm:py-2 md:py-2.5 rounded-lg flex items-center gap-1 sm:gap-1.5 md:gap-2 text-[10px] sm:text-xs md:text-sm font-medium">
                      <Icon name="chart-bar" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 flex-shrink-0" />
                      <span class="hidden sm:block truncate">Tableau de bord</span>
                    </div>
                    <div class="text-white/80 hover:text-white px-1.5 sm:px-2 md:px-3 py-1.5 sm:py-2 md:py-2.5 rounded-lg flex items-center gap-1 sm:gap-1.5 md:gap-2 text-[10px] sm:text-xs md:text-sm">
                      <Icon name="document" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 flex-shrink-0" />
                      <span class="hidden sm:block truncate">Rapports</span>
                    </div>
                    <div class="text-white/80 hover:text-white px-1.5 sm:px-2 md:px-3 py-1.5 sm:py-2 md:py-2.5 rounded-lg flex items-center gap-1 sm:gap-1.5 md:gap-2 text-[10px] sm:text-xs md:text-sm">
                      <Icon name="users-group" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 flex-shrink-0" />
                      <span class="hidden sm:block truncate">CRM</span>
                    </div>
                    <div class="text-white/80 hover:text-white px-1.5 sm:px-2 md:px-3 py-1.5 sm:py-2 md:py-2.5 rounded-lg flex items-center gap-1 sm:gap-1.5 md:gap-2 text-[10px] sm:text-xs md:text-sm">
                      <Icon name="shopping-cart" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 flex-shrink-0" />
                      <span class="hidden sm:block truncate">Commandes</span>
                    </div>
                    <div class="text-white/80 hover:text-white px-1.5 sm:px-2 md:px-3 py-1.5 sm:py-2 md:py-2.5 rounded-lg flex items-center gap-1 sm:gap-1.5 md:gap-2 text-[10px] sm:text-xs md:text-sm">
                      <Icon name="package" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 flex-shrink-0" />
                      <span class="hidden sm:block truncate">Stock</span>
                    </div>
                  </nav>
                </div>

                <!-- Main Content -->
                <div class="flex-1 bg-gray-50 overflow-auto min-w-0">
                  <!-- Top Bar -->
                  <div class="bg-white border-b border-gray-200 px-2 sm:px-4 md:px-6 py-2 sm:py-3 md:py-4 flex items-center justify-between">
                    <h1 class="text-sm sm:text-base md:text-lg lg:text-xl font-bold text-gray-800 truncate">Tableau de bord</h1>
                    <div class="flex items-center gap-1 sm:gap-2 md:gap-3 flex-shrink-0">
                      <div class="hidden md:block text-right text-xs md:text-sm">
                        <div class="font-semibold text-gray-800 truncate">Jean-Luc</div>
                        <div class="text-gray-500 text-[10px] md:text-xs truncate">Administrateur</div>
                      </div>
                      <div class="w-7 h-7 sm:w-8 sm:h-8 md:w-10 md:h-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-bold text-xs sm:text-sm md:text-base flex-shrink-0">
                        J
                      </div>
                    </div>
                  </div>

                  <!-- Stats Cards -->
                  <div class="p-2 sm:p-3 md:p-4 lg:p-6">
                    <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-3 lg:grid-cols-5 gap-1.5 sm:gap-2 md:gap-3 mb-3 sm:mb-4 md:mb-6">
                      <!-- Recette du jour -->
                      <div class="bg-gradient-to-br from-emerald-500 to-emerald-600 rounded-lg md:rounded-xl p-2 sm:p-2.5 md:p-3 lg:p-4 text-white shadow-lg">
                        <div class="flex items-center gap-0.5 sm:gap-1 md:gap-2 mb-1 sm:mb-1.5 md:mb-2 lg:mb-3">
                          <Icon name="document" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 lg:w-5 lg:h-5 flex-shrink-0" />
                          <div class="text-[7px] sm:text-[8px] md:text-[9px] lg:text-[10px] font-semibold leading-tight">Recette<br/>du jour</div>
                        </div>
                        <div class="text-sm sm:text-base md:text-lg lg:text-2xl xl:text-3xl font-black mb-0.5 sm:mb-1">487,500</div>
                        <div class="text-[6px] sm:text-[7px] md:text-[8px] lg:text-[10px] font-medium">FCFA<br/>aujourd'hui</div>
                      </div>

                      <!-- CA mensuel -->
                      <div class="bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg md:rounded-xl p-2 sm:p-2.5 md:p-3 lg:p-4 text-white shadow-lg">
                        <div class="flex items-center gap-0.5 sm:gap-1 md:gap-2 mb-1 sm:mb-1.5 md:mb-2 lg:mb-3">
                          <Icon name="chart-bar" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 lg:w-5 lg:h-5 flex-shrink-0" />
                          <div class="text-[7px] sm:text-[8px] md:text-[9px] lg:text-[10px] font-semibold leading-tight">CA<br/>mensuel</div>
                        </div>
                        <div class="text-sm sm:text-base md:text-lg lg:text-2xl xl:text-3xl font-black mb-0.5 sm:mb-1">12.4M</div>
                        <div class="text-[6px] sm:text-[7px] md:text-[8px] lg:text-[10px] font-medium">→ +24%<br/>vs mois dernier</div>
                      </div>

                      <!-- Ventes -->
                      <div class="bg-gradient-to-br from-green-500 to-green-600 rounded-lg md:rounded-xl p-2 sm:p-2.5 md:p-3 lg:p-4 text-white shadow-lg">
                        <div class="flex items-center gap-0.5 sm:gap-1 md:gap-2 mb-1 sm:mb-1.5 md:mb-2 lg:mb-3">
                          <Icon name="shopping-cart" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 lg:w-5 lg:h-5 flex-shrink-0" />
                          <div class="text-[7px] sm:text-[8px] md:text-[9px] lg:text-[10px] font-semibold leading-tight">Ventes</div>
                        </div>
                        <div class="text-sm sm:text-base md:text-lg lg:text-2xl xl:text-3xl font-black mb-0.5 sm:mb-1">847</div>
                        <div class="text-[6px] sm:text-[7px] md:text-[8px] lg:text-[10px] font-medium">→ +18%<br/>vs mois dernier</div>
                      </div>

                      <!-- Clients -->
                      <div class="bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg md:rounded-xl p-2 sm:p-2.5 md:p-3 lg:p-4 text-white shadow-lg col-span-1">
                        <div class="flex items-center gap-0.5 sm:gap-1 md:gap-2 mb-1 sm:mb-1.5 md:mb-2 lg:mb-3">
                          <Icon name="users-group" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 lg:w-5 lg:h-5 flex-shrink-0" />
                          <div class="text-[7px] sm:text-[8px] md:text-[9px] lg:text-[10px] font-semibold leading-tight">Clients</div>
                        </div>
                        <div class="text-sm sm:text-base md:text-lg lg:text-2xl xl:text-3xl font-black mb-0.5 sm:mb-1">324</div>
                        <div class="text-[6px] sm:text-[7px] md:text-[8px] lg:text-[10px] font-medium">clients<br/>actifs</div>
                      </div>

                      <!-- Produits -->
                      <div class="bg-gradient-to-br from-orange-500 to-orange-600 rounded-lg md:rounded-xl p-2 sm:p-2.5 md:p-3 lg:p-4 text-white shadow-lg col-span-1">
                        <div class="flex items-center gap-0.5 sm:gap-1 md:gap-2 mb-1 sm:mb-1.5 md:mb-2 lg:mb-3">
                          <Icon name="package" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 lg:w-5 lg:h-5 flex-shrink-0" />
                          <div class="text-[7px] sm:text-[8px] md:text-[9px] lg:text-[10px] font-semibold leading-tight">Produits</div>
                        </div>
                        <div class="text-sm sm:text-base md:text-lg lg:text-2xl xl:text-3xl font-black mb-0.5 sm:mb-1">1,247</div>
                        <div class="text-[6px] sm:text-[7px] md:text-[8px] lg:text-[10px] font-medium">en<br/>catalogue</div>
                      </div>
                    </div>

                    <!-- Bottom Sections -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-2 sm:gap-3 md:gap-4">
                      <!-- Meilleurs Commerciaux -->
                      <div class="bg-white rounded-lg md:rounded-xl p-2 sm:p-3 md:p-4 lg:p-5 shadow-sm border border-gray-200">
                        <div class="flex items-center justify-between mb-2 sm:mb-3 md:mb-4">
                          <div class="flex items-center gap-1 sm:gap-1.5 md:gap-2">
                            <div class="w-5 h-5 sm:w-6 sm:h-6 md:w-7 md:h-7 lg:w-8 lg:h-8 rounded-lg bg-yellow-100 flex items-center justify-center flex-shrink-0">
                              <Icon name="users" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 lg:w-5 lg:h-5 text-yellow-600" />
                            </div>
                            <div class="min-w-0">
                              <div class="font-bold text-gray-900 text-[9px] sm:text-[10px] md:text-xs lg:text-sm truncate">Meilleurs Commerciaux</div>
                              <div class="text-[7px] sm:text-[8px] md:text-[9px] lg:text-[10px] text-gray-600 truncate">Top 3 du mois</div>
                            </div>
                          </div>
                        </div>
                        <div class="space-y-1.5 sm:space-y-2 md:space-y-3">
                          <div class="flex items-center justify-between gap-2">
                            <div class="flex items-center gap-1 sm:gap-1.5 md:gap-2 min-w-0">
                              <div class="w-5 h-5 sm:w-6 sm:h-6 md:w-7 md:h-7 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-black text-[9px] sm:text-[10px] md:text-xs lg:text-sm flex-shrink-0">1</div>
                              <span class="font-semibold text-gray-800 text-[9px] sm:text-[10px] md:text-xs lg:text-sm truncate">Kouassi A.</span>
                            </div>
                            <span class="font-black text-gray-900 text-[9px] sm:text-[10px] md:text-xs lg:text-sm whitespace-nowrap">3.2M</span>
                          </div>
                          <div class="flex items-center justify-between gap-2">
                            <div class="flex items-center gap-1 sm:gap-1.5 md:gap-2 min-w-0">
                              <div class="w-5 h-5 sm:w-6 sm:h-6 md:w-7 md:h-7 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-black text-[9px] sm:text-[10px] md:text-xs lg:text-sm flex-shrink-0">2</div>
                              <span class="font-semibold text-gray-800 text-[9px] sm:text-[10px] md:text-xs lg:text-sm truncate">Koné S.</span>
                            </div>
                            <span class="font-black text-gray-900 text-[9px] sm:text-[10px] md:text-xs lg:text-sm whitespace-nowrap">2.8M</span>
                          </div>
                          <div class="flex items-center justify-between gap-2">
                            <div class="flex items-center gap-1 sm:gap-1.5 md:gap-2 min-w-0">
                              <div class="w-5 h-5 sm:w-6 sm:h-6 md:w-7 md:h-7 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-black text-[9px] sm:text-[10px] md:text-xs lg:text-sm flex-shrink-0">3</div>
                              <span class="font-semibold text-gray-800 text-[9px] sm:text-[10px] md:text-xs lg:text-sm truncate">Diallo M.</span>
                            </div>
                            <span class="font-black text-gray-900 text-[9px] sm:text-[10px] md:text-xs lg:text-sm whitespace-nowrap">2.1M</span>
                          </div>
                        </div>
                      </div>

                      <!-- Produits les Plus Vendus -->
                      <div class="bg-white rounded-lg md:rounded-xl p-2 sm:p-3 md:p-4 lg:p-5 shadow-sm border border-gray-200">
                        <div class="flex items-center justify-between mb-2 sm:mb-3 md:mb-4">
                          <div class="flex items-center gap-1 sm:gap-1.5 md:gap-2">
                            <div class="w-5 h-5 sm:w-6 sm:h-6 md:w-7 md:h-7 lg:w-8 lg:h-8 rounded-lg bg-blue-100 flex items-center justify-center flex-shrink-0">
                              <Icon name="chart-bar" class="w-3 h-3 sm:w-3.5 sm:h-3.5 md:w-4 md:h-4 lg:w-5 lg:h-5 text-blue-600" />
                            </div>
                            <div class="min-w-0">
                              <div class="font-bold text-gray-900 text-[9px] sm:text-[10px] md:text-xs lg:text-sm truncate">Produits Plus Vendus</div>
                              <div class="text-[7px] sm:text-[8px] md:text-[9px] lg:text-[10px] text-gray-600 truncate">Top 5</div>
                            </div>
                          </div>
                        </div>
                        <div class="space-y-1.5 sm:space-y-2 md:space-y-2.5">
                          <div class="flex items-center justify-between gap-2">
                            <span class="font-semibold text-gray-800 text-[8px] sm:text-[9px] md:text-[10px] lg:text-xs truncate">Cahier 200 pages</span>
                            <span class="font-black text-gray-900 text-[9px] sm:text-[10px] md:text-xs lg:text-sm whitespace-nowrap">847</span>
                          </div>
                          <div class="flex items-center justify-between gap-2">
                            <span class="font-semibold text-gray-800 text-[8px] sm:text-[9px] md:text-[10px] lg:text-xs truncate">Stylo BIC bleu</span>
                            <span class="font-black text-gray-900 text-[9px] sm:text-[10px] md:text-xs lg:text-sm whitespace-nowrap">612</span>
                          </div>
                          <div class="flex items-center justify-between gap-2">
                            <span class="font-semibold text-gray-800 text-[8px] sm:text-[9px] md:text-[10px] lg:text-xs truncate">Classeur A4</span>
                            <span class="font-black text-gray-900 text-[9px] sm:text-[10px] md:text-xs lg:text-sm whitespace-nowrap">423</span>
                          </div>
                          <div class="flex items-center justify-between gap-2">
                            <span class="font-semibold text-gray-800 text-[8px] sm:text-[9px] md:text-[10px] lg:text-xs truncate">Ramette papier</span>
                            <span class="font-black text-gray-900 text-[9px] sm:text-[10px] md:text-xs lg:text-sm whitespace-nowrap">298</span>
                          </div>
                          <div class="flex items-center justify-between gap-2">
                            <span class="font-semibold text-gray-800 text-[8px] sm:text-[9px] md:text-[10px] lg:text-xs truncate">Marqueur tableau</span>
                            <span class="font-black text-gray-900 text-[9px] sm:text-[10px] md:text-xs lg:text-sm whitespace-nowrap">276</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Floating elements -->
            <div class="absolute -top-4 -left-4 md:-top-6 md:-left-6 w-16 h-16 md:w-24 md:h-24 bg-blue-500/20 rounded-full blur-2xl"></div>
            <div class="absolute -bottom-4 -right-4 md:-bottom-6 md:-right-6 w-20 h-20 md:w-32 md:h-32 bg-emerald-500/20 rounded-full blur-2xl"></div>
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
            <h2 class="text-4xl font-bold text-white mb-4 whitespace-nowrap">
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
            <span class="text-xl font-bold text-white">Ges-<span class="text-green-500">com</span></span>
          </div>

          <div class="text-gray-400 text-sm">
            © 2025 Ges-<span class="text-green-500">com</span>. Tous droits réservés.
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
