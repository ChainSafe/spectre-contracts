// The Licensed Work is (c) 2023 ChainSafe
// Code: https://github.com/ChainSafe/Spectre
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.19;

import {StepLib} from "../src/StepLib.sol";

/**
 * @title SyncStepExternal
 * @dev This contract exists solely for the purpose of exposing the SyncStepLib functions
 *      so they can be used in the Rust test suite. It should not be part of a production deployment
 */
contract StepExternal {
    using StepLib for StepLib.StepInput;

    function toPublicInputsCommitment(
        StepLib.StepInput calldata args
    ) public pure returns (uint256) {
        return args.toPublicInputsCommitment();
    }
}
