---
title: "MPC key vs native multisig on the Logos Blockchain"
tags: [bedrock, mpc, multisig, channel, zksign, trade-offs]
access_date: 2026-11-08
---

# MPC key vs native multisig on the Logos Blockchain

| | **Channel multisig** (native) | **MPC Ed25519 key** (FROST or vendor) as a channel key | **Multi-key ZkSign** (native) | **co-SNARK ZkSign** (MPC) |
|---|---|---|---|---|
| Protects | Notes held in a channel | Same | Plain notes | Plain notes |
| k-of-n enforced by | Ledger (`transfer_threshold`) | Signing protocol, invisible on chain | **Not a threshold**: one prover needs **all** listed keys | MPC protocol |
| Visible on chain | Channel id, accredited keys, thresholds, which indices signed; all treasury flows linkable | One key in a public channel config (the channel is still visible) | n/a | One `pk` per note, indistinguishable from a single owner |
| Liveness | Any k of n | Any t of n (FROST) | 1 prover with every key | **All n** MPC parties |
| Membership change | `ChannelConfigOp` at `configuration_threshold` | Reshare (same key) or reconfigure the channel | Spend to new notes | Reshare (same key) or spend to new notes |
| Vendor support | n/a | Fordefi, Fireblocks, Dfns EdDSA | ✗ | ✗ (self-hosted co-circom) |
| Maturity | Protocol | ZF FROST: NCC-audited at v0.6.0 (2023), the PoC uses 3.0.0; vendors: in production | Protocol | Experimental, unaudited |

Notes:
- ZkSign accepts up to 32 keys, which looks like multisig but is not threshold signing. Every key must be fed to one prover, so it is **aggregation**, not k-of-n.
- **Channel notes and MPC Ed25519 keys** is the only vendor-compatible option, but the treasury must *be* a channel. Its structure, signer indices, balance and flows are public and linkable, payers must use `ChannelDeposit`, and channel semantics are built for zones ([[bedrock-channel-multisig]]).
- **co-SNARK ZkSign** is the only way to put *plain* notes (including fee notes) under threshold control. The n-of-n liveness and semi-honest model make it a better fit for a small set of always-on, mutually distrusting servers than for humans on phones.

Related: [[bedrock-channel-multisig]], [[threshold-zksign-cosnark]], [[mpc-custody-design-for-bedrock]].
