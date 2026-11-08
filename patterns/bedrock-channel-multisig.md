---
title: "Bedrock channel multisig (native k-of-n Ed25519)"
tags: [bedrock, channel, multisig, ed25519, zone]
access_date: 2026-11-08
source_commit: "logos-blockchain master @ ce15ec1"
---

# Bedrock channel multisig

**Channels** are the objects zones use to post inscriptions to the Logos Blockchain and to hold deposited notes. A channel's spending authority is a **native k-of-n Ed25519 multisig**:

- **`ChannelConfigOp`** (`core/src/mantle/ops/channel/config.rs:40`) sets:
  - up to `CHANNEL_MAX_KEYS` **accredited Ed25519 keys**,
  - a `configuration_threshold`: signatures needed to change the config (must be ≤ the number of keys),
  - a `transfer_threshold`: signatures needed for `ChannelWithdraw` (release notes back to the ledger) and `ChannelTransfer`.
- **`ChannelMultiSigProof`** is an ordered map `key_index → Ed25519 signature` over the tx hash. `verify_channel_multi_sig` (`core/src/mantle/ops/channel/verification.rs:8`) requires **exactly** `transfer_threshold` entries, each verified against the accredited key at that index.
- **`ChannelInscribe`** takes a single `Ed25519Sig`.
- **Bootstrapping:** a channel comes into being on its first inscription. The first config is checked against a threshold of 0 and carries an empty proof (see the ledger tests around `create_genesis_config_tx`).

## Where MPC fits

The chain only sees Ed25519 public keys, so any accredited key can be a **threshold key**. The ledger cannot tell the difference ([[frost-ed25519-channel-keys]]). Three patterns:

1. **Nested:** k-of-n on chain across organisations, with each organisation's key an MPC key (FROST-Ed25519, or a vendor EdDSA vault such as Fordefi's `eddsa25519`). This is the PoC configuration: a 2-of-3 on-chain threshold whose members are two FROST 2-of-3 groups and one plain key.
2. **Flattened:** one threshold key and `transfer_threshold = 1`. Cheaper (one signature on chain) and hides the signer set, but there is no on-chain record of who approved.
3. **Native only:** individual keys and on-chain k-of-n. MPC then adds nothing on chain; it only protects each member's key.

## Notes

- Key rotation is a `ChannelConfigOp` signed at `configuration_threshold`. Membership changes are on chain, unlike MPC resharing, which is invisible.
- Each signature is checked with `verify_strict`, so a vendor signer must produce canonical Ed25519 signatures. FROST-Ed25519 does ([[frost-ed25519-channel-keys]]).

Related: [[bedrock-key-types]], [[mpc-vs-native-multisig-bedrock]].
