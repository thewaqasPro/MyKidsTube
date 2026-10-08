import type { APIRoute } from 'astro';
import { GET as studioGet, DELETE as studioDelete, OPTIONS as studioOptions } from '../studio/videos';

export const OPTIONS: APIRoute = async (context) => {
  return studioOptions(context);
};

export const GET: APIRoute = async (context) => {
  return studioGet(context);
};

export const DELETE: APIRoute = async (context) => {
  return studioDelete(context);
};
