---
title: "FROST-Ed25519 keys as accredited channel keys (PoC)"
tags: [bedrock, frost, ed25519, channel, multisig, poc]
access_date: 2026-11-08
poc: "poc/bedrock-ledger.patch → ledger/src/tests/frost_channel_poc.rs"
---

# FROST-Ed25519 channel keys (PoC)

**Result:** the real Bedrock ledger (`LedgerState::try_apply_tx_operations` plus deferred proof verification) accepts a `ChannelWithdraw` whose multisig entries come from **FROST 2-of-3 groups**. It rejects the transaction when the threshold isn't met or a signature covers a different tx.

## Setup

Bedrock `ce15ec1` with `frost-ed25519` 3.0.0 as a dev-dependency:

1. A channel is created by an inscription with an ordinary key.
2. `ChannelConfigOp` accredits `[FROST group A, FROST group B, ordinary key]` with configuration and transfer thresholds of **2**.
3. A note is deposited into the channel (ZkSign by its owner).
4. `ChannelWithdraw` is signed by A (participants 0 and 2) and B (participants 1 and 2). No participant ever holds a full key.

| Test | Expected | Result |
|---|---|---|
| `frost_ed25519_groups_satisfy_channel_multisig` | accepted, note released | ✓ |
| `one_frost_group_alone_is_below_threshold` | rejected | ✓ |
| `frost_signature_over_another_tx_is_rejected` | rejected | ✓ |
| `frost_treasury_channel_pays_recipient`: channel created by **config alone** (no inscription, posting timeframe/timeout 0); deposit; the depositor's own `Transfer` of the locked note fails; `ChannelTransfer` (6 000 to recipient, 4 000 change) + `ChannelWithdraw` in one tx, FROST signatures only | recipient holds an ordinary note; change stays a channel note | ✓ |

The first three passed on 5 consecutive runs on the working checkout. All four passed on a pristine checkout with the patch applied (2026-11-09).

## What this shows

- FROST-Ed25519 aggregates are canonical Ed25519 and pass Bedrock's `verify_strict`.
- Nested custody works with no protocol change: an on-chain k-of-n where each member is itself a t-of-n MPC key.
- **This is custody of channel notes, not plain notes.** The treasury is a channel, with the visibility and linkability costs listed in [[bedrock-channel-multisig]].
- By extension, any vendor whose EdDSA black-box output is standard RFC 8032 should work the same way (Fordefi `eddsa25519`, Fireblocks `MPC_EDDSA_ED25519`). Not tested against those vendors ([[black-box-vault-bedrock]]).

## Limits

- Trusted-dealer key generation (`generate_with_dealer`). DKG (`frost::keys::dkg`) yields the same key packages but was not run.
- Ledger-level test. No node, mempool or network was involved.

Run it:

```sh
git clone https://github.com/logos-blockchain/logos-blockchain && cd logos-blockchain
git checkout ce15ec1 && git apply <this repo>/poc/bedrock-ledger.patch
cargo test -p logos-blockchain-ledger frost_        # 4 tests
```

Related: [[tools/frost-zf]], [[threshold-zksign-cosnark]].
