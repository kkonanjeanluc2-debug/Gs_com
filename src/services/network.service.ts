export interface NetworkStatus {
  isOnline: boolean;
  wasOffline: boolean;
}

class NetworkService {
  private status: NetworkStatus = {
    isOnline: navigator.onLine,
    wasOffline: false,
  };

  private listeners: Array<(status: NetworkStatus) => void> = [];

  constructor() {
    this.init();
  }

  private init() {
    window.addEventListener('online', this.handleOnline.bind(this));
    window.addEventListener('offline', this.handleOffline.bind(this));
  }

  private handleOnline() {
    console.log('Network: Online');
    this.status = {
      isOnline: true,
      wasOffline: this.status.wasOffline || !this.status.isOnline,
    };
    this.notifyListeners();
  }

  private handleOffline() {
    console.log('Network: Offline');
    this.status = {
      isOnline: false,
      wasOffline: true,
    };
    this.notifyListeners();
  }

  onStatusChange(callback: (status: NetworkStatus) => void): () => void {
    this.listeners.push(callback);
    callback(this.status);

    return () => {
      this.listeners = this.listeners.filter(cb => cb !== callback);
    };
  }

  private notifyListeners() {
    this.listeners.forEach(callback => callback(this.status));
  }

  getStatus(): NetworkStatus {
    return this.status;
  }

  isOnline(): boolean {
    return this.status.isOnline;
  }

  resetWasOffline(): void {
    this.status.wasOffline = false;
  }
}

export const networkService = new NetworkService();
