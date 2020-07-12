// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

/// @title ERC-2767 Governance with Equal Voting Rights
/// @dev ERC-165 InterfaceID: 0xbfca4246
interface IGovernanceEqual {
    /// @dev This emits when a governor is added
    event GovernorAdded(address indexed governor);

    /// @dev This emits when a governor is removed
    event GovernorRemoved(address indexed governor);

    /// @notice Gets list of governors
    /// @return List of governors
    function getGovernors() external view returns (address[] memory);

    /// @notice Gets whether an address is governor or not
    /// @param _governor Address of governor
    /// @return governor status
    function isGovernor(address _governor) external view returns (bool);

    /// @notice Gets the count of all governors
    /// @return Count of all governors
    function governorsCount() external view returns (uint256);

    /// @notice Adds governor
    /// @param _newGovernor New governor addresses
    function addGovernor(address _newGovernor) external;

    /// @notice Removes governor
    /// @param _existingGovernor Existing governor addresses
    function removeGovernor(address _existingGovernor) external;

    /// @notice Removes governor
    /// @param _governor Existing governor address
    /// @param _newGovernor New governor address
    function replaceGovernor(address _governor, address _newGovernor) external;

    /// @notice Gets static or dynamic number votes required for consensus
    /// @dev Required is dynamic if denominator is non zero (for e.g. 66% consensus)
    /// @return Required number of consensus votes
    function required() external view returns (uint256);

    /// @notice Gets required fraction of votes from all governors for consensus
    /// @return numerator: Required consensus numberator if denominator is
    ///         non zero. Exact votes required if denominator is zero
    /// @return denominator: Required consensus denominator. It is zero if
    ///         the numerator represents simple number instead of fraction
    function getConsensus() external view returns (uint256, uint256);

    /// @notice Sets consensus requirement
    /// @param _numerator Required consensus numberator if denominator is
    ///         non zero. Exact votes required if denominator is zero
    /// @param _denominator Required consensus denominator. It is zero if
    ///         the numerator represents simple number instead of fraction
    /// @dev For 66% consensus _numerator = 2, _denominator = 3
    ///      For 5 fixed votes _numerator = 5, _denominator = 0
    function setConsensus(uint256 _numerator, uint256 _denominator) external;
}
