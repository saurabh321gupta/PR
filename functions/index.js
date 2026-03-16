const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

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
