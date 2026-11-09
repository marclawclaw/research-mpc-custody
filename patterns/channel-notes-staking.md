---
title: "Can treasury-channel funds stake? (consensus vs Blend)"
tags: [bedrock, channel, staking, cryptarchia, pos, blend, sdp, treasury]
access_date: 2026-11-09
source_commit: "logos-blockchain master @ 36847f856 (2026-09-02); line numbers refer to this commit"
---

# Can treasury-channel funds stake? (consensus vs Blend)

This concerns shape A of [[mpc-custody-design-for-bedrock]], where the treasury is a channel ([[bedrock-channel-multisig]]).

**Short answer:**
- The funds stay on the Logos Blockchain.
- They **can** stake for consensus (the Cryptarchia leader lottery).
- They **cannot** be Blend (SDP) collateral while they are in the channel.

## The funds stay on the Logos Blockchain

A channel is not a separate chain or a bridge to one.
- `ChannelDeposit` consumes the input notes and re-creates the **same notes** (same `value` and `pk`) in the Bedrock UTXO set. It then registers each one as a channel note (`core/src/mantle/ops/channel/deposit.rs:39-51`, `:143-153`).
- The registration only changes **who can move** the note:
  - a plain `Transfer` rejects it (`core/src/mantle/ledger.rs:334`, `InputsError::ChannelNote`);
  - only the channel's `transfer_threshold` Ed25519 multisig can move it (`ChannelTransfer` / `ChannelWithdraw`).

## Consensus staking (Cryptarchia proof of leadership): yes, by design

- Commit `ba1236b3c`, "feat(mantle): Enable PoS for channels (#3145)" (2026-07-20), introduced the current channel-note design. Channel notes remain ordinary UTXOs, so they stay in the stake set.
- The leader lottery needs the **ZK secret key** behind the note's `pk`. The channel's Ed25519 keys play no part in it.

This splits the keys into roles:

| Key | Can | Cannot |
|---|---|---|
| ZK key of the channel note's `pk` (the staking node) | Run the leader lottery with the note's stake, produce blocks, claim rewards | Move the principal: `Transfer` rejects channel notes |
| Channel accredited Ed25519 keys (k-of-n, FROST / vault) | Move or release the note (`ChannelTransfer`, `ChannelWithdraw`) | Stake: they are not ZK keys |

**Consequence:** a staking node can hold a **hot ZK key that cannot steal the treasury**, while custody stays with the k-of-n.

To change which node stakes, the multisig re-assigns the note to a new `pk` with `ChannelTransfer`. The outputs stay channel notes (`channel_transfer.rs:171-183`).

**Rewards do not go back to the channel automatically.**
- `LeaderClaimOp` carries a `pk` chosen by the claimer and pays the reward as a new plain note to that `pk` (`core/src/mantle/ops/leader_claim.rs:55-63`, `:261-262`).
- So the staking operator controls the rewards. Getting them into the treasury needs an explicit `ChannelDeposit`, which is an operational or policy matter, not something the protocol enforces.

**Not verified:**
- No PoC staked with a channel note. This section is based on the code and the commit's stated purpose.
- The PoL circuit proves membership in the aged UTXO root and knowledge of the secret key. It does not consult the channel registry.

## Blend staking (SDP declaration): no, not from the channel

- `SDPDeclareOp::validate` explicitly rejects channel notes as service collateral (`core/src/mantle/ops/sdp/declare.rs:54-57`, `SdpError::ChannelNote`). The check was added in the same commit, `ba1236b3c`.
- For a Blend node to stake treasury funds, the treasury must first:
  1. **release** the note with `ChannelWithdraw` (k-of-n Ed25519);
  2. **declare** it with `SDPDeclare` (`ZkAndEd25519`): a ZkSign from the note's ZK key plus the provider's Ed25519 key.
- While it is locked for Blend, the collateral is a **plain note under one ZK key**. Keeping it under threshold control requires the co-SNARK route ([[threshold-zksign-cosnark]], shape B). Otherwise the custody of that stake falls back to whoever holds that key.

## Summary

| | Treasury as a channel (shape A) | Plain notes under co-SNARK ZkSign (shape B) |
|---|---|---|
| Funds on the Logos Blockchain | ✓ | ✓ |
| Consensus (leader) stake | ✓ The staker holds the note's ZK key but cannot spend; principal under k-of-n | ✓ only if the PoL is also proved via MPC (not tested; PoL is a different circuit) |
| Blend / SDP collateral | ✗ must `ChannelWithdraw` first, then custody is single ZK key or shape B | ✓ in principle (SDP ZkSign via co-circom; not tested) |
| Rewards | To a `pk` chosen by the leader, outside the channel | Same |

Related: [[bedrock-channel-multisig]], [[bedrock-key-types]], [[mpc-custody-design-for-bedrock]].
