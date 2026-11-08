---
title: "Bedrock node KMS, wallet API and zone SDK signing hooks"
tags: [bedrock, kms, node-api, wallet, zone-sdk, external-signer]
access_date: 2026-11-08
source_commit: "logos-blockchain master @ ce15ec1"
---

# Bedrock node KMS and signing hooks

Where a Bedrock node or SDK holds keys, and where an MPC signer could plug in:

| Component | How it signs today | Hook for MPC |
|---|---|---|
| **KMS service** (`services/key-management-system`) | `KMSBackend` trait (`src/backend/mod.rs:6`: `register`, `public_key`, operators). The only implementation is `PreloadKMSBackend`, with keys loaded from node config | Implement an `MpcKmsBackend`: Ed25519 operations forwarded to FROST or a vendor vault, ZK operations to co-circom parties. Not attempted |
| **Node wallet API** | `/wallet/sign/ed25519 {tx_hash, pk}` and `/wallet/sign/zk {tx_hash, pks}` sign with KMS keys | Not needed: external signers sign `tx_hash` themselves and submit through `/mempool/add/tx` |
| **`/wallet/fund`**, C `wallet_fund_tx` | Returns unsigned `Ops` and signs only the appended fee transfer with node keys | Keep a small hot fee balance in the node; the principal stays in MPC custody |
| **zone-sdk** `ZoneSequencer::init(channel_id, signing_key: Ed25519Key, node, funding, …)` | Plaintext Ed25519 key in process | Needs a signer trait for the inscribing key to live in MPC |

Operator crates in `kms/operators/src` cover `ed25519`, `zk` (leader, voucher) and `blend` (PoQ). Some flows, such as leader and blend proofs, are node-internal and out of scope for custody.

Related: [[unsigned-tx-tooling-bedrock]], [[mpc-custody-design-for-bedrock]].
