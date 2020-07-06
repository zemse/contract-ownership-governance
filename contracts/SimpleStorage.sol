// SPDX-License-Identifier: MIT

// Credit: This contract is copied and pasted from https://docs.ethers.io/ethers.js/html/api-contract.html. Some necessary modifications for 0.5.11 have been done.

// Place your solidity files in this contracts folder and run the compile.js file using node compile.js file in project directory to compile your contracts.

pragma solidity ^0.6.10;

contract SimpleStorage {
    string text;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "SS: Only owner allowed");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    function getText() public view returns (string memory) {
        return text;
    }

    function setText(string memory _value) public onlyOwner {
        text = _value;
    }
}
