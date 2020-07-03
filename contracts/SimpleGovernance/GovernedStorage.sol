// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

contract SimpleStorage2 {
  string text;
  address public governance;

  modifier onlyGovernance() {
    require(msg.sender == governance, 'Only governance allowed');
    _;
  }

  constructor(address _governance) public {
    governance = _governance;
  }

  function getText() public view returns (string memory) {
    return text;
  }

  function setText(string memory _value) public onlyGovernance {
    text = _value;
  }
}
