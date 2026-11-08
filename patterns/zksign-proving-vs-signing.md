---
title: "Can proving run separately from the signer for ZK-key notes?"
tags: [bedrock, zksign, groth16, proving, delegated-proving, co-snark, mpc]
access_date: 2026-11-08
source_commit: "logos-blockchain master @ ce15ec1; logos-blockchain-circuits v0.5.7"
answers: "Q3"
---

# Can proving run separately from the signer?

**Answer:** on the Logos Blockchain, the proof **is** the signature. For notes (ZK keys) there is nothing to sign after proving, so "proving" and "signing" cannot be split into a prover plus a signer in the usual sense. Two things *can* be separated:

1. **Building from authorising.** The node funds and returns an unsigned transaction. The ZkSign proof for the user's notes is produced elsewhere and attached afterwards (`SignedOps::from_parts`). See [[unsigned-tx-tooling-bedrock]].
2. **Key holder from the prover, if the prover is distributed.** The prover needs `sk` as a witness, but `sk` can be **secret-shared**. With a co-SNARK (co-circom), several parties produce the Groth16 proof jointly and none of them learns `sk`. This works today against the real ledger ([[threshold-zksign-cosnark]]).

What does **not** work is handing `sk` to a single outsourced prover. That gives the prover the funds.

## Why ZkSign is MPC-friendly

The circuit (`mantle/signature.circom`, v0.5.7) is about as small as a ZK circuit can be:

```circom
template zkSignature(maxInput){
    signal input secret_keys[maxInput];   // private
    signal input msg;                     // public: tx hash as Fr
    signal output public_keys[maxInput];  // public
    for (i ...) public_keys[i] <== derive_public_key(secret_keys[i]);  // Poseidon2(KDF, sk)
    signal dummy; dummy <== msg * msg;    // keeps msg as a public input
}
component main {public [msg]} = zkSignature(32);
```

- The key enters **linearly**. The circuit is only Poseidon2 over BN254, which is cheap in MPC.
- The message binding comes entirely from Groth16's public-input binding. The circuit puts no constraint on `msg` beyond the dummy square, so the proof says "someone who knows these keys produced a proof for this `msg`".
- Consequence: a secret-shared `sk = Σ rⱼ` can be fed to co-circom unchanged, and the **same Bedrock proving key** (`proving_key.zkey`) and verifying key are used. No circuit change and no new trusted setup.
- Measured locally, for 3 parties on one machine: witness extension ≈ 0.3 s, proof ≈ 0.14 s.

## Options for threshold control of notes

| Option | Who sees `sk` | Liveness | Status |
|---|---|---|---|
| Single-party prover (`ZkKey::sign`) | the prover | 1 party | Bedrock default |
| **co-SNARK** (co-circom, Shamir or REP3) | nobody; each party holds a share | **all n parties online**; privacy holds against t colluding parties (honest majority) | **PoC passes against the ledger** ([[threshold-zksign-cosnark]]) |
| TEE prover holding `sk` | the enclave | 1 party | Not explored; custody moves to the TEE |
| Notes in a **channel** instead of plain notes | n/a: withdrawal is Ed25519 k-of-n | k of n | Native. Deposits still need a ZkSign from the depositor, and every transaction's fee is paid from a note (a small hot fee key is enough) ([[bedrock-channel-multisig]]) |

The channel route is worth stressing. Funds held in a channel are already under native k-of-n Ed25519 control, which MPC vaults can sign. A treasury can therefore keep its balance as channel notes and avoid ZkSign custody altogether, at the cost of using channel semantics.

Related: [[bedrock-key-types]], [[tools/co-circom]], [[mpc-custody-design-for-bedrock]].
