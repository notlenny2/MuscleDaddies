const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Run daily at 6pm — nudge anyone inactive 3+ days
exports.dailyNudge = onSchedule("every day 18:00", async () => {
  const threeDaysAgo = new Date(Date.now() - 3 * 86400000);
  const usersSnap = await db.collection("users")
    .where("lastWorkoutDate", "<", threeDaysAgo)
    .get();

  const promises = [];
  for (const doc of usersSnap.docs) {
    const user = doc.data();
    if (!user.fcmToken || !user.groupId) continue;

    // Get group members to personalize message
    promises.push(
      messaging.send({
        token: user.fcmToken,
        notification: {
          title: "Where you at? 👀",
          body: `It's been ${daysSince(user.lastWorkoutDate)} days since your last workout. The group misses you!`,
        },
        apns: { payload: { aps: { sound: "default" } } },
      }).catch(() => {}) // Ignore invalid tokens
    );
  }
  await Promise.all(promises);
});

// Notify group when someone logs a workout
exports.onWorkoutLogged = onDocumentCreated("workouts/{workoutId}", async (event) => {
  const workout = event.data.data();
  if (!workout.groupId) return;

  const userDoc = await db.collection("users").doc(workout.userId).get();
  const userName = userDoc.data()?.displayName || "Someone";

  // Get group members' FCM tokens (except the person who logged)
  const groupDoc = await db.collection("groups").doc(workout.groupId).get();
  const memberIds = (groupDoc.data()?.memberIds || []).filter(id => id !== workout.userId);

  const tokens = [];
  for (const memberId of memberIds) {
    const memberDoc = await db.collection("users").doc(memberId).get();
    const token = memberDoc.data()?.fcmToken;
    if (token) tokens.push(token);
  }

  if (tokens.length === 0) return;

  await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: `${userName} just worked out! 💪`,
      body: `${workout.duration} min of ${workout.type}`,
    },
    apns: { payload: { aps: { sound: "default" } } },
  }).catch(() => {});
});

// Notify when someone gets poked
exports.onPoke = onDocumentCreated("feed/{feedId}", async (event) => {
  const feed = event.data.data();
  if (!feed.content?.includes("poked")) return;

  // Extract poked user name from content like "X poked Y! Get to the gym!"
  const match = feed.content.match(/poked (.+?)!/);
  if (!match) return;
  const pokedName = match[1];

  // Find poked user by display name
  const usersSnap = await db.collection("users")
    .where("displayName", "==", pokedName)
    .limit(1)
    .get();

  if (usersSnap.empty) return;
  const pokedUser = usersSnap.docs[0].data();
  if (!pokedUser.fcmToken) return;

  await messaging.send({
    token: pokedUser.fcmToken,
    notification: {
      title: "You got poked! 👉",
      body: `${feed.userName} says get to the gym!`,
    },
    apns: { payload: { aps: { sound: "default" } } },
  }).catch(() => {});
});

function daysSince(timestamp) {
  if (!timestamp) return "many";
  const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
  return Math.floor((Date.now() - date.getTime()) / 86400000);
}
