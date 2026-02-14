<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Gestion des Ventes</h2>
        <p class="text-sm text-gray-500 mt-1">Enregistrez et consultez l'historique des ventes</p>
      </div>
      <div class="flex gap-2">
        <button
          @click="showPendingSalesModal = true"
          class="bg-amber-600 text-white px-2 md:px-4 py-2 rounded-lg hover:bg-amber-700 transition-colors flex items-center gap-1 md:gap-2"
        >
          <span>⏱️</span>
          <span class="hidden md:inline">Ventes en attente</span>
          <span>({{ pendingSales.length }})</span>
        </button>
        <button
          @click="openNewSaleForm"
          class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >
          <span class="hidden md:inline">Nouvelle Vente</span>
          <span class="md:hidden">+</span>
        </button>
      </div>
    </div>

    <div class="bg-white rounded-lg shadow p-4">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Date début</label>
          <input
            v-model="filters.startDate"
            type="date"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadSales"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Date fin</label>
          <input
            v-model="filters.endDate"
            type="date"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadSales"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Client</label>
          <select
            v-model="filters.clientId"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadSales"
          >
            <option value="">Tous les clients</option>
            <option v-for="client in clients" :key="client.id" :value="client.id">
              {{ client.name }}
            </option>
          </select>
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Produit</label>
          <select
            v-model="filters.productId"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            @change="loadSales"
          >
            <option value="">Tous les produits</option>
            <option v-for="product in products" :key="product.id" :value="product.id">
              {{ product.name }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Total des ventes</p>
            <p class="text-2xl font-bold text-gray-900">{{ stats.total_sales }}</p>
          </div>
          <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">📊</span>
          </div>
        </div>
      </div>
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Chiffre d'affaires</p>
            <p class="text-2xl font-bold text-green-600">{{ stats.total_revenue.toLocaleString('fr-FR') }} F</p>
          </div>
          <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">💰</span>
          </div>
        </div>
      </div>
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-gray-600">Ventes payées</p>
            <p class="text-2xl font-bold text-gray-900">{{ stats.paid_sales }}</p>
          </div>
          <div class="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center">
            <span class="text-2xl">✅</span>
          </div>
        </div>
      </div>
    </div>

    <div v-if="showForm" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-2 md:p-4">
      <div class="bg-gray-100 rounded-lg w-full max-w-7xl h-[100vh] md:h-[90vh] flex flex-col">
        <div class="bg-white px-4 md:px-6 py-3 md:py-4 rounded-t-lg border-b border-gray-200">
          <div class="flex justify-between items-center">
            <div>
              <h3 class="text-lg md:text-xl font-bold text-gray-800">
                {{ currentPendingSaleId ? 'Modifier la vente en attente' : 'Nouvelle Vente' }}
              </h3>
              <p v-if="currentPendingSaleId" class="text-xs text-amber-600 mt-1">
                Mode modification - Cette vente sera mise à jour
              </p>
              <p v-else class="text-xs text-blue-600 mt-1">
                Mode création - Nouvelle vente
              </p>
            </div>
            <button @click="closeForm" class="text-gray-500 hover:text-gray-700 text-2xl">×</button>
          </div>

          <div class="md:hidden flex gap-2 mt-3">
            <button
              @click="mobileTab = 'form'"
              :class="[
                'flex-1 py-2 px-4 rounded-lg font-medium text-sm transition-colors',
                mobileTab === 'form'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-200 text-gray-700'
              ]"
            >
              Formulaire ({{ formData.items.length }})
            </button>
            <button
              @click="mobileTab = 'products'"
              :class="[
                'flex-1 py-2 px-4 rounded-lg font-medium text-sm transition-colors',
                mobileTab === 'products'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-200 text-gray-700'
              ]"
            >
              Produits
            </button>
          </div>
        </div>

        <div class="flex-1 overflow-hidden flex">
          <div
            :class="[
              'w-full md:w-2/5 bg-white p-4 md:p-6 overflow-y-auto md:border-r border-gray-200',
              mobileTab === 'form' ? 'block' : 'hidden md:block'
            ]"
          >
            <form @submit.prevent="handleSubmit" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Client</label>
                <select
                  v-model="formData.client_id"
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Sélectionner un client</option>
                  <option v-for="client in clients" :key="client.id" :value="client.id">
                    {{ client.name }} {{ client.phone ? '/ ' + client.phone : '' }}
                  </option>
                </select>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Dépôt de stockage</label>
                <select
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                >
                  <option>DEPOT PRINCIPAL</option>
                </select>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Commentaire</label>
                <textarea
                  v-model="formData.notes"
                  rows="2"
                  class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  placeholder="Commentaire..."
                ></textarea>
              </div>

              <div class="border-t pt-4">
                <table class="w-full text-sm">
                  <thead>
                    <tr class="border-b">
                      <th class="text-left py-2 px-1">Nom d'article</th>
                      <th class="text-center py-2 px-1 w-16">Qté</th>
                      <th class="text-center py-2 px-1 w-16">T remise</th>
                      <th class="text-right py-2 px-1 w-20">PU TTC</th>
                      <th class="text-right py-2 px-1 w-20">Total</th>
                      <th class="w-8"></th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(item, index) in formData.items" :key="index" class="border-b">
                      <td class="py-2 px-1">
                        <div v-if="item.product_id" class="text-xs font-medium truncate">
                          {{ products.find(p => p.id === item.product_id)?.name }}
                        </div>
                        <div v-else class="text-xs text-gray-400">-</div>
                      </td>
                      <td class="py-2 px-1 text-center">
                        <input
                          v-model.number="item.quantity"
                          type="number"
                          min="1"
                          class="w-full px-1 py-1 text-center border border-gray-300 rounded text-xs"
                        />
                      </td>
                      <td class="py-2 px-1 text-center">
                        <input
                          v-model.number="item.discount_percentage"
                          type="number"
                          min="0"
                          max="100"
                          class="w-full px-1 py-1 text-center border border-gray-300 rounded text-xs"
                        />
                      </td>
                      <td class="py-2 px-1 text-right">
                        <span class="text-xs">{{ item.unit_price.toLocaleString('fr-FR') }}</span>
                      </td>
                      <td class="py-2 px-1 text-right">
                        <span class="text-xs font-semibold">{{ calculateItemSubtotal(item).toLocaleString('fr-FR') }}</span>
                      </td>
                      <td class="py-2 px-1 text-center">
                        <button
                          v-if="formData.items.length > 1"
                          type="button"
                          @click="removeProduct(index)"
                          class="text-red-600 hover:text-red-800 text-xs"
                        >
                          ✕
                        </button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div class="space-y-2 border-t pt-4">
                <div class="bg-green-600 text-white px-4 py-3 rounded flex justify-between items-center">
                  <span class="font-semibold">MONTANT DE LA FACTURE</span>
                  <span class="text-xl font-bold">{{ calculateFinalAmount().toLocaleString('fr-FR') }}</span>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Mode de paiement</label>
                  <select
                    v-model="formData.payment_method"
                    required
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Sélectionner</option>
                    <option value="especes">Espèces</option>
                    <option value="mobile_money">Mobile Money</option>
                    <option value="virement">Virement</option>
                    <option value="cheque">Chèque</option>
                    <option value="carte_bancaire">Carte bancaire</option>
                    <option value="wave">Wave</option>
                    <option value="orange_money">Orange Money</option>
                    <option value="mtn_money">MTN Money</option>
                    <option value="moov_money">Moov Money</option>
                  </select>
                </div>

                <div v-if="formData.payment_method === 'especes'" class="space-y-2">
                  <div class="bg-gray-200 px-4 py-2 rounded flex justify-between items-center">
                    <span class="text-sm font-medium">ESPECE CLIENT</span>
                    <input
                      v-model.number="cashReceived"
                      type="number"
                      min="0"
                      step="0.01"
                      class="w-32 px-2 py-1 border border-gray-300 rounded text-right"
                    />
                  </div>

                  <div class="bg-amber-600 text-white px-4 py-2 rounded flex justify-between items-center">
                    <span class="text-sm font-medium">MONNAIE CLIENT</span>
                    <span class="text-lg font-bold">{{ calculateChange().toLocaleString('fr-FR') }}</span>
                  </div>
                </div>
              </div>

              <div v-if="error" class="bg-red-50 text-red-600 px-4 py-2 rounded-lg text-sm">
                {{ error }}
              </div>

              <div class="flex gap-2 justify-end pt-4">
                <button
                  type="button"
                  @click="closeForm"
                  class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  @click="savePendingSale"
                  class="px-4 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700 flex items-center gap-2"
                >
                  <span>⏱️</span>
                  <span v-if="currentPendingSaleId">Mettre à jour</span>
                  <span v-else>Mettre en attente</span>
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Enregistrer la vente
                </button>
              </div>
            </form>
          </div>

          <div
            :class="[
              'w-full md:w-3/5 bg-white p-4 md:p-6 overflow-y-auto',
              mobileTab === 'products' ? 'block' : 'hidden md:block'
            ]"
          >
            <div class="mb-4">
              <h4 class="text-base md:text-lg font-bold text-gray-800 mb-3">Produits</h4>
              <input
                v-model="productSearchText"
                type="text"
                placeholder="Code barre ou désignation"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div class="grid grid-cols-2 md:grid-cols-3 gap-3 md:gap-4">
              <div
                v-for="product in filteredProducts"
                :key="product.id"
                @click="addProductToSale(product)"
                class="border border-gray-200 rounded-lg p-3 cursor-pointer hover:border-blue-500 hover:shadow-md transition-all"
                :class="{
                  'opacity-50 cursor-not-allowed': product.stock_quantity <= 0
                }"
              >
                <div class="aspect-square bg-gray-100 rounded-lg mb-2 flex items-center justify-center overflow-hidden">
                  <img
                    v-if="product.image_url"
                    :src="product.image_url"
                    :alt="product.name"
                    class="w-full h-full object-cover"
                  />
                  <span v-else class="text-4xl text-gray-400">📦</span>
                </div>
                <div class="text-center">
                  <p class="text-red-600 font-bold text-lg mb-1">
                    {{ product.price.toLocaleString('fr-FR') }}.0
                  </p>
                  <p class="text-xs text-gray-700 font-medium mb-2 truncate" :title="product.name">
                    {{ product.name }}
                  </p>
                  <div
                    v-if="product.stock_quantity > 0"
                    class="text-xs px-2 py-1 rounded"
                    :class="{
                      'bg-green-100 text-green-800': product.stock_quantity >= 10,
                      'bg-yellow-100 text-yellow-800': product.stock_quantity < 10 && product.stock_quantity > 0
                    }"
                  >
                    Disponible {{ product.stock_quantity.toFixed(2) }}
                  </div>
                  <div v-else class="text-xs px-2 py-1 rounded bg-red-100 text-red-800">
                    Rupture de stock
                  </div>
                </div>
              </div>
            </div>

            <div v-if="filteredProducts.length === 0" class="text-center py-12 text-gray-500">
              Aucun produit trouvé
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-if="sales.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">Aucune vente enregistrée</p>
    </div>

    <div v-else class="bg-white rounded-lg shadow overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">N° Vente</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Client</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Commercial</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Montant</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Paiement</th>
            <th class="px-4 md:px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
            <th class="px-4 md:px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr v-for="sale in sales" :key="sale.id">
            <td class="px-4 md:px-6 py-4 whitespace-nowrap font-medium text-sm">{{ sale.sale_number }}</td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-900">{{ sale.client?.name }}</div>
            </td>
            <td class="px-4 md:px-6 py-4 text-sm whitespace-nowrap">{{ sale.commercial?.full_name }}</td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <div class="text-sm">{{ sale.total_amount }} F CFA</div>
              <div v-if="sale.discount_amount > 0" class="text-xs text-red-600">-{{ sale.discount_amount }} F</div>
              <div class="text-sm font-semibold text-green-600">{{ sale.final_amount }} F CFA</div>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap">
              <span
                :class="['text-xs px-2 py-1 rounded-full', getPaymentStatusColor(sale.payment_status)]"
              >
                {{ getPaymentStatusLabel(sale.payment_status) }}
              </span>
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap text-xs md:text-sm text-gray-500">
              {{ new Date(sale.created_at!).toLocaleDateString('fr-FR') }}
            </td>
            <td class="px-4 md:px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
              <div class="flex items-center justify-end gap-2">
                <button
                  @click="viewSaleDetails(sale)"
                  class="text-green-600 hover:text-green-900 p-1"
                  title="Détails"
                >
                  👁️
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="selectedSale" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-start mb-4">
          <h3 class="text-xl font-bold">Détails de la vente {{ selectedSale.sale_number }}</h3>
          <button @click="selectedSale = null" class="text-gray-500 hover:text-gray-700 text-2xl">×</button>
        </div>

        <div class="grid grid-cols-2 gap-6 mb-6">
          <div>
            <h4 class="font-semibold mb-2">Client</h4>
            <p class="text-sm">{{ selectedSale.client?.name }}</p>
            <p v-if="selectedSale.client?.email" class="text-sm text-gray-600">{{ selectedSale.client.email }}</p>
            <p v-if="selectedSale.client?.phone" class="text-sm text-gray-600">{{ selectedSale.client.phone }}</p>
          </div>
          <div>
            <h4 class="font-semibold mb-2">Commercial</h4>
            <p class="text-sm">{{ selectedSale.commercial?.full_name }}</p>
            <p class="text-sm text-gray-600">{{ selectedSale.commercial?.email }}</p>
          </div>
        </div>

        <div class="mb-6">
          <h4 class="font-semibold mb-2">Articles</h4>
          <table class="min-w-full">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-2 text-left text-sm">Produit</th>
                <th class="px-4 py-2 text-center text-sm">Quantité</th>
                <th class="px-4 py-2 text-right text-sm">Prix unitaire</th>
                <th class="px-4 py-2 text-right text-sm">Remise</th>
                <th class="px-4 py-2 text-right text-sm">Sous-total</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in selectedSale.sale_items" :key="item.id" class="border-t">
                <td class="px-4 py-2">{{ item.product?.name }}</td>
                <td class="px-4 py-2 text-center">{{ item.quantity }}</td>
                <td class="px-4 py-2 text-right">{{ item.unit_price }} F CFA</td>
                <td class="px-4 py-2 text-right">{{ item.discount_percentage }}%</td>
                <td class="px-4 py-2 text-right font-semibold">{{ item.subtotal }} F CFA</td>
              </tr>
            </tbody>
            <tfoot class="border-t-2">
              <tr>
                <td colspan="4" class="px-4 py-2 text-right font-semibold">Total:</td>
                <td class="px-4 py-2 text-right font-bold text-lg">{{ selectedSale.final_amount }} F CFA</td>
              </tr>
            </tfoot>
          </table>
        </div>

        <div class="flex gap-2 justify-end">
          <button
            @click="selectedSale = null"
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            Fermer
          </button>
        </div>
      </div>
    </div>

    <div v-if="showPendingSalesModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-start mb-4">
          <h3 class="text-xl font-bold">Ventes en attente</h3>
          <button @click="showPendingSalesModal = false" class="text-gray-500 hover:text-gray-700 text-2xl">×</button>
        </div>

        <div v-if="pendingSales.length === 0" class="text-center py-12 text-gray-500">
          Aucune vente en attente
        </div>

        <div v-else class="space-y-4">
          <div
            v-for="pendingSale in pendingSales"
            :key="pendingSale.id"
            class="border border-gray-200 rounded-lg p-4 hover:border-blue-500 transition-colors"
          >
            <div class="flex justify-between items-start mb-2">
              <div>
                <h4 class="font-semibold text-gray-900">{{ pendingSale.name }}</h4>
                <p class="text-sm text-gray-600">
                  Client: {{ pendingSale.client?.name || 'Non spécifié' }}
                </p>
                <p class="text-xs text-gray-500">
                  Créé le {{ new Date(pendingSale.created_at!).toLocaleString('fr-FR') }}
                </p>
              </div>
              <div class="flex gap-2">
                <button
                  @click="restorePendingSale(pendingSale)"
                  class="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 text-sm"
                  title="Restaurer"
                >
                  Restaurer
                </button>
                <button
                  @click="deletePendingSaleById(pendingSale.id!)"
                  class="px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700 text-sm"
                  title="Supprimer"
                >
                  Supprimer
                </button>
              </div>
            </div>
            <div class="text-sm text-gray-700 mt-2">
              <span class="font-medium">Articles:</span> {{ pendingSale.sale_data.items?.length || 0 }}
              <span class="ml-4 font-medium">Montant:</span>
              {{ calculatePendingSaleTotal(pendingSale).toLocaleString('fr-FR') }} F CFA
            </div>
          </div>
        </div>

        <div class="flex justify-end mt-6">
          <button
            @click="showPendingSalesModal = false"
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            Fermer
          </button>
        </div>
      </div>
    </div>

    <div v-if="showPrintModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-md w-full">
        <div class="text-center mb-6">
          <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <span class="text-4xl">✓</span>
          </div>
          <h3 class="text-xl font-bold text-gray-900 mb-2">Vente enregistrée avec succès</h3>
          <p class="text-sm text-gray-600">Choisissez le format d'impression du reçu</p>
        </div>

        <div class="space-y-3">
          <button
            @click="printA4"
            class="w-full flex items-center justify-center gap-3 px-6 py-4 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <span class="text-2xl">📄</span>
            <div class="text-left">
              <div class="font-semibold">Imprimer en A4</div>
              <div class="text-xs text-blue-100">Format standard (210 x 297 mm)</div>
            </div>
          </button>

          <button
            @click="printTicket"
            class="w-full flex items-center justify-center gap-3 px-6 py-4 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
          >
            <span class="text-2xl">🧾</span>
            <div class="text-left">
              <div class="font-semibold">Imprimer ticket de caisse</div>
              <div class="text-xs text-green-100">Format ticket (80 mm)</div>
            </div>
          </button>

          <button
            @click="closePrintModal"
            class="w-full px-6 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors text-gray-700"
          >
            Ne pas imprimer
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { salesService, type Sale, type CreateSaleData } from '../services/sales.service';
import { clientsService, type Client } from '../services/clients.service';
import { productsService, type Product } from '../services/products.service';
import { pendingSalesService, type PendingSale } from '../services/pending-sales.service';
import { saleReceiptService } from '../services/sale-receipt.service';
import { companyService, type CompanySettings } from '../services/company.service';

