# PoC: treasury channel with one FROST key

Strategy 2 of [[channel-multisig-strategies]]: "one key + FROST".

A channel accredits exactly one Ed25519 key. That key is a FROST-Ed25519 2-of-3 group key (ZF `frost-ed25519` 3.0.0). Both `transfer_threshold` and `configuration_threshold` are 1. Funds enter with `ChannelDeposit`. They leave with `ChannelTransfer` + `ChannelWithdraw` in one transaction.

All keys come from a real DKG (`frost::keys::dkg` part1, part2, part3). No trusted dealer is used. The DKG is simulated in one process, so there is no network and no broadcast channel.

The test runs against the real ledger: `LedgerState::try_apply_tx_operations` plus deferred proof verification. No node, mempool or network is involved.

## Run

```sh
git clone https://github.com/logos-blockchain/logos-blockchain && cd logos-blockchain
git checkout ce15ec1
git apply <this repo>/poc/bedrock-ledger.patch                          # adds frost-ed25519 and the first PoC
git apply <this repo>/poc/frost-single-key-channel/bedrock-ledger.patch # adds this PoC
cargo test -p logos-blockchain-ledger frost_single_key                  # 7 tests
```

The patch adds `ledger/src/tests/frost_single_key_channel_poc.rs` and registers it in `ledger/src/lib.rs`. Note that the filter `frost_` now runs 11 tests: the 4 from the first PoC plus these 7.

## Tests

| Test | What it checks | Expected | Result |
|---|---|---|---|
| `frost1_single_key_config_is_valid` | Channel created by config alone (empty proof). The state holds 1 key and thresholds 1 and 1. A config threshold of 2 with 1 key is refused. A transfer threshold of 2 with 1 key is accepted (not checked). | as described | ✓ |
| `frost1_any_two_of_three_pay_out` | Pair {1,2} pays 6 000 (4 000 change). Pair {2,3} pays 1 000 from the change. Pair {1,3} pays 500. Each proof is one signature at key index 0, 68 bytes. | all accepted | ✓ |
| `frost1_one_participant_alone_cannot_sign` | One signer: `round2::sign` returns `IncorrectNumberOfCommitments`. One share for a two-signer package: `aggregate` returns `UnknownIdentifier`. Plain Ed25519 signature made with one secret share: ledger returns `InvalidSignature`. | all refused | ✓ |
| `frost1_refresh_removes_participant_same_key` | DKG refresh among {1,2} removes participant 3. The group key does not change, so no config op is needed. The refreshed pair pays. Old share 3 plus new share 1 fail to aggregate (`InvalidSignature`). Old shares 1 and 3 still sign a valid payout. | as described | ✓ |
| `frost1_refresh_cannot_change_threshold` | Refresh with a higher t (2 to 3) or a lower t (3 to 2): `InvalidMinSigners`. Refresh with fewer than t participants: `InvalidMaxSigners`. | refused | ✓ |
| `frost1_repair_enrolls_new_participant_same_key` | Helpers 1 and 2 use the repairable-share protocol to give a share to a new identifier 4. The group key does not change. Pair {3,4} pays. | accepted | ✓ |
| `frost1_rotate_to_new_group` | A new 3-of-5 DKG group cannot rotate itself in. The old group (2 of 3) signs a `ChannelConfigOp` that accredits the new key. After that, the old group's payout is rejected (`InvalidSignature`) and the new group (3 of 5) pays. | as described | ✓ |

All 11 `frost_` tests passed 3 times in a row on the working checkout. They also passed on a fresh worktree of `ce15ec1` with both patches applied (2026-11-10).

## Findings

- **Config validation.** One key with both thresholds at 1 is valid. `ChannelConfigOp::new` checks only that `configuration_threshold <= keys.len()` (`core/src/mantle/ops/channel/config.rs:69`). Thresholds are `NonZero<u16>` (`config.rs:48-49`). The key list is a non-empty bounded vec (`core/src/mantle/ops/channel/mod.rs:21-22`). Decoding and serde go through the same check (`config.rs:162-186`).
- **Exact count.** The ledger requires exactly `threshold` signatures, not at least that many: `!=` in `core/src/mantle/ops/channel/verification.rs:19`, `withdraw.rs:119`, `channel_transfer.rs:149`, and `config.rs:241` for config ops. A new channel needs an empty proof (`config.rs:275-284`).
- **What the chain sees.** Each proof is `{0: sig}`: one 64-byte Ed25519 signature at index 0, 68 bytes encoded (`core/src/proofs/channel_multi_sig_proof.rs:110`). It is the same whichever pair signed. Nothing on chain shows t, n or the signers.
- **transfer_threshold is not checked against the key count.** A config with 1 key and `transfer_threshold = 2` is accepted. Payouts would then be impossible until a new config fixes it. The config threshold is still reachable, so this is not a permanent lock.
- **Refresh keeps the key and can remove members, but cannot change t.** `frost-ed25519` 3.0.0 has `keys::refresh` (dealer and DKG variants). It cannot add members, and t must stay the same.
- **Refresh only removes a member if the others delete their old shares.** Old shares still produce valid signatures for the same key. So removing a member this way relies on everyone deleting their old shares. A rotation to a new key does not have this problem.
- **Adding a member with the same key works through `keys::repairable`** with a new identifier. The library documents this module only for recovering a lost share. The caller has to add the new verifying share to the `PublicKeyPackage` by hand.
- **Rotation works.** The old group signs one `ChannelConfigOp`, with `parent` set to the channel's `config_tip_hash`. After that, only the new key authorises payouts. The new group may have a different t and n, and the chain cannot tell.

## Not verified

- A real networked DKG, with a broadcast channel, transport and a malicious participant.
- Fees. Like the first PoC, the test transactions carry no fee input.
- Node, mempool or network behaviour.
