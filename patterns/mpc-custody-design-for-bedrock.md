---
title: "What an MPC / multisig for the Logos Blockchain would look like"
tags: [design, mpc, multisig, bedrock, channel, zksign, architecture, synthesis]
access_date: 2026-11-08
status: proposal
---

# What an MPC / multisig for the Logos Blockchain would look like

Everything marked ✓ is backed by code or a PoC against the Bedrock ledger at `ce15ec1`. Everything else is proposal.

## Two custody shapes

### A. Treasury as a channel: the multisig *is* a zone-like channel (vendor-compatible, privacy cost)

```
            on-chain: channel config  (accredited Ed25519 keys, transfer_threshold = k)
            ┌────────────────────┬────────────────────┬───────────────────┐
 key 0 = FROST t-of-n (Org A)   key 1 = Fordefi eddsa25519 vault   key 2 = hardware/plain key
            └──────── k signatures over tx_hash (Blake2b-256 of Ops) ────────┘
                                   ▼
                  ChannelWithdraw / ChannelTransfer  ✓ (FROST groups, PoC)
```

- **Ed25519 only controls funds inside a channel.** So shape A means creating a channel purely as a custody account:
  - created by `ChannelConfigOp` alone, with posting timeframe/timeout 0 so there is no sequencing duty;
  - funded by `ChannelDeposit`;
  - paid out with `ChannelTransfer` (re-assign to the recipient's `pk`) + `ChannelWithdraw` (release), each needing `transfer_threshold` Ed25519 signatures.
  
  Any accredited key can be MPC. Verified end to end ([[frost-ed25519-channel-keys]]). Three ways to hold the keys (native k-of-n, one FROST key, one MuSig2 key) are compared and PoC'd in [[channel-multisig-strategies]].
- **Downsides** ([[bedrock-channel-multisig]]):
  - the custody structure (keys, thresholds, config history) is public;
  - each payout reveals which members signed;
  - all treasury funds and flows are linkable to one channel id;
  - payers must use `ChannelDeposit`, not a normal transfer;
  - payouts take two ops;
  - channels are built for zone sequencing, so this is off-label use exposed to future channel-rule changes.
- **Staking** ([[channel-notes-staking]]):
  - Consensus: ✓. The treasury's notes count as leader stake. A staking node holds the notes' ZK key, which cannot move them, and rewards go to a `pk` the leader chooses.
  - Blend / SDP collateral: ✗ from the channel. The note must be withdrawn first, and the stake is then a plain note (single key or shape B).
- Signer changes go on chain through `ChannelConfigOp` at `configuration_threshold`.
- **Fees** are paid from ordinary notes, so a small hot fee balance in the operator's node (`/wallet/fund`) is enough.
- **Deposits** into the treasury are signed by whoever is paying in (their own ZkSign).

### B. Plain notes under threshold control (works, experimental)

```
 party 1 ─┐   Shamir shares of sk (dealerless: sk = Σ rⱼ)
 party 2 ─┼── co-circom: MPC witness + MPC Groth16 on mantle/signature.circom
 party 3 ─┘   with Bedrock's proving key  ──►  ZkSig(proof) for tx_hash   ✓ (PoC)
```

- The note is an ordinary `Note(value, pk)`. Nothing on chain shows that it is MPC-held ([[threshold-zksign-cosnark]]).
- It covers what A can't: plain balances, fee payment, deposits and Blend (SDP) collateral from MPC funds. SDP and proof-of-leadership proofs via MPC were not tested.
- Trade-offs:
  - every party must be online for each proof;
  - the security model is semi-honest;
  - co-circom is unaudited and GPL-3.0;
  - no commercial custodian offers it ([[tools/co-circom]]).

## Shared signing flow (both shapes)

```
1. build    MantleTxBuilder → Ops                  or  wallet_fund_tx / POST /wallet/fund
2. hash     tx_hash = ops.hash()                    (Ed25519: bytes; ZkSign: tx_hash.to_fr())
3. policy   decode Ops → amounts, recipients, channel ids; approvers sign off   (missing component)
4. sign     Ed25519 parts → FROST / vault;  ZK parts → co-circom parties
5. attach   SignedOps::from_parts(ops, op_proofs)
6. submit   POST /mempool/add/tx  or  submit_signed_transaction
```

Every MPC participant should run step 3 itself, decoding `Ops` and checking it against policy, rather than trusting a coordinator's summary. Black-box vaults sign blind, so the decoder is what gives transaction-aware policy ([[black-box-vault-bedrock]], [[unsigned-tx-tooling-bedrock]]).

## Where Fordefi fits

- **Yes:** as an accredited Ed25519 key of a **treasury channel** (shape A), alone or alongside other members, with shape A's privacy costs.
- **No:** for plain notes or fees, which need ZkSign ([[tools/fordefi]]).

## What would need building

| Component | Why | Effort |
|---|---|---|
| `Ops` decoder / renderer for approvers | Policy for blind signers | Small: types already exist in `lb-core` |
| Signer adapter (FROST coordinator or vault API ⇄ `tx_hash`) | Glue for shape A | Small |
| `MpcKmsBackend` for the node KMS | Node-driven flows (SDP, zone sequencing) with MPC keys | Medium ([[tools/bedrock-kms]]) |
| Signer hook in `zone-sdk` | Its sequencer takes a plaintext `Ed25519Key` | Small–medium |
| Production DKG for ZkSign keys (commitments, proofs of correct sharing) | The PoC keygen is semi-honest | Medium |
| co-circom hardening (malicious security, audit, licensing review) | Shape B in production | Large; depends on TACEO |

## Open questions

1. Are channels meant to be used as general treasuries, or only for zones? Shape A depends on the Logos team accepting channels as custody accounts, and on channel rules (sequencer rotation over accredited keys, timeouts, bridge logic) staying compatible.
2. Would Logos accept GPL-3.0 tooling (co-circom) in custody infrastructure, or should the MPC prover be rebuilt on the MIT/Apache `co-groth16` and `mpc-core` crates?
3. Could a threshold-friendly signing scheme be added for notes in a future Mantle version, to avoid co-SNARKs? For example, Ed25519 or FROST-compatible note keys as an alternative `OpProof`.

Related: [[mpc-vs-native-multisig-bedrock]], [[signer-compat-matrix]].
