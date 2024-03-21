// The Licensed Work is (c) 2023 ChainSafe
// Code: https://github.com/ChainSafe/Spectre
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/Spectre.sol";

contract SpectreTest is Test {

    Spectre internal spectre;

    address constant stepVerifierAddress = address(0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5);
    address constant committeeUpdateVerifierAddress = address(0xE68badDE25D8389ae4b96962AC526D113f3BaC9D);
    uint256 constant initialSyncPerios = 8;
    uint256 constant initialSyncCommiteePoseidon = 10;
    uint256 constant slotsPerPeriod = 64;
    uint16 constant finalityThreshold = 20; // ~ 2/3 of 32

    function setUp() public {
        spectre = new Spectre(
            stepVerifierAddress,
            committeeUpdateVerifierAddress,
            initialSyncPerios,
            initialSyncCommiteePoseidon,
            slotsPerPeriod,
            finalityThreshold
        );
    }

    function test_SpectreContractSuccessfullyInitialized() public {
        assertEq(spectre.stepVerifierAddress(), stepVerifierAddress);
        assertEq(spectre.rotateVerifierAddress(), committeeUpdateVerifierAddress);
        assertEq(spectre.syncCommitteePoseidons(initialSyncPerios), initialSyncCommiteePoseidon);
        assertEq(spectre.FINALITY_THRESHOLD(), finalityThreshold);
    }
}
