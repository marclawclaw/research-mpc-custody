---
title: "Can a black-box vault sign a Logos Blockchain transaction?"
tags: [bedrock, black-box-signing, fordefi, fireblocks, dfns, ed25519, zksign]
access_date: 2026-11-08
answers: "Q2"
---

# Can a black-box vault sign a Logos Blockchain transaction?

**Answer: yes for the Ed25519 parts, no for spending notes.**
- A black-box (hash-signing) vault with an **Ed25519** key can produce every Ed25519 signature Bedrock needs: channel inscriptions, channel config/withdraw/transfer multisig entries, and the Ed25519 half of an SDP declaration. The payload is the raw 32-byte Blake2b tx hash, so no Bedrock-specific support is required in the vault.
- **No vault can spend a note**, because that needs a ZkSign Groth16 proof over BN254/Poseidon2 keys ([[bedrock-key-types]]). That is not a signature scheme any custodian offers.

## Vendor check (2026-11-08)

| Signer | Black-box / raw schemes | Bedrock Ed25519 ops | Bedrock notes (ZkSign) |
|---|---|---|---|
| **Fordefi** black-box vault | `eddsa25519`, `ecdsa_secp256k1`, `ecdsa_stark` | ✓ `eddsa25519`, signs a `hash_binary` payload | ✗ |
| **Fireblocks** raw signing | `MPC_EDDSA_ED25519`, `MPC_ECDSA_SECP256K1` | ✓ | ✗ |
| **Dfns** `kind: Hash` | EdDSA, ECDSA, Schnorr | ✓ EdDSA | ✗ |
| **FROST-Ed25519** (self-hosted) | Ed25519 | ✓ verified against the Bedrock ledger ([[frost-ed25519-channel-keys]]) | ✗ |
| **co-circom** (self-hosted co-SNARK) | Groth16 proofs of any circom circuit | — | ✓ verified against the Bedrock ledger ([[threshold-zksign-cosnark]]) |

Sources:
- Fordefi: [[sources/2026-11-08-fordefi-black-box-signing-guide.html]], [[sources/2026-11-08-fordefi-bb-eddsa-signatures.html]]
- Fireblocks: [[sources/2026-11-08-fireblocks-raw-signing.html]]
- Dfns: [[sources/2026-11-08-dfns-generate-signature.md]]

The vendor Ed25519 signatures were **not** tested against Bedrock; only FROST-Ed25519 was. Fordefi's own EdDSA example verifies its output with standard `nacl`. Bedrock additionally applies `verify_strict` (it rejects small-order keys and non-canonical encodings), which honest RFC 8032 signers satisfy.

## Caveats

- **Blind signing.** Fordefi: "for black-box vaults Fordefi does not verify or enforce any specific amount or assets rules, and will sign any buffer given by the customer as long as it is approved". A vault's policy engine can control *who* approves, but not *what*, unless something in front of it decodes the Mantle ops behind the hash ([[unsigned-tx-tooling-bedrock]]).
- **Fees.** Every transaction pays fees from notes, which needs a ZkSign. A vault-only setup therefore needs either a node-held fee key (the node's `/wallet/fund` signs only the appended fee transfer) or MPC ZkSign for the fee notes too ([[mpc-custody-design-for-bedrock]]).

Related: [[tools/fordefi]], [[signer-compat-matrix]].
