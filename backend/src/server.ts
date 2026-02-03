import './instrument';
import * as Sentry from '@sentry/node';
import express from 'express';
import cors from 'cors';
import { config } from './composition/config/config';
import { buildContainer } from './composition/containers/container';
import { createAppRouter } from './infrastructure/http/routes';

const app = express();
const PORT = config.PORT || 3000;

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

Sentry.setupExpressErrorHandler(app);

app.listen(PORT, () => {
  console.info(`Server running on port ${PORT}`);
});
