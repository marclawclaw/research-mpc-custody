---
title: "Threshold ZkSign: spending a note with an MPC-produced proof (PoC)"
tags: [bedrock, zksign, groth16, co-snark, co-circom, mpc, dkg, poc]
access_date: 2026-11-08
poc: "poc/zksign-co-circom/run.sh + poc/bedrock-ledger.patch (ledger/src/tests/zksign_mpc_poc.rs)"
---

# Threshold ZkSign via co-SNARK (PoC)

**Result:** three parties hold Shamir shares of a ZK secret key **that nobody ever knew**. Together they:
1. derive the note public key,
2. produce the ZkSign Groth16 proof for a real Mantle `Transfer`, using Bedrock's own circuit and proving key.

The Bedrock ledger accepts the transfer, and rejects the same proof for a different transaction. **Funds held in plain notes can be under threshold control today, with no change to Bedrock.**

## Pipeline (`poc/zksign-co-circom/run.sh`)

| Step | What | Tool |
|---|---|---|
| 1. Dealerless keygen | Each party *j* picks a random `rⱼ` in BN254 `Fr` and Shamir-shares it (`t = 1`, `n = 3`). Party *k* adds the shares it received, giving shares of `sk = r₀ + r₁ + r₂`. Plaintext contributions are deleted at once | `co-circom split-input`, then `shamir_share_tool add` (local addition; Shamir is linear) |
| 2. Public key in MPC | Run `signature.circom` in MPC with `msg = 0`. The public output `public_keys[0] = Poseidon2(KDF, sk)` is the note's `pk` | `co-circom generate-witness` + `generate-proof groth16` |
| 3. Build the tx | A `Transfer` spending a note `Note(10 000, pk)`. Export `tx_hash.to_fr()` | Bedrock test `zksign_mpc_step1_write_input` |
| 4. Sign in MPC | Replace the public `msg` in each party's share with the tx hash, then MPC witness extension and MPC Groth16 with **Bedrock's `proving_key.zkey` (circuits v0.5.7)** | `shamir_share_tool set-public`, `co-circom` |
| 5. Verify on the ledger | `SignedOps::from_parts(ops, [ZkSig(proof)])` → `preverify` → `try_apply_tx_operations` → `deferred.verify()` | Bedrock test `zksign_mpc_step2_apply_mpc_proof` |

Observed:
- All three parties output byte-identical `proof.json`.
- The public inputs are `[pk, 0×31 padding pks, msg]` (33 values), and `pk` and `msg` match the ledger's view.
- On one machine over local TLS: witness extension ≈ 0.3 s, proving ≈ 0.14 s.
- 4 full keygen-and-sign runs with fresh random keys all passed: one on a fresh Bedrock checkout and build with the patch applied, three reusing that checkout.
- Control test `zksign_mpc_control_local_prover` (a normal single-party proof through the same harness) passes.
- Negative check: the MPC proof attached to a different `Transfer` is rejected.

## Security and operational caveats

- **Semi-honest, honest majority.** TACEO's docs describe both co-circom protocols as semi-honest: 3-party replicated (ABY3-based) and N-party Shamir (DN07-based). A malicious party can make proving fail or produce a wrong proof, but should not learn `sk` if at most `t` parties collude. Malicious security is not claimed. Source: [TACEO MPC docs](https://taceo-deploy-docs.pages.dev/docs/resources/mpc), not archived (it redirects).
- **Liveness is n-of-n.** Shamir with `t = 1, n = 3` needs **all 3** parties online for each proof. This is *not* a "any 2 of 3" scheme like FROST. More parties raise the collusion bound, but every party must still take part.
- **Unaudited, GPL-3.0.** co-snarks calls itself "experimental and un-audited". The `co-circom` binary and `circom-mpc-compiler` are GPL-3.0; the libraries are MIT/Apache-2.0 ([[sources/2026-11-08-co-snarks-readme.md]]).
- **The PoC keygen is semi-honest too.** A party could contribute a bad share, and there are no commitments or consistency checks. A production DKG would add commitments and proofs of correct sharing.
- **No policy layer.** Parties prove whatever `msg` they are given. Each party should decode the `Ops` and check them against policy before taking part ([[unsigned-tx-tooling-bedrock]]).
- **Key slots.** The circuit takes 32 secret keys. A transfer spending several MPC notes can use one shared key or several, each secret-shared.

Related: [[zksign-proving-vs-signing]], [[tools/co-circom]], [[mpc-custody-design-for-bedrock]].
