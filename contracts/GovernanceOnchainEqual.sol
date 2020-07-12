// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./interfaces/IGovernanceOnchain.sol";
import "./interfaces/IGovernanceEqual.sol";

contract Governance is IGovernanceOnchain, IGovernanceEqual {
    /// @dev Transactions proposed for being executed
    Transaction[] transactions;

    uint256[2] consensus;

    address[] governors;

    /// @dev Transaction confirmation given by individual governors
    mapping(uint256 => mapping(address => bool)) confirmation;

    /// @notice Stores initial set of governors
    /// @param _governors List of initial governor addresses
    constructor(address[] memory _governors) public {
        governors = _governors;
        for (uint256 i = 0; i < _governors.length; i++) {
            emit GovernorAdded(_governors[i]);
        }
    }

    /// @dev Allows an governor to submit and confirm a transaction.
    /// @param _destination Transaction target address.
    /// @param _value Transaction ether value.
    /// @param _data Transaction data payload.
    /// @return Returns transaction ID.
    function createTransaction(
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
                votes: 0
            })
        );

        /// @dev only governor can confirm the transaction
        confirmTransaction(_transactionId);

        return _transactionId;
    }

    /// @dev Allows a governor to confirm a transaction.
    /// @param _transactionId Transaction ID.
    function confirmTransaction(uint256 _transactionId) public override {
        require(_transactionId < transactions.length, "Gov: Tx doesnt exists");
        require(!transactions[_transactionId].executed, "Gov: Tx already executed");
        require(confirmation[_transactionId][msg.sender], "Gov: Already confirmed");

        confirmation[_transactionId][msg.sender] = true;
        transactions[_transactionId].votes += 1;
    }

    /// @dev Allows a governor to revoke a confirmation for a transaction.
    /// @param _transactionId Transaction ID.
    function revokeConfirmation(uint256 _transactionId) public override {
        require(_transactionId < transactions.length, "Gov: Tx doesnt exists");
        require(!transactions[_transactionId].executed, "Gov: Tx already executed");
        require(!confirmation[_transactionId][msg.sender], "Gov: Not confirmed");

        confirmation[_transactionId][msg.sender] = false;
        transactions[_transactionId].votes -= 1;
    }

    function executeTransaction(uint256 _transactionId) public override {
        require(isTransactionConfirmed(_transactionId), "Gov: Consensus not acheived");

        (bool _success, ) = transactions[_transactionId].destination.call{
            value: transactions[_transactionId].value
        }(transactions[_transactionId].data);

        require(_success, "Call was reverted");
    }

    function isTransactionConfirmed(uint256 _transactionId) internal view returns (bool) {
        return transactions[_transactionId].votes >= required();
    }

    function getTransaction(uint256 _transactionId)
        public
        override
        view
        returns (Transaction memory)
    {
        return transactions[_transactionId];
    }

    function required() public override view returns (uint256) {
        if (consensus[1] == 0) {
            return consensus[0];
        } else {
            return (consensus[0] * governors.length) / consensus[1] + 1;
        }
    }

    function getConsensus() public override view returns (uint256, uint256) {
        return (consensus[0], consensus[1]);
    }

    function setConsensus(uint256 _numerator, uint256 _denominator) public override {
        consensus[0] = _numerator;
        consensus[1] = _denominator;
    }

    function getGovernors() public override view returns (address[] memory) {
        return governors;
    }

    function addGovernor(address _newGovernor) public override {
        require(!isGovernor(_newGovernor), "Already a governor");
        governors.push(_newGovernor);
    }

    function governorsCount() public override view returns (uint256) {
        return governors.length;
    }

    function isGovernor(address _governor) public override view returns (bool) {
        for (uint256 i = 0; i < governors.length; i++) {
            if (governors[i] == _governor) {
                return true;
            }
        }
        return false;
    }

    function removeGovernor(address _existingGovernor) public override {
        uint256 _index;
        bool _exists;
        for (uint256 i = 0; i < governors.length; i++) {
            if (governors[i] == _existingGovernor) {
                _index = i;
                _exists = true;
            }
        }

        require(_exists, "Governor does not exist");

        governors[_index] = governors[governors.length - 1];
        governors.pop();
    }

    function replaceGovernor(address _governor, address _newGovernor) public override {
        uint256 _index;
        bool _exists;
        for (uint256 i = 0; i < governors.length; i++) {
            if (governors[i] == _governor) {
                _index = i;
                _exists = true;
            }
        }

        require(_exists, "Governor does not exist");

        governors[_index] = _newGovernor;
    }
}
