#!/usr/bin/env node
/**
 * create_profile.js — Interactive script to create a single user profile.
 *
 * Walks you through every field, then writes it to Firestore.
 *
 * Usage:
 *   node create_profile.js
 *   node create_profile.js --id custom_user_id    # Use a specific doc ID
 */

import { db } from './firebase_init.js';
import { getAuth } from 'firebase-admin/auth';
import { createInterface } from 'readline';
import { randomUUID, randomBytes } from 'crypto';

const auth = getAuth();

function generateSecret() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  return Array.from(randomBytes(32)).map((b) => chars[b % chars.length]).join('');
}

const rl = createInterface({ input: process.stdin, output: process.stdout });
const ask = (q) => new Promise((res) => rl.question(q, res));

const ALL_INTERESTS = [
  'Hiking', 'Yoga', 'Coffee', 'Travel', 'Photography', 'Cooking',
  'Reading', 'Movies', 'Music', 'Gaming', 'Fitness', 'Wine Tasting',
  'Art', 'Dancing', 'Running', 'Surfing', 'Tech', 'Food',
  'Dogs', 'Cats', 'Board Games', 'Meditation', 'Concerts', 'Theater',
  'Volunteering', 'Writing', 'Cycling', 'Swimming', 'Fashion', 'Anime',
  'Gardening', 'Camping', 'Baking', 'Podcasts', 'Startups', 'Basketball',
  'Cricket', 'Football', 'Tennis', 'Badminton', 'Chess', 'Karaoke',
  'Stand-up Comedy', 'Astronomy', 'DIY', 'Languages', 'Skincare',
  'Pottery', 'Journaling', 'Investing', 'NFTs', 'Spirituality', 'Cars',
];

// ── Helpers ──────────────────────────────────────────────────────────────────

function pickOption(prompt, options) {
  return new Promise(async (resolve) => {
    console.log();
    options.forEach((opt, i) => console.log(`   ${i + 1}. ${opt}`));
    while (true) {
      const ans = await ask(`\n  ${prompt} [1-${options.length}]: `);
      const idx = parseInt(ans.trim(), 10) - 1;
      if (idx >= 0 && idx < options.length) {
        resolve(options[idx]);
        return;
      }
      console.log('  ⚠️  Invalid choice, try again.');
    }
  });
}

