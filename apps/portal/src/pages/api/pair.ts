import type { APIRoute } from 'astro';
import { POST as v1Pair, OPTIONS as v1Options } from './v1/devices/pair';

export const OPTIONS: APIRoute = async (context) => {
  return v1Options(context);
};

export const POST: APIRoute = async (context) => {
  return v1Pair(context);
};
