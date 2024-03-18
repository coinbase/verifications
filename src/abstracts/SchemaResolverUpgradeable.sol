// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

import {IEAS, Attestation} from "eas-contracts/IEAS.sol";
import {ISchemaResolver} from "eas-contracts/resolver/ISchemaResolver.sol";

import {Predeploys} from "../libraries/Predeploys.sol";

/**
 * @title Base Schema Resolver for EAS
 * @dev Based on EAS `SchemaResolver`, but made upgradeable, and non-payable,
 * while still abiding by the interface.
 */
abstract contract SchemaResolverUpgradeable is Initializable, ISchemaResolver {
    /// @dev Reference to the predeployed EAS contract on OP Stack.
    IEAS private constant _eas = IEAS(Predeploys.EAS);

    error AccessDenied();
    error InsufficientValue();
    error InvalidEAS();
    error InvalidLength();
    error NotPayable();

    /**
     * @dev Creates a new resolver.
     */
    function __SchemaResolver_init() internal onlyInitializing {}

    function __SchemaResolver_init_unchained() internal onlyInitializing {}

    /// @dev Ensures that only the EAS contract can make this call.
    modifier onlyEAS() {
        _onlyEAS();

        _;
    }

    /// @dev Ensures the call does not include any ETH.
    // This is needed so we can still implement `ISchemaResolver`,
    // while ensuring we do not allow any accidental ETH transfers.
    modifier notPayable() {
        if (msg.value != 0) {
            revert NotPayable();
        }
        _;
    }

    /// @inheritdoc ISchemaResolver
    function isPayable() public pure virtual returns (bool) {
        return false;
    }

    /// @dev ETH callback.
    receive() external payable virtual {
        if (!isPayable()) {
            revert NotPayable();
        }
    }

    /// @inheritdoc ISchemaResolver
    function attest(Attestation calldata attestation) external payable notPayable onlyEAS returns (bool) {
        return onAttest(attestation, msg.value);
    }

    /// @inheritdoc ISchemaResolver
    function multiAttest(Attestation[] calldata attestations, uint256[] calldata values)
        external
        payable
        notPayable
        onlyEAS
        returns (bool)
    {
        uint256 length = attestations.length;
        if (length != values.length) {
            revert InvalidLength();
        }

        // We are keeping track of the remaining ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 remainingValue = msg.value;

        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            // Ensure that the attester/revoker doesn't try to spend more than available.
            uint256 value = values[i];
            if (value > remainingValue) {
                revert InsufficientValue();
            }

            // Forward the attestation to the underlying resolver and return false in case it isn't approved.
            if (!onAttest(attestations[i], value)) {
                return false;
            }

            unchecked {
                // Subtract the ETH amount, that was provided to this attestation, from the global remaining ETH amount.
                remainingValue -= value;
            }
        }

        return true;
    }

    /// @inheritdoc ISchemaResolver
    function revoke(Attestation calldata attestation) external payable notPayable onlyEAS returns (bool) {
        return onRevoke(attestation, msg.value);
    }

    /// @inheritdoc ISchemaResolver
    function multiRevoke(Attestation[] calldata attestations, uint256[] calldata values)
        external
        payable
        notPayable
        onlyEAS
        returns (bool)
    {
        uint256 length = attestations.length;
        if (length != values.length) {
            revert InvalidLength();
        }

        // We are keeping track of the remaining ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 remainingValue = msg.value;

        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            // Ensure that the attester/revoker doesn't try to spend more than available.
            uint256 value = values[i];
            if (value > remainingValue) {
                revert InsufficientValue();
            }

            // Forward the revocation to the underlying resolver and return false in case it isn't approved.
            if (!onRevoke(attestations[i], value)) {
                return false;
            }

            unchecked {
                // Subtract the ETH amount, that was provided to this attestation, from the global remaining ETH amount.
                remainingValue -= value;
            }
        }

        return true;
    }

    /**
     * @notice A resolver callback that should be implemented by child contracts.
     * @param attestation The new attestation.
     * @param value An explicit ETH amount that was sent to the resolver. Please note that this value is verified in
     *        both attest() and multiAttest() callbacks EAS-only callbacks and that in case of multi attestations,
     *        it'll usually hold that msg.value != value, since msg.value aggregated the sent ETH amounts for all
     *        the attestations in the batch.
     * @return Whether the attestation is valid.
     */
    function onAttest(Attestation calldata attestation, uint256 value) internal virtual returns (bool);

    /**
     * @notice Processes an attestation revocation and verifies if it can be revoked.
     * @param attestation The existing attestation to be revoked.
     * @param value An explicit ETH amount that was sent to the resolver. Please note that this value is verified in
     *        both revoke() and multiRevoke() callbacks EAS-only callbacks and that in case of multi attestations,
     *        it'll usually hold that msg.value != value, since msg.value aggregated the sent ETH amounts for all
     *        the attestations in the batch.
     * @return Whether the attestation can be revoked.
     */
    function onRevoke(Attestation calldata attestation, uint256 value) internal virtual returns (bool);

    /// @dev Ensures that only the EAS contract can make this call.
    function _onlyEAS() private view {
        if (msg.sender != address(_eas)) {
            revert AccessDenied();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/// @dev A helper function to work with unchecked iterators in loops.
/// @param i The index to increment.
/// @return j The incremented index.
function uncheckedInc(uint256 i) pure returns (uint256 j) {
    unchecked {
        j = i + 1;
    }
}
