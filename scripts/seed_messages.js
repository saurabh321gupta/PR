#!/usr/bin/env node
/**
 * seed_messages.js — Populates chat threads with realistic messages.
 *
 * Usage:
 *   node seed_messages.js                  # Adds messages to ALL existing matches
 *   node seed_messages.js --match <id>     # Adds messages to a specific match
 *   node seed_messages.js --count 20       # Number of messages per chat (default: 12)
 */

import { db } from './firebase_init.js';

// ── Conversation templates ──────────────────────────────────────────────────

const CONVERSATIONS = [
  [
    'Hey! Nice to match with you 😊',
    'Hi! Likewise! Your bio cracked me up 😂',
    'Haha thanks, I try. So what do you do?',
    'Product manager at a tech company. You?',
    'Software engineer — we\'re natural enemies apparently 😄',
    'Lol the classic PM-engineer dynamic. At least we matched first before the sprint planning 😅',
    'True true. So what\'s your go-to weekend plan?',
    'Usually hiking if the weather is good, otherwise a cozy cafe and a book. You?',
    'I love hiking too! Have you been to any trails recently?',
    'Yeah did the Rajmachi trek last month. It was amazing!',
    'Oh I\'ve been wanting to do that one. Maybe we should go together sometime?',
    'I\'d love that! Let\'s plan it 🙌',
    'How about next weekend if the weather holds up?',
    'Perfect. I know a great starting point. I\'ll share the details.',
    'Sounds like a plan! Looking forward to it ☺️',
  ],
  [
    'Your dog in the second photo is adorable! What\'s their name?',
    'That\'s Bruno! He\'s a golden retriever and basically my entire personality 😂',
    'I respect that honestly. I\'m a dog person too',
    'Then we\'re already off to a great start. Do you have one?',
    'Yep! A beagle named Mochi. She runs my life.',
    'Mochi 😭 that\'s the cutest name. We need a dog playdate.',
    'Absolutely. There\'s a great dog park in Cubbon Park area',
    'Oh I go there all the time! Surprised we haven\'t run into each other',
    'Probably have and just didn\'t know it. The universe works in mysterious ways.',
    'Haha very philosophical for a dating app conversation',
    'What can I say, I contain multitudes 😌',
    'So when are we doing this dog park meetup?',
    'How about Saturday morning? Bruno is most social before noon',
    'Saturday works! Mochi is always ready. 10am?',
    'Done! See you there 🐕',
  ],
  [
    'Okay I have to ask — is that pasta in your third photo homemade?',
    'Yes! I make fresh pasta every Sunday. It\'s my therapy 🍝',
    'That\'s incredible. I can barely make maggi without burning it',
    'Everyone starts somewhere! Maggi is an art form too 😄',
    'You\'re too kind. What\'s your specialty?',
    'Cacio e pepe. Simple but so satisfying when you nail it.',
    'I don\'t even know what that is but I already want some',
    'It\'s just pasta with pecorino cheese and black pepper. Sounds simple but the technique is everything.',
    'Okay now I\'m definitely hungry. Are you always this dangerous?',
    'Only when I talk about food. Which is always.',
    'A person after my own heart honestly',
    'So should we grab dinner sometime? I promise not to judge your cooking skills 😂',
    'Only if you cook for me eventually. Deal?',
    'Deal. How about Thursday evening?',
    'Thursday is perfect! You pick the place 🍕',
  ],
];

// ── Helpers ──────────────────────────────────────────────────────────────────

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomTimestamp(baseDate, offsetMinutes) {
  const d = new Date(baseDate.getTime() + offsetMinutes * 60 * 1000);
  // Add some random seconds so messages aren't perfectly spaced
  d.setSeconds(Math.floor(Math.random() * 60));
  return d.toISOString();
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function seedMessagesForMatch(matchDoc, msgCount) {
  const data = matchDoc.data();
  const users = data.users;
  const mId = matchDoc.id;

  if (!users || users.length < 2) return;

  // Pick a random conversation template
  const convo = pick(CONVERSATIONS);
  const messages = convo.slice(0, msgCount);

  const baseDate = new Date();
  baseDate.setHours(baseDate.getHours() - messages.length); // start N hours ago

  const batch = db.batch();
  let lastMsg = '';
  let lastSender = '';
  let lastTime = '';

  for (let i = 0; i < messages.length; i++) {
    const sender = users[i % 2]; // alternate between users
    const ts = randomTimestamp(baseDate, i * 15); // 15min apart roughly
    const text = messages[i];

    batch.set(db.collection('chats').doc(mId).collection('messages').doc(), {
      senderId: sender,
      text,
      createdAt: ts,
    });

    lastMsg = text;
    lastSender = sender;
    lastTime = ts;
  }

  // Update match preview
  batch.update(db.collection('matches').doc(mId), {
    lastMessage: lastMsg,
    lastMessageAt: lastTime,
    lastMessageSenderId: lastSender,
  });

  await batch.commit();

  // Fetch names for pretty logging
  const [u1Doc, u2Doc] = await Promise.all([
    db.collection('users').doc(users[0]).get(),
    db.collection('users').doc(users[1]).get(),
  ]);
  const n1 = u1Doc.exists ? u1Doc.data().firstName : users[0];
  const n2 = u2Doc.exists ? u2Doc.data().firstName : users[1];

  console.log(`   💬 ${n1} ↔ ${n2}  (${mId})  →  ${messages.length} messages`);
}

// ── CLI ──────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const matchIndex = args.indexOf('--match');
const specificMatch = matchIndex !== -1 ? args[matchIndex + 1] : null;
const countIndex = args.indexOf('--count');
const msgCount = countIndex !== -1 ? parseInt(args[countIndex + 1], 10) : 12;

console.log(`\n💬 Seeding messages (${msgCount} per chat)...\n`);

if (specificMatch) {
  const doc = await db.collection('matches').doc(specificMatch).get();
  if (!doc.exists) {
    console.log(`⚠️  Match ${specificMatch} not found.`);
    process.exit(1);
  }
  await seedMessagesForMatch(doc, msgCount);
} else {
  const matchSnap = await db.collection('matches').get();
  if (matchSnap.empty) {
    console.log('⚠️  No matches found. Run seed_matches.js first.');
    process.exit(1);
  }
  for (const doc of matchSnap.docs) {
    await seedMessagesForMatch(doc, msgCount);
  }
}

console.log('\n🎉 Done!\n');
process.exit(0);
