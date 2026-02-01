import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { buildContainer } from './composition/containers/container';
import { createAppRouter } from './infrastructure/http/routes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());

app.use(express.json());

const container = buildContainer();

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/', (req, res) => {
  res.json({});
});

app.use(createAppRouter(container));

app.listen(PORT, () => {
  console.info(`Server running on port ${PORT}`);
});
