import type { APIRoute } from 'astro';
import { POST as v1Ingest } from './v1/ingest';

export const POST: APIRoute = async (context) => {
  return v1Ingest(context);
};
