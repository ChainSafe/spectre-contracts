
// The Licensed Work is (c) 2023 ChainSafe
// Code: https://github.com/ChainSafe/Spectre
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity ^0.8.0;


contract MockVerifier {
    fallback(bytes calldata) external returns (bytes memory) {
        assembly ("memory-safe") {
            return (0, 0)
        }
    }
}
