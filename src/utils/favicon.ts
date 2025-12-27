import { companyService } from '../services/company.service';

export const updateFavicon = async () => {
  try {
    const settings = await companyService.getSettings();

    if (settings?.logo_url) {
      const favicon = document.getElementById('favicon') as HTMLLinkElement;
      if (favicon) {
        favicon.href = settings.logo_url;
      }
    }

    if (settings?.name) {
      document.title = settings.name;
    }
  } catch (error) {
    console.error('Error updating favicon:', error);
  }
};
