# Research: MPC / Threshold-Signature Custody (Fordefi-style) on the Logos Blockchain

**Topic:** MPC wallets and threshold custody, from commercial platforms such as Fordefi to open-source FROST and co-SNARKs, and how they map onto the **Logos Blockchain** (Bedrock; transactions are Mantle ops).

**Initiated:** 2026-11-08
**Researcher:** marclawclaw (Marclaw research agent)
**Code examined:**

| Repository | Revision |
|---|---|
| `logos-blockchain/logos-blockchain` | master @ `ce15ec1` (2026-11-06) |
| `logos-blockchain/logos-blockchain-circuits` | `v0.5.7` (the version Bedrock pins) |
| `logos-blockchain/logos-blockchain-module` | `c4f52b9` |
| `TaceoLabs/co-snarks` | `b6e99e0` |

## Questions and answers

| # | Question | Short answer | Notes |
|---|---|---|---|
| 1 | What signature scheme and curve do Logos Blockchain keys use? | **Ed25519** for channel inscriptions, the native k-of-n channel multisig and SDP, signing the 32-byte Blake2b-256 tx hash. **ZkSign** for notes (transfers, deposits, fees): a Groth16 proof over **BN254** of knowing the secret keys whose Poseidon2 hashes are the note public keys, bound to the tx hash. No secp256k1. | [[bedrock-key-types]], [[bedrock-channel-multisig]] |
| 2 | Could a black-box vault sign a Logos Blockchain transaction? | **Yes for Ed25519 parts.** Fordefi `eddsa25519`, Fireblocks and Dfns EdDSA vaults sign the raw tx hash, so they can hold channel keys; FROST-Ed25519 was verified against the ledger. **No for notes:** ZkSign is a proof, not a signature any vault offers. | [[black-box-vault-bedrock]], [[frost-ed25519-channel-keys]] |
| 3 | For notes (ZK keys), can proving run separately from the signer? | The proof **is** the signature, so a single outsourced prover must hold `sk`. **But the prover can be distributed:** three co-circom parties holding Shamir shares of a dealerless key produced a ZkSign proof with Bedrock's own circuit and proving key, and the ledger accepted the transfer. Caveats: all parties online, semi-honest, unaudited. | [[zksign-proving-vs-signing]], [[threshold-zksign-cosnark]] |
| 4 | What library builds an unsigned transaction today? | **`logos-blockchain-core`**: `MantleTxBuilder` → `Ops` (unsigned), `ops.hash()`, `SignedOps::from_parts`. **Node API:** `POST /wallet/fund` returns unsigned `Ops`, `POST /mempool/add/tx` submits. **C bindings and Logos Core module:** `wallet_fund_tx` and `submit_signed_transaction`. Missing: an `Ops` decoder for approvers and a remote-signer KMS backend. | [[unsigned-tx-tooling-bedrock]], [[tools/bedrock-kms]] |

**What it would look like:** [[mpc-custody-design-for-bedrock]]. In short:
- **Treasury in a channel:** native k-of-n Ed25519, where each accredited key can be FROST or a Fordefi-style vault. Practical today.
- **Plain notes under co-SNARK ZkSign:** works, but experimental.

## Proofs of concept (`poc/`)

Both run against the real Bedrock ledger (`LedgerState::try_apply_tx_operations` plus deferred proof verification) via `poc/bedrock-ledger.patch`:
- `frost_channel_poc.rs`: two FROST-Ed25519 2-of-3 groups and one plain key form a 2-of-3 channel; withdraw accepted; below-threshold and wrong-tx signatures rejected.
- `poc/zksign-co-circom/run.sh`: dealerless 3-party keygen, MPC public-key derivation, MPC ZkSign of a `Transfer`; ledger accepts it and rejects the proof on another tx.

## Related research
- [research-multisig-sovereign](https://github.com/marclawclaw/research-multisig-sovereign): sovereign multisig and FROST
- [research-cross-chain-dex: tss-custody-vault](https://github.com/marclawclaw/research-cross-chain-dex/blob/main/patterns/tss-custody-vault.md): Thorchain GG20 TSS vaults
- `research-mpc-web3` (private): MPC/TSS protocol and vendor notes, including the Paxos–Fordefi acquisition

## Structure
- `_index.md`: index and shortlist
- `patterns/`: one question or mechanism per note
- `tools/`: one note per product, library or Bedrock component
- `metrics/`: comparison tables
- `poc/`: Bedrock ledger patch, co-circom run script, share tool
- `sources/`: archived copies of cited web pages (code is cited by repo, commit and path:line)
- `[[wikilinks]]` between notes (Obsidian vault)
