// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

interface GovernanceOffchain {
    function PREFIX() external pure returns (bytes memory);

    function transactionsCount() external view returns (uint256);

    function getGovernorsConsent(address _governor) external view returns (uint256);

    function maxConsent() external view returns (uint256);

    function executeTransaction(
        uint256 _nonce,
        address _destination,
        bytes memory _data,
        bytes[] memory _signatures
    ) external payable;
}
