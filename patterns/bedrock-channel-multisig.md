---
title: "Bedrock channels: what Ed25519 keys can and cannot do"
tags: [bedrock, channel, multisig, ed25519, zone, sequencer, treasury]
access_date: 2026-11-09
source_commit: "logos-blockchain master @ ce15ec1"
---

# Bedrock channels: what Ed25519 keys can and cannot do

**Ed25519 keys never control ordinary notes.** On the Logos Blockchain:
- Spending a plain note (`Transfer`) always needs a **ZkSign** from the note's ZK key.
- Ed25519 keys appear only in **channel** operations: the objects zones (their sequencers) post to and bridge through, plus the Ed25519 half of SDP declarations.

Within a channel the accredited Ed25519 keys play two roles:

| Role | Ops | Authority |
|---|---|---|
| **Sequencing** | `ChannelInscribe` (`Ed25519Sig` from the current sequencer) | The accredited keys *are* the sequencer rotation list (`tip_sequencer` indexes into `accredited_keys`, `core/src/mantle/channel.rs:109`) |
| **Bridging / custody** | `ChannelTransfer`, `ChannelWithdraw`, `ChannelConfig` (`ChannelMultiSigProof`: `transfer_threshold` or `configuration_threshold` signatures) | Moves **channel notes only** |

## Channel notes

A note becomes a channel note through `ChannelDeposit`, which its owner signs with their ZkSign. From then on:

- **The owner can no longer spend it.** A regular `Transfer` rejects any input that is a channel note (`InputsError::ChannelNote`, `core/src/mantle/ledger.rs:320`).
- **`ChannelTransfer { channel_id, inputs, outputs }`**, signed by `transfer_threshold` accredited keys, consumes channel notes and creates new notes with **any** public key and value (balanced in = out). The outputs **stay registered in the channel** (`channel_transfer.rs`, `execute`).
- **`ChannelWithdraw { channel_id, inputs }`**, signed by `transfer_threshold` keys, **releases** channel notes back to the ordinary ledger. A released note is then spendable by the ZK key it carries.

So paying out of a channel takes `ChannelTransfer` (re-assign to the recipient's `pk`) plus `ChannelWithdraw` (release). Both can go in one transaction, as the PoC shows.

## Using a channel as a multisig treasury

Making a multisig on the Logos Blockchain with Ed25519/MPC keys **means making the treasury a channel, a zone-like object.** The protocol allows it today:

- **Created by config alone:** a `ChannelConfigOp` for a fresh channel id carries an empty proof. No inscription is needed.
- **No sequencing duty:** `posting_timeframe = 0` ("infinity") and `posting_timeout = 0` ("no timeout") (`channel.rs:128`).
- **Funded by `ChannelDeposit` and paid out by `ChannelTransfer` + `ChannelWithdraw`.** All of this is verified against the real ledger with FROST 2-of-3 groups as accredited keys ([[frost-ed25519-channel-keys]], test `frost_treasury_channel_pays_recipient`).

### Downsides

| | Treasury as a channel (Ed25519 k-of-n) | Plain notes under a single ZK key (or co-SNARK MPC, [[threshold-zksign-cosnark]]) |
|---|---|---|
| **Custody structure visible** | Yes: channel id, the accredited key list, both thresholds and every config change are public ledger state | No: an MPC-held note looks like any single-owner note |
| **Who approved** | Each `ChannelMultiSigProof` lists the **key indices** that signed, so on-chain observers learn which members approved each payment | Hidden (one proof) |
| **Balance and flows linkable** | All treasury funds are tagged to one channel id: total balance, every deposit and every payout are trivially linkable | Funds can be spread across fresh keys/notes; an observer cannot group them by owner unless keys are reused |
| **Receiving funds** | Payers must use `ChannelDeposit` to the channel id; a plain transfer to a key is *not* under channel control. Wallets and exchanges need explicit support | A normal transfer to `pk` |
| **Payout cost** | Two ops (`ChannelTransfer` + `ChannelWithdraw`), each with k Ed25519 signatures | One `Transfer` with one ZkSign |
| **Fees** | Channel ops don't pay fees from channel notes; each tx needs a fee input from a plain note (a ZkSign, e.g. a small hot fee key) | Paid from the MPC notes themselves (co-SNARK) or a fee key |
| **Semantics** | Off-label: channels are built for zone sequencing and bridging. The accredited keys double as a sequencer rotation list, and future changes to channel rules (sequencing, timeouts, bridge logic) would apply to the treasury | Core ledger semantics |
| **Vendor compatibility** | ✓ Fordefi/Fireblocks/Dfns EdDSA vaults and FROST-Ed25519 | ✗ vendors; ✓ self-hosted co-circom only |
| **Liveness** | Any k of n (FROST t-of-n inside each member) | All n parties (co-SNARK) |

### Staking

Channel notes stay in the Bedrock UTXO set:
- **Consensus (leader lottery):** they can stake, using the note's ZK key, which cannot spend them.
- **Blend / SDP:** they are rejected as collateral (`SdpError::ChannelNote`).

Details: [[channel-notes-staking]].

Bedrock notes are not confidential anyway: `Note { value, pk }` is public ledger state. The privacy lost by using a channel is **unlinkability and hiding the custody structure**, not amount privacy.

## Summary

- For a sequencer: Ed25519 = inscribing.
- For custody: Ed25519 controls funds **only if those funds are deposited into a channel**. Then the channel *is* the multisig.
- The price is a publicly visible, linkable custody account with off-label semantics. In exchange you get native k-of-n with commercial vault support.

Related: [[bedrock-key-types]], [[mpc-vs-native-multisig-bedrock]], [[mpc-custody-design-for-bedrock]].
