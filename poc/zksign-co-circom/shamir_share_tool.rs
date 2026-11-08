//! Local (non-interactive) operations on one party's co-circom Shamir input shares.
//!
//!   add <out> <in>...                    sum shares of the same party (Shamir is linear:
//!                                         shares of r_0 + r_1 + r_2 = shares of sk)
//!   set-public <in> <name> <value> <out>  replace a public entry, e.g. `msg` = tx hash
//!
//! Used for dealerless ZkSign key generation for Bedrock: each party contributes a
//! random r_j, nobody learns sk = Σ r_j, and the same key shares sign many transactions.
use std::{fs::File, io::BufReader, str::FromStr};

use ark_bn254::Fr;
use co_circom_types::{ShamirInputType, ShamirSharedInput};
use mpc_core::protocols::shamir::ShamirPrimeFieldShare;

fn load(path: &str) -> ShamirSharedInput<Fr> {
    serde_json::from_reader(BufReader::new(File::open(path).expect(path))).expect("decode share")
}

fn store(path: &str, v: &ShamirSharedInput<Fr>) {
    serde_json::to_writer(File::create(path).expect(path), v).expect("encode share")
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    match args.get(1).map(String::as_str) {
        Some("add") => {
            let mut acc = load(&args[3]);
            for p in &args[4..] {
                for (name, v) in load(p) {
                    let cur = acc.get_mut(&name).unwrap_or_else(|| panic!("{name} missing"));
                    match (cur, v) {
                        (ShamirInputType::Shared(a), ShamirInputType::Shared(b)) => {
                            *a = ShamirPrimeFieldShare { a: a.a + b.a }
                        }
                        (ShamirInputType::Public(a), ShamirInputType::Public(b)) => {
                            assert_eq!(*a, b, "public entry {name} differs")
                        }
                        _ => panic!("{name}: shared/public mismatch"),
                    }
                }
            }
            store(&args[2], &acc);
        }
        Some("set-public") => {
            let mut v = load(&args[2]);
            let entry = v.get_mut(&args[3]).expect("no such entry");
            assert!(entry.is_public(), "only public entries can be replaced");
            *entry = ShamirInputType::Public(Fr::from_str(&args[4]).expect("decimal field element"));
            store(&args[5], &v);
        }
        _ => eprintln!("usage: add <out> <in>... | set-public <in> <name> <value> <out>"),
    }
}