interface SaleItemForm {
  product_id: string;
  quantity: number;
  unit_price: number;
  discount_percentage: number;
}

interface SaleFormData {
  client_id: string;
  items: SaleItemForm[];
  payment_method: 'especes' | 'mobile_money' | 'virement' | 'cheque' | 'carte_bancaire' | 'wave' | 'orange_money' | 'mtn_money' | 'moov_money' | '';
  payment_status: 'paye' | 'en_attente' | 'partiellement_paye';
  notes?: string;
}

const sales = ref<Sale[]>([]);
const clients = ref<Client[]>([]);
const products = ref<Product[]>([]);
const showForm = ref(false);
const error = ref('');
const selectedSale = ref<Sale | null>(null);
const productSearchText = ref('');
const cashReceived = ref(0);
const counterClient = ref<Client | null>(null);
const mobileTab = ref<'form' | 'products'>('products');
const pendingSales = ref<PendingSale[]>([]);
const showPendingSalesModal = ref(false);
const currentPendingSaleId = ref<string | null>(null);
const showPrintModal = ref(false);
const lastCreatedSale = ref<Sale | null>(null);
const company = ref<CompanySettings | null>(null);

const stats = ref({
  total_sales: 0,
  total_revenue: 0,
  paid_sales: 0,
  pending_sales: 0,
});

