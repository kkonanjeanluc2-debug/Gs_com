<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { categoriesService, type Category, type Subcategory } from '../services/categories.service';

const categories = ref<Category[]>([]);
const subcategories = ref<Subcategory[]>([]);
const loading = ref(false);
const activeView = ref<'categories' | 'subcategories'>('categories');

const showCategoryForm = ref(false);
const editingCategory = ref<Category | null>(null);
const categoryFormData = ref({
  name: '',
  description: '',
});

const showSubcategoryForm = ref(false);
const editingSubcategory = ref<Subcategory | null>(null);
const subcategoryFormData = ref({
  category_id: '',
  name: '',
  description: '',
});

const subcategoriesByCategory = computed(() => {
  const grouped: Record<string, Subcategory[]> = {};
  subcategories.value.forEach(sub => {
    if (!grouped[sub.category_id]) {
      grouped[sub.category_id] = [];
    }
    grouped[sub.category_id].push(sub);
  });
  return grouped;
});

onMounted(() => {
  loadCategories();
  loadSubcategories();
});

const loadCategories = async () => {
  loading.value = true;
  try {
    categories.value = await categoriesService.getAllCategories();
  } catch (error) {
    console.error('Error loading categories:', error);
    alert('Erreur lors du chargement des catégories');
  } finally {
    loading.value = false;
  }
};

const loadSubcategories = async () => {
  loading.value = true;
  try {
    subcategories.value = await categoriesService.getAllSubcategories();
  } catch (error) {
    console.error('Error loading subcategories:', error);
    alert('Erreur lors du chargement des sous-catégories');
  } finally {
    loading.value = false;
  }
};

const openCategoryForm = (category?: Category) => {
  if (category) {
    editingCategory.value = category;
    categoryFormData.value = {
      name: category.name,
      description: category.description || '',
    };
  } else {
    editingCategory.value = null;
    categoryFormData.value = {
      name: '',
      description: '',
    };
  }
  showCategoryForm.value = true;
};

const closeCategoryForm = () => {
  showCategoryForm.value = false;
  editingCategory.value = null;
};

const handleCategorySubmit = async () => {
  try {
    if (editingCategory.value) {
      await categoriesService.updateCategory(editingCategory.value.id, categoryFormData.value);
    } else {
      await categoriesService.createCategory(categoryFormData.value);
    }
    await loadCategories();
    closeCategoryForm();
  } catch (error) {
    console.error('Error saving category:', error);
    alert('Erreur lors de la sauvegarde');
  }
};

const handleDeleteCategory = async (category: Category) => {
  const subs = subcategoriesByCategory.value[category.id] || [];
  if (subs.length > 0) {
    if (!confirm(`Cette catégorie contient ${subs.length} sous-catégorie(s). Elles seront également supprimées. Continuer ?`)) {
      return;
    }
  } else {
    if (!confirm(`Supprimer la catégorie "${category.name}" ?`)) {
      return;
    }
  }

  try {
    await categoriesService.deleteCategory(category.id);
    await loadCategories();
    await loadSubcategories();
  } catch (error) {
    console.error('Error deleting category:', error);
    alert('Erreur lors de la suppression');
  }
};

const openSubcategoryForm = (subcategory?: Subcategory) => {
  if (subcategory) {
    editingSubcategory.value = subcategory;
    subcategoryFormData.value = {
      category_id: subcategory.category_id,
      name: subcategory.name,
      description: subcategory.description || '',
    };
  } else {
    editingSubcategory.value = null;
    subcategoryFormData.value = {
      category_id: categories.value[0]?.id || '',
      name: '',
      description: '',
    };
  }
  showSubcategoryForm.value = true;
};

const closeSubcategoryForm = () => {
  showSubcategoryForm.value = false;
  editingSubcategory.value = null;
};

const handleSubcategorySubmit = async () => {
  try {
    if (editingSubcategory.value) {
      await categoriesService.updateSubcategory(editingSubcategory.value.id, subcategoryFormData.value);
    } else {
      await categoriesService.createSubcategory(subcategoryFormData.value);
    }
    await loadSubcategories();
    closeSubcategoryForm();
  } catch (error) {
    console.error('Error saving subcategory:', error);
    alert('Erreur lors de la sauvegarde');
  }
};

const handleDeleteSubcategory = async (subcategory: Subcategory) => {
  if (!confirm(`Supprimer la sous-catégorie "${subcategory.name}" ?`)) return;

  try {
    await categoriesService.deleteSubcategory(subcategory.id);
    await loadSubcategories();
  } catch (error) {
    console.error('Error deleting subcategory:', error);
    alert('Erreur lors de la suppression');
  }
};

