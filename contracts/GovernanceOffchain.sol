// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./lib/ECDSA.sol";

/// @title Governance Offchain Smart Contract
/// @notice Governs a decentralised application to perform administrative tasks.
contract GovernanceOffChain {
    /// @dev EIP-191 Prepend byte + Version byte
    bytes public constant PREPEND_BYTES = hex"1966";

    /// @dev Keeps signed data scoped only for this governance contract
    bytes32 public constant DOMAIN_SEPERATOR = keccak256("TestlandGovernance");

    /// @dev Prevents replay of transactions. It is used as nonce.
    uint256 public transactionsCount;

    /// @dev Governor addresses with corresponding consents (vote weightage)
    mapping(address => uint256) consents;

    /// @dev Sum of all governor consents
    uint256 public maxConsent;

    /// @notice Stores initial set of governors
    /// @param _governors List of initial governor addresses
    /// @param _consents List of corresponding initial consents
    constructor(address[] memory _governors, uint256[] memory _consents) public {
        require(_governors.length == _consents.length, "Gov: Invalid input lengths");

        uint256 _maxConsent;
        for (uint256 i = 0; i < _governors.length; i++) {
            consents[_governors[i]] = _consents[i];
            _maxConsent += _consents[i];
        }
        maxConsent = _maxConsent;
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

        bytes32 _digest = keccak256(abi.encodePacked(PREFIX(), _nonce, _destination, _data));

        verifySignatures(_digest, _signatures);

        transactionsCount++;

        (bool _success, ) = _destination.call{ value: msg.value }(_data);
        require(_success, "Call was reverted");
    }

    /// @notice Updates governor statuses
    /// @param _governors List of governor addresses
    /// @param _newConsents List of corresponding new consents
    function updateConsents(address[] memory _governors, uint256[] memory _newConsents) external {
        require(msg.sender == address(this), "Gov: Only self can call");
        require(_governors.length == _newConsents.length, "Gov: Invalid input lengths");

        uint256 _maxConsent = maxConsent;

        for (uint256 i = 0; i < _governors.length; i++) {
            if (_newConsents[i] != consents[_governors[i]]) {
                // TODO: Add safe math
                _maxConsent = _maxConsent - consents[_governors[i]] + _newConsents[i];

                consents[_governors[i]] = _newConsents[i];
            }
        }

        maxConsent = _maxConsent;
    }

    function getGovernorsConsent(address _governor) public view returns (uint256) {
        return consents[_governor];
    }

    /// @notice Makes the signature by governor specific to this contract
    /// @return EIP-191 Message prefix for signing transaction with ECDSA
    function PREFIX() public pure returns (bytes memory) {
        return abi.encodePacked(PREPEND_BYTES, DOMAIN_SEPERATOR);
    }

    /// @notice Checks for consensus
    /// @param _digest hash of sign data
    /// @param _signatures sorted sigs according to increasing signer addresses
    function verifySignatures(bytes32 _digest, bytes[] memory _signatures) internal view {
        uint160 _lastGovernor;
        uint256 _consent;
        for (uint256 i = 0; i < _signatures.length; i++) {
            address _signer = ECDSA.recover(_digest, _signatures[i]);

            // Prevents duplicate signatures
            uint160 _thisGovernor = uint160(_signer);
            require(_thisGovernor > _lastGovernor, "Gov: Invalid arrangement");
            _lastGovernor = _thisGovernor;

            require(getGovernorsConsent(_signer) > 0, "Gov: Not a governor");
            _consent += getGovernorsConsent(_signer);
        }

        // 66% consensus
        // TODO: Add safe math
        require(_consent * 3 > maxConsent * 2, "Gov: Not 66% consensus");
    }
}
