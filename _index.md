# Research Index: MPC / Threshold Custody on the Logos Blockchain

**Domain definition:** MPC/TSS custody systems, both commercial (Fordefi, Fireblocks, Dfns) and open-source (FROST, co-SNARKs), evaluated for use on the Logos Blockchain (Bedrock).

**Primary metric:** fit with Bedrock's two proof kinds, Ed25519 and ZkSign, scored in [[signer-compat-matrix]].

## Entities

| Name | Type | Bedrock surface | Licence | Note |
|---|---|---|---|---|
| Fordefi | Commercial MPC (Paxos) | Ed25519 channel keys only (`eddsa25519` black-box) | Proprietary | [[tools/fordefi]] |
| Fireblocks | Commercial MPC | Ed25519 (raw signing) | Proprietary | [[black-box-vault-bedrock]] |
| Dfns | Commercial MPC | Ed25519 (hash signing) | Proprietary | [[black-box-vault-bedrock]] |
| ZF FROST (`frost-ed25519`) | Open-source threshold Schnorr | Ed25519 channel keys ✓ PoC | MIT/Apache-2.0 | [[tools/frost-zf]] |
| co-circom (TACEO) | Open-source co-SNARK | ZkSign for notes ✓ PoC | GPL-3.0 binary; MIT/Apache libraries | [[tools/co-circom]] |
| Bedrock KMS / wallet API | Node component | signing hooks | MIT/Apache-2.0 | [[tools/bedrock-kms]] |

## Notes by question

1. Schemes: [[bedrock-key-types]], [[bedrock-channel-multisig]] (what Ed25519 can and cannot move), [[channel-notes-staking]] (consensus and Blend staking from a treasury channel)
2. Black-box vaults: [[black-box-vault-bedrock]], [[frost-ed25519-channel-keys]]
3. Proving vs signing: [[zksign-proving-vs-signing]], [[threshold-zksign-cosnark]]
4. Unsigned transactions: [[unsigned-tx-tooling-bedrock]], [[tools/bedrock-kms]]

Synthesis: [[mpc-custody-design-for-bedrock]], [[mpc-vs-native-multisig-bedrock]], [[channel-multisig-strategies]] (native k-of-n vs one FROST key vs one MuSig2 key, all three PoC'd).

## Shortlist

1. **Treasury channel and FROST-Ed25519 or a Fordefi `eddsa25519` vault as accredited keys.** Native, vendor-compatible, verified. Costs: the treasury is a public, linkable, zone-like channel ([[bedrock-channel-multisig]]). Can stake for consensus but not for Blend ([[channel-notes-staking]]).
2. **co-circom ZkSign** for plain notes and fees, where n-of-n liveness and semi-honest security are acceptable.
3. **`Ops` decoder plus signer adapter**: the only missing glue for 1.

## Open questions
See [[mpc-custody-design-for-bedrock#Open questions]].