const filters = ref({
  startDate: '',
  endDate: '',
  clientId: '',
  productId: '',
});

const formData = ref<SaleFormData>({
  client_id: '',
  items: [],
  payment_method: 'especes',
  payment_status: 'paye',
  notes: '',
});

const filteredProducts = computed(() => {
  const search = productSearchText.value.toLowerCase();
  if (!search) return products.value;

  return products.value.filter(p =>
    p.name.toLowerCase().includes(search) ||
    p.sku?.toLowerCase().includes(search)
  );
});

const loadSales = async () => {
  try {
    const filterParams: any = {};
    if (filters.value.startDate) filterParams.startDate = filters.value.startDate;
    if (filters.value.endDate) filterParams.endDate = filters.value.endDate;
    if (filters.value.clientId) filterParams.clientId = filters.value.clientId;
    if (filters.value.productId) filterParams.productId = filters.value.productId;

    sales.value = await salesService.getSales(filterParams);
    await loadStats();
  } catch (err) {
    console.error('Error loading sales:', err);
  }
};

const loadStats = async () => {
  try {
    const statsData = await salesService.getSalesStats(filters.value.startDate, filters.value.endDate);
    stats.value = statsData;
  } catch (err) {
    console.error('Error loading stats:', err);
  }
};

const loadClients = async () => {
  try {
    const allClients = await clientsService.getAllClients();
    clients.value = allClients;
    counterClient.value = allClients.find(c => c.name === 'Client comptoir') || null;
  } catch (err) {
    console.error('Error loading clients:', err);
  }
};

