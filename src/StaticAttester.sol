// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {
    IEAS,
    AttestationRequest,
    AttestationRequestData,
    MultiAttestationRequest,
    RevocationRequest,
    MultiRevocationRequest
} from "eas-contracts/IEAS.sol";

import {Predeploys} from "./libraries/Predeploys.sol";

/**
 * @title EAS Static Attester
 * @notice A relayer to EAS to allow multiple addresses to attest / revoke as a
 * single address (i.e. the smart contract address).
 * This makes it easier to verify specific attestations from an entity / organization.
 */
contract StaticAttester is UUPSUpgradeable, AccessControlUpgradeable, PausableUpgradeable {
    /// @dev Reference to the predeployed EAS contract on OP Stack.
    IEAS private constant _eas = IEAS(Predeploys.EAS);

    bytes32 public constant ATTESTER_ROLE = keccak256("cbattestations.staticattester.attester");
    bytes32 public constant PAUSER_ROLE = keccak256("cbattestations.staticattester.pauser");
    bytes32 public constant UPGRADER_ROLE = keccak256("cbattestations.staticattester.upgrader");

    bytes32 public constant VERIFIED_ACCOUNT_SCHEMA = keccak256("cbattestations.staticattester.schema.verifiedAccount");
    bytes32 public constant VERIFIED_COUNTRY_SCHEMA = keccak256("cbattestations.staticattester.schema.verifiedCountry");

    /// @notice Recipient address is not provided or not valid.
    error InvalidRecipient();
    /// @notice Country code is not provided or not valid.
    error InvalidCountry();
    /// @notice Internal schema ID is not registered.
    error SchemaNotRegistered(bytes32 internalSchemaId);
    /// @notice Internal schema ID is not valid.
    error InvalidInternalSchemaId();
    /// @notice EAS schema ID is not valid.
    error InvalidEasSchemaId();

    /// @notice Emitted when a schema is registered.
    event SchemaRegistered(bytes32 indexed internalSchemaId, bytes32 indexed easSchemaId);

    /**
     * @dev Mapping of internal schema ID to the EAS schema registry schema ID
     */
    mapping(bytes32 internalSchemaId => bytes32 easSchemaId) private _schemas;

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
     */
    function initialize(address defaultAdmin) public reinitializer(2) {
        require(defaultAdmin != address(0), "missing default admin address");

        __UUPSUpgradeable_init();
        __AccessControl_init();
        __Pausable_init();

        _grantRole(AccessControlUpgradeable.DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    /**
     * @notice Initializes V2 of the contract. This must be called for every new deployment.
     * @dev This sets up schema configuration for "Verified Account", and "Verified Country".
     *
     * In V2, we have introduced first-class functions for issuing "Verified Account",
     * and "Verified Country" attestations to reduce calldata size, and hence, gas usage.
     *
     * @param verifiedAccountSchema The bytes32 identifier for the "Verified Account" schema.
     * @param verifiedCountrySchema The bytes32 identifier for the "Verified Country" schema.
     */
    function initializeV2(bytes32 verifiedAccountSchema, bytes32 verifiedCountrySchema) public reinitializer(3) {
        _registerSchema(VERIFIED_ACCOUNT_SCHEMA, verifiedAccountSchema);
        _registerSchema(VERIFIED_COUNTRY_SCHEMA, verifiedCountrySchema);
    }

    /// @dev See {IEAS-attest}.
    function attest(AttestationRequest calldata request)
        external
        whenNotPaused
        onlyRole(ATTESTER_ROLE)
        returns (bytes32)
    {
        return _eas.attest(request);
    }

    /// @dev See {IEAS-multiAttest}.
    function multiAttest(MultiAttestationRequest[] calldata multiRequests)
        external
        whenNotPaused
        onlyRole(ATTESTER_ROLE)
        returns (bytes32[] memory)
    {
        return _eas.multiAttest(multiRequests);
    }

    /// @dev See {IEAS-revoke}.
    function revoke(RevocationRequest calldata request) external whenNotPaused onlyRole(ATTESTER_ROLE) {
        _eas.revoke(request);
    }

    /// @dev See {IEAS-multiRevoke}.
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests)
        external
        whenNotPaused
        onlyRole(ATTESTER_ROLE)
    {
        _eas.multiRevoke(multiRequests);
    }

    /**
     * @notice Attests to a "Verified Account" schema for a given address.
     * @dev This is a gas optimization to reduce calldata size when attesting by templatizing the attestation request data.
     * @param recipient Address of the recipient of the attestation.
     */
    function attestAccount(address recipient) external whenNotPaused onlyRole(ATTESTER_ROLE) returns (bytes32) {
        if (recipient == address(0)) {
            revert InvalidRecipient();
        }

        bytes32 verifiedAccountSchema = _schemas[VERIFIED_ACCOUNT_SCHEMA];
        if (verifiedAccountSchema == 0) {
            revert SchemaNotRegistered(VERIFIED_ACCOUNT_SCHEMA);
        }

        AttestationRequest memory request = AttestationRequest({
            schema: verifiedAccountSchema,
            data: AttestationRequestData({
                recipient: recipient,
                expirationTime: 0,
                revocable: true,
                refUID: 0x0,
                // The Verified Account attestation schema is 'bool verifiedAccount'.
                // Bool fields are represented as a single uint256 and in our case is always set to true.
                data: abi.encode(true),
                value: 0
            })
        });

        return _eas.attest(request);
    }

    /**
     * @notice Attests to a "Verified Country" schema for a given address.
     * @dev This is a gas optimization to reduce calldata size when attesting by templatizing the attestation request data.
     * @param recipientAndCountry 256-bit representation of a recipient address and the country code string.
     */
    function attestCountry(uint256 recipientAndCountry)
        external
        whenNotPaused
        onlyRole(ATTESTER_ROLE)
        returns (bytes32)
    {
        address recipient = address(uint160(recipientAndCountry));
        if (recipient == address(0)) {
            revert InvalidRecipient();
        }

        uint16 country = uint16(recipientAndCountry >> 160);
        if (country == 0) {
            revert InvalidCountry();
        }

        bytes32 verifiedCountrySchema = _schemas[VERIFIED_COUNTRY_SCHEMA];
        if (verifiedCountrySchema == 0) {
            revert SchemaNotRegistered(VERIFIED_COUNTRY_SCHEMA);
        }

        AttestationRequest memory request = AttestationRequest({
            schema: verifiedCountrySchema,
            data: AttestationRequestData({
                recipient: recipient,
                expirationTime: 0,
                revocable: true,
                refUID: 0x0,
                // The Verified Country attestation schema is 'string verifiedCountry'.
                // String fields are abi encoded by 3 uint256 values.
                // The 1st uint256, uint256(32), is the offset of when the string starts, which is after 32 bytes.
                // The 2nd unint256, uint256(2), is the length of the string, which is always 2 since we use alpha2 numeric country codes
                // The 3rd uint256, uint16(country) + uint240(0), is the 2 byte ascii encoded country code followed by 30 bytes of padding
                data: abi.encodePacked(uint256(32), uint256(2), country, uint240(0)),
                value: 0
            })
        });

        return _eas.attest(request);
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
     * @dev Function to register a schema.
     *      Take the keccak256 of the schema name and assign it to the EAS schema ID.
     * @param schemaId Internal schema ID, should remain constant.
     * @param easSchemaId The EAS schema ID.
     */
    function registerSchema(bytes32 schemaId, bytes32 easSchemaId) external onlyRole(ATTESTER_ROLE) {
        _registerSchema(schemaId, easSchemaId);
    }

    /**
     * @dev Internal function to register a schema.
     *      Take the keccak256 of the schema name and assign it to the EAS schema ID.
     * @param schemaId Internal schema id, should remain constant.
     * @param easSchemaId The EAS schema ID.
     */
    function _registerSchema(bytes32 schemaId, bytes32 easSchemaId) internal {
        if (schemaId == 0) {
            revert InvalidInternalSchemaId();
        }

        if (easSchemaId == 0) {
            revert InvalidEasSchemaId();
        }

        _schemas[schemaId] = easSchemaId;
        emit SchemaRegistered(schemaId, easSchemaId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
