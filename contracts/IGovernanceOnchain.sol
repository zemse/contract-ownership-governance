// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

/// @title ERC-2767 Contract Ownership Governance Standard
interface GovernanceOnchain {
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
        uint256 consensus;
    }

    function getTransaction(uint256 _transactionId) external view returns (Transaction memory);

    /// @notice Allows an governor to submit and confirm a transaction.
    /// @param _destination Transaction target address.
    /// @param _value Transaction ether value.
    /// @param _data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(
        address _destination,
        uint256 _value,
        bytes memory _data
    ) external returns (uint256);

    /// @notice Allows a governor to confirm a transaction.
    /// @param _transactionId Transaction ID.
    function confirmTransaction(uint256 _transactionId) external;

    /// @notice Allows a governor to revoke a confirmation for a transaction.
    /// @param _transactionId Transaction ID.
    function revokeConfirmation(uint256 _transactionId) external;

    /// @notice Calls the dApp to perform administrative task
    /// @param _transactionId Transaction ID
    function executeTransaction(uint256 _transactionId) external;
}
