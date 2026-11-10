# Native channel multisig (plain Ed25519 keys)

PoC for strategy 1 in [[channel-multisig-strategies]]. A channel is the treasury. It lists n plain Ed25519 member keys as `accredited_keys`, with `transfer_threshold = k` and `configuration_threshold = k'`. No MPC is involved. The ledger checks k signatures over the 32-byte tx hash (`ChannelMultiSigProof`).

The tests run on the real ledger path: `LedgerState::try_apply_tx_operations`, then the deferred proof check. No node, mempool or network.

## What it tests

1. Payout with 2-of-3 plain keys: `ChannelTransfer` (6 000 to a recipient, 4 000 change) plus `ChannelWithdraw` in one tx. Too few, too many, or wrong signatures are rejected.
2. Membership change by `ChannelConfigOp`: rotate a key, add a key and raise k. Bad config updates are rejected.
3. Signer index handling: repeated index, index out of range, a key listed twice.
4. Gas: execution gas of a payout and of a config change, against the threshold.

Every treasury in the tests is created by a config alone (empty proof, posting timeframe and timeout 0), then funded by one `ChannelDeposit` of 10 000.

## Run

```sh
git clone https://github.com/logos-blockchain/logos-blockchain && cd logos-blockchain
git checkout ce15ec1
git apply <this repo>/poc/bedrock-ledger.patch
git apply <this repo>/poc/native-channel-multisig/bedrock-ledger.patch
cargo test -p logos-blockchain-ledger native_channel_multisig_poc     # 17 tests
```

The second patch adds `ledger/src/tests/native_channel_multisig_poc.rs` and registers it in `ledger/src/lib.rs`. It needs the first patch, which adds the test module list it extends.

## Results

Verified 2026-11-10 on a fresh worktree of `ce15ec1` with both patches. 5 runs, all green:

```
test result: ok. 17 passed; 0 failed; 0 ignored; 0 measured; 196 filtered out
```

The existing `frost_` tests still pass (4 of 4).

| Test | Setup | Expected | Result |
|---|---|---|---|
| `native_2_of_3_pays_recipient` | keys [a, b, c], k = 2; a and c sign | recipient holds an ordinary note; change stays a channel note | ✓ |
| `native_every_pair_of_members_can_pay` | same; pairs (a,b), (a,c), (b,c) | all accepted | ✓ |
| `native_one_signature_is_below_threshold` | b alone | rejected | ✓ |
| `native_more_signatures_than_threshold_is_rejected` | a, b and c sign, k = 2 | rejected: the ledger wants **exactly** k | ✓ |
| `native_signature_by_non_member_is_rejected` | a, plus an outsider's signature at index 1 | rejected | ✓ |
| `native_out_of_range_index_is_rejected` | a at 0, b's valid signature at index 3 (only 0..2 exist) | rejected | ✓ |
| `native_same_index_cannot_count_twice` | build and decode a proof with index 0 twice | both refused (`DuplicateItem`) | ✓ |
| `native_key_listed_twice_counts_twice` | keys [a, a, b], k = 2; a signs at 0 and 1 | **accepted**: one holder meets k = 2 alone | ✓ (as the code predicts) |
| `native_membership_change_rotates_a_key` | config [a, b, d], signed by a and c (old set); then pay | c's signature at index 2 rejected, d's accepted | ✓ |
| `native_membership_change_adds_key_and_raises_threshold` | config [a, b, c, d], k = 3, signed by b and c | 2 signatures rejected; 3 of 4 accepted | ✓ |
| `native_config_change_below_threshold_is_rejected` | config signed by a alone, k' = 2 | rejected (`ThresholdUnmet`, 1 of 2) | ✓ |
| `native_config_change_with_empty_proof_is_rejected` | empty proof on an existing channel | rejected (`ThresholdUnmet`, 0 of 2) | ✓ |
| `native_config_change_with_stale_parent_is_rejected` | parent = root, not the current config id | rejected (`InvalidParent`) | ✓ |
| `native_removed_member_cannot_reconfigure` | after c is removed, a and c try to add c back | rejected | ✓ |
| `native_transfer_threshold_above_key_count_locks_payouts` | 3 keys, k = 4 | config accepted; 3 signatures rejected; k' members lower k to 2 and pay | ✓ |
| `native_payout_gas_scales_with_threshold` | 5 keys, k = 1, 2, 3, 5 | execution gas = (56 + 56) × k: 112, 224, 336, 560 | ✓ |
| `native_config_gas_scales_with_configuration_threshold` | k' = 3 | execution gas = 56 × 3, using k' in force before the change | ✓ |

## Rules found in the code (at `ce15ec1`)

- **Exactly k signatures.** Transfer and withdraw reject any count other than `transfer_threshold` (`core/src/mantle/ops/channel/verification.rs:19`). Config does the same with `configuration_threshold` (`config.rs:241`). Signing with more members than needed fails, so a wallet must drop extras.
- **Config update of an existing channel.** `parent` must equal the current config id (`config.rs:231`). The proof needs exactly k' signatures from the **current** key set, over the tx hash (`config.rs:240-264`). The new keys and thresholds replace the old ones in full (`config.rs:306-315`). Only a channel that does not exist yet takes an empty proof (`config.rs:265-284`).
- **Config sanity.** `ChannelConfigOp::new` checks k' ≤ n (`config.rs:69`). It does not check k ≤ n. It does not reject a key listed twice (`accredited_keys` is a plain bounded vec, `utils/src/bounded/vec.rs:27-30`).
- **One signature per index.** The proof is a map keyed by index (`core/src/proofs/channel_multi_sig_proof.rs:46-53`). Building it with a repeated index fails (`utils/src/bounded/btree_map.rs:93-104`). The canonical decoder rejects a repeated or out-of-order index. Through serde, a repeated index keeps the last value, so it still counts once (test at `channel_multi_sig_proof.rs:211-230`).
- **Out-of-range index.** Rejected as `KeyNotFound` (`ledger/src/mantle/helpers.rs:139-156`) or `InvalidSignatureIndex` (`config.rs:254`).
- **Gas.** `ChannelTransfer` and `ChannelWithdraw` cost their profile entry times `transfer_threshold`. `ChannelConfig` costs its entry times `configuration_threshold` (`core/src/mantle/ops/op_ref.rs:54-63`). It scales with the threshold, which equals the signature count because of the exact-count rule. The threshold is read before each op in the tx (`core/src/mantle/transactions/tx_list/ops.rs:206-218`).

## Limits

- Ledger-level only. No node, mempool or network.
- Signers are deterministic test keys. No vendor vault or hardware key was used.
- Fees were not modelled. The payout tx has no fee input.
- `ChannelTransfer` and `ChannelWithdraw` turn every multisig error into `InvalidSignature` (`withdraw.rs:97`, `channel_transfer.rs:120`), so the tests check rejection, not the exact cause.
