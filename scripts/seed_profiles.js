#!/usr/bin/env node
/**
 * seed_profiles.js — Creates realistic test user profiles in Firestore.
 *
 * Usage:
 *   node seed_profiles.js              # Creates all 10 default test profiles
 *   node seed_profiles.js --count 5    # Creates 5 profiles
 *   node seed_profiles.js --clear      # Deletes existing test profiles first, then seeds
 */

import { db } from './firebase_init.js';
import { getAuth } from 'firebase-admin/auth';
import { randomBytes } from 'crypto';

const auth = getAuth();

function generateSecret() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  return Array.from(randomBytes(32)).map((b) => chars[b % chars.length]).join('');
}

// ── Test data pools ─────────────────────────────────────────────────────────

const PLACEHOLDER_PHOTOS = [
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=500&fit=crop',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=500&fit=crop',
  'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&h=500&fit=crop',
  'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=500&fit=crop',
  'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=500&fit=crop',
  'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400&h=500&fit=crop',
];

const INTERESTS = [
  'Hiking', 'Yoga', 'Coffee', 'Travel', 'Photography', 'Cooking',
  'Reading', 'Movies', 'Music', 'Gaming', 'Fitness', 'Wine Tasting',
  'Art', 'Dancing', 'Running', 'Surfing', 'Tech', 'Food',
  'Dogs', 'Cats', 'Board Games', 'Meditation', 'Concerts', 'Theater',
];

const CITIES = [
  'Mumbai', 'Bangalore', 'Delhi', 'Hyderabad', 'Chennai',
  'Pune', 'Kolkata', 'Ahmedabad', 'Gurgaon', 'Noida',
];

const INDUSTRIES = [
  'Technology', 'Finance', 'Healthcare', 'E-Commerce', 'Consulting',
  'Media', 'Education', 'Marketing', 'Legal', 'Manufacturing',
];

const ROLES = [
  'Software Engineer', 'Product Manager', 'Data Scientist',
  'UX Designer', 'Marketing Manager', 'Business Analyst',
  'Engineering Manager', 'Finance Lead', 'Operations Head', 'Founder',
];

const DOMAINS = [
  'walmart.com', 'google.com', 'microsoft.com', 'amazon.com',
  'flipkart.com', 'infosys.com', 'tcs.com', 'wipro.com',
];

const BIOS_WOMEN = [
  'Design nerd by day, amateur chef by night. Looking for someone who appreciates both good UX and good pasta.',
  'Corporate lawyer who secretly writes poetry. Seeking someone who can keep up with my hiking pace and my reading list.',
  'Data scientist who believes the best algorithms are found in grandma\'s recipe book. Dog mom. Coffee dependent.',
  'Marketing exec with a travel addiction. 30 countries and counting. Need a co-pilot for the next adventure.',
  'Product manager by profession, stand-up comedy fan by passion. Warning: I will quote The Office in every situation.',
];

const BIOS_MEN = [
  'Engineer who can actually cook. My biryani has a 5-star rating from my mom, which is the toughest critic there is.',
  'Finance guy who doesn\'t talk about finance on dates. I\'d rather talk about that documentary you just watched.',
  'Startup founder running on chai and ambition. Looking for someone who gets why I\'m excited about spreadsheets.',
  'Ex-consultant turned product builder. I traded my suits for hoodies but kept the presentation skills.',
  'Software architect who builds apps by day and Lego sets by night. Yes, I\'m that kind of nerd.',
];

const FIRST_NAMES_WOMEN = ['Priya', 'Ananya', 'Isha', 'Riya', 'Meera', 'Tara', 'Neha', 'Sana', 'Kavya', 'Diya'];
const FIRST_NAMES_MEN = ['Arjun', 'Rohan', 'Vikram', 'Aditya', 'Karan', 'Dev', 'Nikhil', 'Sameer', 'Raj', 'Ayaan'];

// ── Helpers ──────────────────────────────────────────────────────────────────

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function pickN(arr, n) {
  const shuffled = [...arr].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, n);
}

function randomAge() {
  return 24 + Math.floor(Math.random() * 12); // 24–35
}

function randomPhotos() {
  const count = 2 + Math.floor(Math.random() * 3); // 2–4 photos
  return pickN(PLACEHOLDER_PHOTOS, count);
}

