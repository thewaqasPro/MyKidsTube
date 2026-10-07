import type { APIRoute } from 'astro';
import { POST as v1Ingest, OPTIONS as v1Options } from './v1/ingest';

export const OPTIONS: APIRoute = async (context) => {
  return v1Options(context);
};

export const POST: APIRoute = async (context) => {
  return v1Ingest(context);
};
