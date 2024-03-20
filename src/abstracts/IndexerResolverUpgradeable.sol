// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

import {Attestation, SchemaResolverUpgradeable} from "./SchemaResolverUpgradeable.sol";
import {IAttestationIndexer} from "../interfaces/IAttestationIndexer.sol";

/**
 * @title Indexer Schema Resolver for EAS
 * @dev A base contract for creating an EAS Schema Resolver that can call
 * to an external contract to index a newly created / issued attestation.
 */
abstract contract IndexerResolverUpgradeable is Initializable, SchemaResolverUpgradeable {
    /// @notice Emitted when the indexer is updated.
    event IndexerUpdated(address indexed previousIndexer, address indexed updatedIndexer);

    /// @notice Indexer address is not valid or unchanged.
    error InvalidIndexer();

    /// @notice The contract responsible for indexing attestations.
    IAttestationIndexer public indexer;

    /**
     * @dev Internal initialization function, only meant to be called once.
     * @param _indexer The address of the attestation indexer contract.
     */
    function __IndexerResolver_init(IAttestationIndexer _indexer) internal onlyInitializing {
        __IndexerResolver_init_unchained(_indexer);
    }

    function __IndexerResolver_init_unchained(IAttestationIndexer _indexer) internal onlyInitializing {
        _setIndexer(_indexer);
    }

    /**
     * @dev Passes an attestation's UID to an external contract for indexing.
     * See {SchemaResolverUpgradeable-onAttest}.
     *
     * This contract does not pass the full attestation to the indexer
     * because we want the indexer to retrieve the full attestation from EAS
     * directly, thereby minimizing trust assumptions.
     * Consequently, this operation is slightly more gas intensive.
     *
     * @param attestation The new attestation to be indexed.
     * @return bool True if the attestation was indexed successfully without reverting.
     */
    function onAttest(Attestation calldata attestation, uint256) internal virtual override returns (bool) {
        indexer.index(attestation.uid);
        return true;
    }

    /**
     * @dev Not implemented as indexing on revocation is not necessary.
     * See {SchemaResolverUpgradeable-onRevoke}.
     *
     * Attestations should always be verified upon usage.
     * The indexer should not be relied upon as the source of truth or
     * for an attestation's liveness.
     *
     * @return bool Always true since this functionality is not implemented.
     */
    function onRevoke(Attestation calldata, uint256) internal virtual override returns (bool) {
        return true;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
