import { supabase } from './supabase';

export class ImageUploadService {
  private bucketName = 'product-images';

  async uploadImage(file: File, bucketName?: string): Promise<string> {
    const bucket = bucketName || this.bucketName;
    const fileExt = file.name.split('.').pop();
    const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
    const filePath = `${fileName}`;

    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false,
      });

    if (error) {
      throw error;
    }

    const { data: urlData } = supabase.storage
      .from(bucket)
      .getPublicUrl(data.path);

    return urlData.publicUrl;
  }

  async deleteImage(imageUrl: string, bucketName?: string): Promise<void> {
    const bucket = bucketName || this.bucketName;
    const urlParts = imageUrl.split('/');
    const fileName = urlParts[urlParts.length - 1];

    const { error } = await supabase.storage
      .from(bucket)
      .remove([fileName]);

    if (error) {
      console.error('Error deleting image:', error);
    }
  }

  validateImageFile(file: File): { valid: boolean; error?: string } {
    const maxSize = 5 * 1024 * 1024;
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];

    if (!allowedTypes.includes(file.type)) {
      return {
        valid: false,
        error: 'Type de fichier non supporté. Utilisez JPG, PNG, WEBP ou GIF.',
      };
    }

    if (file.size > maxSize) {
      return {
        valid: false,
        error: 'Le fichier est trop volumineux. Taille maximale : 5 MB.',
      };
    }

    return { valid: true };
  }
}

export const imageUploadService = new ImageUploadService();
