#!/usr/bin/env node
/**
 * cleanup.js — Removes ALL test data from Firestore.
 *
 * What it deletes:
 *   • users     — docs starting with "test_user_"
 *   • swipes    — any swipe involving a test user
 *   • matches   — any match involving a test user
 *   • chats     — message sub-collections for test matches
 *
 * Usage:
 *   node cleanup.js              # Dry-run (shows what would be deleted)
 *   node cleanup.js --confirm    # Actually deletes
 *   node cleanup.js --nuke       # ⚠️  Deletes ALL data (test + real) — use with extreme caution
 */

import { db } from './firebase_init.js';

const TEST_PREFIX = 'test_user_';

async function deleteBatch(refs, label) {
  if (refs.length === 0) {
    console.log(`   ${label}: nothing to delete`);
    return 0;
  }

  // Firestore batch limit is 500
  for (let i = 0; i < refs.length; i += 500) {
    const batch = db.batch();
    refs.slice(i, i + 500).forEach((ref) => batch.delete(ref));
    await batch.commit();
  }

  console.log(`   ${label}: deleted ${refs.length} documents`);
  return refs.length;
}

async function cleanup(dryRun) {
  const mode = dryRun ? '🔍 DRY RUN' : '🗑️  DELETING';
  console.log(`\n${mode} — scanning for test data...\n`);

  let total = 0;

  // 1. Test users
  const usersSnap = await db.collection('users').get();
  const testUserRefs = usersSnap.docs
    .filter((d) => d.id.startsWith(TEST_PREFIX))
    .map((d) => d.ref);
  console.log(`   users:   ${testUserRefs.length} test profiles`);
  total += testUserRefs.length;

  // 2. Swipes involving test users
  const swipesSnap = await db.collection('swipes').get();
  const testSwipeRefs = swipesSnap.docs
    .filter((d) => {
      const data = d.data();
      return (
        (data.fromUserId && data.fromUserId.startsWith(TEST_PREFIX)) ||
        (data.toUserId && data.toUserId.startsWith(TEST_PREFIX))
      );
    })
    .map((d) => d.ref);
  console.log(`   swipes:  ${testSwipeRefs.length} test swipes`);
  total += testSwipeRefs.length;

  // 3. Matches involving test users + their chat messages
  const matchesSnap = await db.collection('matches').get();
  const testMatchRefs = [];
  const chatMsgRefs = [];

  for (const doc of matchesSnap.docs) {
    const users = doc.data().users || [];
    if (users.some((u) => u.startsWith(TEST_PREFIX))) {
      testMatchRefs.push(doc.ref);
      // Collect chat messages
      const msgs = await db.collection('chats').doc(doc.id).collection('messages').get();
      msgs.docs.forEach((m) => chatMsgRefs.push(m.ref));
    }
  }
  console.log(`   matches: ${testMatchRefs.length} test matches`);
  console.log(`   chats:   ${chatMsgRefs.length} test messages`);
  total += testMatchRefs.length + chatMsgRefs.length;

  if (dryRun) {
    console.log(`\n📊 Total: ${total} documents would be deleted.`);
    console.log('   Run with --confirm to actually delete.\n');
    return;
  }

  // Actually delete
  let deleted = 0;
  deleted += await deleteBatch(chatMsgRefs, 'chats');
  deleted += await deleteBatch(testMatchRefs, 'matches');
  deleted += await deleteBatch(testSwipeRefs, 'swipes');
  deleted += await deleteBatch(testUserRefs, 'users');

  console.log(`\n✅ Cleaned up ${deleted} test documents.\n`);
}

async function nukeEverything() {
  console.log('\n⚠️  NUKING ALL DATA — this cannot be undone!\n');

  const collections = ['users', 'swipes', 'matches'];
  let total = 0;

  for (const col of collections) {
    const snap = await db.collection(col).get();
    const refs = snap.docs.map((d) => d.ref);

    // For matches, also delete chat messages
    if (col === 'matches') {
      for (const doc of snap.docs) {
        const msgs = await db.collection('chats').doc(doc.id).collection('messages').get();
        const msgRefs = msgs.docs.map((m) => m.ref);
        total += await deleteBatch(msgRefs, `chats/${doc.id}/messages`);
      }
    }

    total += await deleteBatch(refs, col);
  }

  console.log(`\n💀 Nuked ${total} documents across all collections.\n`);
}

// ── CLI ──────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);

if (args.includes('--nuke')) {
  if (!args.includes('--confirm')) {
    console.log('\n⚠️  --nuke requires --confirm flag. This deletes ALL data (test + real).');
    console.log('   Usage: node cleanup.js --nuke --confirm\n');
    process.exit(1);
  }
  await nukeEverything();
} else {
  const dryRun = !args.includes('--confirm');
  await cleanup(dryRun);
}

process.exit(0);
