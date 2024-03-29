// The Licensed Work is (c) 2023 ChainSafe
// Code: https://github.com/ChainSafe/Spectre
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {Spectre} from "../src/Spectre.sol";
import {Halo2Verifier as CommitteeUpdateVerifier} from "../snark-verifiers/testnet/committee_update_verifier.sol";
import {Halo2Verifier as SyncStepVerifier} from "../snark-verifiers/testnet/sync_step_verifier.sol";

contract DeploySpectre is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 initialSyncPeriod = vm.envUint("INITIAL_SYNC_PERIOD");
        uint256 initialCommitteePoseidon = vm.envUint(
            "INITIAL_COMMITTEE_POSEIDON"
        );
        uint256 slotsPerPeriod = vm.envUint("SLOTS_PER_PERIOD");
        uint16 finalityThreshold = uint16(vm.envUint("FINALITY_THRESHOLD"));

        vm.startBroadcast(deployerPrivateKey);

        SyncStepVerifier stepVerifier = new SyncStepVerifier();
        CommitteeUpdateVerifier updateVerifier = new CommitteeUpdateVerifier();

        new Spectre(
            address(stepVerifier),
            address(updateVerifier),
            initialSyncPeriod,
            initialCommitteePoseidon,
            slotsPerPeriod,
            finalityThreshold
        );

        vm.stopBroadcast();
    }
}
