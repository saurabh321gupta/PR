#!/usr/bin/env node
/**
 * seed_matches.js — Creates matches between test users (or between a real user and test users).
 *
 * Usage:
 *   node seed_matches.js                           # Match test users with each other (pairs)
 *   node seed_matches.js --with <your-uid>         # Match YOUR real account with test users
 *   node seed_matches.js --with <uid> --count 3    # Match you with 3 test users
 *   node seed_matches.js --clear                   # Delete test matches first, then seed
 *
 * This also creates the corresponding swipe documents (both directions) so
 * the swipe screen won't re-show matched profiles.
 */

import { db } from './firebase_init.js';

const TEST_PREFIX = 'test_user_';

// ── Helpers ──────────────────────────────────────────────────────────────────

function matchId(uid1, uid2) {
  const ids = [uid1, uid2].sort();
  return ids.join('_');
}

async function getTestUserIds() {
  const snap = await db.collection('users').get();
  return snap.docs
    .map((d) => d.id)
    .filter((id) => id.startsWith(TEST_PREFIX))
    .sort();
}

async function clearTestMatches() {
  console.log('🗑️  Clearing test matches & swipes...');
  const [matchSnap, swipeSnap] = await Promise.all([
    db.collection('matches').get(),
    db.collection('swipes').get(),
  ]);

  const batch = db.batch();
  let count = 0;

  for (const doc of matchSnap.docs) {
    const users = doc.data().users || [];
    if (users.some((u) => u.startsWith(TEST_PREFIX))) {
      batch.delete(doc.ref);
      // Also delete the chat sub-collection
      const msgs = await db.collection('chats').doc(doc.id).collection('messages').get();
      for (const m of msgs.docs) batch.delete(m.ref);
      count++;
    }
  }

  for (const doc of swipeSnap.docs) {
    const d = doc.data();
    if (
      (d.fromUserId && d.fromUserId.startsWith(TEST_PREFIX)) ||
      (d.toUserId && d.toUserId.startsWith(TEST_PREFIX))
    ) {
      batch.delete(doc.ref);
    }
  }

  if (count > 0) {
    await batch.commit();
    console.log(`   Deleted ${count} test matches + related swipes.\n`);
  } else {
    console.log('   No test matches found.\n');
  }
}

async function createMatch(uid1, uid2) {
  const batch = db.batch();
  const mId = matchId(uid1, uid2);
  const now = new Date().toISOString();

  // Match document
  batch.set(db.collection('matches').doc(mId), {
    users: [uid1, uid2].sort(),
    createdAt: now,
  });

  // Mutual swipes (so swipe screen won't re-show them)
  batch.set(db.collection('swipes').doc(), {
    fromUserId: uid1,
    toUserId: uid2,
    direction: 'like',
    createdAt: now,
  });
  batch.set(db.collection('swipes').doc(), {
    fromUserId: uid2,
    toUserId: uid1,
    direction: 'like',
    createdAt: now,
  });

  await batch.commit();
  return mId;
}

// ── Main ─────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const shouldClear = args.includes('--clear');
const withIndex = args.indexOf('--with');
const realUid = withIndex !== -1 ? args[withIndex + 1] : null;
const countIndex = args.indexOf('--count');
const maxMatches = countIndex !== -1 ? parseInt(args[countIndex + 1], 10) : 5;

if (shouldClear) await clearTestMatches();

const testIds = await getTestUserIds();
if (testIds.length === 0) {
  console.log('⚠️  No test profiles found. Run seed_profiles.js first.');
  process.exit(1);
}

console.log(`Found ${testIds.length} test profiles.\n`);

if (realUid) {
  // Match real user with N test users
  const toMatch = testIds.slice(0, maxMatches);
  console.log(`💕 Creating ${toMatch.length} matches between YOU (${realUid}) and test users:\n`);

  for (const tid of toMatch) {
    const mId = await createMatch(realUid, tid);
    const userDoc = await db.collection('users').doc(tid).get();
    const name = userDoc.exists ? userDoc.data().firstName : tid;
    console.log(`   ✅ ${name} (${tid})  →  match: ${mId}`);
  }
} else {
  // Match test users with each other in pairs
  const pairs = [];
  for (let i = 0; i < testIds.length - 1 && pairs.length < maxMatches; i += 2) {
    pairs.push([testIds[i], testIds[i + 1]]);
  }

  console.log(`💕 Creating ${pairs.length} matches between test users:\n`);

  for (const [a, b] of pairs) {
    const mId = await createMatch(a, b);
    console.log(`   ✅ ${a} ↔ ${b}  →  match: ${mId}`);
  }
}

console.log('\n🎉 Done!\n');
process.exit(0);
