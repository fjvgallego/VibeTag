import * as Sentry from '@sentry/node';
import { config } from './composition/config/config';

Sentry.init({
  dsn: config.SENTRY_DSN,
  integrations: [],
  // NOTE: sendDefaultPii includes IP addresses and other personal data in error reports.
  // Ensure this aligns with GDPR/CCPA compliance and your privacy policy.
  sendDefaultPii: true, // As requested in docs
  tracesSampleRate: 1.0,
});
