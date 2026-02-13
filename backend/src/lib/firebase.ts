import admin from "firebase-admin";

// Initialize Firebase Admin SDK
// GOOGLE_APPLICATION_CREDENTIALS env var points to the service account JSON file.
// firebase-admin will automatically use it when no explicit credential is passed.
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

export const firebaseAuth: import("firebase-admin/auth").Auth = admin.auth();
export default admin;
