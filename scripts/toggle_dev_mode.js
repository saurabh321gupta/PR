#!/usr/bin/env node
/**
 * toggle_dev_mode.js — Toggle dev mode for the Grred app.
 *
 * When dev mode is ON:
 *   - OTP is shown on screen (not emailed)
 *   - No SMTP credentials needed
 *
 * When dev mode is OFF:
 *   - OTP is emailed to the work email via Gmail SMTP
 *   - SMTP secrets must be configured in Cloud Functions
 *
 * Usage:
 *   node toggle_dev_mode.js          # Show current status
 *   node toggle_dev_mode.js on       # Enable dev mode
 *   node toggle_dev_mode.js off      # Disable dev mode
 */

import { db } from "./firebase_init.js";

const ref = db.collection("app_config").doc("settings");

async function main() {
  const action = process.argv[2]?.toLowerCase();

  const doc = await ref.get();
  const current = doc.exists ? doc.data() : {};

  if (!action) {
    console.log("\n╔═══════════════════════════════════════╗");
    console.log("║       Grred App Config                ║");
    console.log("╚═══════════════════════════════════════╝\n");
    console.log(`  Dev Mode: ${current.devMode ? "✅ ON" : "❌ OFF"}`);
    console.log("");
    console.log("  Usage:");
    console.log("    node toggle_dev_mode.js on    → OTP shown on screen");
    console.log("    node toggle_dev_mode.js off   → OTP sent via email\n");
    return;
  }

  if (action === "on" || action === "true" || action === "1") {
    await ref.set({ ...current, devMode: true }, { merge: true });
    console.log("✅  Dev mode ENABLED — OTP will be shown on screen (no emails sent)");
  } else if (action === "off" || action === "false" || action === "0") {
    await ref.set({ ...current, devMode: false }, { merge: true });
    console.log("✅  Dev mode DISABLED — OTP will be emailed to the user");
    console.log("    Make sure SMTP secrets are configured:");
    console.log("      firebase functions:secrets:set SMTP_EMAIL");
    console.log("      firebase functions:secrets:set SMTP_PASSWORD");
  } else {
    console.error(`❌  Unknown action: "${action}". Use "on" or "off".`);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error("❌  Error:", err.message);
  process.exit(1);
});
