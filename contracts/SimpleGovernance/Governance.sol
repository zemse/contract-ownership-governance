// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

contract Governance {
    uint256 public validatorCount;
    mapping(address => bool) validators;

    constructor(address[] memory _validators) public {
        for (uint256 i = 0; i < _validators.length; i++) {
            validators[_validators[i]] = true;
        }

        validatorCount = _validators.length;
    }

    function makeGovernedCall(address _to, bytes memory _data) external payable {
        (bool _success, ) = _to.call{ value: msg.value }(_data);
        require(_success, "Call was reverted");
    }

    function isValidator(address _validator) public view returns (bool) {
        return validators[_validator];
    }
}