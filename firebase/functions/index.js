// SURVIVE 72 server. One function: after the app has signed in with Firebase
// phone authentication (SMS code), it signs the verified number together with
// the phone's public mesh key. Other phones check that proof offline.
// Nothing is stored: the number is only read from the sign-in token.
"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { makeProof } = require("./proof");

initializeApp();

// Base64 of the 32-byte Ed25519 private key. Set with:
//   firebase functions:secrets:set MESH_PROOF_KEY
const meshProofKey = defineSecret("MESH_PROOF_KEY");

// The SMS sign-in must be recent: a stolen old session cannot ask for proofs.
const MAX_SIGN_IN_AGE_SECONDS = 15 * 60;

exports.verifyPhone = onCall(
  { region: "europe-west1", secrets: [meshProofKey], maxInstances: 5 },
  (request) => {
    const token = request.auth && request.auth.token;
    const e164 = token && token.phone_number;
    if (!e164) {
      throw new HttpsError("unauthenticated", "Sign in with the SMS code first.");
    }
    const now = Math.floor(Date.now() / 1000);
    if (!token.auth_time || now - token.auth_time > MAX_SIGN_IN_AGE_SECONDS) {
      throw new HttpsError("unauthenticated", "The SMS sign-in is too old. Verify the number again.");
    }
    const keyText = request.data && request.data.signingKey;
    const signingKey = typeof keyText === "string" ? Buffer.from(keyText, "base64") : Buffer.alloc(0);
    if (signingKey.length !== 32) {
      throw new HttpsError("invalid-argument", "signingKey must be a base64 32-byte public key.");
    }
    const seed = Buffer.from(meshProofKey.value().trim(), "base64");
    return makeProof({ e164, signingKey, issuedAt: now, seed });
  }
);
