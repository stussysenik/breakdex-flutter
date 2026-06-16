// Firebase client init (Auth only — no Firestore, no Storage). The web mirror
// uses Firebase purely as the login gate; the Drive token comes from the same
// Google sign-in.
import { initializeApp, getApps, getApp, type FirebaseApp } from "firebase/app";
import {
  getAuth,
  GoogleAuthProvider,
  signInWithPopup,
  signOut as fbSignOut,
  type Auth,
} from "firebase/auth";

export interface FirebaseConfig {
  apiKey: string;
  authDomain: string;
  projectId: string;
  appId: string;
  messagingSenderId: string;
}

export function readFirebaseConfig(): FirebaseConfig | null {
  const apiKey = process.env.NEXT_PUBLIC_FIREBASE_API_KEY;
  const appId = process.env.NEXT_PUBLIC_FIREBASE_APP_ID;
  // Without a real apiKey + appId we cannot init Firebase; caller shows config error.
  if (!apiKey || !appId) return null;
  return {
    apiKey,
    authDomain:
      process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ??
      "breakdex-flutter.firebaseapp.com",
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? "breakdex-flutter",
    appId,
    messagingSenderId:
      process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID ?? "",
  };
}

export const driveScope =
  process.env.NEXT_PUBLIC_DRIVE_SCOPE ??
  "https://www.googleapis.com/auth/drive.file";

let _app: FirebaseApp | null = null;
let _auth: Auth | null = null;

export function getFirebaseAuth(config: FirebaseConfig): Auth {
  if (!_app) _app = getApps().length ? getApp() : initializeApp(config);
  if (!_auth) _auth = getAuth(_app);
  return _auth;
}

export interface SignInResult {
  email: string | null;
  displayName: string | null;
  /** Google OAuth access token for Drive REST calls. */
  accessToken: string | null;
}

/** One Google sign-in that yields both the Firebase session and a Drive token. */
export async function signInWithGoogle(auth: Auth): Promise<SignInResult> {
  const provider = new GoogleAuthProvider();
  provider.addScope(driveScope);
  // Force account chooser so the owner can pick the right Google account.
  provider.setCustomParameters({ prompt: "select_account" });
  const result = await signInWithPopup(auth, provider);
  const credential = GoogleAuthProvider.credentialFromResult(result);
  return {
    email: result.user.email,
    displayName: result.user.displayName,
    accessToken: credential?.accessToken ?? null,
  };
}

export async function signOut(auth: Auth): Promise<void> {
  await fbSignOut(auth);
}
