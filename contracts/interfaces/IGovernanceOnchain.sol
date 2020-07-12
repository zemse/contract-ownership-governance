// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

/// @title ERC-2767 On-chain Governance
interface IGovernanceOnchain {
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
        uint256 votes;
    }

    /// @dev Emits when a transaction is proposed
    event Created(uint256 indexed transactionId);

    /// @dev Emits every time a governor confirms a transaction
    event Confirmed(uint256 indexed transactionId);

    /// @dev Emits whenever a governor takes back their confirmation
    event Revoked(uint256 indexed transactionId);

    /// @dev Emits when a transactions with enough confirmations is executed
    event Executed(uint256 indexed transactionId);

    /// @notice Gets transaction parameters
    /// @param _transactionId TransactionID
    /// @return ABIV2 encoded Transaction struct
    function getTransaction(uint256 _transactionId) external view returns (Transaction memory);

    /// @notice Allows an governor to submit and confirm a transaction.
    /// @param _destination Transaction target address, the governed contract
    /// @param _value Transaction ether value
    /// @param _data Transaction data payload
    /// @return Returns transaction ID
    function createTransaction(
        address _destination,
        uint256 _value,
        bytes memory _data
    ) external returns (uint256);

    /// @notice Allows a governor to confirm a transaction.
    /// @param _transactionId Transaction ID
    function confirmTransaction(uint256 _transactionId) external;

    /// @notice Allows a governor to revoke a confirmation for a transaction
    /// @param _transactionId Transaction ID
    function revokeConfirmation(uint256 _transactionId) external;

    /// @notice Calls the governed contract to perform administrative task
    /// @param _transactionId Transaction ID
    function executeTransaction(uint256 _transactionId) external;
}
