# Coinbase Verifications

"Coinbase Verifications" is a set of Coinbase-verified onchain attestations that enable access to apps and other onchain benefits. Our implementation is Ethereum-aligned by leveraging [Ethereum Attestation Service ("EAS")](https://attest.sh/), an open-source public good that is included as a predeploy in the OP Stack.

**Onchain is the next online.** This repository is intended for builders looking to integrate our attestations.


## Disclaimer

_By using the "Coinbase Verifications" service and accessing any attestation that Coinbase has provided in respect of a Coinbase customer through the Ethereum Attestation Service, you acknowledge and understand that this attestation is for informational purposes only and should not be relied upon by you or any third party for any legal, compliance, or contractual purpose. Any attestation provided by Coinbase using the Ethereum Attestation Service represents the status of the relevant individual’s Coinbase account as of the time of issuance, and subsequent changes to the status of such individual’s Coinbase account that result in such attestation no longer being true may not be reflected immediately in the Ethereum Attestation Service.  Therefore, Coinbase does not represent, warrant or guarantee that the information contained in any attestation or represented thereby is complete, accurate, or current.  Additionally, you should be aware that the specific processes that Coinbase uses to verify the identities of its customers may differ by jurisdiction.  Furthermore, you agree that Coinbase will not be liable for any damages or loss caused by your use of the attestation._


## Contracts

### Base Goerli (Development)

| Contract              | Description                                                                                                                                                                                                                                                                                                                                                                                 | Address (on Base)                                                                                                                        |
|-----------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| EAS                   | Stores, and manages attestations. See EAS' [docs](https://docs.attest.sh/docs/quick--start/quickstart) for more info.                                                                                                                                                                                                                                                                       | [0x4200000000000000000000000000000000000021](https://goerli.basescan.org/address/0x4200000000000000000000000000000000000021) (Predeploy) |
| Schema Registry (EAS) | Stores schema definitions (templates for attestations). See EAS' [docs](https://docs.attest.sh/docs/quick--start/quickstart) for more info.                                                                                                                                                                                                                                                 | [0x4200000000000000000000000000000000000020](https://goerli.basescan.org/address/0x4200000000000000000000000000000000000020) (Predeploy) |
| Coinbase Indexer      | All Coinbase attestations will be indexed in this contract.<br><br>You can query for the latest attestation ID by providing the attestation's recipient (address), and target schema ID (bytes32). See [below](#build-with-coinbase-verifications) for details on the full interface.<br><br>The actual attestation, and its data can be retrieved directly from EAS using the returned ID. | [0x1905E996C2246D7C188E312aDb65E27FBCC25e93](https://goerli.basescan.org/address/0x1905E996C2246D7C188E312aDb65E27FBCC25e93)             |
| Coinbase Attester     | All Coinbase attestations will be issued from this contract / address.<br><br>You can use the address of this contract for verifying the origin of the attestation, though, verifying the schema ID should be sufficient in most cases as our schemas are protected such that only Coinbase permitted attesters may use it.                                                                 | [0x97168a4E824687991C90523CAf2bc87EfD713A3C](https://goerli.basescan.org/address/0x97168a4E824687991C90523CAf2bc87EfD713A3C)             |

### Base Sepolia (Development)

_Coming soon._

### Base Mainnet (Production)

_See previous section for description._

| Contract              | Address (on Base)                                                                                                                 |
|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| EAS                   | [0x4200000000000000000000000000000000000021](https://basescan.org/address/0x4200000000000000000000000000000000000021) (Predeploy) |
| Schema Registry (EAS) | [0x4200000000000000000000000000000000000020](https://basescan.org/address/0x4200000000000000000000000000000000000020) (Predeploy) |
| Coinbase Indexer      | [0x2c7eE1E5f416dfF40054c27A62f7B357C4E8619C](https://basescan.org/address/0x2c7eE1E5f416dfF40054c27A62f7B357C4E8619C)             |
| Coinbase Attester     | [0x357458739F90461b99789350868CD7CF330Dd7EE](https://basescan.org/address/0x357458739F90461b99789350868CD7CF330Dd7EE)             |


## EAS Schemas

### Base Goerli (Development)

| Schema | Description | ID |
|---|---|---|
| Verified Account | An attestation type that can be claimed by a Coinbase user with a valid Coinbase trading account. The criteria / definition for this will vary across jurisdictions.<br><br>The attestation includes a boolean field that is always set to true.<br><br>[(Example)](https://base-goerli-predeploy.easscan.org/attestation/view/0xee3d6e68a014ca45169c3cacc4bcae57e646ffdd2096d6c82bf3670357b56315) | [0x229b...5c65](https://base-goerli-predeploy.easscan.org/schema/view/0x229bf5be6b9c05db7cb9e3be704499ecc4b73fde00aa5a5c0bff8f7dd5765c65) |
| Verified Country | An attestation type that can be claimed by a Coinbase user that includes the user’s verified country of residence on Coinbase.<br><br>The attestation includes a string field that is set to the customer’s residing country code in ISO 3166-1 alpha-2 format.<br><br>[(Example)](https://base-goerli-predeploy.easscan.org/attestation/view/0x2773f586de4e24ff5d2f16b730f4e413f0b41c6a59735086221ca96990162b59) | [0x41da...d805](https://base-goerli-predeploy.easscan.org/schema/view/0x41da234470e4d2fba2bba91b98f78e19da22467b473a643d9bbaabef3adcd805) |

### Base Sepolia (Development)

_Coming soon._

### Base Mainnet (Production)

_See previous section for description._

| Schema | ID |
|---|---|
| Verified Account | [0xf8b05c79f090979bf4a80270aba232dff11a10d9ca55c4f88de95317970f0de9](https://base.easscan.org/schema/view/0xf8b05c79f090979bf4a80270aba232dff11a10d9ca55c4f88de95317970f0de9) |
| Verified Country | [0x1801901fabd0e6189356b4fb52bb0ab855276d84f7ec140839fbd1f6801ca065](https://base.easscan.org/schema/view/0x1801901fabd0e6189356b4fb52bb0ab855276d84f7ec140839fbd1f6801ca065) |


## Build with Coinbase Verifications

**Looking to build with Coinbase Verifications?** [Get in touch with us!](https://app.deform.cc/form/69d6f46e-426a-4bcd-bfe6-d3b3678bf4bf/)

### Base Contracts

To get started with our base contracts using [Foundry](https://github.com/foundry-rs/foundry):

```sh
forge install coinbase/verifications
```

| Contract | Description |
|---|---|
| `src/abstracts/AttestationAccessControl.sol` | An abstract contract for managing access to a contract's functions using attestations. It is also an example of how you can use our [indexer](#contracts), `IAttestationIndexer`. |
| `src/interfaces/IAttestationIndexer.sol` | The interface implemented by the [Coinbase Indexer](#contracts). You can use this to ease making contract-to-contract calls to our indexer or to generate an ABI for interacting with our indexer offchain. |
| `src/libraries/AttestationErrors.sol` | Common errors which may be returned from our attestation verifier library. |
| `src/libraries/AttestationVerifier.sol` | A simple library for verifying any EAS attestation. |
| `src/libraries/Predeploys.sol` | Common predeploy addresses on OP Stack, e.g. EAS, Schema Registry. |

### Examples

_Coming soon._
