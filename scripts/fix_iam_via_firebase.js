#!/usr/bin/env node
/**
 * fix_iam_via_firebase.js — Uses the Firebase CLI's cached OAuth token
 * to grant "Service Account Token Creator" to the compute SA.
 *
 * This works because `firebase login` already authorized your Google account
 * which (as project owner) has permission to modify IAM policies.
 *
 * Usage:  node fix_iam_via_firebase.js
 */

import { readFileSync, existsSync } from "fs";
import { homedir } from "os";
import { join } from "path";

const PROJECT_ID = "pr-5c180";
const PROJECT_NUMBER = "205599538881";
const COMPUTE_SA = `${PROJECT_NUMBER}-compute@developer.gserviceaccount.com`;
const ROLE = "roles/iam.serviceAccountTokenCreator";

// ── Find Firebase CLI token ───────────────────────────────────────────
// Firebase CLI stores its refresh token in ~/.config/configstore/firebase-tools.json

function getFirebaseToken() {
  const paths = [
    join(homedir(), ".config", "configstore", "firebase-tools.json"),
    join(homedir(), ".config", "firebase", "firebase-tools.json"),
  ];

  for (const p of paths) {
    if (existsSync(p)) {
      try {
        const data = JSON.parse(readFileSync(p, "utf-8"));
        const token = data?.tokens?.refresh_token;
        if (token) {
          console.log(`🔧  Found Firebase token at: ${p}`);
          return token;
        }
        // Newer format
        if (data?.user?.tokens?.refresh_token) {
          console.log(`🔧  Found Firebase token at: ${p}`);
          return data.user.tokens.refresh_token;
        }
      } catch {}
    }
  }
  return null;
}

async function refreshAccessToken(refreshToken) {
  // Firebase CLI uses the same OAuth client as gcloud
  const CLIENT_ID =
    "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com";
  const CLIENT_SECRET = "j9iVZfS8kkCEFUPaAeJV0sAi";

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: refreshToken,
      grant_type: "refresh_token",
    }),
  });

  const data = await res.json();
  if (!data.access_token) {
    throw new Error(`Token refresh failed: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

async function main() {
  console.log("╔══════════════════════════════════════════════╗");
  console.log("║  Fix IAM: Grant signBlob to Cloud Functions  ║");
  console.log("╚══════════════════════════════════════════════╝\n");

  const refreshToken = getFirebaseToken();
  if (!refreshToken) {
    console.error(
      "❌  Could not find Firebase CLI token.\n" +
      "    Run `firebase login` first, then re-run this script."
    );
    process.exit(1);
  }

  console.log("🔧  Refreshing access token...");
  const accessToken = await refreshAccessToken(refreshToken);
  console.log("✅  Got access token\n");

  // 1. Get current IAM policy
  console.log("🔧  Fetching IAM policy for project:", PROJECT_ID);
  const getRes = await fetch(
    `https://cloudresourcemanager.googleapis.com/v1/projects/${PROJECT_ID}:getIamPolicy`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
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

  console.log(`✅  Got policy (version ${policy.version}, ${policy.bindings?.length} bindings)\n`);

  // 2. Check if already granted
  const member = `serviceAccount:${COMPUTE_SA}`;
  const existing = policy.bindings?.find((b) => b.role === ROLE);

  if (existing?.members?.includes(member)) {
    console.log(`✅  ${COMPUTE_SA} already has ${ROLE}`);
    console.log("    If auth still fails, wait 1-2 minutes for propagation.\n");
    return;
  }

  // 3. Add the role
  console.log(`🔧  Granting ${ROLE} to:`);
  console.log(`    ${COMPUTE_SA}\n`);

  if (existing) {
    existing.members.push(member);
  } else {
    policy.bindings = policy.bindings || [];
    policy.bindings.push({ role: ROLE, members: [member] });
  }

  // 4. Set updated policy
  const setRes = await fetch(
    `https://cloudresourcemanager.googleapis.com/v1/projects/${PROJECT_ID}:setIamPolicy`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ policy }),
    }
  );
  const result = await setRes.json();

  if (result.error) {
    console.error("❌  Failed to set IAM policy:", result.error.message);
    console.error("    Details:", JSON.stringify(result.error.details, null, 2));
    process.exit(1);
  }

  console.log("✅  Successfully granted 'Service Account Token Creator' role!");
  console.log("    Wait 1-2 minutes for propagation, then test the app.\n");
  console.log("💡  To verify, run:  node test_auth_flow.js\n");
}

main().catch((err) => {
  console.error("❌  Fatal:", err.message);
  process.exit(1);
});
