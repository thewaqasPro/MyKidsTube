import type { APIRoute } from 'astro';
import { POST as v1Pair } from './v1/devices/pair';

export const POST: APIRoute = async (context) => {
  return v1Pair(context);
};
