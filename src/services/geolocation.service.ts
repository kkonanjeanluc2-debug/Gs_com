import { supabase } from './supabase';

export interface CommercialLocation {
  id: string;
  user_id: string;
  company_id: string;
  latitude: number;
  longitude: number;
  accuracy?: number;
  timestamp: string;
  is_active: boolean;
  activity_type: 'en_visite' | 'en_deplacement' | 'pause' | 'inactif';
  created_at: string;
}

export interface CommercialLocationWithProfile extends CommercialLocation {
  profile: {
    first_name: string;
    last_name: string;
    photo_url?: string;
  };
}

export interface LocationUpdate {
  latitude: number;
  longitude: number;
  accuracy?: number;
  activity_type?: 'en_visite' | 'en_deplacement' | 'pause' | 'inactif';
}

class GeolocationService {
  private watchId: number | null = null;
  private updateInterval: NodeJS.Timeout | null = null;

  async getCurrentPosition(): Promise<GeolocationPosition> {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('La géolocalisation n\'est pas supportée par votre navigateur'));
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (position) => resolve(position),
        (error) => reject(error),
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0
        }
      );
    });
  }

  async updateLocation(
    userId: string,
    companyId: string,
    locationData: LocationUpdate
  ): Promise<CommercialLocation> {
    const { data, error } = await supabase
      .from('commercial_locations')
      .insert({
        user_id: userId,
        company_id: companyId,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        accuracy: locationData.accuracy,
        activity_type: locationData.activity_type || 'en_deplacement',
        timestamp: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async getActiveLocations(companyId: string): Promise<CommercialLocationWithProfile[]> {
    const { data, error } = await supabase
      .from('commercial_locations')
      .select(`
        *,
        profile:profiles!commercial_locations_user_id_fkey(
          first_name,
          last_name,
          photo_url
        )
      `)
      .eq('company_id', companyId)
      .eq('is_active', true)
      .order('timestamp', { ascending: false });

    if (error) throw error;
    return data as CommercialLocationWithProfile[];
  }

  async getLocationHistory(
    userId: string,
    startDate?: string,
    endDate?: string
  ): Promise<CommercialLocation[]> {
    let query = supabase
      .from('commercial_locations')
      .select('*')
      .eq('user_id', userId)
      .order('timestamp', { ascending: false });

    if (startDate) {
      query = query.gte('timestamp', startDate);
    }

    if (endDate) {
      query = query.lte('timestamp', endDate);
    }

    const { data, error } = await query.limit(1000);

    if (error) throw error;
    return data;
  }

  async updateActivityType(
    locationId: string,
    activityType: 'en_visite' | 'en_deplacement' | 'pause' | 'inactif'
  ): Promise<void> {
    const { error } = await supabase
      .from('commercial_locations')
      .update({ activity_type: activityType })
      .eq('id', locationId);

    if (error) throw error;
  }

  startTracking(
    userId: string,
    companyId: string,
    intervalMinutes: number = 5,
    activityType: 'en_visite' | 'en_deplacement' | 'pause' | 'inactif' = 'en_deplacement'
  ): void {
    if (this.updateInterval) {
      this.stopTracking();
    }

    const updatePosition = async () => {
      try {
        const position = await this.getCurrentPosition();
        await this.updateLocation(userId, companyId, {
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
          accuracy: position.coords.accuracy,
          activity_type: activityType,
        });
      } catch (error) {
        console.error('Erreur lors de la mise à jour de la position:', error);
      }
    };

    updatePosition();

    this.updateInterval = setInterval(updatePosition, intervalMinutes * 60 * 1000);
  }

  stopTracking(): void {
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
      this.updateInterval = null;
    }

    if (this.watchId !== null) {
      navigator.geolocation.clearWatch(this.watchId);
      this.watchId = null;
    }
  }

  watchPosition(
    onPositionUpdate: (position: GeolocationPosition) => void,
    onError?: (error: GeolocationPositionError) => void
  ): void {
    if (!navigator.geolocation) {
      console.error('La géolocalisation n\'est pas supportée');
      return;
    }

    this.watchId = navigator.geolocation.watchPosition(
      onPositionUpdate,
      onError,
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 30000
      }
    );
  }

  calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
  ): number {
    const R = 6371;
    const dLat = this.toRad(lat2 - lat1);
    const dLon = this.toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) *
        Math.cos(this.toRad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private toRad(degrees: number): number {
    return degrees * (Math.PI / 180);
  }

  async deleteOldLocations(daysOld: number = 30): Promise<void> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    const { error } = await supabase
      .from('commercial_locations')
      .delete()
      .lt('timestamp', cutoffDate.toISOString())
      .eq('is_active', false);

    if (error) throw error;
  }
}

export const geolocationService = new GeolocationService();
