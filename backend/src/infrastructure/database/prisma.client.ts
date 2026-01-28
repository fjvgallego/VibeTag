import { PrismaClient } from '../../../prisma/generated/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import { config } from '../../composition/config/config';

const pool = new Pool({ connectionString: config.DATABASE_URL });
const adapter = new PrismaPg(pool);

export const prisma = new PrismaClient({ adapter });
