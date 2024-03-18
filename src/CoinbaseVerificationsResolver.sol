// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";

import {IEAS, Attestation, SchemaResolverUpgradeable} from "./abstracts/SchemaResolverUpgradeable.sol";
import {AllowlistResolverUpgradeable} from "./abstracts/AllowlistResolverUpgradeable.sol";
import {IndexerResolverUpgradeable} from "./abstracts/IndexerResolverUpgradeable.sol";
import {IAttestationIndexer} from "./interfaces/IAttestationIndexer.sol";

/**
 * @title EAS Schema Resolver for Coinbase Verifications
 * @notice Manages schemas related to Coinbase Verifications attestations.
 * @dev Only allowlisted entities can attest; successful attestations are indexed.
 */
contract CoinbaseVerificationsResolver is
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    SchemaResolverUpgradeable,
    AllowlistResolverUpgradeable,
    IndexerResolverUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("cbattestations.coinbaseverificationsresolver.pauser");
    bytes32 public constant UPGRADER_ROLE = keccak256("cbattestations.coinbaseverificationsresolver.upgrader");

    /**
     * @dev Locks the contract, preventing any future reinitialization. This implementation contract was designed to be called through proxies.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract.
     * @param defaultAdmin The address to be granted with the default admin Role.
     * @param _indexer The address of the EAS attestation indexer contract.
     */
    function initialize(address defaultAdmin, IAttestationIndexer _indexer) public reinitializer(2) {
        require(defaultAdmin != address(0), "missing default admin address");

        __UUPSUpgradeable_init();
        __AccessControl_init();
        __Pausable_init();

        __SchemaResolver_init();
        __AllowlistResolver_init();
        __IndexerResolver_init(_indexer);

        _grantRole(AccessControlUpgradeable.DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    /// @inheritdoc SchemaResolverUpgradeable
    /// @dev See {AllowlistResolverUpgradeable-onAttest}, and {IndexerResolverUpgradeable-onAttest}.
    function onAttest(Attestation calldata attestation, uint256 value)
        internal
        override(SchemaResolverUpgradeable, AllowlistResolverUpgradeable, IndexerResolverUpgradeable)
        whenNotPaused
        returns (bool)
    {
        return AllowlistResolverUpgradeable.onAttest(attestation, value)
            && IndexerResolverUpgradeable.onAttest(attestation, value);
    }

    /// @inheritdoc SchemaResolverUpgradeable
    /// @dev See {AllowlistResolverUpgradeable-onRevoke}, and {IndexerResolverUpgradeable-onRevoke}.
    function onRevoke(Attestation calldata attestation, uint256 value)
        internal
        override(SchemaResolverUpgradeable, AllowlistResolverUpgradeable, IndexerResolverUpgradeable)
        whenNotPaused
        returns (bool)
    {
        return AllowlistResolverUpgradeable.onRevoke(attestation, value)
            && IndexerResolverUpgradeable.onRevoke(attestation, value);
    }

    /**
     * @notice Updates the attestation indexer's contract address.
     * @dev Only the contract's admin can call this.
     * @param _indexer The new address for the attestation indexer contract.
     */
    function setIndexer(IAttestationIndexer _indexer) external onlyRole(AccessControlUpgradeable.DEFAULT_ADMIN_ROLE) {
        _setIndexer(_indexer);
    }

    /**
     * @notice Adds a new allowed attester.
     * @dev Only the contract's admin can call this.
     * @param attester The address of the attester to be added to allowlist.
     */
    function allowAttester(address attester) external onlyRole(AccessControlUpgradeable.DEFAULT_ADMIN_ROLE) {
        _allowAttester(attester);
    }

    /**
     * @notice Removes an existing allowed attester.
     * @dev Only the contract's admin can call this.
     * @param attester The address of the attester to be removed from allowlist.
     */
    function removeAttester(address attester) external onlyRole(AccessControlUpgradeable.DEFAULT_ADMIN_ROLE) {
        _removeAttester(attester);
    }

    /**
     * @notice Pauses the contract, halting attestations and revocations.
     * @dev Only those with the PAUSER_ROLE can call this.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Resumes contract operations, allowing attestations and revocations.
     * @dev Only those with the PAUSER_ROLE can call this.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Authorizes the upgrade of the contract.
    /// @dev Only those with the UPGRADER_ROLE can call this.
    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
