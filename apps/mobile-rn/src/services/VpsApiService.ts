import { ChildProfile } from '../types/profile';
import { normalizeServerUrl } from '../utils/urlHelpers';

export interface RegisterDeviceResponse {
  pairing_code: string;
  device_id: string;
  expires_in?: number;
  qr_code_data?: string;
}

export interface DeviceStatusResponse {
  status: 'pending' | 'paired' | 'expired';
  auth_token?: string;
  device_id?: string;
  profile?: {
    id: string;
    name: string;
    avatar_icon?: string;
    age_bracket?: string;
  };
  message?: string;
}

export interface CatalogResponse {
  videos?: any[];
  categories?: any[];
  profile?: any;
}

class VpsApiService {
  private static instance: VpsApiService;
  private authToken: string | null = null;

  public static getInstance(): VpsApiService {
    if (!VpsApiService.instance) {
      VpsApiService.instance = new VpsApiService();
    }
    return VpsApiService.instance;
  }

  private constructor() {}

  public setAuthToken(token: string | null): void {
    this.authToken = token;
  }

  public getAuthToken(): string | null {
    return this.authToken;
  }

  private getHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    };
    if (this.authToken && this.authToken.length > 0) {
      headers.Authorization = `Bearer ${this.authToken}`;
    }
    return headers;
  }

  private async fetchWithTimeout(
    url: string,
    options: RequestInit = {},
    timeoutMs: number = 15000
  ): Promise<Response> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
      });
      return response;
    } finally {
      clearTimeout(timer);
    }
  }

  public async checkHealth(baseUrl: string): Promise<boolean> {
    try {
      const cleanUrl = normalizeServerUrl(baseUrl);
      const res = await this.fetchWithTimeout(`${cleanUrl}/api/v1/health`, {
        method: 'GET',
        headers: this.getHeaders(),
      }, 8000);
      return res.status === 200;
    } catch (_) {
      return false;
    }
  }

  public async pingHealth(baseUrl: string): Promise<number | null> {
    const cleanUrl = normalizeServerUrl(baseUrl);
    const start = Date.now();
    try {
      const res = await this.fetchWithTimeout(`${cleanUrl}/api/v1/health`, {
        method: 'GET',
        headers: this.getHeaders(),
      }, 8000);
      if (res.status === 200) {
        return Date.now() - start;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // --- Device Registration & Pairing ---
  public async registerDevice(
    baseUrl: string,
    deviceName: string = 'Kids Tablet'
  ): Promise<RegisterDeviceResponse | null> {
    try {
      const cleanUrl = normalizeServerUrl(baseUrl);
      const res = await this.fetchWithTimeout(`${cleanUrl}/api/v1/devices/register`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({ device_name: deviceName }),
      });
      if (res.status === 200) {
        const data = await res.json();
        return data as RegisterDeviceResponse;
      }
      return null;
    } catch (e) {
      console.error('registerDevice error:', e);
      return null;
    }
  }

  public async checkDeviceStatus(
    baseUrl: string,
    pairingCode: string
  ): Promise<DeviceStatusResponse | null> {
    try {
      const cleanUrl = normalizeServerUrl(baseUrl);
      const res = await this.fetchWithTimeout(
        `${cleanUrl}/api/v1/devices/status/${encodeURIComponent(pairingCode)}`,
        {
          method: 'GET',
          headers: this.getHeaders(),
        }
      );
      if (res.status === 200) {
        return (await res.json()) as DeviceStatusResponse;
      }
      if (res.status === 404) {
        return { status: 'expired', message: 'Pairing code expired or invalid' };
      }
      return null;
    } catch (e) {
      console.error('checkDeviceStatus error:', e);
      return null;
    }
  }

  // --- Profiles & Curated Catalog ---
  public async fetchProfiles(baseUrl: string): Promise<ChildProfile[]> {
    try {
      const cleanUrl = normalizeServerUrl(baseUrl);
      const res = await this.fetchWithTimeout(`${cleanUrl}/api/v1/profiles`, {
        method: 'GET',
        headers: this.getHeaders(),
      });
      if (res.status === 200) {
        const data = await res.json();
        if (Array.isArray(data)) {
          return data.map((p: any) => ({
            id: String(p.id),
            name: p.name || 'Child',
            avatarIcon: p.avatar_icon || 'bear',
            ageBracket: p.age_bracket || 'all',
          }));
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  public async fetchCatalog(
    baseUrl: string,
    profileId?: string
  ): Promise<CatalogResponse | null> {
    try {
      const cleanUrl = normalizeServerUrl(baseUrl);
      let endpoint = `${cleanUrl}/api/v1/catalog`;
      if (profileId) {
        endpoint += `?profile_id=${encodeURIComponent(profileId)}`;
      }
      const res = await this.fetchWithTimeout(endpoint, {
        method: 'GET',
        headers: this.getHeaders(),
      });
      if (res.status === 200) {
        return (await res.json()) as CatalogResponse;
      }
      return null;
    } catch (e) {
      console.error('fetchCatalog error:', e);
      return null;
    }
  }

  public async ingestUrl(
    baseUrl: string,
    url: string,
    options: {
      categoryId?: string;
      quality?: string;
      allowedProfileIds?: string[];
    } = {}
  ): Promise<boolean> {
    try {
      const cleanUrl = normalizeServerUrl(baseUrl);
      const res = await this.fetchWithTimeout(`${cleanUrl}/api/v1/ingest`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({
          url,
          category_id: options.categoryId || 'cartoons',
          quality: options.quality || '720p',
          allowed_profile_ids: options.allowedProfileIds,
        }),
      });
      return res.status === 200;
    } catch (_) {
      return false;
    }
  }

  public async deleteVideos(baseUrl: string, videoIds: string[]): Promise<boolean> {
    if (videoIds.length === 0) return true;
    try {
      const cleanUrl = normalizeServerUrl(baseUrl);
      const idsParam = videoIds.map((id) => encodeURIComponent(id)).join(',');
      const res = await this.fetchWithTimeout(
        `${cleanUrl}/api/studio/videos?ids=${idsParam}`,
        {
          method: 'DELETE',
          headers: this.getHeaders(),
        }
      );
      return res.status === 200;
    } catch (_) {
      return false;
    }
  }

  public async syncWatchEvents(
    baseUrl: string,
    events: any[]
  ): Promise<{ success: boolean; synced_count?: number } | null> {
    if (events.length === 0) return { success: true, synced_count: 0 };
    try {
      const cleanUrl = normalizeServerUrl(baseUrl);
      const res = await this.fetchWithTimeout(`${cleanUrl}/api/metrics/watch`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({ events }),
      });
      if (res.status === 200) {
        return await res.json();
      }
      return null;
    } catch (e) {
      console.error('syncWatchEvents error:', e);
      return null;
    }
  }
}

export const vpsApiService = VpsApiService.getInstance();
