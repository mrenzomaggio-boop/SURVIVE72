// Creates the server key pair. Run once: `node new-key.js`.
// The private key goes into the MESH_PROOF_KEY secret, never into git.
// The public key goes into MeshPhoneProof.serverKey in the app.
"use strict";
const { randomBytes } = require("node:crypto");
const { publicKeyFromSeed } = require("./proof");

const seed = randomBytes(32);
console.log("MESH_PROOF_KEY (secret):", seed.toString("base64"));
console.log("Public key for the app: ", publicKeyFromSeed(seed).toString("base64"));
