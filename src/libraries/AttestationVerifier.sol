// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Attestation} from "eas-contracts/IEAS.sol";

import {
    AttestationNotFound,
    AttestationExpired,
    AttestationRevoked,
    AttestationSchemaMismatch,
    AttestationRecipientMismatch,
    AttestationInvariantViolation
} from "./AttestationErrors.sol";

/**
 * @title EAS Attestation Verifier
 * @dev Helper functions to verify EAS attestations.
 */
library AttestationVerifier {
    /**
     * @notice Verifies the EAS attestation, ensuring its validity, and integrity.
     * @dev Throws an error if the attestation is not found, has expired or has been revoked.
     * @param attestation Full EAS attestation to verify.
     */
    function verifyAttestation(Attestation memory attestation) internal view {
        _verifyAttestation(attestation);
    }

    /**
     * @notice Verifies the EAS attestation, ensuring its validity, integrity,
     * targeted recipient, and adherence to the expected schema.
     *
     * @dev Throws an error if the attestation is not found,
     * has an unexpected recipient, has an unexpected schema,
     * has expired or has been revoked.
     *
     * @param attestation Full EAS attestation to verify.
     * @param recipient Address of the expected attestation's subject.
     * @param schemaUid Unique identifier of the expected schema.
     */
    function verifyAttestation(Attestation memory attestation, address recipient, bytes32 schemaUid) internal view {
        // Attestation being checked must be for the expected recipient.
        if (attestation.recipient != recipient) {
            revert AttestationRecipientMismatch(attestation.recipient, recipient);
        }
        // Attestation being checked must be using the expected schema.
        if (attestation.schema != schemaUid) {
            revert AttestationSchemaMismatch(attestation.schema, schemaUid);
        }

        _verifyAttestation(attestation);
    }

    function _verifyAttestation(Attestation memory attestation) private view {
        // Attestation must exist.
        if (attestation.uid == 0) {
            revert AttestationNotFound();
        }

        // Attestation must not be expired.
        if (attestation.expirationTime != 0 && attestation.expirationTime <= block.timestamp) {
            revert AttestationExpired(attestation.uid, attestation.expirationTime);
        }
        // Attestation must not be revoked.
        if (attestation.revocationTime != 0) {
            revert AttestationRevoked(attestation.uid, attestation.revocationTime);
        }

        // Check invariants. They are unlikely to occur, but we should
        // check just in case.
        if (attestation.attester == address(0)) {
            revert AttestationInvariantViolation("missing attester");
        }
        if (attestation.schema == 0) {
            revert AttestationInvariantViolation("missing schema");
        }
    }
}
