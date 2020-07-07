// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

/// @title ERC-2767 Contract Ownership Governance Standard
interface GovernanceOffchain {
    /// @dev This emits when governors privilege changes
    event GovernorsPrivilegeUpdated(address[] governors, uint256[] privileges);

    /// @notice Gets the consensus privilege of the governor
    /// @param _governor Address of the governor
    /// @return The governor's voting privileges
    function getGovernorPrivileges(address _governor) external view returns (uint256);

    /// @notice Gets the sum of the privileges of all governors
    /// @return Sum of the privileges of all governors
    function totalPrivileges() external view returns (uint256);

    /// @notice Get the transactions count
    /// @dev To be used as nonce
    /// @return The transactions count
    function transactionsCount() external view returns (uint256);

    /// @notice Makes the signature by governor specific to this contract
    /// @return EIP-191 Message prefix for signing transaction with ECDSA
    function PREFIX() external pure returns (bytes memory);

    /// @notice Calls the dApp to perform administrative task
    /// @param _nonce Serial number of transaction
    /// @param _destination Address of contract to make a call to, should be dApp address
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
