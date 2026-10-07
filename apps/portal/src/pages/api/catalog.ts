import type { APIRoute } from 'astro';
import { GET as v1Catalog } from './v1/catalog';

export const GET: APIRoute = async (context) => {
  return v1Catalog(context);
};
