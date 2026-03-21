#!/usr/bin/env node
/**
 * wipe_all.js — Deletes ALL data from Firestore AND Firebase Auth users.
 *
 * Clears:
 *   • Firestore: users, swipes, matches, blocks, reports,
 *                user_secrets, otp_verifications, chat messages
 *   • Firebase Auth: all user accounts
 *
 * Usage:
 *   node wipe_all.js              # Dry-run — shows counts of what would be deleted
 *   node wipe_all.js --confirm    # Actually deletes everything
 */

import { db } from './firebase_init.js';
import { getAuth } from 'firebase-admin/auth';

const auth = getAuth();

const COLLECTIONS = [
  'users',
  'swipes',
  'matches',
  'blocks',
  'reports',
  'user_secrets',
  'otp_verifications',
];

async function deleteDocs(refs) {
  for (let i = 0; i < refs.length; i += 500) {
    const batch = db.batch();
    refs.slice(i, i + 500).forEach((ref) => batch.delete(ref));
    await batch.commit();
  }
}

async function listAllAuthUsers() {
  const users = [];
  let nextPageToken;
  do {
    const result = await auth.listUsers(1000, nextPageToken);
    users.push(...result.users);
    nextPageToken = result.pageToken;
  } while (nextPageToken);
  return users;
}

async function wipeAll(dryRun) {
  console.log(dryRun
    ? '\n🔍 DRY RUN — scanning everything...\n'
    : '\n🗑️  WIPING all data (Firestore + Auth)...\n');

  let total = 0;

  // ── 1. Chat messages (sub-collections under chats/{matchId}/messages) ──

  const matchSnap = await db.collection('matches').get();
  const chatMsgRefs = [];

  for (const doc of matchSnap.docs) {
    const msgs = await db.collection('chats').doc(doc.id).collection('messages').get();
    msgs.docs.forEach((m) => chatMsgRefs.push(m.ref));
  }

  console.log(`   chats/messages    : ${chatMsgRefs.length} messages`);
  total += chatMsgRefs.length;

  if (!dryRun && chatMsgRefs.length > 0) {
    await deleteDocs(chatMsgRefs);
    console.log(`     ✅ deleted`);
  }

  // ── 2. Top-level Firestore collections ──

  for (const col of COLLECTIONS) {
    const snap = await db.collection(col).get();
    console.log(`   ${col.padEnd(20)}: ${snap.size} documents`);
    total += snap.size;

    if (!dryRun && snap.size > 0) {
      await deleteDocs(snap.docs.map((d) => d.ref));
      console.log(`     ✅ deleted`);
    }
  }

  // ── 3. Firebase Auth users ──

  const authUsers = await listAllAuthUsers();
  console.log(`   Firebase Auth     : ${authUsers.length} users`);
  total += authUsers.length;

  if (!dryRun && authUsers.length > 0) {
    // deleteUsers supports up to 1000 at a time
    const uids = authUsers.map((u) => u.uid);
    for (let i = 0; i < uids.length; i += 1000) {
      const batch = uids.slice(i, i + 1000);
      const result = await auth.deleteUsers(batch);
      if (result.failureCount > 0) {
        console.log(`     ⚠️  ${result.failureCount} auth deletions failed`);
        result.errors.forEach((e) => console.log(`        ${e.error.message}`));
      }
    }
    console.log(`     ✅ deleted ${authUsers.length} auth users`);
  }

  // ── Summary ──

  if (dryRun) {
    console.log(`\n📊 Total: ${total} items would be deleted.`);
    console.log('   Run with --confirm to actually delete.\n');
  } else {
    console.log(`\n✅ Wiped ${total} items (Firestore docs + Auth users).\n`);
  }
}

// ── CLI ──────────────────────────────────────────────────────────────────────

const dryRun = !process.argv.includes('--confirm');
await wipeAll(dryRun);
process.exit(0);
