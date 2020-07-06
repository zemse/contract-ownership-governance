// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./lib/ECDSA.sol";

/// @title Governance Smart Contract
/// @notice Works as the owner of a decentralised application to perform administrative tasks.
contract Governance {
    /// @dev EIP-191 Prepend byte + Version byte
    bytes public constant PREFIX = hex"1966";
    /// @dev Keeps signed data scoped only for this governance contract
    bytes32 public constant DOMAIN_SEPERATOR = keccak256("TestlandGovernance");

    /// @dev Prevents replay of transactions. It is used as nonce.
    uint256 public transactionsCount;

    /// @dev These are addresses to whom the administration is decentralized
    uint256 public validatorCount;
    mapping(address => bool) validators;

    /// @param _validators used to set the initial validators
    constructor(address[] memory _validators) public {
        for (uint256 i = 0; i < _validators.length; i++) {
            validators[_validators[i]] = true;
        }

        validatorCount = _validators.length;
    }

    /// @notice Calls the dApp to perform administrative task
    /// @param _nonce serial number of transaction
    /// @param _to address of contract to make a call to, should be dApp address
    /// @param _data input data in the transaction
    /// @param _signatures sorted sigs according to increasing signer addresses
    function executeTransaction(
        uint256 _nonce,
        address _to,
        bytes memory _data,
        bytes[] memory _signatures
    ) external payable {
        require(_nonce >= transactionsCount, "Gov: Nonce is already used");
        require(_nonce == transactionsCount, "Gov: Nonce is too high");

        bytes32 _digest = keccak256(abi.encodePacked(PREFIX, DOMAIN_SEPERATOR, _nonce, _to, _data));

        verifySignatures(_digest, _signatures);

        transactionsCount++;

        (bool _success, ) = _to.call{ value: msg.value }(_data);
        require(_success, "Call was reverted");
    }

    function isValidator(address _validator) public view returns (bool) {
        return validators[_validator];
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

            require(isValidator(_signer), "Gov: Not a validator");
        }

        // 66% consensus
        require(_signatures.length * 3 > validatorCount * 2, "Gov: Not 66% validators");
    }
}