const loadProducts = async () => {
  try {
    products.value = await productsService.getAllProducts();
  } catch (err) {
    console.error('Error loading products:', err);
  }
};

const openNewSaleForm = () => {
  console.log('=== openNewSaleForm ===');
  console.log('currentPendingSaleId avant reset:', currentPendingSaleId.value);
  showForm.value = true;
  mobileTab.value = 'products';
  currentPendingSaleId.value = null;
  formData.value = {
    client_id: counterClient.value?.id || '',
    items: [],
    payment_method: 'especes',
    payment_status: 'paye',
    notes: '',
  };
  productSearchText.value = '';
  error.value = '';
  console.log('currentPendingSaleId après reset:', currentPendingSaleId.value);
  console.log('Nouveau formulaire de vente ouvert (panier vide)');
};

const addProductToSale = (product: Product) => {
  if (product.stock_quantity <= 0) {
    error.value = `${product.name} est en rupture de stock`;
    return;
  }

  const existingItemIndex = formData.value.items.findIndex(item => item.product_id === product.id);

  if (existingItemIndex >= 0) {
    const item = formData.value.items[existingItemIndex];
    if (item.quantity < product.stock_quantity) {
      item.quantity++;
    } else {
      error.value = `Stock insuffisant pour ${product.name}`;
      setTimeout(() => error.value = '', 3000);
    }
  } else {
    formData.value.items.push({
      product_id: product.id!,
      quantity: 1,
      unit_price: product.price,
      discount_percentage: 0,
    });
  }

  if (window.innerWidth < 768) {
    mobileTab.value = 'form';
  }

  error.value = '';
};

