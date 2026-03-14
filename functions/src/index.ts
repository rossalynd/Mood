import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

function requireAuth(auth: any): string {
  const uid = auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  return uid;
}

function requestId(fromUID: string, toUID: string): string {
  return `${fromUID}_${toUID}`;
}

async function ensureUserExists(uid: string): Promise<void> {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "User not found.");
  }
}

async function ensureNotBlocked(a: string, b: string): Promise<void> {
  const [aBlocksB, bBlocksA] = await Promise.all([
    db.collection("users").doc(a).collection("blocked").doc(b).get(),
    db.collection("users").doc(b).collection("blocked").doc(a).get(),
  ]);

  if (aBlocksB.exists || bBlocksA.exists) {
    throw new HttpsError("permission-denied", "Friend action is not allowed.");
  }
}

export const sendFriendRequest = onCall(async (request) => {
  const fromUID = requireAuth(request.auth);
  const toUID = String(request.data?.toUID ?? "").trim();

  if (!toUID) {
    throw new HttpsError("invalid-argument", "Missing toUID.");
  }

  if (fromUID === toUID) {
    throw new HttpsError("failed-precondition", "You can't add yourself.");
  }

  await ensureUserExists(fromUID);
  await ensureUserExists(toUID);
  await ensureNotBlocked(fromUID, toUID);

  const reqRef = db.collection("friendRequests").doc(requestId(fromUID, toUID));
  const existingFriendRef = db
    .collection("friends")
    .doc(fromUID)
    .collection("list")
    .doc(toUID);

  await db.runTransaction(async (tx) => {
    const [existingRequestSnap, existingFriendSnap] = await Promise.all([
      tx.get(reqRef),
      tx.get(existingFriendRef),
    ]);

    if (existingFriendSnap.exists) {
      throw new HttpsError("already-exists", "You are already friends.");
    }

    if (existingRequestSnap.exists) {
      const data = existingRequestSnap.data();
      if (data?.status === "pending") {
        throw new HttpsError("already-exists", "Friend request already sent.");
      }
    }

    tx.set(reqRef, {
      fromUID,
      toUID,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});

export const cancelFriendRequest = onCall(async (request) => {
  const fromUID = requireAuth(request.auth);
  const toUID = String(request.data?.toUID ?? "").trim();

  if (!toUID) {
    throw new HttpsError("invalid-argument", "Missing toUID.");
  }

  const ref = db.collection("friendRequests").doc(requestId(fromUID, toUID));

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);

    if (!snap.exists) {
      return;
    }

    const data = snap.data();
    if (!data || data.fromUID !== fromUID || data.status !== "pending") {
      throw new HttpsError("permission-denied", "Cannot cancel this request.");
    }

    tx.delete(ref);
  });

  return { ok: true };
});

export const acceptFriendRequest = onCall(async (request) => {
  const currentUID = requireAuth(request.auth);
  const fromUID = String(request.data?.fromUID ?? "").trim();

  if (!fromUID) {
    throw new HttpsError("invalid-argument", "Missing fromUID.");
  }

  if (fromUID === currentUID) {
    throw new HttpsError("invalid-argument", "Invalid request.");
  }

  await ensureUserExists(fromUID);
  await ensureUserExists(currentUID);
  await ensureNotBlocked(fromUID, currentUID);

  const reqRef = db.collection("friendRequests").doc(requestId(fromUID, currentUID));

  const currentFriendRef = db
    .collection("friends")
    .doc(currentUID)
    .collection("list")
    .doc(fromUID);

  const otherFriendRef = db
    .collection("friends")
    .doc(fromUID)
    .collection("list")
    .doc(currentUID);

  await db.runTransaction(async (tx) => {
    const [reqSnap, currentFriendSnap, otherFriendSnap] = await Promise.all([
      tx.get(reqRef),
      tx.get(currentFriendRef),
      tx.get(otherFriendRef),
    ]);

    if (!reqSnap.exists) {
      throw new HttpsError("not-found", "Friend request not found.");
    }

    const data = reqSnap.data();
    if (
      !data ||
      data.fromUID !== fromUID ||
      data.toUID !== currentUID ||
      data.status !== "pending"
    ) {
      throw new HttpsError("failed-precondition", "Invalid pending request.");
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    if (!currentFriendSnap.exists) {
      tx.set(currentFriendRef, {
        uid: fromUID,
        source: "friend_request",
        createdAt: now,
      });
    }

    if (!otherFriendSnap.exists) {
      tx.set(otherFriendRef, {
        uid: currentUID,
        source: "friend_request",
        createdAt: now,
      });
    }

    tx.update(reqRef, {
      status: "accepted",
      updatedAt: now,
    });
  });

  return { ok: true };
});

export const declineFriendRequest = onCall(async (request) => {
  const currentUID = requireAuth(request.auth);
  const fromUID = String(request.data?.fromUID ?? "").trim();

  if (!fromUID) {
    throw new HttpsError("invalid-argument", "Missing fromUID.");
  }

  const reqRef = db.collection("friendRequests").doc(requestId(fromUID, currentUID));

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(reqRef);

    if (!snap.exists) {
      throw new HttpsError("not-found", "Friend request not found.");
    }

    const data = snap.data();
    if (
      !data ||
      data.fromUID !== fromUID ||
      data.toUID !== currentUID ||
      data.status !== "pending"
    ) {
      throw new HttpsError("failed-precondition", "Invalid pending request.");
    }

    tx.update(reqRef, {
      status: "declined",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});

export const removeFriend = onCall(async (request) => {
  const currentUID = requireAuth(request.auth);
  const otherUID = String(request.data?.otherUID ?? "").trim();

  if (!otherUID) {
    throw new HttpsError("invalid-argument", "Missing otherUID.");
  }

  if (otherUID === currentUID) {
    throw new HttpsError("invalid-argument", "Invalid friend.");
  }

  const currentFriendRef = db
    .collection("friends")
    .doc(currentUID)
    .collection("list")
    .doc(otherUID);

  const otherFriendRef = db
    .collection("friends")
    .doc(otherUID)
    .collection("list")
    .doc(currentUID);

  await db.runTransaction(async (tx) => {
    const [a, b] = await Promise.all([
      tx.get(currentFriendRef),
      tx.get(otherFriendRef),
    ]);

    if (a.exists) tx.delete(currentFriendRef);
    if (b.exists) tx.delete(otherFriendRef);
  });

  return { ok: true };
});