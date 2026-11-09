---
title: "Logos Blockchain key types and which operation needs which"
tags: [bedrock, logos-blockchain, mantle, ed25519, zksign, groth16, poseidon2, keys]
access_date: 2026-11-08
source_commit: "logos-blockchain master @ ce15ec1 (2026-11-06); logos-blockchain-circuits v0.5.7"
answers: "Q1"
---

# Logos Blockchain key types

**Answer:** The Logos Blockchain (Bedrock, transactions = Mantle ops) has **two** key types (`kms/keys/src/keys/mod.rs:30`, `enum Key { Ed25519, Zk }`):

| Key | Curve / field | What a "signature" is | Verified with |
|---|---|---|---|
| `Ed25519Key` | **Ed25519** | Standard 64-byte Ed25519 signature over the 32-byte tx hash | `ed25519-dalek` `verify_strict` (`kms/keys/src/keys/ed25519/public.rs:64`) |
| `ZkKey` | **BN254 scalar field `Fr`**. Public key = Poseidon2 compression of a KDF constant and `sk` (`circuits ledger/notes.circom`, `derive_public_key`) | **ZkSign**: a **Groth16 proof over BN254** that the prover knows the secret keys behind up to **32** public keys, with the tx hash (as an `Fr`) as a public input. Circuit `mantle/signature.circom`, proved with rapidsnark | `lb_zksign::verify` against the fixed ZkSign verifying key, deferred and batchable |

There is no secp256k1 anywhere in Bedrock.

**Ed25519 never authorises spending an ordinary note.** It is used for:
- sequencing (inscriptions),
- the channel multisig, which moves only notes that were deposited into a channel,
- SDP declarations.

All value held in plain notes is controlled by ZK keys. See [[bedrock-channel-multisig]].

## What gets signed

- The tx hash is **Blake2b-256** over the ops' signing bytes (`core/src/crypto.rs:2`, `tx_list/hash.rs:6`).
- Ed25519 signs those 32 bytes (`tx_hash.as_signing_bytes()`).
- ZkSign takes `tx_hash.to_fr()`, the same bytes reduced mod the BN254 scalar order (`transactions/hash.rs`, `to_fr`).
- A note is `Note { value, pk: ZkPublicKey }` (`core/src/mantle/ledger.rs:491`). Notes are UTXOs owned by a **ZK key**.

## Operation → required proof

From `does_proof_match`, `core/src/mantle/ops/op.rs:267`:

| Mantle op | Proof | Key |
|---|---|---|
| `Transfer` (spend notes) | `ZkSig` | ZK keys of all input notes |
| `ChannelDeposit` | `ZkSig` | ZK keys of the deposited notes |
| `ChannelInscribe` | `Ed25519Sig` | the inscribing key |
| `ChannelConfig`, `ChannelWithdraw`, `ChannelTransfer` | `ChannelMultiSigProof` | k-of-n accredited Ed25519 keys ([[bedrock-channel-multisig]]) |
| `SDPDeclare` | `ZkAndEd25519Sigs` | both |
| `SDPWithdraw`, `SDPActive` | `ZkSig` | ZK key |
| `LeaderClaim` | `PoC` (Groth16) | — |
| `ClaimPowReward` | none | — |

- One `ZkSig` covers **all** input notes of an op: the circuit takes 32 key slots, and unused slots are filled with `sk = 0` (`kms/keys/src/keys/zk/private.rs:89`, `public.rs:112`).
- The verifier takes its public inputs from the notes being spent plus the tx hash (`core/src/mantle/ops/transfer.rs:149`).

## Consequences for MPC custody

- **Ed25519 parts:** any threshold-Ed25519 signer works as long as it produces a standard signature over 32 bytes. Examples: FROST-Ed25519, or vendor EdDSA vaults such as Fordefi and Fireblocks. Proven against the real ledger in [[frost-ed25519-channel-keys]]. For custody this only helps if the funds are kept **in a channel**, which makes the treasury a zone-like object with public, linkable structure ([[bedrock-channel-multisig]]).
- **ZK parts (funds in notes):** no signing API can produce a ZkSign, because it is a proof whose witness is the secret key. It *can* be produced by **collaborative proving** over secret-shared keys. Proven against the real ledger in [[threshold-zksign-cosnark]]. See [[zksign-proving-vs-signing]].

Related: [[signer-compat-matrix]], [[mpc-custody-design-for-bedrock]].
