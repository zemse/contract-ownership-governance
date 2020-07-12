// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./lib/ECDSA.sol";
import "./interfaces/IGovernanceOffchain.sol";
import "./interfaces/IGovernancePrivileged.sol";

/// @title Governance Offchain Smart Contract
/// @notice Governs a decentralised application to perform administrative tasks.
contract Governance is IGovernanceOffchain, IGovernancePrivileged {
    /// @dev EIP-191 Prepend byte + Version byte
    bytes public PREFIX = abi.encodePacked((hex"1900"), address(this));

    /// @dev Prevents replay of transactions. It is used as nonce.
    uint256 public override transactionsCount;

    /// @dev Sum of the powers of all governors
    uint256 public override totalPower;

    /// @dev consensus numerator and denominator stored together
    ///      For 66% consensus, numerator = 2, denominator = 3
    ///      For 5 fixed votes, numerator = 5, denominator = 0
    uint256[2] consensus;

    /// @dev Governor addresses with corresponding powers (vote weightage)
    mapping(address => uint256) powers;

    /// @dev This contract calls self methods if consensus is acheived
    modifier onlyGovernance() {
        require(msg.sender == address(this), "Only Governance");
        _;
    }

    /// @notice Stores initial set of governors
    /// @param _governors List of initial governor addresses
    /// @param _powers List of corresponding initial powers
    constructor(address[] memory _governors, uint256[] memory _powers) public {
        require(_governors.length == _powers.length, "Gov: Invalid input lengths");

        uint256 _totalPower;
        for (uint256 i = 0; i < _governors.length; i++) {
            powers[_governors[i]] = _powers[i];
            _totalPower += _powers[i];
            emit GovernorPowerUpdated(_governors[i], _powers[i]);
        }
        totalPower = _totalPower;
    }

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
    ) external override payable {
        require(_nonce >= transactionsCount, "Gov: Nonce is already used");
        require(_nonce == transactionsCount, "Gov: Nonce is too high");

        bytes32 _digest = keccak256(abi.encodePacked(PREFIX, _nonce, _destination, _data));

        verifySignatures(_digest, _signatures);

        transactionsCount++;

        (bool _success, ) = _destination.call{ value: msg.value }(_data);
        require(_success, "Call was reverted");
    }

    /// @notice Updates governor statuses
    /// @param _governor List of governor addresses
    /// @param _newPrivilege List of corresponding new powers
    function updatePower(address _governor, uint256 _newPrivilege)
        external
        override
        onlyGovernance
    {
        require(msg.sender == address(this), "Gov: Only self can call");

        uint256 _totalPower = totalPower;

        if (_newPrivilege != powers[_governor]) {
            // TODO: Add safe math
            _totalPower = _totalPower - powers[_governor] + _newPrivilege;

            powers[_governor] = _newPrivilege;
        }

        totalPower = _totalPower;

        emit GovernorPowerUpdated(_governor, _newPrivilege);
    }

    /// @notice Gets the consensus privilege of the governor
    /// @param _governor Address of the governor
    /// @return The governor's voting powers
    function powerOf(address _governor) public override view returns (uint256) {
        return powers[_governor];
    }

    /// @notice Checks for consensus
    /// @param _digest hash of sign data
    /// @param _signatures sorted sigs according to increasing signer addresses
    function verifySignatures(bytes32 _digest, bytes[] memory _signatures) internal view {
        uint160 _lastGovernor;
        uint256 _consensus;
        for (uint256 i = 0; i < _signatures.length; i++) {
            address _signer = ECDSA.recover(_digest, _signatures[i]);

            // Prevents duplicate signatures
            uint160 _thisGovernor = uint160(_signer);
            require(_thisGovernor > _lastGovernor, "Gov: Invalid arrangement");
            _lastGovernor = _thisGovernor;

            require(powerOf(_signer) > 0, "Gov: Not a governor");
            _consensus += powerOf(_signer);
        }

        // 66% consensus
        // TODO: Add safe math
        require(_consensus * 3 > totalPower * 2, "Gov: Not 66% consensus");
    }

    /// @notice Gets static or dynamic number votes required for consensus
    /// @dev Required is dynamic if denominator is non zero (for e.g. 66% consensus)
    /// @return Required number of consensus votes
    function required() public override view returns (uint256) {
        if (consensus[1] == 0) {
            return consensus[0];
        } else {
            return (consensus[0] * totalPower) / consensus[1] + 1;
        }
    }

    /// @notice Gets required fraction of votes from all governors for consensus
    /// @return numerator: Required consensus numberator if denominator is
    ///         non zero. Exact votes required if denominator is zero
    /// @return denominator: Required consensus denominator. It is zero if
    ///         the numerator represents simple number instead of fraction
    function getConsensus() public override view returns (uint256, uint256) {
        return (consensus[0], consensus[1]);
    }

    /// @notice Sets consensus requirement
    /// @param _numerator Required consensus numberator if denominator is
    ///         non zero. Exact votes required if denominator is zero
    /// @param _denominator Required consensus denominator. It is zero if
    ///         the numerator represents simple number instead of fraction
    /// @dev For 66% consensus _numerator = 2, _denominator = 3
    ///      For 5 fixed votes _numerator = 5, _denominator = 0
    function setConsensus(uint256 _numerator, uint256 _denominator) public override onlyGovernance {
        consensus[0] = _numerator;
        consensus[1] = _denominator;
    }
}
