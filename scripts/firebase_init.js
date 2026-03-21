/**
 * Shared Firebase Admin init for all test scripts.
 *
 * Auth: Uses Application Default Credentials.
 * Run `firebase login` first, then:
 *   export GOOGLE_APPLICATION_CREDENTIALS=<path-to-service-account-key.json>
 * Or simply run with: npx firebase-tools auth:export
 *
 * The simplest way: download a service account key from
 * Firebase Console → Project Settings → Service Accounts → Generate New Private Key
 * and save it as scripts/service-account.json
 */

import { initializeApp, cert, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { readFileSync, existsSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const saPath = join(__dirname, 'service-account.json');

if (existsSync(saPath)) {
  const sa = JSON.parse(readFileSync(saPath, 'utf8'));
  initializeApp({ credential: cert(sa) });
} else {
  // Falls back to ADC (works if `gcloud auth application-default login` is configured)
  initializeApp({ credential: applicationDefault() });
}

export const db = getFirestore();
