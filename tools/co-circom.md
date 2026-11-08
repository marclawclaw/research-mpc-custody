---
title: "co-circom (TACEO co-snarks)"
tags: [co-snark, co-circom, mpc, groth16, circom, taceo, zksign]
type: open-source-library
licence: "GPL-3.0 (co-circom binary, circom-mpc-compiler); MIT/Apache-2.0 (libraries)"
version: "co-circom 0.10.0, co-snarks @ b6e99e0 (2026-11-04)"
access_date: 2026-11-08
---

# co-circom

TACEO's collaborative-SNARK toolkit. It runs an **unmodified circom circuit** in MPC, both witness extension and Groth16 or Plonk proving, over secret-shared inputs. The output proofs are snarkjs-compatible ([[sources/2026-11-08-co-snarks-readme.md]]).

- **Protocols:** REP3 (3-party replicated secret sharing, ABY3-based) and Shamir (n parties, DN07-based). TACEO describes both as **semi-honest**, honest majority.
- **Curves:** BN254 and BLS12-381. Bedrock's ZkSign is BN254, so it is supported directly.
- **CLI flow:** `split-input` → `generate-witness` (MPC) → `generate-proof groth16` (MPC) → `verify`. Parties connect over TLS (config per party: id, bind address, peers, certificates).
- **Bedrock result:** proves Bedrock's `mantle/signature.circom` with Bedrock's own `proving_key.zkey`. The ledger accepts the resulting proof as a note-spending ZkSign ([[threshold-zksign-cosnark]]).
- **Gaps:**
  - No built-in share arithmetic. `merge-input-shares` combines disjoint inputs only. For dealerless keygen the PoC adds a ~60-line tool (`poc/zksign-co-circom/shamir_share_tool.rs`) to sum shares and swap the public `msg`.
  - All `n` parties must be online for each proof.
- **Status:** "experimental and un-audited".
