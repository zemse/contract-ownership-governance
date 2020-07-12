![tests](https://github.com/zemse/contract-ownership-governance/workflows/tests/badge.svg)

# Contract Ownership Governance

A standard interface for Governance contracts that administratively decentralize the ownership of smart contracts.

Rendered version of the draft: https://github.com/zemse/EIPs/blob/eip-contract-ownership-governance/EIPS/eip-2767.md

## Reference Implementations

1. Governance Onchain with Equal Voting Rights ([Contract](https://github.com/zemse/contract-ownership-governance/blob/master/contracts/GovernanceOnchainEqual.sol), [Tests](https://github.com/zemse/contract-ownership-governance/blob/master/test/suites/OnchainEqual.test.ts))
2. Governance Offchain with Privileged Voting Rights ([Contract](https://github.com/zemse/contract-ownership-governance/blob/master/contracts/GovernanceOffchainPrivileged.sol), [Tests](https://github.com/zemse/contract-ownership-governance/blob/master/test/suites/OffchainPrivileged.test.ts))

> There can be similar implementations for Offchain + Equal Voting Rights and Onchain + Privileged Voting Rights. An implementation with Offchain + Onchain is also possible.

## Repository setup

```
$ git clone git@github.com:zemse/contract-ownership-governance.git
$ cd contract-ownership-governance
$ npm ci
$ npm test
```
