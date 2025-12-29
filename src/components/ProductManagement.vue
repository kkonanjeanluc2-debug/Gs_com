<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { productsService } from '../services/products.service';
import { categoriesService, type Category, type Subcategory } from '../services/categories.service';
import { imageUploadService } from '../services/image-upload.service';
import { productImportService } from '../services/product-import.service';
import type { Product } from '../services/supabase';

const products = ref<Product[]>([]);
const categories = ref<Category[]>([]);
const subcategories = ref<Subcategory[]>([]);
const loading = ref(false);
const showForm = ref(false);
const editingProduct = ref<Product | null>(null);
const uploading = ref(false);
const selectedImageFile = ref<File | null>(null);
const imagePreviewUrl = ref<string | null>(null);
const importing = ref(false);
const showImportDialog = ref(false);
const importFileInput = ref<HTMLInputElement | null>(null);

const formData = ref({
  name: '',
  sku: '',
  price: 0,
  stock_quantity: 0,
  image_url: '',
  category_id: '',
  subcategory_id: '',
});

const filteredSubcategories = computed(() => {
  if (!formData.value.category_id) return [];
  return subcategories.value.filter(sub => sub.category_id === formData.value.category_id);
});

onMounted(() => {
  loadProducts();
  loadCategories();
  loadSubcategories();
});

const loadProducts = async () => {
  loading.value = true;
  try {
    products.value = await productsService.getAllProducts();
  } catch (error) {
    console.error('Error loading products:', error);
    alert('Erreur lors du chargement des produits');
  } finally {
    loading.value = false;
  }
};

const loadCategories = async () => {
  try {
    categories.value = await categoriesService.getAllCategories();
  } catch (error) {
    console.error('Error loading categories:', error);
  }
};

const loadSubcategories = async () => {
  try {
    subcategories.value = await categoriesService.getAllSubcategories();
  } catch (error) {
    console.error('Error loading subcategories:', error);
  }
};

const handleImageSelect = (event: Event) => {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];

  if (!file) {
    selectedImageFile.value = null;
    imagePreviewUrl.value = null;
    return;
  }

  const validation = imageUploadService.validateImageFile(file);
  if (!validation.valid) {
    alert(validation.error);
    target.value = '';
    selectedImageFile.value = null;
    imagePreviewUrl.value = null;
    return;
  }

  selectedImageFile.value = file;
  const reader = new FileReader();
  reader.onload = (e) => {
    imagePreviewUrl.value = e.target?.result as string;
  };
  reader.readAsDataURL(file);
};

const removeImage = () => {
  selectedImageFile.value = null;
  imagePreviewUrl.value = null;
  formData.value.image_url = '';
};

const openForm = (product?: Product) => {
  if (product) {
    editingProduct.value = product;
    formData.value = {
      name: product.name,
      sku: product.sku,
      price: product.price,
      stock_quantity: product.stock_quantity,
      image_url: product.image_url || '',
      category_id: product.category_id || '',
      subcategory_id: product.subcategory_id || '',
    };
    imagePreviewUrl.value = product.image_url;
  } else {
    editingProduct.value = null;
    formData.value = {
      name: '',
      sku: '',
      price: 0,
      stock_quantity: 0,
      image_url: '',
      category_id: '',
      subcategory_id: '',
    };
    imagePreviewUrl.value = null;
  }
  selectedImageFile.value = null;
  showForm.value = true;
};

const closeForm = () => {
  showForm.value = false;
  editingProduct.value = null;
};

const handleSubmit = async () => {
  try {
    uploading.value = true;
    let imageUrl = formData.value.image_url;

    if (selectedImageFile.value) {
      imageUrl = await imageUploadService.uploadImage(selectedImageFile.value);
    }

    const productData = {
      ...formData.value,
      description: null,
      min_stock: 0,
      category_id: formData.value.category_id || null,
      subcategory_id: formData.value.subcategory_id || null,
      image_url: imageUrl || null,
    };

    if (editingProduct.value) {
      if (selectedImageFile.value && editingProduct.value.image_url) {
        await imageUploadService.deleteImage(editingProduct.value.image_url);
      }
      await productsService.updateProduct(editingProduct.value.id, productData);
    } else {
      await productsService.createProduct(productData);
    }
    await loadProducts();
    closeForm();
  } catch (error) {
    console.error('Error saving product:', error);
    alert('Erreur lors de la sauvegarde');
  } finally {
    uploading.value = false;
  }
};

const getCategoryName = (categoryId: string | null) => {
  if (!categoryId) return '';
  return categories.value.find(c => c.id === categoryId)?.name || '';
};

const getSubcategoryName = (subcategoryId: string | null) => {
  if (!subcategoryId) return '';
  return subcategories.value.find(s => s.id === subcategoryId)?.name || '';
};

