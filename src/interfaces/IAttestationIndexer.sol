// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IAttestationIndexer {
    /**
     * @notice Records / indexes an EAS attestation by its unique identifier.
     * @dev Implementing contracts should handle the logic of recording / indexing
     * the attestation using this identifier, and they should emit an event
     * if successful. The identifier can be used for retrieving the full
     * attestation from EAS. This is to minimize trust assumptions on the caller.
     *
     * @param attestationUid The unique identifier of the attestation.
     */
    function index(bytes32 attestationUid) external;

    /**
     * @notice Retrieves an EAS attestation unique identifier by the recipient and schema.
     * @dev Intended for guarded / permissioned EAS schemas.
     * That is, any attesters / issuers of attestations for a specific schema are trusted
     * because the schema is protected by a resolver.
     *
     * The attestation unique identifier can be used to retrieve the
     * full attestation from EAS. This is to minimize trust assumptions on the indexer.
     * See {AttestationAccessControl-_getAttestation}.
     *
     * @param recipient Address of the recipient of the attestation.
     * @param schemaUid Unique identifier of the schema.
     * @return Unique identifier of the indexed attestation matching the given
     * recipient, and schema.
     * It can return 0 if the attestation does not exist or has not been indexed yet.
     * The attestation may also not be up-to-date, and it can be possible for
     * another valid attestation with a different unique identifier to exist for the
     * same given recipient, and schema.
     * Callers should take care by verifying the attestation after retrieving
     * it from EAS using this unique identifier.
     */
    function getAttestationUid(address recipient, bytes32 schemaUid) external view returns (bytes32);

    /// @notice Emitted when an attestation is indexed.
    event AttestationIndexed(
        address indexer, address indexed recipient, bytes32 indexed schema, bytes32 indexed attestationUid
    );
}
