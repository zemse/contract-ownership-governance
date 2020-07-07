// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./lib/ECDSA.sol";
import "./GovernanceOffchainInterface.sol";

/// @title Governance Offchain Smart Contract
/// @notice Governs a decentralised application to perform administrative tasks.
contract Governance is GovernanceOffchain {
    /// @dev EIP-191 Prepend byte + Version byte
    bytes public constant PREPEND_BYTES = hex"1966";

    /// @dev Keeps signed data scoped only for this governance contract
    bytes32 public constant DOMAIN_SEPERATOR = keccak256("TestlandGovernance");

    /// @dev Prevents replay of transactions. It is used as nonce.
    uint256 public override transactionsCount;

    /// @dev Sum of the privileges of all governors
    uint256 public override totalPrivileges;

    /// @dev Governor addresses with corresponding privileges (vote weightage)
    mapping(address => uint256) privileges;

    /// @dev This emits when governors privilege changes.
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

        bytes32 _digest = keccak256(abi.encodePacked(PREFIX(), _nonce, _destination, _data));

        verifySignatures(_digest, _signatures);

        transactionsCount++;

        (bool _success, ) = _destination.call{ value: msg.value }(_data);
        require(_success, "Call was reverted");
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

    /// @notice Gets the consensus privilege of the governor
    /// @param _governor Address of the governor
    /// @return The governor's voting privileges
    function getGovernorPrivileges(address _governor) public override view returns (uint256) {
        return privileges[_governor];
    }

    /// @notice Makes the signature by governor specific to this contract
    /// @return EIP-191 Message prefix for signing transaction with ECDSA
    function PREFIX() public override pure returns (bytes memory) {
        return abi.encodePacked(PREPEND_BYTES, DOMAIN_SEPERATOR);
    }

    /// @notice Checks for consensus
    /// @param _digest hash of sign data
    /// @param _signatures sorted sigs according to increasing signer addresses
    function verifySignatures(bytes32 _digest, bytes[] memory _signatures) internal view {
        uint160 _lastGovernor;
        uint256 _privilege;
        for (uint256 i = 0; i < _signatures.length; i++) {
            address _signer = ECDSA.recover(_digest, _signatures[i]);

            // Prevents duplicate signatures
            uint160 _thisGovernor = uint160(_signer);
            require(_thisGovernor > _lastGovernor, "Gov: Invalid arrangement");
            _lastGovernor = _thisGovernor;

            require(getGovernorPrivileges(_signer) > 0, "Gov: Not a governor");
            _privilege += getGovernorPrivileges(_signer);
        }

        // 66% consensus
        // TODO: Add safe math
        require(_privilege * 3 > totalPrivileges * 2, "Gov: Not 66% consensus");
    }
}
