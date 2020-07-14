// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
/// @title ERC-2767 Governance with Privileged Voting Rights
/// @dev ERC-165 InterfaceID: 0x69c56387
interface IGovernancePrivileged {
    /// @dev This emits when governor power changes
    event GovernorPowerUpdated(address indexed governor, uint256 power);

    /// @notice Gets the consensus power of the governor
    /// @param _governor Address of the governor
    /// @return The governor's voting power
    function powerOf(address _governor) external view returns (uint256);

    /// @notice Gets the sum of the power of all governors
    /// @return Sum of the power of all governors
    function totalPower() external view returns (uint256);

    /// @notice Gets number votes required for acheiving consensus
    /// @return Required number of consensus votes
    function required() external view returns (uint256);

    /// @notice Updates governor statuses
    /// @param _governor Governor address
    /// @param _newPower New power for the governor
    function updateGovernor(address _governor, uint256 _newPower) external;

    /// @notice Replaces governor
    /// @param _governor Existing governor address
    /// @param _newGovernor New governor address
    function replaceGovernor(address _governor, address _newGovernor) external;
}