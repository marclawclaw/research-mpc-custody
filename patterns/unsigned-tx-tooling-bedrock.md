---
title: "What builds an unsigned Logos Blockchain transaction today"
tags: [bedrock, tooling, unsigned-transaction, http-api, c-bindings, kms, wallet]
access_date: 2026-11-08
source_commit: "logos-blockchain master @ ce15ec1; logos-blockchain-module @ c4f52b9 (2026-11-05)"
answers: "Q4"
---

# What builds an unsigned transaction today?

**Answer:** Bedrock already separates building from signing at every layer:
- **Rust:** `MantleTxBuilder` builds the transaction. `Ops` is the unsigned transaction and `ops.hash()` is what gets signed. `SignedOps::from_parts(ops, op_proofs)` attaches proofs produced anywhere.
- **Node HTTP API:** `POST /wallet/fund` returns a funded, **unsigned** `Ops`. `POST /mempool/add/tx` accepts the externally signed transaction.
- **C bindings and Logos Core module:** the same pair as `wallet_fund_tx` and `submit_signed_transaction`.

An MPC signer only has to turn `tx_hash` into the right `OpProof`s.

## Inventory

| Layer | Build / fund | Sign | Submit | Notes |
|---|---|---|---|---|
| `logos-blockchain-core` (Rust) | `MantleTxBuilder` (`core/src/mantle/transactions/builder.rs:66`) → `build(fork_digest)` → `Ops` | external: `OpProof::{Ed25519Sig, ZkSig, ChannelMultiSigProof, …}` | n/a | `SignedOps::from_parts` (`tx_list/signed_ops.rs:52`) checks that the proof count and kinds match the ops |
| `logos-blockchain-wallet` | `fund_tx(builder, change_pk, pks, …)` picks UTXOs and adds change (`wallet/src/lib.rs:239`) | — | — | Library used by the node |
| Node HTTP API (`nodes/api-common/src/paths.rs:52`) | `POST /wallet/fund` → `{ tip, funded_tx: Ops /* all ops unsigned */, fee proof }` (`bodies/wallet.rs:241`, `:264`) | `POST /wallet/sign/ed25519 {tx_hash, pk}`, `POST /wallet/sign/zk {tx_hash, pks}`: **node-held keys only** | `POST /mempool/add/tx` | `/wallet/fund` signs only the appended fee transfer, with the node's `funding_public_keys` |
| C bindings (`c-bindings/src/api/wallet.rs`) | `wallet_fund_tx` (`:1728`), the same contract as `/wallet/fund` | — | `submit_signed_transaction` (`:1801`), "a transaction funded via `wallet_fund_tx` and completed with the caller's op proofs" | |
| Logos Core `logos-blockchain-module` (Qt) | `wallet_fund_tx(request_json)` | — | `submit_signed_transaction(signed_tx_json)` | `src/logos_blockchain_module.h:138`, `:144` |
| Node KMS (`services/key-management-system`) | — | `KMSBackend` trait (`src/backend/mod.rs:6`) | — | The only backend is `PreloadKMSBackend` (keys from config). An MPC backend could implement the trait ([[tools/bedrock-kms]]) |
| `zone-sdk` | builds inscriptions and channel ops | `ZoneSequencer::init(channel_id, signing_key: Ed25519Key, …)` takes a **plaintext key** | via node | No external-signer hook ([[tools/bedrock-kms]]) |

## MPC integration path (no Bedrock changes)

```
app ── MantleTxBuilder / wallet_fund_tx ──► Ops (unsigned) + fee proof
                                           │ tx_hash = Blake2b(ops)
          ┌────────────────────────────────┴─────────────────────┐
  Ed25519 parts: FROST-Ed25519 / vendor EdDSA vault     ZK parts: co-circom parties
          └────────────────────────────────┬─────────────────────┘
                     SignedOps::from_parts(ops, proofs) ──► /mempool/add/tx
```

## Gaps

1. **Opaque payload for approvers.** Every signer sees only a 32-byte hash. A decoder that renders `Ops` (amounts, recipients, channel ids) for policy and approval UIs does not exist as a standalone component.
2. **No remote-signer backend in the node.** `/wallet/sign/*` and the zone SDK assume keys held in-process. An `MpcKmsBackend` (or a remote-signer `KMSBackend`) would let node-driven flows (SDP, zone sequencing) use MPC keys.
3. **The fee key is a node key.** `/wallet/fund` must hold the fee note keys. With MPC-held funds, either keep a small hot fee balance in the node or fund from MPC notes with an extra co-SNARK round.

Related: [[bedrock-key-types]], [[mpc-custody-design-for-bedrock]].
