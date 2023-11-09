// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @notice Error when no attestation is found.
error AttestationNotFound();
/// @notice Error when an attestation has expired.
error AttestationExpired(bytes32 attestationUid, uint256 expirationTime);
/// @notice Error when an attestation has been revoked.
error AttestationRevoked(bytes32 attestationUid, uint256 revocationTime);
/// @notice Error when the desired recipient does not match the recipient in the retrieved attestation.
error AttestationRecipientMismatch(address got, address want);
/// @notice Error when the desired schema does not match the schema in the retrieved attestation.
error AttestationSchemaMismatch(bytes32 got, bytes32 want);
/// @notice Error when an attestation is corrupted / missing data.
error AttestationInvariantViolation(string reason);
