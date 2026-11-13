# SURVIVE 72 server (Firebase)

One function, `verifyPhone`. Once the app has signed in with Firebase phone
authentication (SMS code), the function signs "this number belongs to this
mesh key". Other phones check that proof without internet, using the public
key built into the app (`MeshPhoneProof.serverKey`). No number is stored.

- `functions/proof.js`: proof format, the same as `MeshPhoneProof` in the app.
- `functions/new-key.js`: creates the server key pair (run once).
- Tests: `cd functions && npm test`. The fixed vector is also checked by the iOS
  tests (`MeshPhoneProofTests`).

The private key is the `MESH_PROOF_KEY` secret in Firebase, never in git.
