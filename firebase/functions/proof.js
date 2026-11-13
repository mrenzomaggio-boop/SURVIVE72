// Phone proof: "the owner of this mesh key received an SMS on this number".
// The byte layout must stay identical to MeshPhoneProof.signedBytes in the
// iOS app (ios/SURVIVE72/Models/MeshIdentity.swift).
"use strict";

const { createHash, createPrivateKey, createPublicKey, sign } = require("node:crypto");

// PKCS#8 header for a raw 32-byte Ed25519 private key (seed).
const PKCS8_ED25519_PREFIX = Buffer.from("302e020100300506032b657004220420", "hex");

/** Same as MeshPhone.tag in the app: first 16 bytes of SHA-256, hex. */
function phoneTag(e164) {
  return createHash("sha256")
    .update("survive72.mesh.phone.v1:" + e164, "utf8")
    .digest()
    .subarray(0, 16)
    .toString("hex");
}

function signedBytes(tag, signingKey, issuedAt) {
  const parts = [Buffer.from(tag, "utf8"), signingKey, Buffer.from(String(issuedAt), "utf8")];
  const chunks = [Buffer.from("survive72.mesh.phone-proof.v1", "utf8")];
  for (const part of parts) {
    const length = Buffer.alloc(4);
    length.writeUInt32BE(part.length);
    chunks.push(length, part);
  }
  return Buffer.concat(chunks);
}

function privateKeyFromSeed(seed) {
  if (seed.length !== 32) throw new Error("The server key must be 32 bytes");
  return createPrivateKey({ key: Buffer.concat([PKCS8_ED25519_PREFIX, seed]), format: "der", type: "pkcs8" });
}

/** Raw 32-byte public key, the one built into the app. */
function publicKeyFromSeed(seed) {
  const der = createPublicKey(privateKeyFromSeed(seed)).export({ format: "der", type: "spki" });
  return der.subarray(der.length - 32);
}

/** The proof as the app decodes it (Data fields are base64). */
function makeProof({ e164, signingKey, issuedAt, seed }) {
  const tag = phoneTag(e164);
  const signature = sign(null, signedBytes(tag, signingKey, issuedAt), privateKeyFromSeed(seed));
  return { phoneTag: tag, issuedAt, signature: signature.toString("base64") };
}

module.exports = { phoneTag, signedBytes, publicKeyFromSeed, makeProof };
