# PoC: one MuSig2 key as the only channel key

> **Warning: unaudited demo MuSig2.** The MuSig2 code in this patch is a minimal, test-only sketch written for this PoC. It has had no review. It is not constant time. It has no session state machine and no nonce storage. Its hash tags are ad hoc because no Ed25519 MuSig2 standard exists. Do not use it to hold funds.

## What it tests

Strategy 3 of `patterns/channel-multisig-strategies.md`. A treasury channel lists exactly one accredited Ed25519 key. That key is a MuSig2 3-of-3 aggregate. Both thresholds are 1.

The test runs against the real Bedrock ledger (`LedgerState::try_apply_tx_operations` plus deferred proof checks). Bedrock checks channel signatures with ed25519-dalek `verify_strict` over the 32-byte tx hash. So MuSig2 must output a plain RFC 8032 signature `(R, s)` with `s·B = R + SHA-512(R‖X‖m)·X`.

The demo scheme, on `curve25519-dalek` 4.1.3 and `sha2` 0.10 (both already in Bedrock's `Cargo.lock`):

- Each member has a raw random scalar `x_i` and key `X_i = x_i·B`. No RFC 8032 seed hashing or clamping.
- Key aggregation: keys sorted, `a_i = H_agg(L, X_i)`, `X = Σ a_i·X_i`.
- Round 1: each member sends two nonce points `R_i1`, `R_i2`.
- `b = H_non(X, R1, R2, m)`, `R = R1 + b·R2`.
- Challenge: `c = SHA-512(R‖X‖m) mod ℓ`, the exact Ed25519 challenge.
- Round 2: `s_i = r_i1 + b·r_i2 + c·a_i·x_i`. The aggregator checks each `s_i` and sums them.

## Setup

1. A channel is created by config alone: `[X]`, thresholds 1 and 1, posting timeframe and timeout 0.
2. A note is deposited (ZkSign of the depositor).
3. A payout tx holds `ChannelTransfer` (6 000 to a recipient, 4 000 change) and `ChannelWithdraw` of the payment. One MuSig2 signature over the tx hash serves as the proof of both ops.

## Tests

File: `ledger/src/tests/musig2_single_key_channel_poc.rs`. Every rejection is checked to be `InvalidSignature`, not some other error.

| Test | Expected | Result |
|---|---|---|
| `musig2_output_is_standard_ed25519`: 3-of-3 signature checked by Bedrock's key type (`verify_strict`) and by ZF `frost-ed25519`'s Ed25519 verifier; aggregation does not depend on key order | accepted by both | ✓ |
| `musig2_coefficients_stop_rogue_key`: with a naive sum `X1+X2+X3` one member can pick a key that makes the sum his own; with MuSig2 coefficients he cannot | naive sum = attacker key; MuSig2 aggregate differs | ✓ |
| `musig2_single_key_treasury_pays_recipient`: create, deposit, `ChannelTransfer` + `ChannelWithdraw` signed by all 3 | recipient holds an ordinary note; change stays a channel note | ✓ |
| `musig2_two_of_three_is_rejected`: (a) 3 send nonces, 1 withholds its partial; (b) and (c) only 2 members take part; (d) 2 members sign for their own 2-key aggregate | (a)-(c) fail `verify_strict` and the ledger; (d) is a valid signature for a key the channel does not list, ledger rejects | ✓ |
| `musig2_signature_over_another_tx_is_rejected`: valid 3-of-3 signature over a different tx | rejected | ✓ |
| `musig2_rotation_signed_by_old_aggregate`: `ChannelConfigOp` to a new aggregate `{1, 2, 4}`, parent = previous config id | the new group alone cannot rotate; old aggregate rotates; then the old aggregate cannot pay and the new one can | ✓ |

All 6 passed on 4 consecutive runs of the final code, and once more on a fresh `ce15ec1` worktree with both patches applied (2026-11-10). The existing FROST tests still pass.

## Run it

```sh
git clone https://github.com/logos-blockchain/logos-blockchain && cd logos-blockchain
git checkout ce15ec1
git apply <this repo>/poc/bedrock-ledger.patch
git apply <this repo>/poc/musig2-single-key-channel/bedrock-ledger.patch
cargo test -p logos-blockchain-ledger musig2_        # 6 tests
```

The patch adds `curve25519-dalek` (workspace) and `sha2 = "0.10"` as ledger dev-dependencies. `Cargo.lock` is not in the patch. Cargo updates it on first build.

## What this shows

- Bedrock does not care how a key was made. A MuSig2 aggregate point passes the ledger's small-order check and `verify_strict`, like a FROST or a single key.
- The threshold lives entirely off chain. The ledger sees one key and one signature. Two of three members cannot pay.
- Rotation works with the normal `ChannelConfigOp`, signed by the old aggregate. That needs all old members.

## Limits

- n-of-n only. One lost member freezes the treasury unless the channel lists another key.
- Demo crypto, see the warning. No audited Ed25519 MuSig2 library was found (ZenGo-X code is GPL-3.0, unaudited, unmaintained since 2022).
- The aggregator checks that the aggregate key is torsion free. It does not check each member key. A member with a mixed-order key could break signing (denial of service). This was not tested.
- Single process. No network, no nonce storage, no concurrent sessions, no adversarial members beyond the cases above.
- Ledger-level test. No node, mempool or network was involved.
