// The Licensed Work is (c) 2023 ChainSafe
// Code: https://github.com/ChainSafe/Spectre
// SPDX-License-Identifier: LGPL-3.0-only

#![allow(incomplete_features)]
#![feature(generic_const_exprs)]
use ethers::contract::abigen;
use lightclient_circuits::witness::SyncStepArgs;
use tree_hash::TreeHash;

abigen!(
    Spectre,
    "./out/Spectre.sol/Spectre.json";
    StepVerifier,
    "./out/sync_step_verifier.sol/Halo2Verifier.json";
    CommitteeUpdateVerifier,
    "./out/committee_update_verifier.sol/Halo2Verifier.json";
    MockVerifier,
    "./out/MockVerifier.sol/MockVerifier.json";
);

// SyncStepInput type produced by abigen macro matches the solidity struct type
impl<Spec: eth_types::Spec> From<SyncStepArgs<Spec>> for StepInput {
    fn from(args: SyncStepArgs<Spec>) -> Self {
        let participation = args
            .pariticipation_bits
            .iter()
            .map(|v| *v as u64)
            .sum::<u64>();

        let finalized_header_root: [u8; 32] = args.finalized_header.tree_hash_root().0;

        let execution_payload_root: [u8; 32] = args.execution_payload_root.try_into().unwrap();

        StepInput {
            attested_slot: args.attested_header.slot.into(),
            finalized_slot: args.finalized_header.slot.into(),
            participation,
            finalized_header_root,
            execution_payload_root,
        }
    }
}
