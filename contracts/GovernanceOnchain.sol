// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./IGovernanceOnchain.sol";

contract Governance is GovernanceOnchain {
    /// @dev Transactions proposed for being executed
    Transaction[] transactions;

    /// @dev Sum of the privileges of all governors
    uint256 public override totalPrivileges;

    /// @dev Transaction confirmation given by individual governors
    mapping(uint256 => mapping(address => bool)) confirmation;

    /// @dev Governor addresses with corresponding privileges (vote weightage)
    mapping(address => uint256) privileges;

    /// @dev This emits when governors privilege changes
    event GovernorsPrivilegeUpdated(address[] governors, uint256[] privileges);

    /// @notice Stores initial set of governors
    /// @param _governors List of initial governor addresses
    /// @param _privileges List of corresponding initial privileges
    constructor(address[] memory _governors, uint256[] memory _privileges) public {
        require(_governors.length == _privileges.length, "Gov: Invalid input lengths");

        uint256 _totalPrivileges;
        for (uint256 i = 0; i < _governors.length; i++) {
            privileges[_governors[i]] = _privileges[i];
            _totalPrivileges += _privileges[i];
        }
        totalPrivileges = _totalPrivileges;

        emit GovernorsPrivilegeUpdated(_governors, _privileges);
    }

    /// @dev Allows an governor to submit and confirm a transaction.
    /// @param _destination Transaction target address.
    /// @param _value Transaction ether value.
    /// @param _data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(
        address _destination,
        uint256 _value,
        bytes memory _data
    ) public override returns (uint256) {
        uint256 _transactionId = transactions.length;
        transactions.push(
            Transaction({
                destination: _destination,
                value: _value,
                data: _data,
                executed: false,
                consensus: 0
            })
        );

        /// @dev only governor can confirm the transaction
        confirmTransaction(_transactionId);

        return _transactionId;
    }

    /// @dev Allows a governor to confirm a transaction.
    /// @param _transactionId Transaction ID.
    function confirmTransaction(uint256 _transactionId) public override {
        require(privileges[msg.sender] > 0, "Gov: Only governors can call");
        require(_transactionId < transactions.length, "Gov: Tx doesnt exists");
        require(!transactions[_transactionId].executed, "Gov: Tx already executed");
        require(confirmation[_transactionId][msg.sender], "Gov: Already confirmed");

        confirmation[_transactionId][msg.sender] = true;
        transactions[_transactionId].consensus += getGovernorPrivileges(msg.sender);
    }

    /// @dev Allows a governor to revoke a confirmation for a transaction.
    /// @param _transactionId Transaction ID.
    function revokeConfirmation(uint256 _transactionId) public override {
        require(privileges[msg.sender] > 0, "Gov: Only governors can call");
        require(_transactionId < transactions.length, "Gov: Tx doesnt exists");
        require(!transactions[_transactionId].executed, "Gov: Tx already executed");
        require(!confirmation[_transactionId][msg.sender], "Gov: Not confirmed");

        confirmation[_transactionId][msg.sender] = false;
        transactions[_transactionId].consensus -= getGovernorPrivileges(msg.sender);
    }

    function executeTransaction(uint256 _transactionId) public override {
        require(isTransactionConfirmed(_transactionId), "Gov: Consensus not acheived");

        (bool _success, ) = transactions[_transactionId].destination.call{
            value: transactions[_transactionId].value
        }(transactions[_transactionId].data);

        require(_success, "Call was reverted");
    }

    function isTransactionConfirmed(uint256 _transactionId) internal view returns (bool) {
        return transactions[_transactionId].consensus * 3 > totalPrivileges * 2;
    }

    /// @notice Updates governor statuses
    /// @param _governors List of governor addresses
    /// @param _newPrivileges List of corresponding new privileges
    function updatePrivileges(address[] memory _governors, uint256[] memory _newPrivileges)
        external
        override
    {
        require(msg.sender == address(this), "Gov: Only self can call");
        require(_governors.length == _newPrivileges.length, "Gov: Invalid input lengths");

        uint256 _totalPrivileges = totalPrivileges;

        for (uint256 i = 0; i < _governors.length; i++) {
            if (_newPrivileges[i] != privileges[_governors[i]]) {
                // TODO: Add safe math
                _totalPrivileges = _totalPrivileges - privileges[_governors[i]] + _newPrivileges[i];

                privileges[_governors[i]] = _newPrivileges[i];
            }
        }

        totalPrivileges = _totalPrivileges;

        emit GovernorsPrivilegeUpdated(_governors, _newPrivileges);
    }

    /// @notice Gets the consensus privilege of the governor
    /// @param _governor Address of the governor
    /// @return The governor's voting privileges
    function getGovernorPrivileges(address _governor) public override view returns (uint256) {
        return privileges[_governor];
    }

    function getTransaction(uint256 _transactionId)
        public
        override
        view
        returns (Transaction memory)
    {
        return transactions[_transactionId];
    }
}
