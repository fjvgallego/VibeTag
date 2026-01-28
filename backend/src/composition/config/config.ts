import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

export const envSchema = z.object({
  NODE_ENV: z.enum(['dev', 'pro']).default('dev'),
  DATABASE_URL_DEV: z.url(),
  DATABASE_URL_PRO: z.url(),
  PORT: z
    .string()
    .default('3000')
    .transform((val) => Number(val)),
});

const _env = envSchema.safeParse(process.env);

if (!_env.success) {
  console.error('❌ Invalid environment variables:', _env.error.format());
  throw new Error('Invalid environment variables');
}

const env = _env.data;

export const config = {
  NODE_ENV: env.NODE_ENV,
  PORT: env.PORT,
  DATABASE_URL: env.NODE_ENV === 'pro' ? env.DATABASE_URL_PRO : env.DATABASE_URL_DEV,
};
