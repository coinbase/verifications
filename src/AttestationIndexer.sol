// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";

import {IEAS, Attestation} from "eas-contracts/IEAS.sol";

import {IAttestationIndexer} from "./interfaces/IAttestationIndexer.sol";
import {AttestationVerifier} from "./libraries/AttestationVerifier.sol";
import {Predeploys} from "./libraries/Predeploys.sol";

/**
 * @title EAS Indexer
 * @notice An indexer for EAS attestations.
 */
contract AttestationIndexer is UUPSUpgradeable, AccessControlUpgradeable, PausableUpgradeable, IAttestationIndexer {
    /// @dev Reference to the predeployed EAS contract on OP Stack.
    IEAS private constant _eas = IEAS(Predeploys.EAS);

    /// @notice Error when an attestation being indexed has no recipient.
    error AttestationMissingRecipient(bytes32 attestationUid);

    // 0xa4b7c61933f9e8e6b18106b7a7eccb4ca9257d93e402b5c7989e9ffa46f0d909
    bytes32 public constant INDEXER_ROLE = keccak256("cbattestations.attestationindexer.indexer");
    // 0x72efae548e8175c0e430e0ec64bc027dc7790c481f0c80a241b49baee3944485
    bytes32 public constant PAUSER_ROLE = keccak256("cbattestations.attestationindexer.pauser");
    // 0x8079bd74ca2f4fee66abd92f3c41f9e04756c7dc7d8af05c5c48725c356a41c6
    bytes32 public constant UPGRADER_ROLE = keccak256("cbattestations.attestationindexer.upgrader");

    /**
     * @notice Attestation index by recipient, and schema.
     * Returns the attestation's UID.
     * @dev Intended for guarded / permissioned EAS schemas.
     * That is, any attesters / issuers of attestations for a specific schema are trusted
     * because the schema is protected by a resolver.
     */
    mapping(address recipient => mapping(bytes32 schemaUid => bytes32 attestationUid)) private _attestationsByRecipient;

    /**
     * @dev Locks the contract, preventing any future reinitialization. This implementation contract was designed to be called through proxies.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract.
     */
    function initialize(address defaultAdmin) public reinitializer(2) {
        require(defaultAdmin != address(0), "missing default admin address");

        __UUPSUpgradeable_init();
        __AccessControl_init();
        __Pausable_init();

        // This makes the deployer the default admin.
        _grantRole(AccessControlUpgradeable.DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    /**
     * @inheritdoc IAttestationIndexer
     * @dev Only those with the INDEXER_ROLE can call this.
     */
    function index(bytes32 attestationUid) external whenNotPaused onlyRole(INDEXER_ROLE) {
        _index(attestationUid);
    }

    /**
     * @inheritdoc IAttestationIndexer
     */
    function getAttestationUid(address recipient, bytes32 schemaUid) external view returns (bytes32) {
        return _attestationsByRecipient[recipient][schemaUid];
    }

    /**
     * @notice Pauses the contract. This prevents further indexing from occurring.
     * Enabling this will impact new EAS attestations from being created / issued
     * if indexing occurs at the schema resolver level.
     * @dev Only those with the PAUSER_ROLE can call this.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Resumes the contract operations by allowing for new indexing actions.
     * @dev Only those with the PAUSER_ROLE can call this.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAttestationIndexer).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Indexes an EAS attestation using its UID.
     * The function will lookup the attestation from the global EAS contract,
     * and verify it, before creating indexes. An event will be emitted when the
     * attestation is successfully indexed.
     *
     * @param attestationUid The unique identifier of the attestation.
     */
    function _index(bytes32 attestationUid) private {
        Attestation memory attestation = _eas.getAttestation(attestationUid);

        AttestationVerifier.verifyAttestation(attestation);

        // Attestation must include a recipient otherwise it arguably does not
        // benefit from being indexed.
        if (attestation.recipient == address(0)) {
            revert AttestationMissingRecipient(attestation.uid);
        }

        // We do not have to verify `recipient`, and `schema` because they already exist in EAS.
        // Overriding existing attestations is OK by design.
        // We do not allow expired or revoked attestations, so we should not have
        // a scenario where an "invalid" attestation overrides a "valid" one.
        // We do not want to be too prescriptive about what should take precedence.
        _attestationsByRecipient[attestation.recipient][attestation.schema] = attestation.uid;

        emit AttestationIndexed(msg.sender, attestation.recipient, attestation.schema, attestation.uid);
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
    uint256[48] private __gap;
}
