// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Predeploys
 * @notice Contains constant addresses for contracts that are pre-deployed to the OP Stack L2 system.
 * @dev Based on https://github.com/ethereum-optimism/optimism/blob/c73850809be1bef888ba7dd1194acdf222e4d819/packages/contracts-bedrock/src/libraries/Predeploys.sol
 */
library Predeploys {
    /// @notice Address of the SchemaRegistry predeploy.
    address internal constant SCHEMA_REGISTRY = 0x4200000000000000000000000000000000000020;

    /// @notice Address of the EAS predeploy.
    address internal constant EAS = 0x4200000000000000000000000000000000000021;
}
