// The Licensed Work is (c) 2023 ChainSafe
// Code: https://github.com/ChainSafe/Spectre
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity ^0.8.0;

import {StepLib} from "./StepLib.sol";

struct RotateData {
    uint256 newSyncCommitteePoseidon;
    bytes32 finalizedHeaderRoot;
}

contract Spectre {
    using StepLib for StepLib.StepInput;

    uint256 internal immutable SLOTS_PER_PERIOD;

    uint256 internal constant MIN_SYNC_COMMITTEE_PARTICIPANTS = 10;

    /// Maps from a sync period to the poseidon commitment for the sync committee.
    mapping(uint256 => uint256) public syncCommitteePoseidons;

    /// Maps from a slot to a beacon block header root.
    mapping(uint256 => bytes32) public blockHeaderRoots;

    /// Maps from a slot to the current finalized ethereum1 execution state root.
    mapping(uint256 => bytes32) public executionPayloadRoots;

    /// The highest slot that has been verified
    uint256 public head = 0;

    address public stepVerifierAddress;
    address public rotateVerifierAddress;

    constructor(
        address _stepVerifierAddress,
        address _committeeUpdateVerifierAddress,
        uint256 _initialSyncPeriod,
        uint256 _initialSyncCommitteePoseidon,
        uint256 _slotsPerPeriod
    ) {
        stepVerifierAddress = _stepVerifierAddress;
        rotateVerifierAddress = _committeeUpdateVerifierAddress;
        syncCommitteePoseidons[
            _initialSyncPeriod
        ] = _initialSyncCommitteePoseidon;
        SLOTS_PER_PERIOD = _slotsPerPeriod;
    }

    /// @notice Verify that a sync committee has attested to a block that finalizes the given header root and execution payload
    /// @param input The input to the sync step. Defines the slot and attestation to verify
    /// @param proof The proof for the sync step
    function step(
        StepLib.StepInput calldata input,
        bytes calldata proof
    ) external {
        uint256 currentPeriod = _getSyncCommitteePeriod(input.attestedSlot);

        require(
            syncCommitteePoseidons[currentPeriod] != 0,
            "Sync committee not yet set for this period"
        );

        require(
            input.participation > MIN_SYNC_COMMITTEE_PARTICIPANTS,
            "Less than MIN_SYNC_COMMITTEE_PARTICIPANTS signed"
        );

        _verifyStepProof(input, proof, syncCommitteePoseidons[currentPeriod]);

        // update the contract state
        executionPayloadRoots[input.finalizedSlot] = input.executionPayloadRoot;
        blockHeaderRoots[input.finalizedSlot] = input.finalizedHeaderRoot;
        head = input.finalizedSlot;
    }

    /// @notice Use the current sync committee to verify the transition to a new sync committee
    /// @param rotateProof The proof for the rotation
    /// @param stepInput The input to the sync step.
    /// @param stepProof The proof for the sync step
    function rotate(
        bytes calldata rotateProof,
        StepLib.StepInput calldata stepInput,
        bytes calldata stepProof
    ) external {
        // *step phase*
        // This allows trusting that the current sync committee has signed off on the finalizedHeaderRoot which is used as the base of the SSZ proof
        // that checks the new committee is in the beacon state 'next_sync_committee' field. It also allows trusting the finalizedSlot which is
        // used to calculate the sync period that the new committee belongs to.
        uint256 attestingPeriod = _getSyncCommitteePeriod(
            stepInput.attestedSlot
        );

        require(
            syncCommitteePoseidons[attestingPeriod] != 0,
            "Sync committee not yet set for this period"
        );

        _verifyStepProof(
            stepInput,
            stepProof,
            syncCommitteePoseidons[attestingPeriod]
        );

        // *rotation phase*
        // This proof checks that the given poseidon commitment and SSZ commitment to the sync committee are equivalent and that
        // that there exists an SSZ proof that can verify this SSZ commitment to the committee is in the state
        uint256 currentPeriod = _getSyncCommitteePeriod(
            stepInput.finalizedSlot
        );
        uint256 nextPeriod = currentPeriod + 1;

        RotateData memory rotateData = _verifyRotateProof(rotateProof);

        require(
            rotateData.finalizedHeaderRoot == stepInput.finalizedHeaderRoot,
            "Invalid finalized header root"
        );

        // update the contract state
        syncCommitteePoseidons[nextPeriod] = rotateData
            .newSyncCommitteePoseidon;
    }

    function _getSyncCommitteePeriod(
        uint256 slot
    ) internal view returns (uint256) {
        return slot / SLOTS_PER_PERIOD;
    }

    function _verifyStepProof(
        StepLib.StepInput calldata input,
        bytes calldata proof,
        uint256 syncCommitteePoseidon
    ) internal {
        uint256 publicInputsCommitment = input.toPublicInputsCommitment();

        //  The public instances are laid out in the proof calldata as follows:
        //    ** First 4 * 3 * 32 = 384 bytes are reserved for proof verification data used with the pairing precompile
        //    ** The next blocks of 2 groups of 32 bytes each are:
        //    ** `publicInputsCommitment`       as a field element
        //    ** `syncCommitteePoseidon`        as a field element
        uint256 _publicInputsCommitment = uint256(bytes32(proof[384:384 + 32]));
        uint256 _syncCommitteePoseidon = uint256(
            bytes32(proof[384 + 32:384 + 2 * 32])
        );

        require(
            _publicInputsCommitment == publicInputsCommitment,
            "Invalid public inputs commitment"
        );

        require(
            _syncCommitteePoseidon == syncCommitteePoseidon,
            "Invalid sync committee poseidon"
        );

        (bool success, ) = stepVerifierAddress.call(proof);
        if (!success) {
            revert("Step proof verification failed");
        }
    }

    function _verifyRotateProof(
        bytes calldata proof
    ) internal returns (RotateData memory rotateData) {
        //  The public instances are laid out in the proof calldata as follows:
        //    ** First 4 * 3 * 32 = 384 bytes are reserved for proof verification data used with the pairing precompile
        //    ** The next blocks of 3 groups of 32 bytes each are:
        //    ** `newSyncCommitteePoseidon`     as a field element
        //    ** `finalizedHeaderRoot`          as 2 field elements, in hi-lo form

        rotateData.newSyncCommitteePoseidon = uint256(
            bytes32(proof[384:384 + 32])
        );
        rotateData.finalizedHeaderRoot = bytes32(
            (uint256(bytes32(proof[384 + 32:384 + 2 * 32]))) |
                uint256(bytes32(proof[384 + 2 * 32:384 + 3 * 32]) << 128) // parse into lo-hi form
        );

        (bool success, ) = rotateVerifierAddress.call(proof);
        if (!success) {
            revert("Rotate proof verification failed");
        }
    }
}
