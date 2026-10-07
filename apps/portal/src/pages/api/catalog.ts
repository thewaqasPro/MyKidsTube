import type { APIRoute } from 'astro';
import { GET as v1Catalog, OPTIONS as v1Options } from './v1/catalog';

export const OPTIONS: APIRoute = async (context) => {
  return v1Options(context);
};

export const GET: APIRoute = async (context) => {
  return v1Catalog(context);
};
