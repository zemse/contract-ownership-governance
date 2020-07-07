// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

/// @title ERC-2767 Contract Ownership Governance Standard
interface SimpleGovernance {
    /// @dev This emits when governor is added
    event GovernorAdded(address governor);

    /// @dev This emits when governor is removed
    event GovernorRemoved(address governor);

    /// @notice Gets the consensus privilege of the governor
    /// @return List of governors
    function governors() external view returns (address[] memory);

    /// @notice Gets the count of all governors
    /// @return Count of all governors
    function governorsCount() external view returns (uint256);

    /// @notice Adds governor
    /// @param _newGovernors List of governor addresses
    function addGovernors(address[] memory _newGovernors) external;

    /// @notice Removes governor
    /// @param _existingGovernors List of governor addresses
    function removeGovernors(address[] memory _existingGovernors) external;

    /// @notice Removes governor
    /// @param _governor E addresses
    /// @param _newGovernor
    function replaceGovernor(address _governor, address _newGovernor) external;
}
