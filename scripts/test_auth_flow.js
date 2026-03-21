#!/usr/bin/env node
/**
 * test_auth_flow.js — End-to-end diagnostic for the Cloud Function auth flow.
 *
 * Tests each step independently so you can see exactly where things break:
 *   1. Firebase Admin SDK initialisation
 *   2. Firestore read/write (user_secrets)
 *   3. Firebase Auth user creation
 *   4. Custom token generation  ← the step that requires signBlob permission
 *   5. Cleanup test data
 *
 * Also tests the deployed Cloud Function endpoints directly from the CLI.
 *
 * Usage:  node test_auth_flow.js
 */

import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import crypto from "crypto";

const __dirname = dirname(fileURLToPath(import.meta.url));
const saPath = join(__dirname, "service-account.json");

let sa;
try {
  sa = JSON.parse(readFileSync(saPath, "utf-8"));
} catch {
  console.error("❌  Cannot read service-account.json — place it in scripts/");
  process.exit(1);
}

// ── Firebase Admin init ───────────────────────────────────────────────
import { initializeApp, cert } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

const TEST_EMAIL = `diag-test-${Date.now()}@test-grred.com`;
let testUid = null;

console.log("╔══════════════════════════════════════════════════════╗");
console.log("║       Grred Auth Flow Diagnostic                    ║");
console.log("╚══════════════════════════════════════════════════════╝\n");

async function step(name, fn) {
  process.stdout.write(`  ⏳ ${name}...`);
  try {
    const result = await fn();
    console.log(` ✅`);
    if (result) console.log(`     → ${result}`);
    return true;
  } catch (err) {
    console.log(` ❌`);
    console.log(`     → ${err.message || err}`);
    if (err.code) console.log(`     → code: ${err.code}`);
    return false;
  }
}

