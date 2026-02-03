import * as Sentry from '@sentry/node';
import { config } from './composition/config/config';

Sentry.init({
  dsn: config.SENTRY_DSN,
  integrations: [],
  sendDefaultPii: true, // As requested in docs
  tracesSampleRate: 1.0,
});
