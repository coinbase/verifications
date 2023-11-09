// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IEAS} from "eas-contracts/IEAS.sol";

import {IAttestationIndexer} from "../interfaces/IAttestationIndexer.sol";
import {Attestation, AttestationVerifier} from "../libraries/AttestationVerifier.sol";
import {Predeploys} from "../libraries/Predeploys.sol";

/**
 * @title Basic Access Control using EAS Attestations
 * @dev A base contract for using, and verifying EAS attestations.
 * It can be used for guarding interactions with a contract based on
 * the caller's presence or absence of specific attestations.
 */
abstract contract AttestationAccessControl {
    /// @dev Reference to the predeployed EAS contract on OP Stack.
    IEAS private constant _eas = IEAS(Predeploys.EAS);

    /// @notice Emitted when the indexer is updated.
    event IndexerUpdated(address indexed previousIndexer, address indexed updatedIndexer);

    /// @notice Indexer address is not valid.
    error InvalidIndexer();

    /// @notice Indexer contract to locate an attestation for further verification.
    IAttestationIndexer public indexer;

    /**
     * @dev Modifier to ensure the caller has a valid attestation for the specified schema.
     * @param schemaUid Unique identifier of the schema.
     */
    modifier onlyAttestation(bytes32 schemaUid) {
        Attestation memory attestation = _getAttestation(msg.sender, schemaUid);
        AttestationVerifier.verifyAttestation(attestation, msg.sender, schemaUid);
        _;
    }

    /**
     * @dev Retrieves an attestation for a given recipient, and schema.
     *
     * EAS does not index attestations, so this function relies on an external
     * indexer which may not be up-to-date.
     * The attestation returned from this function comes directly from EAS,
     * but it must still be verified as it may be expired or revoked.
     *
     * @param recipient Address of the recipient of the attestation.
     * @param schemaUid Unique identifier of the schema.
     * @return Attestation from EAS that matches the given recipient, and schema.
     * This attestation may not be the latest for the given recipient, and schema.
     */
    function _getAttestation(address recipient, bytes32 schemaUid) internal view returns (Attestation memory) {
        bytes32 attestationUid = indexer.getAttestationUid(recipient, schemaUid);
        return _eas.getAttestation(attestationUid);
    }

    /**
     * @dev Updates the attestation indexer's contract address.
     *
     * If this function were to be made public or external,
     * it should be protected to only allow authorized callers.
     *
     * @param _indexer The new address for the attestation indexer contract.
     */
    function _setIndexer(IAttestationIndexer _indexer) internal {
        if (address(_indexer) == address(0) || address(_indexer) == address(indexer)) {
            revert InvalidIndexer();
        }
        address previousIndexer = address(indexer);
        indexer = _indexer;
        emit IndexerUpdated(previousIndexer, address(_indexer));
    }
}
