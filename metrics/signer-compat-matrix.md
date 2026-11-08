---
title: "Signer compatibility matrix (Logos Blockchain surfaces × signers)"
tags: [metrics, compatibility, fordefi, fireblocks, dfns, frost, co-circom, bedrock]
access_date: 2026-11-08
---

# Signer compatibility matrix

Status as of 2026-11-08. ✓ = verified against the Bedrock ledger · ✓ᵈ = standard scheme per vendor docs, not tested against Bedrock · ✗ = not possible · — = not applicable.

| Signer | Ed25519: inscribe, channel multisig, SDP half | ZkSign: note transfer, deposit, fees | Liveness | Evidence |
|---|---|---|---|---|
| FROST-Ed25519 (ZF, self-hosted) | ✓ | ✗ | t of n | [[frost-ed25519-channel-keys]] |
| Fordefi black-box `eddsa25519` | ✓ᵈ | ✗ | Fordefi share + customer share + policy approvers | [[tools/fordefi]] |
| Fireblocks raw `MPC_EDDSA_ED25519` | ✓ᵈ | ✗ | vendor | [[black-box-vault-bedrock]] |
| Dfns `kind: Hash`, EdDSA | ✓ᵈ | ✗ | vendor | [[black-box-vault-bedrock]] |
| co-circom (Shamir/REP3, self-hosted) | — | ✓ | **n of n** | [[threshold-zksign-cosnark]] |
| Bedrock native channel multisig | ✓ (k-of-n of any of the above) | — | k of n | [[bedrock-channel-multisig]] |
| Bedrock multi-key ZkSign | — | ✓, but needs **all** keys in one prover (not threshold) | 1 prover | [[bedrock-key-types]] |
