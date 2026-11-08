#!/usr/bin/env bash
# Threshold (MPC) ZkSign for a Logos Blockchain note transfer, end to end.
#
#   1. Dealerless keygen: each of 3 parties picks a random r_j and Shamir-shares it;
#      every party sums what it receives -> shares of sk = r_0 + r_1 + r_2. Nobody knows sk.
#   2. The note public key pk = Poseidon2(KDF, sk) is computed in MPC (a keygen proof, msg = 0).
#   3. A Mantle Transfer spending a note owned by pk is built with the real Bedrock code;
#      its tx hash becomes the circuit's public `msg`.
#   4. The 3 parties run co-circom witness extension + Groth16 proving in MPC with
#      Bedrock's own signature.circom and proving key (circuits v0.5.7).
#   5. The Bedrock ledger applies the transfer with that proof (and rejects it for another tx).
#
# Everything is pinned; override paths with env vars to reuse existing checkouts.
set -euo pipefail

WORK=${WORK:-$PWD/work}
HERE=$(cd "$(dirname "$0")" && pwd)
BEDROCK_REV=ce15ec1           # logos-blockchain master, 2026-11-06
CIRCUITS_TAG=v0.5.7           # the circuits version that Bedrock pins
COSNARKS_REV=b6e99e0          # TaceoLabs/co-snarks, 2026-11-04
mkdir -p "$WORK"; cd "$WORK"

BEDROCK=${BEDROCK:-$WORK/logos-blockchain}
CIRCUITS=${CIRCUITS:-$WORK/logos-blockchain-circuits}
COSNARKS=${COSNARKS:-$WORK/co-snarks}

if [ ! -d "$BEDROCK" ]; then
  git clone -q https://github.com/logos-blockchain/logos-blockchain.git "$BEDROCK"
  git -C "$BEDROCK" checkout -q $BEDROCK_REV
  git -C "$BEDROCK" apply "$HERE/../bedrock-ledger.patch"
fi
if [ ! -d "$CIRCUITS" ]; then
  git clone -q --depth 1 --branch $CIRCUITS_TAG https://github.com/logos-blockchain/logos-blockchain-circuits.git "$CIRCUITS"
  git -C "$CIRCUITS" submodule update -q --init --depth 1 circomlib
fi
if [ ! -d "$COSNARKS" ]; then
  git clone -q https://github.com/TaceoLabs/co-snarks.git "$COSNARKS"
  git -C "$COSNARKS" checkout -q $COSNARKS_REV
  cp "$HERE/shamir_share_tool.rs" "$COSNARKS/co-circom/co-circom/examples/"
fi
(cd "$COSNARKS" && unset CARGO_TARGET_DIR && cargo build -q --release --bin co-circom && cargo build -q --release --example shamir_share_tool -p co-circom)
CC=$COSNARKS/target/release/co-circom
TOOL=$COSNARKS/target/release/examples/shamir_share_tool
CIRCUIT=$CIRCUITS/mantle/signature.circom

# Bedrock's prebuilt circuit artifacts (downloaded by its build script on first build).
(cd "$BEDROCK" && cargo test -q -p logos-blockchain-ledger --no-run >/dev/null 2>&1)
ART=${ART:-$HOME/.cache/logos/blockchain/logos-blockchain-circuits-$CIRCUITS_TAG-linux-x86_64/signature}
ZKEY=$ART/proving_key.zkey; VK=$ART/verification_key.json

RUN=$WORK/run; rm -rf "$RUN"; mkdir -p "$RUN"; cd "$RUN"
cp -r "$COSNARKS/co-circom/co-circom/examples/data" .
printf '[compiler]\nallow_leaky_loops = false\nlink_library = []\n' > split.toml
for k in 0 1 2; do
  sed -e 's|link_library = \["../lib"\]|link_library = []|' -e "s|../data/|$RUN/data/|g" \
    "$COSNARKS/co-circom/co-circom/examples/configs/party$((k+1)).toml" > party$k.toml
done

mpc_prove() { # $1 = input-share prefix (…/x => x.$k.shared), $2 = output dir
  local in=$1 out=$2; mkdir -p "$out"
  for k in 0 1 2; do
    $CC generate-witness -O2 --input "$in.$k.shared" --circuit "$CIRCUIT" --protocol SHAMIR --curve BN254 \
      --config party$k.toml --out "$out/witness.$k.shared" >"$out/wit$k.log" 2>&1 &
  done; wait
  for k in 0 1 2; do
    extra=(); [ $k = 0 ] && extra=(--public-input "$out/public_input.json")
    $CC generate-proof groth16 --witness "$out/witness.$k.shared" --zkey "$ZKEY" --protocol SHAMIR --curve BN254 \
      --config party$k.toml --out "$out/proof.$k.json" "${extra[@]}" >"$out/prf$k.log" 2>&1 &
  done; wait
  $CC verify groth16 --proof "$out/proof.0.json" --vk "$VK" --public-input "$out/public_input.json" --curve BN254 2>&1 | grep -q "verified successfully"
}

echo "== 1. dealerless keygen (each party shares a random contribution)"
R_BN254=21888242871839275222246405745257275088548364400416034343698204186575808495617
for j in 0 1 2; do
  r=$(python3 -I -c "import secrets; print(secrets.randbelow($R_BN254))")
  python3 -I -c "import json,sys; print(json.dumps({'secret_keys':[sys.argv[1]]+['0']*31,'msg':'0'}))" "$r" > contrib$j.json
  mkdir -p contrib$j
  $CC split-input --circuit "$CIRCUIT" --input contrib$j.json --protocol SHAMIR --curve BN254 --out-dir contrib$j --config split.toml >/dev/null 2>&1
  rm contrib$j.json   # party j's plaintext contribution never leaves party j
done
for k in 0 1 2; do   # party k sums the shares it received from everyone
  $TOOL add key.$k.shared contrib0/contrib0.json.$k.shared contrib1/contrib1.json.$k.shared contrib2/contrib2.json.$k.shared
done
rm -rf contrib0 contrib1 contrib2

echo "== 2. MPC: derive the public key pk = Poseidon2(KDF, sk)"
mpc_prove "$RUN/key" "$RUN/keygen"
cp keygen/public_input.json keygen_public_input.json
echo "   pk = $(python3 -I -c "import json; print(json.load(open('keygen_public_input.json'))[0])")"

echo "== 3. Bedrock: build a Transfer spending a note owned by pk; export its tx hash"
(cd "$BEDROCK" && ZKSIGN_POC_DIR=$RUN cargo test -q -p logos-blockchain-ledger zksign_mpc_step1 -- --ignored >/dev/null)
MSG=$(cat msg.txt); echo "   msg (tx hash as Fr) = $MSG"

echo "== 4. MPC: sign (ZkSign Groth16 proof) with the same key shares"
for k in 0 1 2; do $TOOL set-public key.$k.shared msg "$MSG" sign.$k.shared; done
mpc_prove "$RUN/sign" "$RUN/sign_out"
cp sign_out/proof.0.json proof.json
python3 -I -c "
import json; p=json.load(open('sign_out/public_input.json')); k=json.load(open('keygen_public_input.json'))
assert p[0]==k[0] and p[32]=='$MSG', 'public inputs mismatch'; print('   public inputs: pk and msg match')"

echo "== 5. Bedrock ledger: apply the transfer with the MPC proof"
(cd "$BEDROCK" && ZKSIGN_POC_DIR=$RUN cargo test -q -p logos-blockchain-ledger zksign_mpc_step2 -- --ignored 2>&1 | grep "test result")