const removeProduct = (index: number) => {
  formData.value.items.splice(index, 1);
};

const calculateItemSubtotal = (item: SaleItemForm) => {
  const total = item.quantity * item.unit_price;
  const discount = (total * item.discount_percentage) / 100;
  return total - discount;
};

const calculateFinalAmount = () => {
  return formData.value.items
    .reduce((sum, item) => {
      const total = item.quantity * item.unit_price;
      const discount = (total * item.discount_percentage) / 100;
      return sum + (total - discount);
    }, 0);
};

const calculateChange = () => {
  const total = calculateFinalAmount();
  return Math.max(0, cashReceived.value - total);
};

const handleSubmit = async () => {
  error.value = '';

  if (formData.value.items.length === 0) {
    error.value = 'Ajoutez au moins un produit';
    return;
  }

  if (!formData.value.payment_method) {
    error.value = 'Sélectionnez un mode de paiement';
    return;
  }

  for (const item of formData.value.items) {
    const product = products.value.find(p => p.id === item.product_id);

    if (!product) {
      error.value = 'Produit introuvable';
      return;
    }

    if (product.stock_quantity <= 0) {
      error.value = `${product.name} est en rupture de stock`;
      return;
    }

    if (item.quantity > product.stock_quantity) {
      error.value = `Quantité demandée (${item.quantity}) supérieure au stock disponible pour ${product.name} (${product.stock_quantity})`;
      return;
    }
  }

  try {
    const saleData: CreateSaleData = {
      client_id: formData.value.client_id,
      items: formData.value.items.map(item => ({
        product_id: item.product_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
        discount_percentage: item.discount_percentage,
      })),
      payment_method: formData.value.payment_method as any,
      payment_status: formData.value.payment_status,
      notes: formData.value.notes,
    };

    const createdSale = await salesService.createSale(saleData);

    if (currentPendingSaleId.value) {
      await pendingSalesService.deletePendingSale(currentPendingSaleId.value);
      await loadPendingSales();
    }

    await loadSales();
    await loadProducts();

    if (createdSale) {
      lastCreatedSale.value = sales.value.find(s => s.id === createdSale.id) || createdSale;
      closeForm();
      showPrintModal.value = true;
    } else {
      closeForm();
      alert('Vente enregistrée avec succès');
    }
  } catch (err: any) {
    console.error('Error creating sale:', err);
    error.value = err.message || 'Erreur lors de l\'enregistrement de la vente';
  }
};

