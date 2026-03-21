#!/usr/bin/env node
/**
 * fix_iam.js — Grants the "Service Account Token Creator" role to the
 * Compute Engine default service account so that Cloud Functions can
 * call `auth.createCustomToken()`.
 *
 * Usage:  node fix_iam.js
 *
 * Requires: scripts/service-account.json (Firebase Admin SDK key)
 */

import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const saPath = join(__dirname, "service-account.json");

let sa;
try {
  sa = JSON.parse(readFileSync(saPath, "utf-8"));
} catch {
  console.error("❌  Cannot read service-account.json — place it in scripts/");
  process.exit(1);
}

const projectId = sa.project_id;
// The default compute service account used by Cloud Functions (Gen 2)
const computeSA = `${sa.project_id.replace(/-/g, "").length > 0 ? "" : ""}`;

// ── Get access token using service account credentials ──────────────

import crypto from "crypto";

function createJWT(sa) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/cloud-platform",
    aud: "https://oauth2.googleapis.com/token",
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

async function getAccessToken() {
  const jwt = createJWT(sa);
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  if (!data.access_token) {
    throw new Error(`Token exchange failed: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

// ── Patch IAM policy ────────────────────────────────────────────────

async function main() {
  console.log(`🔧  Project: ${projectId}`);
  console.log(`🔧  Getting access token...`);
  const token = await getAccessToken();

  // 1. Get current IAM policy
  console.log(`🔧  Fetching current IAM policy...`);
  const getRes = await fetch(
    `https://cloudresourcemanager.googleapis.com/v1/projects/${projectId}:getIamPolicy`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ options: { requestedPolicyVersion: 3 } }),
    }
  );
  const policy = await getRes.json();

  if (policy.error) {
    console.error("❌  Failed to get IAM policy:", policy.error.message);
    process.exit(1);
  }

  // 2. Find the Cloud Functions service account (default compute)
  // For Gen 2 functions it's: PROJECT_NUMBER-compute@developer.gserviceaccount.com
  // We can extract the project number from the service account key's client_id
  // or from the existing policy bindings.

  // Let's find it from the logs — it's 205599538881
  // Actually, let's extract it from project config
  const projectNumber = sa.client_id
    ? sa.client_id.split(".")[0]
    : null;

  // Look through existing bindings to find the compute service account
  let computeEmail = null;
  for (const binding of policy.bindings || []) {
    for (const member of binding.members || []) {
      if (member.includes("-compute@developer.gserviceaccount.com")) {
        computeEmail = member.replace("serviceAccount:", "");
        break;
      }
    }
    if (computeEmail) break;
  }

  if (!computeEmail) {
    // Fallback: try the standard pattern
    // Get project number from the API
    console.log("🔧  Looking up project number...");
    const projRes = await fetch(
      `https://cloudresourcemanager.googleapis.com/v1/projects/${projectId}`,
      {
        headers: { Authorization: `Bearer ${token}` },
      }
    );
    const projData = await projRes.json();
    const num = projData.projectNumber;
    if (num) {
      computeEmail = `${num}-compute@developer.gserviceaccount.com`;
    } else {
      console.error("❌  Could not determine compute service account email.");
      console.error("    Manually grant 'Service Account Token Creator' role to your Cloud Functions service account.");
      process.exit(1);
    }
  }

  console.log(`🔧  Cloud Functions SA: ${computeEmail}`);

  // 3. Check if the role is already granted
  const ROLE = "roles/iam.serviceAccountTokenCreator";
  const member = `serviceAccount:${computeEmail}`;

  const existingBinding = policy.bindings?.find((b) => b.role === ROLE);
  if (existingBinding?.members?.includes(member)) {
    console.log(`✅  ${computeEmail} already has ${ROLE}`);
    console.log("    If auth still fails, the role may need a few minutes to propagate.");
    return;
  }

  // 4. Add the binding
  if (existingBinding) {
    existingBinding.members.push(member);
  } else {
    policy.bindings = policy.bindings || [];
    policy.bindings.push({ role: ROLE, members: [member] });
  }

  // 5. Set the updated policy
  console.log(`🔧  Granting ${ROLE}...`);
  const setRes = await fetch(
    `https://cloudresourcemanager.googleapis.com/v1/projects/${projectId}:setIamPolicy`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ policy }),
    }
  );
  const result = await setRes.json();

  if (result.error) {
    console.error("❌  Failed to set IAM policy:", result.error.message);
    process.exit(1);
  }

  console.log(`✅  Granted '${ROLE}' to ${computeEmail}`);
  console.log("    It may take 1-2 minutes for the permission to propagate.");
  console.log("    After that, try signing up again in the app!");
}

main().catch((err) => {
  console.error("❌  Unexpected error:", err);
  process.exit(1);
});
