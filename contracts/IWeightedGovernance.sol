// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

/// @title ERC-2767 Contract Ownership Governance Standard
interface WeightedGovernance {
    /// @dev This emits when governors privilege changes
    event GovernorsPrivilegeUpdated(address[] governors, uint256[] privileges);

    /// @notice Gets the consensus privilege of the governor
    /// @param _governor Address of the governor
    /// @return The governor's voting privileges
    function getGovernorPrivileges(address _governor) external view returns (uint256);

    /// @notice Gets the sum of the privileges of all governors
    /// @return Sum of the privileges of all governors
    function totalPrivileges() external view returns (uint256);

    /// @notice Updates governor statuses
    /// @param _governors List of governor addresses
    /// @param _newPrivileges List of corresponding new privileges
    function updatePrivileges(address[] memory _governors, uint256[] memory _newPrivileges)
        external;
}
