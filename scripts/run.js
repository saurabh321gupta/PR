#!/usr/bin/env node
/**
 * run.js — Interactive test-data manager for Grred.
 *
 * Usage:  node run.js   (or:  npm test  from scripts/)
 *
 * Presents a menu to seed profiles, matches, messages, or clean up.
 */

import { createInterface } from 'readline';
import { execSync } from 'child_process';
import { dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const rl = createInterface({ input: process.stdin, output: process.stdout });
const ask = (q) => new Promise((res) => rl.question(q, res));

function run(cmd) {
  console.log(`\n── Running: ${cmd} ──\n`);
  try {
    execSync(cmd, { cwd: __dirname, stdio: 'inherit' });
  } catch (e) {
    console.error(`\n❌ Command failed: ${e.message}\n`);
  }
}

async function main() {
  console.log(`
╔══════════════════════════════════════════════════╗
║          🔥  Grred Test Data Manager  🔥         ║
╠══════════════════════════════════════════════════╣
║                                                  ║
║   1 │ Create single profile (interactive)         ║
║   2 │ Seed test profiles (bulk)                  ║
║   3 │ Seed matches (test ↔ test)                 ║
║   4 │ Seed matches (YOUR account ↔ test users)   ║
║   5 │ Seed chat messages                         ║
║   6 │ Seed everything (profiles + matches + msgs)║
║   7 │ Cleanup test_user_ data (dry run)          ║
║   8 │ Cleanup test_user_ data (for real)         ║
║   9 │ Wipe entire DB (dry run)                   ║
║  10 │ Wipe entire DB (for real)                  ║
║   0 │ Exit                                       ║
║                                                  ║
╚══════════════════════════════════════════════════╝
`);

  const choice = await ask('  Pick an option: ');

  switch (choice.trim()) {
    case '1':
      run('node create_profile.js');
      break;

    case '2': {
      const count = await ask('  How many profiles? [10]: ');
      const n = count.trim() || '10';
      const clear = await ask('  Clear existing test profiles first? (y/N): ');
      const flag = clear.trim().toLowerCase() === 'y' ? '--clear' : '';
      run(`node seed_profiles.js --count ${n} ${flag}`);
      break;
    }

    case '3':
      run('node seed_matches.js');
      break;

    case '4': {
      const uid = await ask('  Enter YOUR Firebase UID: ');
      if (!uid.trim()) {
        console.log('  ⚠️  No UID provided. Aborting.');
        break;
      }
      const count = await ask('  How many matches? [5]: ');
      const n = count.trim() || '5';
      run(`node seed_matches.js --with ${uid.trim()} --count ${n}`);
      break;
    }

    case '5': {
      const count = await ask('  Messages per chat? [12]: ');
      const n = count.trim() || '12';
      run(`node seed_messages.js --count ${n}`);
      break;
    }

    case '6':
      run('node seed_profiles.js --clear && node seed_matches.js --clear && node seed_messages.js');
      break;

    case '7':
      run('node cleanup.js');
      break;

    case '8':
      run('node cleanup.js --confirm');
      break;

    case '9':
      run('node wipe_all.js');
      break;

    case '10': {
      const confirm = await ask('  ⚠️  This deletes ALL data (profiles, matches, chats, swipes, blocks). Type "WIPE" to confirm: ');
      if (confirm.trim() === 'WIPE') {
        run('node wipe_all.js --confirm');
      } else {
        console.log('  Aborted.');
      }
      break;
    }

    case '0':
      console.log('  Bye! 👋\n');
      break;

    default:
      console.log('  Unknown option.\n');
  }

  rl.close();
}

main();