async function main() {
  // ── Step 1: Admin SDK init ──────────────────────────────────────────
  let db, auth;
  const s1 = await step("Initialize Firebase Admin SDK", () => {
    const app = initializeApp({ credential: cert(sa) });
    db = getFirestore();
    auth = getAuth();
    return `Project: ${sa.project_id}`;
  });
  if (!s1) {
    console.log("\n  🛑  Cannot proceed without Admin SDK.\n");
    return;
  }

  // ── Step 2: Firestore write ─────────────────────────────────────────
  const s2 = await step("Firestore write (user_secrets)", async () => {
    await db.collection("user_secrets").doc(TEST_EMAIL).set({
      secret: "diag-test-secret",
      uid: "pending",
      createdAt: new Date().toISOString(),
    });
    return `Wrote user_secrets/${TEST_EMAIL}`;
  });

  // ── Step 3: Firestore read ──────────────────────────────────────────
  const s3 = await step("Firestore read (user_secrets)", async () => {
    const doc = await db.collection("user_secrets").doc(TEST_EMAIL).get();
    if (!doc.exists) throw new Error("Document not found after write!");
    return `Read back: ${JSON.stringify(doc.data())}`;
  });

  // ── Step 4: Auth user creation ──────────────────────────────────────
  const s4 = await step("Firebase Auth — create user", async () => {
    const userRecord = await auth.createUser({
      email: TEST_EMAIL,
      password: "DiagTestPassword123!",
    });
    testUid = userRecord.uid;
    return `Created UID: ${testUid}`;
  });

  // ── Step 5: Custom token generation (THIS is the step that was failing) ──
  let customToken = null;
  const s5 = await step(
    "Firebase Auth — createCustomToken (requires signBlob IAM)",
    async () => {
      if (!testUid) throw new Error("Skipped — no UID from step 4");
      customToken = await auth.createCustomToken(testUid);
      return `Token: ${customToken.substring(0, 40)}...`;
    }
  );

  // ── Step 6: Test the deployed Cloud Functions ─────────────────────

  console.log("\n  ── Deployed Cloud Function tests ──\n");

  // We'll call the functions using a simple HTTP POST (like the Firebase SDK does)
  const FUNCTIONS_URL = `https://us-central1-${sa.project_id}.cloudfunctions.net`;

  // Get an access token for calling the function
  function createJWT() {
    const now = Math.floor(Date.now() / 1000);
    const header = { alg: "RS256", typ: "JWT" };
    const payload = {
      iss: sa.client_email,
      sub: sa.client_email,
      aud: `https://us-central1-${sa.project_id}.cloudfunctions.net/createAccount`,
      iat: now,
      exp: now + 3600,
    };
    const encode = (obj) =>
      Buffer.from(JSON.stringify(obj)).toString("base64url");
    const unsigned = `${encode(header)}.${encode(payload)}`;
    const sign = crypto.createSign("RSA-SHA256");
    sign.update(unsigned);
    const signature = sign.sign(sa.private_key, "base64url");
    return `${unsigned}.${signature}`;
  }

  // For callable functions, we need to use the callable protocol
  const CALLABLE_EMAIL = `diag-callable-${Date.now()}@test-grred.com`;
  let callableUid = null;

  const s6 = await step(
    "Call createAccount Cloud Function",
    async () => {
      const res = await fetch(`${FUNCTIONS_URL}/createAccount`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data: { email: CALLABLE_EMAIL } }),
      });
      const body = await res.json();
      if (body.error) {
        throw new Error(
          `${body.error.status || body.error.code}: ${body.error.message}`
        );
      }
      if (body.result?.token) {
        callableUid = body.result.uid;
        return `Got custom token + UID: ${callableUid}`;
      }
      return `Response: ${JSON.stringify(body).substring(0, 200)}`;
    }
  );

  const s7 = await step(
    "Call signInUser Cloud Function",
    async () => {
      if (!callableUid) throw new Error("Skipped — createAccount didn't succeed");
      const res = await fetch(`${FUNCTIONS_URL}/signInUser`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data: { email: CALLABLE_EMAIL } }),
      });
      const body = await res.json();
      if (body.error) {
        throw new Error(
          `${body.error.status || body.error.code}: ${body.error.message}`
        );
      }
      if (body.result?.token) {
        return `Got custom token for UID: ${body.result.uid}`;
      }
      return `Response: ${JSON.stringify(body).substring(0, 200)}`;
    }
  );

  // ── Cleanup ─────────────────────────────────────────────────────────

  console.log("\n  ── Cleanup ──\n");

  await step("Delete test Firestore docs", async () => {
    const deleted = [];
    await db.collection("user_secrets").doc(TEST_EMAIL).delete();
    deleted.push(TEST_EMAIL);
    try {
      await db.collection("user_secrets").doc(CALLABLE_EMAIL).delete();
      deleted.push(CALLABLE_EMAIL);
    } catch {}
    return `Deleted user_secrets for: ${deleted.join(", ")}`;
  });

  await step("Delete test Auth users", async () => {
    const uids = [testUid, callableUid].filter(Boolean);
    if (uids.length === 0) return "No UIDs to clean up";
    await auth.deleteUsers(uids);
    return `Deleted UIDs: ${uids.join(", ")}`;
  });

  // ── Summary ─────────────────────────────────────────────────────────

  console.log("\n╔══════════════════════════════════════════════════════╗");
  console.log("║       Summary                                       ║");
  console.log("╚══════════════════════════════════════════════════════╝\n");

  const results = [
    ["Admin SDK init", s1],
    ["Firestore write", s2],
    ["Firestore read", s3],
    ["Auth user creation", s4],
    ["Custom token (signBlob)", s5],
    ["createAccount function", s6],
    ["signInUser function", s7],
  ];

  for (const [name, ok] of results) {
    console.log(`  ${ok ? "✅" : "❌"} ${name}`);
  }

  const allPassed = results.every(([, ok]) => ok);
  console.log(
    allPassed
      ? "\n  🎉 All checks passed! Auth flow should work in the app.\n"
      : "\n  ⚠️  Some checks failed. Fix the issues above and re-run.\n"
  );

  if (!s5 || !s6) {
    console.log("  💡 To fix the signBlob permission issue, run:");
    console.log("     node fix_iam.js\n");
  }
}

main().catch((err) => {
  console.error("❌  Fatal:", err);
  process.exit(1);
});
