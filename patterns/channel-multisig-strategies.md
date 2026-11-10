---
title: "Treasury channel: native k-of-n vs one FROST key vs one MuSig2 key"
tags: [bedrock, channel, multisig, frost, musig2, ed25519, treasury, comparison]
access_date: 2026-11-10
source_commit: "logos-blockchain master @ ce15ec1"
---

# Treasury channel: three ways to hold the Ed25519 side

All three use the same custody object: a channel used as a treasury ([[bedrock-channel-multisig]]).
- Funds enter with `ChannelDeposit`.
- Funds leave with `ChannelTransfer` + `ChannelWithdraw`, each signed over the 32-byte Blake2b-256 tx hash and checked with Ed25519 `verify_strict`.

The three differ only in **where the threshold lives**.

| # | Strategy | Channel config on chain | Threshold enforced by |
|---|---|---|---|
| 1 | **Native channel multisig** | `accredited_keys = [K₁…Kₙ]`, `transfer_threshold = k`, `configuration_threshold = k'` | The ledger: k independent Ed25519 signatures, one per listed key |
| 2 | **One key + FROST** | `accredited_keys = [K_frost]`, both thresholds `1` | FROST (RFC 9591): t-of-n off chain → one ordinary Ed25519 signature |
| 3 | **One key + MuSig2** | `accredited_keys = [K_musig]`, both thresholds `1` | MuSig2: n-of-n off chain → one ordinary Ed25519 signature |

Each member key Kᵢ in strategy 1 can itself be a plain or hardware key, a vendor vault (Fordefi `eddsa25519`, Fireblocks, Dfns) or a FROST group. The hybrid of 1 and 2 is what [[frost-ed25519-channel-keys]] tested.

## Comparison

| | 1. Native k-of-n | 2. One key + FROST | 3. One key + MuSig2 |
|---|---|---|---|
| **Threshold** | Any k of n | Any t of n | **n of n only** |
| **Liveness / loss of one member** | Fine while ≥ k remain | Fine while ≥ t remain | **Key is dead.** Funds are stuck unless the channel lists a fallback key, which turns it back into strategy 1 |
| **On-chain view** | Every member key, k, k', every config change, and **which indices signed** each payout | One key; size of group and threshold hidden | One key; size of group hidden |
| **Still public in all three** | Channel id, balance, every deposit and payout are linkable ([[bedrock-channel-multisig]]) | same | same |
| **Accountability** | On chain: each payout shows who approved | Off chain only (coordinator logs; ZF FROST identifies a cheating share) | Off chain only |
| **Key setup** | None: list members' existing keys | DKG ceremony (or trusted dealer) | Non-interactive: aggregate members' existing keys (no DKG) |
| **Signing rounds** | 1 per member, async, no coordination between members | 2 rounds via a coordinator (commitments, then shares) | 2 rounds (nonces, then partial sigs) |
| **Membership change** | `ChannelConfigOp` signed by k' members: add or remove a key, change k (verified) | Same key: refresh removes members (only effective if the rest delete their old shares) and repair can add one; **t cannot change**. Otherwise a new group + `ChannelConfigOp` signed by the old group (all verified) | New aggregate key + `ChannelConfigOp` signed by **all** old members |
| **Mixing custodians** | ✓ Vendor vault + FROST group + hardware key side by side | ✗ Every member runs the same FROST implementation; vendor MPC vaults can't join | ✗ Same, and no vendor offers Ed25519 MuSig2 |
| **Vendor / hardware support** | ✓ Any Ed25519 signer (vendor support per docs, not tested) | Self-hosted (ZF `frost-ed25519`); FROST hardware is niche (e.g. Frostsnap, secp256k1) | None known for Ed25519 |
| **Standard and libraries** | Plain Ed25519 (RFC 8032) | RFC 9591 with an Ed25519 ciphersuite; ZF `frost-ed25519` 3.0.0, NCC-audited at v0.6.0 | BIP-327 is **secp256k1 only**; no Ed25519 MuSig2 standard |
| **Signature size and gas** | 2 + 66·k bytes; payout gas (56 + 56)·k, measured 112/224/336/560 for k = 1/2/3/5 | 68 bytes, 112 gas (k = 1) | 68 bytes, 112 gas (k = 1) |
| **Sequencer rotation** (unused by a treasury) | Rotates over n keys | Single key | Single key |
| **Verified against the Bedrock ledger** | ✓ 17 tests | ✓ 7 tests (real DKG) | ✓ 6 tests (**own unaudited MuSig2 code**) |

