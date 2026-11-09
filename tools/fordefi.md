---
title: "Fordefi"
tags: [fordefi, mpc, custody, black-box-signing, policy-engine, paxos, ed25519]
type: commercial-mpc-wallet
licence: proprietary
access_date: 2026-11-08
---

# Fordefi

An institutional MPC wallet focused on DeFi. **Acquired by Paxos on 2025-11-25** for more than $100M. Paxos said Fordefi would initially keep running as a separate product. (Earlier private vault `research-mpc-web3`, note "Paxos Acquires Fordefi".)

## Architecture (from Fordefi's docs)

- Each key is split between **Fordefi** (its share sits in a cloud **secure enclave**) and the **customer**: a mobile-app share in the phone's secure enclave, or an **API Signer** share on a server the customer runs. MPC signing never rebuilds the key.
- Fordefi calls its protocol "peer-reviewed" and "audited", but does **not name** it publicly.
- A **policy engine** decides which approvers each class of transaction needs. API requests are signed by the API user's key (`x-signature` over `path|timestamp|body`).
- Sources: [[sources/2026-11-08-fordefi-product-security.html]], [[sources/2026-11-08-fordefi-black-box-signing-guide.html]].

## Black-box signing (for chains Fordefi doesn't support)

- Create a vault with `type: black_box` and a key type: **`ecdsa_stark`, `ecdsa_secp256k1` or `eddsa25519`**.
- `POST /api/v1/transactions` with `type: black_box_signature` and `details: { format: "hash_binary", hash_binary: <base64> }`. The EdDSA result is a base64 signature that verifies with plain `nacl` against the vault's `public_key_compressed` ([[sources/2026-11-08-fordefi-bb-eddsa-signatures.html]]).
- REST API only. Fordefi "does not verify or enforce any specific amount or assets rules" for black-box vaults.

## Fit with the Logos Blockchain

| Bedrock surface | Needs | Fordefi |
|---|---|---|
| Channel key: inscribe, channel config/withdraw/transfer multisig | Ed25519 over the 32-byte tx hash | ✓ `eddsa25519` black-box vault (not tested against Bedrock; standard Ed25519 output) |
| SDP declaration | Ed25519 + ZkSign | Ed25519 half only |
| Notes: transfer, deposit, fees | ZkSign (Groth16, BN254/Poseidon2) | ✗ not a signature scheme Fordefi supports |

**In practice:** Fordefi can hold one of a channel's accredited keys (or the only one), and so control treasury funds **only if they are kept as channel notes**. The treasury is then a zone-like channel, with a public, linkable custody structure. Fordefi cannot hold plain notes, and it cannot pay fees, which need a ZkSign. See [[black-box-vault-bedrock]] and [[mpc-custody-design-for-bedrock]].
