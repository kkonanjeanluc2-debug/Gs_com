import { localStorageService } from './local-storage.service';
import { syncService } from './sync.service';
import { networkService } from './network.service';

export async function offlineQuery<T>(
  table: string,
  onlineQuery: () => Promise<{ data: T[] | null; error: any }>,
  useOfflineCache: boolean = true
): Promise<T[]> {
  if (networkService.isOnline()) {
    try {
      const result = await onlineQuery();
      if (result.error) throw result.error;

      if (result.data && result.data.length > 0) {
        await localStorageService.saveAll(table, result.data);
      }

      return result.data || [];
    } catch (error) {
      console.error(`Error fetching ${table} online, falling back to cache:`, error);

      if (useOfflineCache) {
        return localStorageService.getAll<T>(table);
      }

      throw error;
    }
  } else {
    if (useOfflineCache) {
      return localStorageService.getAll<T>(table);
    }

    throw new Error('Mode hors ligne: impossible de récupérer les données');
  }
}

export async function offlineCreate<T extends { id?: string }>(
  table: string,
  data: T,
  onlineCreate: () => Promise<{ data: any | null; error: any }>
): Promise<T> {
  if (networkService.isOnline()) {
    try {
      const result = await onlineCreate();
      if (result.error) throw result.error;

      const createdItem = result.data;
      if (createdItem) {
        await localStorageService.save(table, createdItem);
      }

      return createdItem;
    } catch (error) {
      console.error(`Error creating ${table} online, queuing for sync:`, error);

      const tempId = `temp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const itemWithTempId = { ...data, id: tempId };

      await localStorageService.save(table, itemWithTempId);
      await syncService.queueOperation('create', table, data);

      return itemWithTempId as T;
    }
  } else {
    const tempId = `temp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const itemWithTempId = { ...data, id: tempId };

    await localStorageService.save(table, itemWithTempId);
    await syncService.queueOperation('create', table, data);

    return itemWithTempId as T;
  }
}

export async function offlineUpdate<T extends { id: string }>(
  table: string,
  id: string,
  data: Partial<T>,
  onlineUpdate: () => Promise<{ data: any | null; error: any }>
): Promise<void> {
  if (networkService.isOnline()) {
    try {
      const result = await onlineUpdate();
      if (result.error) throw result.error;

      const existingItem = await localStorageService.getById<T>(table, id);
      if (existingItem) {
        const updatedItem = { ...existingItem, ...data };
        await localStorageService.save(table, updatedItem);
      }
    } catch (error) {
      console.error(`Error updating ${table} online, queuing for sync:`, error);

      const existingItem = await localStorageService.getById<T>(table, id);
      if (existingItem) {
        const updatedItem = { ...existingItem, ...data };
        await localStorageService.save(table, updatedItem);
      }

      await syncService.queueOperation('update', table, { id, ...data });
    }
  } else {
    const existingItem = await localStorageService.getById<T>(table, id);
    if (existingItem) {
      const updatedItem = { ...existingItem, ...data };
      await localStorageService.save(table, updatedItem);
    }

    await syncService.queueOperation('update', table, { id, ...data });
  }
}

export async function offlineDelete(
  table: string,
  id: string,
  onlineDelete: () => Promise<{ error: any }>
): Promise<void> {
  if (networkService.isOnline()) {
    try {
      const result = await onlineDelete();
      if (result.error) throw result.error;

      await localStorageService.delete(table, id);
    } catch (error) {
      console.error(`Error deleting ${table} online, queuing for sync:`, error);

      await localStorageService.delete(table, id);
      await syncService.queueOperation('delete', table, { id });
    }
  } else {
    await localStorageService.delete(table, id);
    await syncService.queueOperation('delete', table, { id });
  }
}

export function isOfflineMode(): boolean {
  return !networkService.isOnline();
}

export async function getSyncStatus() {
  return syncService.getStatus();
}