function buildProfile(index) {
  const isWoman = index % 2 === 0;
  const gender = isWoman ? 'Woman' : 'Man';
  const firstName = isWoman
    ? FIRST_NAMES_WOMEN[index % FIRST_NAMES_WOMEN.length]
    : FIRST_NAMES_MEN[index % FIRST_NAMES_MEN.length];
  const bio = isWoman
    ? BIOS_WOMEN[index % BIOS_WOMEN.length]
    : BIOS_MEN[index % BIOS_MEN.length];

  const interestedOptions = isWoman ? ['Men', 'Everyone'] : ['Women', 'Everyone'];

  return {
    firstName,
    age: randomAge(),
    gender,
    interestedIn: pick(interestedOptions),
    bio,
    photos: randomPhotos(),
    interests: pickN(INTERESTS, 3 + Math.floor(Math.random() * 3)), // 3–5
    city: pick(CITIES),
    companyDomain: pick(DOMAINS),
    workVerified: true,
    industryCategory: pick(INDUSTRIES),
    role: pick(ROLES),
    showIndustry: Math.random() > 0.3,
    showRole: Math.random() > 0.3,
    createdAt: new Date().toISOString(),
  };
}

// ── Main ─────────────────────────────────────────────────────────────────────

const TEST_EMAIL_DOMAIN = '@test-grred.com';

async function clearTestProfiles() {
  console.log('🗑️  Clearing existing test profiles (Auth + Firestore)...');

  // Find test user_secrets by email domain
  const secretsSnap = await db.collection('user_secrets').get();
  const testSecrets = secretsSnap.docs.filter((d) => d.id.endsWith(TEST_EMAIL_DOMAIN));

  if (testSecrets.length === 0) {
    console.log('   No existing test profiles found.');
    return;
  }

  const batch = db.batch();
  const authUids = [];

  for (const doc of testSecrets) {
    const uid = doc.data().uid;
    if (uid) {
      authUids.push(uid);
      // Delete Firestore profile
      batch.delete(db.collection('users').doc(uid));
    }
    // Delete user_secret
    batch.delete(doc.ref);
  }

  await batch.commit();
  console.log(`   Deleted ${testSecrets.length} Firestore profiles + secrets.`);

  // Delete Firebase Auth users
  if (authUids.length > 0) {
    const result = await auth.deleteUsers(authUids);
    console.log(`   Deleted ${authUids.length - result.failureCount} Auth users.`);
    if (result.failureCount > 0) {
      console.log(`   ⚠️  ${result.failureCount} Auth deletions failed.`);
    }
  }
}

async function seedProfiles(count) {
  console.log(`\n🌱 Seeding ${count} test profiles (Auth + Firestore)...\n`);
  const ids = [];

  for (let i = 0; i < count; i++) {
    const profile = buildProfile(i);
    const email = `${profile.firstName.toLowerCase()}${i}@test-grred.com`;
    const secret = generateSecret();

    // 1. Create Firebase Auth user
    let authUser;
    try {
      authUser = await auth.createUser({
        email,
        password: secret,
        displayName: profile.firstName,
      });
    } catch (e) {
      if (e.code === 'auth/email-already-exists') {
        authUser = await auth.getUserByEmail(email);
      } else {
        console.log(`   ❌ Failed to create auth for ${email}: ${e.message}`);
        continue;
      }
    }

    const uid = authUser.uid;

    // 2. Store secret in user_secrets (keyed by email)
    const batch = db.batch();
    batch.set(db.collection('user_secrets').doc(email), {
      secret,
      uid,
      createdAt: new Date().toISOString(),
    });

    // 3. Save profile (keyed by UID)
    profile.id = uid;
    batch.set(db.collection('users').doc(uid), profile);
    await batch.commit();

    ids.push(uid);
    console.log(`   ✅ ${profile.firstName.padEnd(8)} (${email})  →  uid: ${uid.slice(0, 12)}…  ${profile.gender}, ${profile.age}, ${profile.city}`);
  }

  console.log(`\n🎉 Done! Created ${ids.length} profiles with Auth accounts.`);
  console.log(`   Login emails: <name><index>@test-grred.com\n`);
  return ids;
}

// ── CLI ──────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const shouldClear = args.includes('--clear');
const countIndex = args.indexOf('--count');
const count = countIndex !== -1 ? parseInt(args[countIndex + 1], 10) : 10;

if (shouldClear) await clearTestProfiles();
await seedProfiles(count);
process.exit(0);
