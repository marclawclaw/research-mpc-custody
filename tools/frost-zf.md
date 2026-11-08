---
title: "ZF FROST (frost-ed25519)"
tags: [frost, threshold-signature, ed25519, open-source, zcash-foundation]
type: open-source-library
licence: MIT OR Apache-2.0
version: "3.0.0"
access_date: 2026-11-08
---

# ZF FROST

The Zcash Foundation's Rust implementation of FROST (RFC 9591): two-round threshold Schnorr signing with DKG, one crate per ciphersuite. **`frost-ed25519`** produces standard Ed25519 signatures, which is what Bedrock channel keys need.

- **Bedrock fit:** a FROST group key accredited as a channel key passes the real ledger ([[frost-ed25519-channel-keys]]).
- **Keygen:** trusted dealer (`keys::generate_with_dealer`) or DKG (`keys::dkg`, three parts). Earlier research on the ChillDKG ceremony shape is in [research-multisig-sovereign: frost-dkg-ceremony](https://github.com/marclawclaw/research-multisig-sovereign/blob/master/patterns/frost-dkg-ceremony.md).
- **Liveness:** any `t` of `n` participants can sign. Signing has 2 rounds; with nonce preprocessing, round 1 can be done ahead of time. A coordinator relays messages. It can abort, but it cannot forge.
- **Not robust:** one misbehaving signer aborts the session, which is then restarted with another subset.
- **Audit:** NCC Group audited v0.6.0 (report 2023-10-19); the PoC uses 3.0.0.
- **Docs:** [[sources/2026-11-08-docsrs-frost-ed25519-3.0.0.html]].

FROST does **not** help with ZkSign: that is a Groth16 proof, not a Schnorr signature ([[tools/co-circom]]).
