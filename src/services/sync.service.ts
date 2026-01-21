import { supabase } from './supabase';
import { localStorageService, PendingOperation } from './local-storage.service';

export interface SyncStatus {
  isSyncing: boolean;
  lastSyncTime: number | null;
  pendingCount: number;
  error: string | null;
}

class SyncService {
  private syncStatus: SyncStatus = {
    isSyncing: false,
    lastSyncTime: null,
    pendingCount: 0,
    error: null,
  };

  private listeners: Array<(status: SyncStatus) => void> = [];
  private syncInterval: number | null = null;

  onStatusChange(callback: (status: SyncStatus) => void): () => void {
    this.listeners.push(callback);
    callback(this.syncStatus);

    return () => {
      this.listeners = this.listeners.filter(cb => cb !== callback);
    };
  }

  private notifyListeners() {
    this.listeners.forEach(callback => callback(this.syncStatus));
  }

  private updateStatus(updates: Partial<SyncStatus>) {
    this.syncStatus = { ...this.syncStatus, ...updates };
    this.notifyListeners();
  }

  async startAutoSync(intervalMs: number = 30000): Promise<void> {
    if (this.syncInterval) {
      clearInterval(this.syncInterval);
    }

    this.syncInterval = window.setInterval(async () => {
      if (navigator.onLine) {
        await this.syncAll();
      }
    }, intervalMs);

    if (navigator.onLine) {
      await this.syncAll();
    }
  }

  stopAutoSync(): void {
    if (this.syncInterval) {
      clearInterval(this.syncInterval);
      this.syncInterval = null;
    }
  }

  async syncAll(): Promise<void> {
    if (this.syncStatus.isSyncing) return;

    this.updateStatus({ isSyncing: true, error: null });

    try {
      await this.syncPendingOperations();

      await this.syncTable('products');
      await this.syncTable('clients');
      await this.syncTable('categories');
      await this.syncTable('suppliers');
      await this.syncTable('sales');
      await this.syncTable('orders');
      await this.syncTable('purchases');

      this.updateStatus({
        isSyncing: false,
        lastSyncTime: Date.now(),
        pendingCount: 0,
      });
    } catch (error: any) {
      console.error('Sync error:', error);
      this.updateStatus({
        isSyncing: false,
        error: error.message || 'Erreur de synchronisation',
      });
    }
  }

  private async syncPendingOperations(): Promise<void> {
    const operations = await localStorageService.getPendingOperations();
    this.updateStatus({ pendingCount: operations.length });

    for (const operation of operations) {
      try {
        await this.executePendingOperation(operation);
        await localStorageService.removePendingOperation(operation.id);
      } catch (error: any) {
        console.error('Error executing pending operation:', error);

        operation.retryCount++;
        if (operation.retryCount < 5) {
          await localStorageService.updatePendingOperation(operation);
        } else {
          console.error('Max retry count reached, removing operation:', operation);
          await localStorageService.removePendingOperation(operation.id);
        }
      }
    }
  }

  private async executePendingOperation(operation: PendingOperation): Promise<void> {
    const { type, table, data } = operation;

    switch (type) {
      case 'create':
        await supabase.from(table).insert(data);
        break;
      case 'update':
        await supabase.from(table).update(data).eq('id', data.id);
        break;
      case 'delete':
        await supabase.from(table).delete().eq('id', data.id);
        break;
    }
  }

  private async syncTable(tableName: string): Promise<void> {
    const { data: session } = await supabase.auth.getSession();
    if (!session?.session) return;

    const { data: profile } = await supabase
      .from('profiles')
      .select('company_id')
      .eq('id', session.session.user.id)
      .single();

    if (!profile?.company_id) return;

    const lastSync = await localStorageService.getLastSync(tableName);

    let query = supabase
      .from(tableName)
      .select('*')
      .eq('company_id', profile.company_id);

    if (lastSync) {
      query = query.gte('updated_at', new Date(lastSync).toISOString());
    }

    const { data, error } = await query;

    if (error) {
      console.error(`Error syncing ${tableName}:`, error);
      return;
    }

    if (data && data.length > 0) {
      await localStorageService.saveAll(tableName, data);
      await localStorageService.setLastSync(tableName, Date.now());
    }
  }

  async getLocalData<T>(table: string): Promise<T[]> {
    return localStorageService.getAll<T>(table);
  }

  async saveLocalData<T>(table: string, data: T): Promise<void> {
    await localStorageService.save(table, data);
  }

  async queueOperation(
    type: 'create' | 'update' | 'delete',
    table: string,
    data: any
  ): Promise<void> {
    await localStorageService.addPendingOperation({ type, table, data });
    this.updateStatus({
      pendingCount: (await localStorageService.getPendingOperations()).length
    });

    if (navigator.onLine) {
      await this.syncAll();
    }
  }

  getStatus(): SyncStatus {
    return this.syncStatus;
  }
}

export const syncService = new SyncService();
