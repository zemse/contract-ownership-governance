// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "../lib/ECDSA.sol";

contract Governance {
    /// @dev EIP-191 Prepend byte + Version byte
    bytes public constant PREFIX = hex"1966";
    bytes32 public constant DOMAIN_SEPERATOR = keccak256("TestlandGovernance");

    uint256 public transactionsCount;

    uint256 public validatorCount;
    mapping(address => bool) validators;

    constructor(address[] memory _validators) public {
        for (uint256 i = 0; i < _validators.length; i++) {
            validators[_validators[i]] = true;
        }

        validatorCount = _validators.length;
    }

    function makeGovernedCall(
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

    function verifySignatures(bytes32 _digest, bytes[] memory _signatures) internal view {
        uint160 _lastValidator;
        for (uint256 i = 0; i < _signatures.length; i++) {
            address _signer = ECDSA.recover(_digest, _signatures[i]);
            uint160 _thisValidator = uint160(_signer);
            require(_thisValidator > _lastValidator, "Gov: Invalid arrangement");
            _lastValidator = _thisValidator;
            require(isValidator(_signer), "Gov: Not a validator");
        }

        require(_signatures.length * 3 > validatorCount * 2, "Gov: Not 66% validators");
    }
}
