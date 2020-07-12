// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

/// @title ERC-2767 Governance with Privileged Voting Rights
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

    /// @notice Updates governor statuses
    /// @param _governor Governor address
    /// @param _newPower New power for the governor
    function updatePower(address _governor, uint256 _newPower) external;

    /// @notice Gets static or dynamic number votes required for consensus
    /// @dev Required is dynamic if denominator is non zero (for e.g. 66% consensus)
    /// @return Required number of consensus votes
    function getRequiredVotes() external view returns (uint256);

    /// @notice Sets consensus requirement
    /// @param _numerator Required consensus numberator if denominator is
    ///         non zero. Exact votes required if denominator is zero
    /// @param _denominator Required consensus denominator. It is zero if
    ///         the numerator represents simple number instead of fraction
    /// @dev For 66% consensus _numerator = 2, _denominator = 3
    ///      For 5 fixed votes _numerator = 5, _denominator = 0
    function setRequiredVotes(uint256 _numerator, uint256 _denominator) external;
}
