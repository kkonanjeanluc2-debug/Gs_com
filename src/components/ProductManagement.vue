<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { productsService } from '../services/products.service';
import { categoriesService, type Category, type Subcategory } from '../services/categories.service';
import { imageUploadService } from '../services/image-upload.service';
import { productImportService } from '../services/product-import.service';
import type { Product } from '../services/supabase';
import Icon from './Icon.vue';

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
  if (!confirm(`Supprimer le produit "${product.name}" ?\n\nAttention : Cette action est irréversible.`)) return;

  try {
    if (product.image_url) {
      await imageUploadService.deleteImage(product.image_url);
    }
    await productsService.deleteProduct(product.id);
    await loadProducts();
    alert(`Le produit "${product.name}" a été supprimé avec succès.`);
  } catch (error: any) {
    console.error('Error deleting product:', error);

    // Check if error is due to foreign key constraint
    if (error?.message?.includes('violates foreign key constraint') ||
        error?.code === '23503' ||
        error?.message?.includes('order_items')) {
      alert(
        `Impossible de supprimer "${product.name}".\n\n` +
        `Ce produit a été utilisé dans des commandes et ne peut pas être supprimé pour préserver l'historique.\n\n` +
        `Vous pouvez :\n` +
        `• Modifier le stock à 0 pour le rendre indisponible\n` +
        `• Modifier le nom en ajoutant "(Archivé)" pour le masquer`
      );
    } else {
      alert(`Erreur lors de la suppression du produit : ${error?.message || 'Erreur inconnue'}`);
    }
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
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div class="flex items-center gap-3">
        <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-emerald-500 to-emerald-600 flex items-center justify-center shadow-lg">
          <Icon name="package" class="w-6 h-6 text-white" />
        </div>
        <div>
          <h2 class="text-2xl font-bold text-gray-800">Gestion du Stock</h2>
          <p class="text-sm text-gray-500">Gérez votre inventaire de produits</p>
        </div>
      </div>
      <div class="flex gap-2 flex-wrap">
        <button @click="downloadTemplate" class="px-4 py-2.5 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 font-medium text-sm inline-flex items-center gap-2 transition-colors">
          <Icon name="download" class="w-4 h-4" />
          <span>Télécharger modèle</span>
        </button>
        <button @click="openImportDialog" class="px-4 py-2.5 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 font-medium text-sm inline-flex items-center gap-2 transition-colors shadow-md">
          <Icon name="upload" class="w-4 h-4" />
          <span>Importer Excel</span>
        </button>
        <button @click="openForm()" class="btn-primary inline-flex items-center gap-2 shadow-lg hover:shadow-xl transition-shadow">
          <Icon name="plus" class="w-5 h-5" />
          <span>Nouveau produit</span>
        </button>
      </div>
    </div>

    <div v-if="showImportDialog" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-xl font-bold text-gray-800">Importer des produits depuis Excel</h3>
          <button @click="closeImportDialog" class="text-gray-400 hover:text-gray-600 transition-colors">
            <Icon name="x" class="w-6 h-6" />
          </button>
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
            class="btn-secondary flex-1 inline-flex items-center justify-center gap-2"
          >
            <Icon name="download" class="w-5 h-5" />
            <span>Télécharger le modèle</span>
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
    </div>

    <div v-if="showForm" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-xl font-bold text-gray-800">
            {{ editingProduct ? 'Modifier le produit' : 'Nouveau produit' }}
          </h3>
          <button @click="closeForm" class="text-gray-400 hover:text-gray-600 transition-colors">
            <Icon name="x" class="w-6 h-6" />
          </button>
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
                class="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-7 h-7 flex items-center justify-center hover:bg-red-600 shadow-md transition-colors"
              >
                <Icon name="x" class="w-4 h-4" />
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
    </div>

    <div v-if="loading" class="text-center py-8">
      <p class="text-gray-600">Chargement...</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="product in products" :key="product.id" class="card hover:shadow-xl transition-all duration-200 border border-gray-100 overflow-hidden">
        <div v-if="product.image_url" class="mb-4 -mx-6 -mt-6">
          <img :src="product.image_url" :alt="product.name" class="w-full h-48 object-cover" />
        </div>
        <div v-else class="mb-4 -mx-6 -mt-6 bg-gradient-to-br from-gray-100 to-gray-200 h-48 flex items-center justify-center">
          <Icon name="image" class="w-16 h-16 text-gray-300" />
        </div>

        <div class="flex justify-between items-start mb-4">
          <div class="flex-1">
            <h3 class="font-bold text-lg text-gray-800 mb-1">{{ product.name }}</h3>
            <div class="flex items-center gap-1.5 text-sm text-gray-500 mb-2">
              <Icon name="package" class="w-3.5 h-3.5" />
              <span>{{ product.sku }}</span>
            </div>
            <div v-if="product.category_id" class="flex flex-wrap gap-1.5 mt-2">
              <span class="inline-flex items-center gap-1 px-2.5 py-1 text-xs font-semibold bg-blue-50 text-blue-700 rounded-full border border-blue-200">
                <Icon name="folder" class="w-3 h-3" />
                <span>{{ getCategoryName(product.category_id) }}</span>
              </span>
              <span v-if="product.subcategory_id" class="inline-block px-2.5 py-1 text-xs font-medium bg-gray-100 text-gray-700 rounded-full">
                {{ getSubcategoryName(product.subcategory_id) }}
              </span>
            </div>
          </div>
        </div>

        <div class="flex items-center justify-between mb-4 p-3 bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg border border-blue-200">
          <div class="flex items-center gap-2">
            <Icon name="box" class="w-5 h-5 text-blue-600" />
            <div>
              <p class="text-xs text-blue-700 font-medium">Stock</p>
              <p class="text-lg font-bold text-blue-900">{{ product.stock_quantity }}</p>
            </div>
          </div>
          <div class="text-right">
            <p class="text-xs text-blue-700 font-medium">Prix</p>
            <p class="text-lg font-bold text-blue-900">{{ product.price.toLocaleString('fr-FR') }} <span class="text-sm">FCFA</span></p>
          </div>
        </div>

        <div class="flex gap-2">
          <button
            @click="openForm(product)"
            class="flex-1 px-3 py-2 text-sm bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 inline-flex items-center justify-center gap-1.5 font-medium transition-colors"
          >
            <Icon name="edit" class="w-4 h-4" />
            <span>Modifier</span>
          </button>
          <button
            @click="handleDelete(product)"
            class="flex-1 px-3 py-2 text-sm bg-red-50 text-red-700 rounded-lg hover:bg-red-100 inline-flex items-center justify-center gap-1.5 font-medium transition-colors"
          >
            <Icon name="trash" class="w-4 h-4" />
            <span>Supprimer</span>
          </button>
        </div>
      </div>
    </div>

    <div v-if="!loading && products.length === 0" class="text-center py-16">
      <div class="w-20 h-20 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center">
        <Icon name="package" class="w-10 h-10 text-gray-400" />
      </div>
      <p class="text-xl font-semibold text-gray-700 mb-2">Aucun produit</p>
      <p class="text-gray-500">Ajoutez votre premier produit pour commencer</p>
    </div>
  </div>
</template>
