// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./lib/ECDSA.sol";

/// @title Governance Offchain Smart Contract
/// @notice Works as the owner of a decentralised application to perform administrative tasks.
contract GovernanceOffChain {
    /// @dev EIP-191 Prepend byte + Version byte
    bytes public constant PREFIX = hex"1966";
    /// @dev Keeps signed data scoped only for this governance contract
    bytes32 public constant DOMAIN_SEPERATOR = keccak256("TestlandGovernance");

    /// @dev Prevents replay of transactions. It is used as nonce.
    uint256 public transactionsCount;

    /// @dev These are addresses to whom the administration is decentralized
    uint256 public ownersCount;
    mapping(address => bool) owners;

    /// @param _owners used to set the initial owners
    constructor(address[] memory _owners) public {
        for (uint256 i = 0; i < _owners.length; i++) {
            owners[_owners[i]] = true;
        }

        ownersCount = _owners.length;
    }

    /// @notice Calls the dApp to perform administrative task
    /// @param _nonce serial number of transaction
    /// @param _destination address of contract to make a call to, should be dApp address
    /// @param _data input data in the transaction
    /// @param _signatures sorted sigs according to increasing signer addresses (required to be collect off chain)
    function executeTransaction(
        uint256 _nonce,
        address _destination,
        bytes memory _data,
        bytes[] memory _signatures
    ) external payable {
        require(_nonce >= transactionsCount, "Gov: Nonce is already used");
        require(_nonce == transactionsCount, "Gov: Nonce is too high");

        bytes32 _digest = keccak256(
            abi.encodePacked(PREFIX, DOMAIN_SEPERATOR, _nonce, _destination, _data)
        );

        verifySignatures(_digest, _signatures);

        transactionsCount++;

        (bool _success, ) = _destination.call{ value: msg.value }(_data);
        require(_success, "Call was reverted");
    }

    /// @notice Updates owner statuses
    /// @param _owners List of addresses to update owner status
    /// @param _newStatus List of corresponding new status of addresses
    function updateValidators(address[] memory _owners, bool[] memory _newStatus) external {
        require(msg.sender == address(this), "Gov: Only self can call");
        require(_owners.length == _newStatus.length, "Gov: Invalid input lengths");

        uint256 _ownersCount = ownersCount;

        for (uint256 i = 0; i < _owners.length; i++) {
            if (_newStatus[i] != owners[_owners[i]]) {
                if (_newStatus[i]) {
                    _ownersCount++;
                } else {
                    _ownersCount--;
                }

                owners[_owners[i]] = _newStatus[i];
            }
        }

        ownersCount = _ownersCount;
    }

    function isValidator(address _owner) public view returns (bool) {
        return owners[_owner];
    }

    /// @notice Checks for consensus
    /// @param _digest hash of sign data
    /// @param _signatures sorted sigs according to increasing signer addresses
    function verifySignatures(bytes32 _digest, bytes[] memory _signatures) internal view {
        uint160 _lastValidator;
        for (uint256 i = 0; i < _signatures.length; i++) {
            address _signer = ECDSA.recover(_digest, _signatures[i]);

            // Prevents duplicate signatures
            uint160 _thisValidator = uint160(_signer);
            require(_thisValidator > _lastValidator, "Gov: Invalid arrangement");
            _lastValidator = _thisValidator;

            require(isValidator(_signer), "Gov: Not a owner");
        }

        // 66% consensus
        require(_signatures.length * 3 > ownersCount * 2, "Gov: Not 66% owners");
    }
}