const handleDelete = async (product: Product) => {
  if (!confirm(`Supprimer le produit "${product.name}" ?`)) return;

  try {
    if (product.image_url) {
      await imageUploadService.deleteImage(product.image_url);
    }
    await productsService.deleteProduct(product.id);
    await loadProducts();
  } catch (error) {
    console.error('Error deleting product:', error);
    alert('Erreur lors de la suppression');
  }
};

const downloadTemplate = () => {
  productImportService.generateTemplate();
};

const openImportDialog = () => {
  showImportDialog.value = true;
};

const closeImportDialog = () => {
  showImportDialog.value = false;
};

const handleImportFile = async (event: Event) => {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];

  if (!file) return;

  const validation = productImportService.validateFile(file);
  if (!validation.valid) {
    alert(validation.error);
    target.value = '';
    return;
  }

  if (!confirm(`Importer les produits depuis "${file.name}" ?`)) {
    target.value = '';
    return;
  }

  importing.value = true;

  try {
    const result = await productImportService.importFromExcel(file);

    let message = `Import terminé:\n✓ ${result.success} produits importés avec succès`;

    if (result.failed > 0) {
      message += `\n✗ ${result.failed} produits ont échoué`;
      if (result.errors.length > 0) {
        message += `\n\nErreurs:\n${result.errors.slice(0, 5).join('\n')}`;
        if (result.errors.length > 5) {
          message += `\n... et ${result.errors.length - 5} autres erreurs`;
        }
      }
    }

    alert(message);
    await loadProducts();
    closeImportDialog();
  } catch (error) {
    console.error('Error importing products:', error);
    alert('Erreur lors de l\'import des produits');
  } finally {
    importing.value = false;
    target.value = '';
  }
};
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center flex-wrap gap-3">
      <h2 class="text-2xl font-bold text-secondary">Gestion du Stock</h2>
      <div class="flex gap-2 flex-wrap">
        <button @click="downloadTemplate" class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 font-medium text-sm">
          📥 Télécharger modèle
        </button>
        <button @click="openImportDialog" class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium text-sm">
          📤 Importer Excel
        </button>
        <button @click="openForm()" class="btn-primary">
          ➕ Nouveau produit
        </button>
      </div>
    </div>

    <div v-if="showImportDialog" class="card">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-xl font-bold text-primary">Importer des produits depuis Excel</h3>
        <button @click="closeImportDialog" class="text-gray-500 hover:text-gray-700">✕</button>
      </div>

      <div class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <h4 class="font-semibold text-blue-900 mb-2">Importation flexible</h4>
          <p class="text-sm text-blue-800 mb-3">Le système accepte différents formats de colonnes:</p>
          <ul class="text-sm text-blue-800 space-y-1 list-disc list-inside">
            <li><strong>Code/SKU/Référence</strong> - généré automatiquement si absent</li>
            <li><strong>Désignation/Nom/Produit</strong> - "Produit sans nom" si absent</li>
            <li><strong>Prix/Montant/Tarif</strong> - 0 si absent ou invalide</li>
            <li><strong>Stock/Quantité/Qté</strong> - 0 si absent ou invalide</li>
          </ul>
          <div class="mt-3 pt-3 border-t border-blue-200">
            <p class="text-sm text-blue-700 font-medium mb-1">
              ✓ Mise à jour automatique
            </p>
            <p class="text-xs text-blue-600">
              Si un produit avec le même SKU existe déjà, il sera mis à jour au lieu d'être créé en double.
            </p>
          </div>
        </div>

        <div>
          <label class="label">Sélectionner un fichier Excel</label>
          <input
            ref="importFileInput"
            type="file"
            accept=".xlsx,.xls"
            @change="handleImportFile"
            :disabled="importing"
            class="input-field disabled:opacity-50 disabled:cursor-not-allowed"
          />
          <p class="text-xs text-gray-500 mt-1">Formats acceptés: .xlsx, .xls (max. 10 MB)</p>
        </div>

        <div v-if="importing" class="flex items-center justify-center py-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mr-3"></div>
          <span class="text-gray-600">Import en cours...</span>
        </div>

        <div class="flex gap-3">
          <button
            type="button"
            @click="downloadTemplate"
            class="btn-secondary flex-1"
          >
            📥 Télécharger le modèle
          </button>
          <button
            type="button"
            @click="closeImportDialog"
            :disabled="importing"
            class="btn-secondary flex-1 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Fermer
          </button>
        </div>
      </div>
    </div>

    <div v-if="showForm" class="card">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-xl font-bold text-primary">
          {{ editingProduct ? 'Modifier le produit' : 'Nouveau produit' }}
        </h3>
        <button @click="closeForm" class="text-gray-500 hover:text-gray-700">✕</button>
      </div>

      <form @submit.prevent="handleSubmit" class="space-y-4">
        <div>
          <label class="label">Code (SKU)</label>
          <input v-model="formData.sku" type="text" class="input-field" required placeholder="Code unique du produit" />
        </div>

        <div>
          <label class="label">Photo du produit</label>
          <div v-if="imagePreviewUrl" class="mb-3">
            <div class="relative inline-block">
              <img :src="imagePreviewUrl" alt="Aperçu" class="w-32 h-32 object-cover rounded-lg border-2 border-gray-200" />
              <button
                type="button"
                @click="removeImage"
                class="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center hover:bg-red-600"
              >
                ✕
              </button>
            </div>
          </div>
          <input
            type="file"
            accept="image/jpeg,image/jpg,image/png,image/webp,image/gif"
            @change="handleImageSelect"
            class="input-field"
          />
          <p class="text-xs text-gray-500 mt-1">JPG, PNG, WEBP ou GIF (max. 5 MB)</p>
        </div>

        <div>
          <label class="label">Désignation</label>
          <input v-model="formData.name" type="text" class="input-field" required placeholder="Nom du produit" />
        </div>

        <div>
          <label class="label">Prix (FCFA)</label>
          <input v-model.number="formData.price" type="number" min="0" class="input-field" required placeholder="0" />
        </div>

        <div>
          <label class="label">Stock</label>
          <input v-model.number="formData.stock_quantity" type="number" min="0" class="input-field" required placeholder="0" />
        </div>

        <div>
          <label class="label">Catégorie</label>
          <select v-model="formData.category_id" class="input-field" @change="formData.subcategory_id = ''">
            <option value="">Aucune</option>
            <option v-for="cat in categories" :key="cat.id" :value="cat.id">
              {{ cat.name }}
            </option>
          </select>
        </div>

        <div>
          <label class="label">Sous-catégorie</label>
          <select v-model="formData.subcategory_id" class="input-field" :disabled="!formData.category_id">
            <option value="">Aucune</option>
            <option v-for="sub in filteredSubcategories" :key="sub.id" :value="sub.id">
              {{ sub.name }}
            </option>
          </select>
        </div>

        <div class="flex gap-3">
          <button type="submit" :disabled="uploading" class="btn-primary flex-1 disabled:opacity-50 disabled:cursor-not-allowed">
            <span v-if="uploading">Téléversement en cours...</span>
            <span v-else>Enregistrer</span>
          </button>
          <button type="button" @click="closeForm" :disabled="uploading" class="btn-secondary flex-1 disabled:opacity-50 disabled:cursor-not-allowed">
            Annuler
          </button>
        </div>
      </form>
    </div>

    <div v-if="loading" class="text-center py-8">
      <p class="text-gray-600">Chargement...</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="product in products" :key="product.id" class="card">
        <div v-if="product.image_url" class="mb-3">
          <img :src="product.image_url" :alt="product.name" class="w-full h-48 object-cover rounded-lg" />
        </div>

        <div class="flex justify-between items-start mb-3">
          <div class="flex-1">
            <h3 class="font-bold text-lg">{{ product.name }}</h3>
            <p class="text-sm text-gray-500">SKU: {{ product.sku }}</p>
            <div v-if="product.category_id" class="mt-1">
              <span class="inline-block px-2 py-1 text-xs font-semibold bg-blue-100 text-primary rounded">
                {{ getCategoryName(product.category_id) }}
              </span>
              <span v-if="product.subcategory_id" class="inline-block px-2 py-1 text-xs bg-gray-100 text-gray-700 rounded ml-1">
                {{ getSubcategoryName(product.subcategory_id) }}
              </span>
            </div>
          </div>
          <span class="px-2 py-1 rounded text-xs font-semibold bg-blue-100 text-primary">
            Stock: {{ product.stock_quantity }}
          </span>
        </div>

        <div class="border-t pt-3 mb-3">
          <p class="text-lg font-bold text-primary">{{ product.price.toLocaleString('fr-FR') }} FCFA</p>
        </div>

        <div class="flex gap-2">
          <button
            @click="openForm(product)"
            class="flex-1 px-3 py-2 text-sm bg-blue-50 text-primary rounded-lg hover:bg-blue-100"
          >
            ✏️ Modifier
          </button>
          <button
            @click="handleDelete(product)"
            class="flex-1 px-3 py-2 text-sm bg-red-50 text-red-700 rounded-lg hover:bg-red-100"
          >
            🗑️ Supprimer
          </button>
        </div>
      </div>
    </div>

    <div v-if="!loading && products.length === 0" class="text-center py-12">
      <div class="text-6xl mb-4">📦</div>
      <p class="text-xl text-gray-600">Aucun produit</p>
      <p class="text-gray-500 mt-2">Ajoutez votre premier produit pour commencer</p>
    </div>
  </div>
</template>
