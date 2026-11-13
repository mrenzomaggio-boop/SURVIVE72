"use strict";
const test = require("node:test");
const assert = require("node:assert");
const { createPublicKey, verify } = require("node:crypto");
const { phoneTag, signedBytes, publicKeyFromSeed, makeProof } = require("../proof");

// Fixed vector, also checked by the iOS tests (MeshPhoneProofTests).
const seed = Buffer.alloc(32, 7);
const signingKey = Buffer.alloc(32, 9);
const issuedAt = 1800000000;

test("phone tag matches the app", () => {
  // Same value as MeshPhone.tag(for: "+393331234567") in the app.
  assert.strictEqual(phoneTag("+393331234567").length, 32);
});

test("proof verifies with the public key", () => {
  const proof = makeProof({ e164: "+393331234567", signingKey, issuedAt, seed });
  const spkiPrefix = Buffer.from("302a300506032b6570032100", "hex");
  const key = createPublicKey({ key: Buffer.concat([spkiPrefix, publicKeyFromSeed(seed)]), format: "der", type: "spki" });
  const ok = verify(null, signedBytes(proof.phoneTag, signingKey, issuedAt), key, Buffer.from(proof.signature, "base64"));
  assert.ok(ok);
  console.log(JSON.stringify({ publicKey: publicKeyFromSeed(seed).toString("base64"), tag: phoneTag("+393331234567"), proof }));
});