## Reading the table

- **1. Native** is the most flexible and the most transparent. It is the only one that mixes vendors, and the only one with on-chain accountability. The cost is that the custody structure, and who approved each payment, are public.
- **2. One FROST key** hides the structure and the approvers and keeps t-of-n. The cost is a DKG ceremony and a single, self-hosted implementation shared by every member.
- **3. One MuSig2 key** hides the structure like 2 and avoids a DKG. But it is **n-of-n**: one lost member freezes the treasury. It also lacks an Ed25519 standard and an audited library. FROST with t = n gives the same on-chain result with better tooling, so 3 only wins where a key ceremony is impossible and every member is always reachable.

The hybrid of 1 and 2 (members of a native k-of-n are themselves FROST groups) is useful when organisations want internal MPC but visible accountability between organisations.

## Verification

The three PoCs were checked on 2026-11-10 against Bedrock `ce15ec1`, through the real ledger path (`LedgerState::try_apply_tx_operations` plus the deferred proof check). Each patch applies on top of [[poc/README|poc/bedrock-ledger.patch]]. On a fresh checkout per patch, the whole ledger test suite passes.

| Strategy | PoC | Result |
|---|---|---|
| 1. Native k-of-n | [[poc/native-channel-multisig/README]] | 17 pass: 2-of-3 payout with every pair; rejects 1, 3 or non-member signatures; key rotation and k raised by `ChannelConfigOp`; bad config updates rejected (below k', empty proof, stale parent, removed member) |
| 2. One key + FROST | [[poc/frost-single-key-channel/README]] | 7 pass: DKG 2-of-3; every pair pays with one 68-byte signature at index 0; one participant can't sign; refresh drops a member under the same key; repair adds one; t can't change; rotation to a new group |
| 3. One key + MuSig2 | [[poc/musig2-single-key-channel/README]] | 6 pass: 3-of-3 payout; 2 of 3 rejected; rogue-key attack stopped by the key coefficients; rotation to a new aggregate. **The MuSig2 is a minimal demo on curve25519-dalek, since no usable Ed25519 MuSig2 library exists** |

### Ledger rules found along the way (all strategies)

- **Exactly k signatures, not at least k.** A proof with more signatures than `transfer_threshold` is rejected (`core/src/mantle/ops/channel/verification.rs:19`, `withdraw.rs:119`, `channel_transfer.rs:149`). Wallets must drop extra approvals.
- **`transfer_threshold` > n is accepted.** `ChannelConfigOp::new` checks only `configuration_threshold ≤ n` (`config.rs:69`). Payouts are then locked until k' members fix the config.
- **The same key can be listed twice** (`accredited_keys` is a plain bounded vec). One holder can then meet k = 2 alone. Members must check the key list.
- Payout errors are all reported as `InvalidSignature` (FIXME at `withdraw.rs:97`, `channel_transfer.rs:120`).
- A config update needs `parent = config_tip_hash` and exactly k' signatures from the **current** keys (`config.rs:231-264`). The new key set replaces the old one in full.

### Library landscape for Ed25519 MuSig2 (2026-11-10)

| Library | Status |
|---|---|
| ZenGo `multi-party-eddsa` (musig2 module) | GPL-3.0, not on crates.io, last change 2022, unaudited |
| ZenGo `two-party-musig2-eddsa` | GPL-3.0, 2 parties only, last change 2022 |
| `musig2` (conduition), `schnorr_fun` | secp256k1 / BIP-327 only |
| Serai `dkg-musig` | MuSig key aggregation feeding FROST signing, not MuSig2 signing |

There is no Ed25519 MuSig2 standard (BIP-327 is secp256k1 only). FROST is RFC 9591.

## Recommendation

- **Default to 1 (native)** when members are different organisations or use vendor vaults. It is the only option that mixes custodians and keeps on-chain accountability.
- **Use 2 (one FROST key)** when hiding the structure and approvers matters and every member can run the same FROST stack. Plan membership changes as rotation to a new group (`ChannelConfigOp`). Treat refresh as valid only if old shares are provably deleted.
- **Avoid 3 (MuSig2)** for now. It is n-of-n with no maintained Ed25519 library. FROST with t = n gives the same on-chain result with an RFC and an audited crate.

Related: [[mpc-custody-design-for-bedrock]], [[mpc-vs-native-multisig-bedrock]], [[tools/frost-zf]].
