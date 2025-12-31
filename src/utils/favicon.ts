import { companyService } from '../services/company.service';

export const updateFavicon = async () => {
  try {
    const settings = await companyService.getSettings();

    const favicon = document.getElementById('favicon') as HTMLLinkElement;
    if (favicon) {
      favicon.href = settings?.logo_url || '/whatsapp_image_2025-12-31_at_10.43.31.jpeg';
    }

    const appleTouchIcon = document.querySelector('link[rel="apple-touch-icon"]') as HTMLLinkElement;
    if (appleTouchIcon) {
      appleTouchIcon.href = settings?.logo_url || '/whatsapp_image_2025-12-31_at_10.43.31.jpeg';
    }

    if (settings?.name) {
      document.title = settings.name;
    } else {
      document.title = 'Gestion commerciale';
    }

    await updateManifest(settings?.logo_url, settings?.name);
  } catch (error) {
    console.error('Error updating favicon:', error);
  }
};

const updateManifest = async (logoUrl?: string, companyName?: string) => {
  try {
    const manifestLink = document.querySelector('link[rel="manifest"]') as HTMLLinkElement;
    if (!manifestLink) return;

    const response = await fetch('/manifest.json');
    const manifest = await response.json();

    manifest.name = companyName || 'Gestion commerciale';
    manifest.short_name = (companyName || 'Gestion').substring(0, 12);

    const iconSrc = logoUrl || '/whatsapp_image_2025-12-31_at_10.43.31.jpeg';
    const iconType = iconSrc.endsWith('.jpeg') || iconSrc.endsWith('.jpg') ? 'image/jpeg' : 'image/png';
    manifest.icons = [
      {
        src: iconSrc,
        sizes: '192x192',
        type: iconType,
        purpose: 'any maskable'
      },
      {
        src: iconSrc,
        sizes: '512x512',
        type: iconType,
        purpose: 'any maskable'
      }
    ];

    const manifestBlob = new Blob([JSON.stringify(manifest)], { type: 'application/json' });
    const manifestURL = URL.createObjectURL(manifestBlob);
    manifestLink.href = manifestURL;
  } catch (error) {
    console.error('Error updating manifest:', error);
  }
};
