# Smart Contract Governance

This is a standard interface for decentralized ownership of contracts.

## Abstract

By standardizing the owner wallet of a smart contract based dApp as a Governance smart contract address instead of a private key wallet, we can enforce enough consensus for performing administrative tasks on decentralized applications. A smart contracts implementing this makes it more administratively decentralised. This implementation expects enough valid signatures to internally call the administrative method on the application smart contract. This implementation is backwards compatible, meaning existing `EIP-173` can upgrade from centralised ownership by deploying a Governance smart contract for their organisation and transferring ownership to it.

## Motivation

Traditionally, many contracts that require that they be owned or controlled in some way use `EIP-173` which standardizes the use of ownership in the smart contracts. For example to withdraw funds or perform administrative actions.

```solidity
// Single owner controlled contract

contract dApp {
  function doSomethingAdministrative() external onlyOwner {
    // admin logic that can be performed by a single wallet
  }
}
```

Often, such administrative rights for a single wallet are written for maintainance purpose, but it overpowers the owner wallet and users need to trust the owner. Rescue operations by owner wallet have raised questions on decentralised nature of the projects. Also, there is a possibility of compromise of owner's private key.

A similar concept of multisig wallets have already been used so that funds cannot be transferred without consensus. This implementation generalizes the concept to dApp administration.

## Specification

A `dApp` smart contract considers address of another smart contract called `Governance` as it's owner (instead of a wallet address).

```solidity
contract Governance {
  function makeGovernedCall(
    uint256 _nonce,
    address _to,
    bytes memory _data,
    bytes[] memory _signatures
  ) external payable {
    // performs initial checks like enough signatures

    // once all checks are done, the governance makes
    //  an internal call to the application contract
    (bool _success, ) = _to.call{value: msg.value}(_data);
  }
}
```

## Rationale

The goals of this effort have been the following:

- decentralise the powers of owner wallet to multiple wallets.
- enable existing `EIP-173` ownership smart contracts to become administratively decentralised.

## Backwards Compatibility

The implementation is compatible with existing dApps implementing `EIP-173`.

## Test Cases

Test cases include:

- calling dApp administrative method through governance with 66%+ sorted signatures
- calling dApp administrative method through governance with 66%+ unsorted signatures expecting revert
- calling dApp administrative method through governance with less than 66% sorted signatures expecting revert
- replaying a previously executed called dApp administrative method through governance expecting revert
- calling dApp administrative method through governance with repeated signatures expecting revert

## Implementations

This is a reference implementation. The relevant smart contract is available at: `contracts/SimpleGovernance/Governance.sol` in this repository.

1. Clone the repository
2. `npm install`
3. `npm test`

## Security Considerations

The format of signed data is as per recommendations of `EIP-191`.

```
0x19 66 <32 bytes domain seperator> <32 bytes nonce> <20 bytes to-address> <input data>.
```

The 1 byte version is choosen as `66` since no other EIP has registered it yet.

The domain seperator is specific to the application. It can be as simple as hash of the unique identifier of the dapp followed by a salt for example `keccak256("NameOfDApp12345")`. The salt is used to prevent replay attacks from DApps with similar names.

To prevent any incorrect interpretation in the signed data, every element excluding the last has fixed length. This helps the implementation to remain simple, i.e. without involving RLP.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