const closeForm = () => {
  console.log('=== closeForm ===');
  console.log('currentPendingSaleId avant reset:', currentPendingSaleId.value);
  showForm.value = false;
  mobileTab.value = 'products';
  formData.value = {
    client_id: counterClient.value?.id || '',
    items: [],
    payment_method: 'especes',
    payment_status: 'paye',
    notes: '',
  };
  productSearchText.value = '';
  cashReceived.value = 0;
  error.value = '';
  currentPendingSaleId.value = null;
  console.log('currentPendingSaleId après reset:', currentPendingSaleId.value);
  console.log('Formulaire fermé et réinitialisé');
};

const viewSaleDetails = (sale: Sale) => {
  selectedSale.value = sale;
};

const getPaymentStatusColor = (status: string) => {
  switch (status) {
    case 'paye':
      return 'bg-green-100 text-green-800';
    case 'partiellement_paye':
      return 'bg-yellow-100 text-yellow-800';
    case 'en_attente':
      return 'bg-red-100 text-red-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
};

const getPaymentStatusLabel = (status: string) => {
  switch (status) {
    case 'paye':
      return 'Payé';
    case 'partiellement_paye':
      return 'Partiellement payé';
    case 'en_attente':
      return 'En attente';
    default:
      return status;
  }
};

const loadPendingSales = async () => {
  try {
    pendingSales.value = await pendingSalesService.getAllPendingSales();
  } catch (err) {
    console.error('Error loading pending sales:', err);
  }
};

const savePendingSale = async () => {
  console.log('=== DEBUT savePendingSale ===');
  console.log('currentPendingSaleId:', currentPendingSaleId.value);
  error.value = '';

  if (formData.value.items.length === 0) {
    error.value = 'Ajoutez au moins un produit avant de mettre en attente';
    alert('Ajoutez au moins un produit avant de mettre en attente');
    return;
  }

  if (!formData.value.client_id) {
    error.value = 'Veuillez sélectionner un client';
    alert('Veuillez sélectionner un client');
    return;
  }

  const saleName = prompt('Donnez un nom à cette vente en attente (optionnel):');

  if (saleName === null) {
    console.log('=== ANNULATION savePendingSale (utilisateur a annulé) ===');
    return;
  }

  try {
    console.log('Saving pending sale...');
    console.log('Form data:', formData.value);

    const items = formData.value.items.map(item => ({
      product_id: item.product_id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      discount_percentage: item.discount_percentage || 0,
    }));

    const pendingSaleData = {
      client_id: formData.value.client_id,
      sale_data: {
        items: items,
        payment_method: formData.value.payment_method,
        payment_status: formData.value.payment_status,
        notes: formData.value.notes || '',
      },
      name: saleName || `Vente en attente ${new Date().toLocaleString('fr-FR')}`,
    };

    console.log('Pending sale data:', pendingSaleData);
    console.log('Items count:', items.length);

    if (currentPendingSaleId.value) {
      console.log('MODE: MISE A JOUR de la vente existante:', currentPendingSaleId.value);
      await pendingSalesService.updatePendingSale(currentPendingSaleId.value, pendingSaleData);
      alert('Vente en attente mise à jour avec succès');
    } else {
      console.log('MODE: CREATION d\'une nouvelle vente en attente');
      const result = await pendingSalesService.createPendingSale(pendingSaleData);
      console.log('Pending sale created result:', result);
      alert('Nouvelle vente mise en attente avec succès');
    }

    console.log('Pending sale saved successfully');
    await loadPendingSales();
    console.log('Nombre de ventes en attente:', pendingSales.value.length);
    closeForm();
    console.log('=== FIN savePendingSale (succès) ===');
  } catch (err: any) {
    console.error('=== ERREUR savePendingSale ===');
    console.error('Error saving pending sale:', err);
    console.error('Error details:', JSON.stringify(err, null, 2));
    error.value = err.message || 'Erreur lors de la mise en attente';
    alert('Erreur: ' + (err.message || 'Erreur lors de la mise en attente'));
  }
};

const restorePendingSale = (pendingSale: PendingSale) => {
  console.log('=== restorePendingSale ===');
  console.log('Restauration de la vente:', pendingSale.name);
  console.log('ID de la vente:', pendingSale.id);
  formData.value = {
    client_id: pendingSale.client_id || '',
    items: pendingSale.sale_data.items || [],
    payment_method: pendingSale.sale_data.payment_method || 'especes',
    payment_status: pendingSale.sale_data.payment_status || 'paye',
    notes: pendingSale.sale_data.notes || '',
  };
  currentPendingSaleId.value = pendingSale.id || null;
  console.log('currentPendingSaleId défini à:', currentPendingSaleId.value);
  console.log('Nombre de produits restaurés:', formData.value.items.length);
  showPendingSalesModal.value = false;
  showForm.value = true;
  mobileTab.value = 'form';
};

const deletePendingSaleById = async (id: string) => {
  if (!confirm('Voulez-vous vraiment supprimer cette vente en attente ?')) {
    return;
  }

  try {
    await pendingSalesService.deletePendingSale(id);
    await loadPendingSales();
  } catch (err) {
    console.error('Error deleting pending sale:', err);
    alert('Erreur lors de la suppression');
  }
};

const calculatePendingSaleTotal = (pendingSale: PendingSale) => {
  const items = pendingSale.sale_data.items || [];
  return items.reduce((sum: number, item: any) => {
    const total = item.quantity * item.unit_price;
    const discount = (total * (item.discount_percentage || 0)) / 100;
    return sum + (total - discount);
  }, 0);
};

const loadCompany = async () => {
  try {
    company.value = await companyService.getSettings();
  } catch (err) {
    console.error('Error loading company:', err);
  }
};

const printA4 = async () => {
  if (!lastCreatedSale.value || !company.value) return;
  try {
    await saleReceiptService.generateA4Receipt(lastCreatedSale.value, company.value);
    showPrintModal.value = false;
  } catch (err) {
    console.error('Error generating A4 receipt:', err);
    alert('Erreur lors de la génération du reçu A4');
  }
};

const printTicket = async () => {
  if (!lastCreatedSale.value || !company.value) return;
  try {
    await saleReceiptService.generateTicketReceipt(lastCreatedSale.value, company.value);
    showPrintModal.value = false;
  } catch (err) {
    console.error('Error generating ticket receipt:', err);
    alert('Erreur lors de la génération du ticket de caisse');
  }
};

const closePrintModal = () => {
  showPrintModal.value = false;
  lastCreatedSale.value = null;
};

onMounted(() => {
  loadSales();
  loadClients();
  loadProducts();
  loadPendingSales();
  loadCompany();
});
</script>
