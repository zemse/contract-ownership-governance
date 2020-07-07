// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

contract GovernanceOnchain {
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
        uint256 consensus;
        mapping(address => bool) confirmation; /// @dev Transaction confirmation given by individual governors
    }

    /// @dev Transactions proposed for being executed
    Transaction[] public transactions;

    /// @dev Sum of the privileges of all governors
    uint256 public totalPrivileges;

    /// @dev Governor addresses with corresponding privileges (vote weightage)
    mapping(address => uint256) public privileges;

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

    /// @dev Allows a governor to confirm a transaction.
    /// @param _transactionId Transaction ID.
    function confirmTransaction(uint256 _transactionId) public {
        require(privileges[msg.sender] > 0, "Gov: Only governors can call");
        require(_transactionId < transactions.length, "Gov: Tx doesnt exists");
        require(!transactions[_transactionId].executed, "Gov: Tx already executed");

        transactions[_transactionId].confirmation[msg.sender] = true;
    }

    /// @dev Allows a governor to revoke a confirmation for a transaction.
    /// @param _transactionId Transaction ID.
    function revokeConfirmation(uint256 _transactionId) public {
        require(privileges[msg.sender] > 0, "Gov: Only governors can call");
        require(_transactionId < transactions.length, "Gov: Tx doesnt exists");
        require(!transactions[_transactionId].executed, "Gov: Tx already executed");

        transactions[_transactionId].confirmation[msg.sender] = false;
    }

    function executeTransaction(uint256 _transactionId) public {
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
}