function pickMultiple(prompt, options, min, max) {
  return new Promise(async (resolve) => {
    // Show in columns
    console.log();
    const cols = 3;
    for (let i = 0; i < options.length; i += cols) {
      const row = options.slice(i, i + cols)
        .map((opt, j) => `   ${String(i + j + 1).padStart(2)}. ${opt.padEnd(18)}`)
        .join('');
      console.log(row);
    }

    while (true) {
      const ans = await ask(`\n  ${prompt} (comma-separated numbers, ${min}-${max}): `);
      const nums = ans.split(',').map((s) => parseInt(s.trim(), 10) - 1);
      const valid = nums.filter((n) => n >= 0 && n < options.length);
      const unique = [...new Set(valid)];

      if (unique.length >= min && unique.length <= max) {
        resolve(unique.map((i) => options[i]));
        return;
      }
      console.log(`  ⚠️  Pick between ${min} and ${max} interests.`);
    }
  });
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`
╔══════════════════════════════════════════════════╗
║        📝  Create a Single Profile  📝          ║
╚══════════════════════════════════════════════════╝
`);

  // Email (used for Firebase Auth)
  let email;
  while (true) {
    email = (await ask('  Work email (e.g. name@company.com): ')).trim().toLowerCase();
    if (email.includes('@') && email.includes('.')) break;
    console.log('  ⚠️  Enter a valid email address.');
  }

  // Basic info
  const firstName = (await ask('  First name: ')).trim();

  let age;
  while (true) {
    const ageStr = await ask('  Age: ');
    age = parseInt(ageStr.trim(), 10);
    if (age >= 18 && age <= 99) break;
    console.log('  ⚠️  Age must be between 18 and 99.');
  }

  const gender = await pickOption('Gender:', ['Man', 'Woman', 'Non-binary']);
  const interestedIn = await pickOption('Interested in:', ['Men', 'Women', 'Everyone']);

  // Location
  const city = (await ask('\n  City: ')).trim();

  // Bio
  let bio;
  while (true) {
    bio = (await ask('  Bio (10-200 chars): ')).trim();
    if (bio.length >= 10 && bio.length <= 200) break;
    console.log(`  ⚠️  Bio is ${bio.length} chars — needs to be 10-200.`);
  }

  // Photos
  console.log('\n  Photos — enter URLs one per line (blank line to stop, min 1):');
  const photos = [];
  while (true) {
    const url = (await ask(`   Photo ${photos.length + 1}: `)).trim();
    if (!url) {
      if (photos.length >= 1) break;
      console.log('  ⚠️  At least 1 photo is required.');
      continue;
    }
    photos.push(url);
    if (photos.length >= 6) {
      console.log('  (max 6 photos reached)');
      break;
    }
  }

  // Interests
  const interests = await pickMultiple('Pick your interests', ALL_INTERESTS, 3, 5);

  // Work info
  console.log('\n  ── Work Details ──');
  const companyDomain = (await ask('  Company email domain (e.g. walmart.com): ')).trim();
  const role = (await ask('  Role / job title: ')).trim();
  const industryCategory = await pickOption('Industry:', [
    'Technology', 'Finance', 'Healthcare', 'E-Commerce', 'Consulting',
    'Media', 'Education', 'Marketing', 'Legal', 'Manufacturing', 'Other',
  ]);

  const showIndustryAns = await ask('  Show industry on profile? (Y/n): ');
  const showIndustry = showIndustryAns.trim().toLowerCase() !== 'n';

  const showRoleAns = await ask('  Show role on profile? (Y/n): ');
  const showRole = showRoleAns.trim().toLowerCase() !== 'n';

  // ── Review ──────────────────────────────────────────────────────────────

  console.log('\n  ── Review ──────────────────────────────────────');
  console.log(`  Email:      ${email}`);
  console.log(`  Name:       ${firstName}, ${age}`);
  console.log(`  Gender:     ${gender}  →  Interested in: ${interestedIn}`);
  console.log(`  City:       ${city}`);
  console.log(`  Bio:        ${bio.slice(0, 60)}${bio.length > 60 ? '…' : ''}`);
  console.log(`  Photos:     ${photos.length} photo(s)`);
  console.log(`  Interests:  ${interests.join(', ')}`);
  console.log(`  Work:       ${role} @ ${companyDomain} (${industryCategory})`);
  console.log(`  Show:       industry=${showIndustry}, role=${showRole}`);
  console.log('  ────────────────────────────────────────────────\n');

  const confirm = await ask('  Save to Firestore + create Auth account? (Y/n): ');
  if (confirm.trim().toLowerCase() === 'n') {
    console.log('\n  Aborted.\n');
    rl.close();
    process.exit(0);
  }

  // ── Save ────────────────────────────────────────────────────────────────

  // 1. Create Firebase Auth user
  const secret = generateSecret();
  let authUser;
  try {
    authUser = await auth.createUser({
      email,
      password: secret,
      displayName: firstName,
    });
  } catch (e) {
    if (e.code === 'auth/email-already-exists') {
      console.log(`\n  ⚠️  Auth account for ${email} already exists. Fetching existing UID...`);
      authUser = await auth.getUserByEmail(email);
    } else {
      throw e;
    }
  }

  const uid = authUser.uid;
  console.log(`  🔐 Auth user: ${uid}`);

  // 2. Store secret in user_secrets (keyed by email, same as the app does)
  await db.collection('user_secrets').doc(email).set({
    secret,
    uid,
    createdAt: new Date().toISOString(),
  });

  // 3. Save profile (keyed by UID, same as the app does)
  const profile = {
    id: uid,
    firstName,
    age,
    gender,
    interestedIn,
    bio,
    photos,
    interests,
    city,
    companyDomain,
    workVerified: true,
    industryCategory,
    role,
    showIndustry,
    showRole,
    createdAt: new Date().toISOString(),
  };

  await db.collection('users').doc(uid).set(profile);

  console.log(`\n  ✅ All done!`);
  console.log(`     Auth account : ${email} (uid: ${uid})`);
  console.log(`     Firestore    : users/${uid}`);
  console.log(`     Secret       : user_secrets/${email}\n`);

  rl.close();
  process.exit(0);
}

main();
