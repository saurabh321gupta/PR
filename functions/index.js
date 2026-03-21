const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const crypto = require("crypto");

initializeApp();

// ── Auth helpers ──────────────────────────────────────────────────────────────

function generateSecurePassword() {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*";
  return Array.from(crypto.randomBytes(32))
    .map((b) => chars[b % chars.length])
    .join("");
}

// ── createAccount ─────────────────────────────────────────────────────────────
// Called from the app after OTP is verified (sign-up flow).
// Creates a Firebase Auth user, stores the secret, returns a custom token.
exports.createAccount = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const email = request.data?.email;
    if (!email || typeof email !== "string" || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "A valid email is required.");
    }

    const db = getFirestore();
    const auth = getAuth();

    // Check if account already exists
    const existing = await db.collection("user_secrets").doc(email).get();
    if (existing.exists) {
      throw new HttpsError(
        "already-exists",
        "An account with this email already exists."
      );
    }

    // Create Firebase Auth user (server-to-server — no carrier issues)
    const secret = generateSecurePassword();
    let userRecord;
    try {
      userRecord = await auth.createUser({
        email,
        password: secret,
      });
    } catch (err) {
      if (err.code === "auth/email-already-exists") {
        // Auth user exists but user_secrets didn't — recover gracefully
        userRecord = await auth.getUserByEmail(email);
      } else {
        console.error("createAccount Auth error:", err);
        throw new HttpsError("internal", "Failed to create account.");
      }
    }

    // Store secret in Firestore (keyed by email)
    await db.collection("user_secrets").doc(email).set({
      secret,
      uid: userRecord.uid,
      createdAt: new Date().toISOString(),
    });

    // Generate custom token for the client to sign in with
    const customToken = await auth.createCustomToken(userRecord.uid);

    console.log(`createAccount: ${email} → uid ${userRecord.uid}`);
    return { token: customToken, uid: userRecord.uid };
  }
);

// ── signInUser ────────────────────────────────────────────────────────────────
// Called from the app after OTP is verified (sign-in flow).
// Verifies the user exists, returns a custom token.
exports.signInUser = onCall(
  { enforceAppCheck: false },
  async (request) => {
    const email = request.data?.email;
    if (!email || typeof email !== "string" || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "A valid email is required.");
    }

    const db = getFirestore();
    const auth = getAuth();

    // Look up the stored secret
    const secretDoc = await db.collection("user_secrets").doc(email).get();
    if (!secretDoc.exists) {
      throw new HttpsError("not-found", "No account found for this email.");
    }

    const { uid } = secretDoc.data();

    // Verify the Auth user still exists
    try {
      await auth.getUser(uid);
    } catch (err) {
      throw new HttpsError("not-found", "Auth account not found.");
    }

    // Generate custom token
    const customToken = await auth.createCustomToken(uid);

    console.log(`signInUser: ${email} → uid ${uid}`);
    return { token: customToken, uid };
  }
);

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Safely sends an FCM message. Ignores invalid/unregistered tokens silently.
 */
async function safeSend(message) {
  try {
    await getMessaging().send(message);
  } catch (err) {
    // Token expired or unregistered — not a fatal error
    if (
      err.code !== "messaging/registration-token-not-registered" &&
      err.code !== "messaging/invalid-registration-token"
    ) {
      console.error("FCM send error:", err);
    }
  }
}

// ── onMatchCreated ────────────────────────────────────────────────────────────
// Fires when matches/{matchId} is created (mutual like).
// Notifies BOTH users.
exports.onMatchCreated = onDocumentCreated(
  "matches/{matchId}",
  async (event) => {
    const match = event.data?.data();
    if (!match) return;

    const users = match.users; // [uid1, uid2]
    if (!Array.isArray(users) || users.length < 2) return;

    const db = getFirestore();

    const [doc1, doc2] = await Promise.all([
      db.collection("users").doc(users[0]).get(),
      db.collection("users").doc(users[1]).get(),
    ]);

    const user1 = doc1.data();
    const user2 = doc2.data();

    const sends = [];

    // Notify user1: "You matched with user2"
    if (user1?.fcmToken) {
      sends.push(
        safeSend({
          token: user1.fcmToken,
          notification: {
            title: "🎉 It's a Match!",
            body: `You and ${user2?.firstName ?? "someone"} both liked each other. Say hi!`,
          },
          data: {
            type: "match",
            matchId: event.params.matchId,
          },
          android: {
            notification: { channelId: "pr_default", priority: "high" },
          },
          apns: { payload: { aps: { sound: "default", badge: 1 } } },
        })
      );
    }

    // Notify user2: "You matched with user1"
    if (user2?.fcmToken) {
      sends.push(
        safeSend({
          token: user2.fcmToken,
          notification: {
            title: "🎉 It's a Match!",
            body: `You and ${user1?.firstName ?? "someone"} both liked each other. Say hi!`,
          },
          data: {
            type: "match",
            matchId: event.params.matchId,
          },
          android: {
            notification: { channelId: "pr_default", priority: "high" },
          },
          apns: { payload: { aps: { sound: "default", badge: 1 } } },
        })
      );
    }

    await Promise.all(sends);
    console.log(`Match ${event.params.matchId}: notified ${sends.length} users`);
  }
);

// ── onMessageSent ─────────────────────────────────────────────────────────────
// Fires when chats/{matchId}/messages/{messageId} is created.
// Notifies the recipient only.
exports.onMessageSent = onDocumentCreated(
  "chats/{matchId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const { matchId } = event.params;
    const senderId = message.senderId;
    const text = message.text ?? "";

    const db = getFirestore();

    // Get the match to find the recipient
    const matchDoc = await db.collection("matches").doc(matchId).get();
    const matchData = matchDoc.data();
    if (!matchData) return;

    const recipientId = matchData.users.find((id) => id !== senderId);
    if (!recipientId) return;

    // Fetch sender name + recipient FCM token in parallel
    const [recipientDoc, senderDoc] = await Promise.all([
      db.collection("users").doc(recipientId).get(),
      db.collection("users").doc(senderId).get(),
    ]);

    const fcmToken = recipientDoc.data()?.fcmToken;
    if (!fcmToken) return; // recipient has no token (logged out / notifications off)

    const senderName = senderDoc.data()?.firstName ?? "Someone";
    const preview = text.length > 100 ? `${text.substring(0, 97)}...` : text;

    await safeSend({
      token: fcmToken,
      notification: {
        title: `💬 ${senderName}`,
        body: preview || "Sent you a message",
      },
      data: {
        type: "message",
        matchId,
        senderId,
      },
      android: {
        notification: { channelId: "pr_default", priority: "high" },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });

    console.log(`Message in ${matchId}: notified recipient ${recipientId}`);
  }
);
