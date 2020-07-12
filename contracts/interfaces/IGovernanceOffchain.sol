// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

/// @title ERC-2767 Off-chain Governance
interface IGovernanceOffchain {
    /// @notice Get the transactions count
    /// @dev To be used as nonce
    /// @return The transactions count
    function transactionsCount() external view returns (uint256);

    /// @notice Calls the governed contract to perform an administrative task
    /// @param _nonce Serial number of transaction
    /// @param _destination Address of contract to make a call to, should be governed contract address
    /// @param _data Input data in the transaction
    /// @param _signatures Signatures of governors collected off chain
    /// @dev The signatures are required to be sorted to prevent duplicates
    function executeTransaction(
        uint256 _nonce,
        address _destination,
        bytes memory _data,
        bytes[] memory _signatures
    ) external payable;
}
