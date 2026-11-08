# Proofs of concept against the Logos Blockchain ledger

Both PoCs are ordinary tests inside Bedrock's `logos-blockchain-ledger` crate. They run transactions through `LedgerState::try_apply_tx_operations` and the deferred proof verification, the same path a node takes for every transaction.

`bedrock-ledger.patch` applies to `logos-blockchain/logos-blockchain` at `ce15ec1`. It adds:
- `frost-ed25519 = "3.0.0"` as a dev-dependency,
- `ledger/src/tests/frost_channel_poc.rs` ([[frost-ed25519-channel-keys]]),
- `ledger/src/tests/zksign_mpc_poc.rs` ([[threshold-zksign-cosnark]]).

## 1. FROST-Ed25519 channel keys

```sh
git clone https://github.com/logos-blockchain/logos-blockchain && cd logos-blockchain
git checkout ce15ec1 && git apply ../research-mpc-custody/poc/bedrock-ledger.patch
cargo test -p logos-blockchain-ledger frost_        # 3 tests
```

## 2. Threshold ZkSign via co-circom

```sh
./zksign-co-circom/run.sh     # clones and pins Bedrock, circuits v0.5.7 and co-snarks, then runs everything in ./work
```

Expected tail:

```
== 2. MPC: derive the public key pk = Poseidon2(KDF, sk)
== 3. Bedrock: build a Transfer spending a note owned by pk; export its tx hash
== 4. MPC: sign (ZkSign Groth16 proof) with the same key shares
   public inputs: pk and msg match
== 5. Bedrock ledger: apply the transfer with the MPC proof
test result: ok. 1 passed; ...
```

- `shamir_share_tool.rs` is copied into co-snarks as an example binary. It adds Shamir input shares (dealerless keygen) and replaces the public `msg` (the tx hash).
- The three MPC parties run as local processes talking over TLS, using co-circom's example certificates. That is fine for a demo; never use those certificates for real keys.
- Verified on 2026-11-08: four full runs with fresh keys, one of them from a fresh Bedrock checkout and build.