const getCategoryName = (categoryId: string) => {
  return categories.value.find(c => c.id === categoryId)?.name || 'N/A';
};
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h2 class="text-2xl font-bold text-secondary">Gestion des Catégories</h2>
      <div class="flex gap-3">
        <button
          @click="activeView = 'categories'"
          :class="[
            'px-4 py-2 rounded-lg font-medium transition-all',
            activeView === 'categories'
              ? 'bg-primary text-white'
              : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
          ]"
        >
          Catégories
        </button>
        <button
          @click="activeView = 'subcategories'"
          :class="[
            'px-4 py-2 rounded-lg font-medium transition-all',
            activeView === 'subcategories'
              ? 'bg-primary text-white'
              : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
          ]"
        >
          Sous-catégories
        </button>
      </div>
    </div>

    <div v-if="activeView === 'categories'">
      <div class="mb-4">
        <button @click="openCategoryForm()" class="btn-primary">
          Nouvelle catégorie
        </button>
      </div>

      <div v-if="showCategoryForm" class="card mb-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-xl font-bold text-primary">
            {{ editingCategory ? 'Modifier la catégorie' : 'Nouvelle catégorie' }}
          </h3>
          <button @click="closeCategoryForm" class="text-gray-500 hover:text-gray-700">✕</button>
        </div>

        <form @submit.prevent="handleCategorySubmit" class="space-y-4">
          <div>
            <label class="label">Nom</label>
            <input v-model="categoryFormData.name" type="text" class="input-field" required />
          </div>

          <div>
            <label class="label">Description</label>
            <textarea v-model="categoryFormData.description" class="textarea-field"></textarea>
          </div>

          <div class="flex gap-3">
            <button type="submit" class="btn-primary flex-1">
              Enregistrer
            </button>
            <button type="button" @click="closeCategoryForm" class="btn-secondary flex-1">
              Annuler
            </button>
          </div>
        </form>
      </div>

      <div v-if="loading" class="text-center py-8">
        <p class="text-gray-600">Chargement...</p>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div v-for="category in categories" :key="category.id" class="card">
          <div class="mb-3">
            <h3 class="font-bold text-lg">{{ category.name }}</h3>
            <p v-if="category.description" class="text-sm text-gray-600 mt-1">
              {{ category.description }}
            </p>
          </div>

          <div class="border-t pt-3 mb-3">
            <p class="text-xs text-gray-500">
              {{ subcategoriesByCategory[category.id]?.length || 0 }} sous-catégorie(s)
            </p>
          </div>

          <div class="flex gap-2">
            <button
              @click="openCategoryForm(category)"
              class="flex-1 px-3 py-2 text-sm bg-blue-50 text-primary rounded-lg hover:bg-blue-100"
            >
              Modifier
            </button>
            <button
              @click="handleDeleteCategory(category)"
              class="flex-1 px-3 py-2 text-sm bg-red-50 text-red-700 rounded-lg hover:bg-red-100"
            >
              Supprimer
            </button>
          </div>
        </div>
      </div>

      <div v-if="!loading && categories.length === 0" class="text-center py-12">
        <div class="text-6xl mb-4">📁</div>
        <p class="text-xl text-gray-600">Aucune catégorie</p>
        <p class="text-gray-500 mt-2">Ajoutez votre première catégorie pour commencer</p>
      </div>
    </div>

    <div v-if="activeView === 'subcategories'">
      <div class="mb-4">
        <button
          @click="openSubcategoryForm()"
          :disabled="categories.length === 0"
          class="btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Nouvelle sous-catégorie
        </button>
        <p v-if="categories.length === 0" class="text-sm text-amber-600 mt-2">
          Vous devez d'abord créer au moins une catégorie
        </p>
      </div>

      <div v-if="showSubcategoryForm" class="card mb-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-xl font-bold text-primary">
            {{ editingSubcategory ? 'Modifier la sous-catégorie' : 'Nouvelle sous-catégorie' }}
          </h3>
          <button @click="closeSubcategoryForm" class="text-gray-500 hover:text-gray-700">✕</button>
        </div>

        <form @submit.prevent="handleSubcategorySubmit" class="space-y-4">
          <div>
            <label class="label">Catégorie</label>
            <select v-model="subcategoryFormData.category_id" class="input-field" required>
              <option value="" disabled>Sélectionner une catégorie</option>
              <option v-for="cat in categories" :key="cat.id" :value="cat.id">
                {{ cat.name }}
              </option>
            </select>
          </div>

          <div>
            <label class="label">Nom</label>
            <input v-model="subcategoryFormData.name" type="text" class="input-field" required />
          </div>

          <div>
            <label class="label">Description</label>
            <textarea v-model="subcategoryFormData.description" class="textarea-field"></textarea>
          </div>

          <div class="flex gap-3">
            <button type="submit" class="btn-primary flex-1">
              Enregistrer
            </button>
            <button type="button" @click="closeSubcategoryForm" class="btn-secondary flex-1">
              Annuler
            </button>
          </div>
        </form>
      </div>

      <div v-if="loading" class="text-center py-8">
        <p class="text-gray-600">Chargement...</p>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div v-for="subcategory in subcategories" :key="subcategory.id" class="card">
          <div class="mb-3">
            <span class="inline-block px-2 py-1 text-xs font-semibold bg-blue-100 text-primary rounded mb-2">
              {{ getCategoryName(subcategory.category_id) }}
            </span>
            <h3 class="font-bold text-lg">{{ subcategory.name }}</h3>
            <p v-if="subcategory.description" class="text-sm text-gray-600 mt-1">
              {{ subcategory.description }}
            </p>
          </div>

          <div class="flex gap-2 mt-4">
            <button
              @click="openSubcategoryForm(subcategory)"
              class="flex-1 px-3 py-2 text-sm bg-blue-50 text-primary rounded-lg hover:bg-blue-100"
            >
              Modifier
            </button>
            <button
              @click="handleDeleteSubcategory(subcategory)"
              class="flex-1 px-3 py-2 text-sm bg-red-50 text-red-700 rounded-lg hover:bg-red-100"
            >
              Supprimer
            </button>
          </div>
        </div>
      </div>

      <div v-if="!loading && subcategories.length === 0" class="text-center py-12">
        <div class="text-6xl mb-4">📂</div>
        <p class="text-xl text-gray-600">Aucune sous-catégorie</p>
        <p class="text-gray-500 mt-2">Ajoutez votre première sous-catégorie pour commencer</p>
      </div>
    </div>
  </div>
</template>
