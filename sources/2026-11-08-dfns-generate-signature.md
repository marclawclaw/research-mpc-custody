> ## Documentation Index
> Fetch the complete documentation index at: https://docs.dfns.co/llms.txt
> Use this file to discover all available pages before exploring further.

# Generate Signature

> Request to generate a signature with the key. **This process does not broadcast anything on-chain**, this is just an off-chain signature request.

Dfns is compatible with any blockchain that uses a supported [key format](https://docs.dfns.co/networks/supported-key-formats). If Dfns doesn't officially integrate with a blockchain, you can use hash signing to generate the signatures to interact with the chain.

<Note>
If you were using the deprecated `POST /wallets/{walletId}/signatures` endpoint, then you should now use this one. See the [deprecation notice](https://docs.dfns.co/deprecation/keys-and-multichain-migration-guide) to get more information about how to change your code. TL,DR: from a wallet you can obtain the key as `wallet.signingKey.id`.
</Note>


#### Authentication

✅ Tenant User (`TenantUser`)\
✅ Organization User (`CustomerEmployee`)\
✅ End User (`EndUser`)\
✅ Service Account

#### Required Permissions

`Keys:Signatures:Create`: Always required.


## OpenAPI

````yaml /openapi.yaml post /keys/{keyId}/signatures
openapi: 3.1.0
info:
  version: 2.0.449
  title: Dfns
servers:
  - url: https://api.dfns.io
    description: Default - Europe
  - url: https://api.uae.dfns.io
    description: UAE
  - url: https://api.dfns.ninja
    description: <Deprecated> Staging
security: []
paths:
  /keys/{keyId}/signatures:
    post:
      tags:
        - Keys
      summary: Generate Signature
      description: >
        Request to generate a signature with the key. **This process does not
        broadcast anything on-chain**, this is just an off-chain signature
        request.


        Dfns is compatible with any blockchain that uses a supported [key
        format](https://docs.dfns.co/networks/supported-key-formats). If Dfns
        doesn't officially integrate with a blockchain, you can use hash signing
        to generate the signatures to interact with the chain.


        <Note>

        If you were using the deprecated `POST /wallets/{walletId}/signatures`
        endpoint, then you should now use this one. See the [deprecation
        notice](https://docs.dfns.co/deprecation/keys-and-multichain-migration-guide)
        to get more information about how to change your code. TL,DR: from a
        wallet you can obtain the key as `wallet.signingKey.id`.

        </Note>
      operationId: generateSignature
      parameters:
        - schema:
            type: string
            minLength: 1
            maxLength: 64
            description: The key to sign with.
          required: true
          description: The key to sign with.
          name: keyId
          in: path
      requestBody:
        required: true
        content:
          application/json:
            schema:
              oneOf:
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - Hash
                    hash:
                      type: string
                      pattern: ^(0x)?[0-9a-fA-F]{64}$
                      description: 32-byte hash in hex encoded format.
                    taprootMerkleRoot:
                      type: string
                      pattern: ^(0x)?([0-9A-Fa-f]{64})?$
                      description: >-
                        Required when signing with a Schnorr key. Specify the
                        merkle root for tweaking the signing key, or the empty
                        string "" to tweak with the default merkle root.
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - hash
                  additionalProperties: false
                  description: >-
                    All cryptographic scheme support hash signing. Different
                    blockchains will apply different hash functions to compute
                    the hash.
                  title: Hash
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - Message
                    message:
                      type: string
                      pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                      description: An arbitrary hex encoded message.
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - message
                  additionalProperties: false
                  description: Signs an arbitrary hex encoded arbitrary message.
                  title: Message
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - Transaction
                    transaction:
                      anyOf:
                        - type: string
                          pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                        - type: object
                          properties: {}
                          description: >-
                            Network-specific JSON transaction object. The
                            accepted fields depend on the target network. For
                            EVM chains the shape matches the EVM transaction
                            object of [Sign and Broadcast
                            Transaction](https://docs.dfns.co/api-reference/wallets/sign-and-broadcast-transaction)
                            (for example `to`, `value`, `data`, `nonce`,
                            `gasLimit`, `maxFeePerGas`, `maxPriorityFeePerGas`).
                            For other JSON networks (such as Starknet or
                            Concordium), refer to the per-network formats
                            described below.
                          title: JSON transaction object
                      description: >-
                        The unsigned hex-encoded transaction or JSON object for
                        compatible networks
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - transaction
                  additionalProperties: false
                  description: >-
                    Signs an unsigned transaction. The transaction parameter
                    accepts hex-encoded transactions or JSON objects for
                    compatible networks (Concordium, Starknet, Evm).


                    The following blockchains only accept JSON transaction
                    objects (not hex strings): Concordium, Starknet.


                    For Starknet transactions, you may use invocation request
                    objects
                    (https://github.com/starkware-libs/starknet-specs/blob/v0.8.1/api/starknet_api_openrpc.json#L2621):


                    | Field                         |
                    Description                                                                                        
                    | Type - Optional                  |

                    |-------------------------------|-----------------------------------------------------------------------------------------------------|----------------------------------|

                    | type                          | transaction type (always
                    INVOKE             
                    )                                                      |
                    String (required)                |

                    | calldata                      | **Array** of encoded
                    function call
                    parameters                                                      
                    | **Array of Strings** (required)  |

                    | nonce                         | Transaction nonce in hex
                    format                                                                    
                    | String (required)                |

                    | version                       | Transaction version in hex
                    format. Typically "0x3" for current
                    transactions                         | String
                    (required)                |

                    | resourceBounds                | Gas bounds for L1, L2, and
                    L1 data
                    gas                                                             
                    | Object (required)                |

                    | ↳ resourceBounds.l1Gas        | L1 gas configuration with
                    maxAmount and
                    maxPricePerUnit                                            
                    | Object (required)                |

                    | ↳ resourceBounds.l2Gas        | L2 gas configuration with
                    maxAmount and
                    maxPricePerUnit                                            
                    | Object (required)                |

                    | ↳ resourceBounds.l1DataGas    | L1 data gas configuration
                    with maxAmount and
                    maxPricePerUnit                                        |
                    Object (required)                |

                    | tip                           | Transaction tip in hex
                    format. Typically
                    "0x0"                                                      |
                    String (required)                |

                    | paymasterData                 | Paymaster data
                    array                                                                               
                    | Array of Strings (required)      |

                    | accountDeploymentData         | Account deployment data
                    array                                                                      
                    | Array of Strings (required)      |

                    | nonceDataAvailabilityMode     | Data availability mode for
                    nonce. Typically "L1" for
                    now                                            | String
                    (required)                |

                    | feeDataAvailabilityMode       | Data availability mode for
                    fee. Typically "L1" for
                    now                                              | String
                    (required)                |

                    | chainId                       | The chain identifier in
                    hex
                    format                                                                 
                    | String (required)                |

                    | senderAddress                 | The address of the account
                    sending the
                    transaction                                                 
                    | String (required)                |


                    For Concordium transactions, use account transaction objects
                    (https://developer.concordium.software/concordium-node-sdk-js/classes/ccd_js_gen.ConcordiumGRPCClient.html):


                    | Field                          |
                    Description                                                                 
                    | Type - Optional              |

                    |--------------------------------|------------------------------------------------------------------------------|------------------------------|

                    | header.sender                  | Account address
                    (base58)                                                    
                    | String (required)            |

                    | header.nonce                   | Account
                    nonce                                                               
                    | String (required)            |

                    | header.expiry                  | Unix epoch seconds
                    expiry                                                    |
                    Number (required)            |

                    | header.executionEnergyAmount   | Max NRG for
                    execution                                                       
                    | String (required)            |

                    | header.numSignatures           | Number of
                    signatures                                                        
                    | Number (optional)            |

                    | payload                        | Transaction payload
                    (type-specific, e.g. Transfer, RegisterData)             |
                    Object (required)            |


                    ```json

                    {
                      "kind": "Transaction",
                      "blockchainKind": "Concordium",
                      "transaction": {
                        "header": {
                          "sender": "4FmiTW2L2AccyR36ZBRKNqwQvBJBH8CAXWMLB1dbX5WyZmRo6N",
                          "nonce": "42",
                          "expiry": 1709510400,
                          "executionEnergyAmount": "501"
                        },
                        "payload": {
                          "Transfer": {
                            "amount": "1000000",
                            "toAddress": "3U4sfVSqGG6XK8g6eho2qRYtnHc4MWJBG1dfxdtPGbfHwFxini"
                          }
                        }
                      }
                    }

                    ```


                    ```json

                    {
                      "kind": "Transaction",
                      "transaction": "0xe703847735941a82520894f0965f5eb35ace69f01b77031f2cff22daca622887470de4df82000080"
                    }

                    ```


                    ```json

                    {
                      "kind": "Transaction",
                      "transaction": {
                        "type": "INVOKE",
                        "calldata": [
                          "1",
                          "2009894490435840142178314390393166646092438090257831307886760648929397478285",
                          "232670485425082704932579856502088130646006032362877466777181098476241604910",
                          "3",
                          "296727860213112272332383824629975240127004024814636931420022890499591637514",
                          "1",
                          "0"
                        ],
                        "nonce": "0x51",
                        "version": "0x3",
                        "resourceBounds": {
                          "l1Gas": { "maxAmount": "0x0", "maxPricePerUnit": "0x239a01ff6e6c" },
                          "l2Gas": { "maxAmount": "0x1694a0", "maxPricePerUnit": "0x10c388d00" },
                          "l1DataGas": { "maxAmount": "0x120", "maxPricePerUnit": "0x98e8" }
                        },
                        "tip": "0x0",
                        "paymasterData": [],
                        "accountDeploymentData": [],
                        "nonceDataAvailabilityMode": "L1",
                        "feeDataAvailabilityMode": "L1",
                        "chainId": "0x534e5f5345504f4c4941",
                        "senderAddress": "0x0535a9762b984c876abe0b164b0ccedb0d23a78978c9fe87e29deae0ea890c72"
                      }
                    }

                    ```
                  title: Transaction
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - Eip191
                    message:
                      type: string
                      pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                      description: Hex-encoded message.
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - message
                  additionalProperties: false
                  description: >-
                    Signs a personal_sign message as defined in
                    [EIP-191](https://eips.ethereum.org/EIPS/eip-191).
                  title: EIP-191 personal_sign Message
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - Eip712
                    types:
                      type: object
                      additionalProperties:
                        type: array
                        items:
                          type: object
                          properties:
                            name:
                              type: string
                            type:
                              type: string
                          required:
                            - name
                            - type
                          additionalProperties: false
                      description: Type definitions.
                    domain:
                      type: object
                      properties:
                        name:
                          type: string
                          description: Name of the signing domain.
                        version:
                          type: string
                          description: Current major version of the signing domain.
                        chainId:
                          anyOf:
                            - type: integer
                              exclusiveMinimum: 0
                            - type: string
                          description: Chain ID.
                        verifyingContract:
                          type: string
                          pattern: ^0x[0-9a-fA-F]{40}$
                          description: >-
                            The address of the contract that will verify the
                            signature.
                        salt:
                          type: string
                          pattern: ^0x[0-9a-fA-F]{64}$
                          description: 32-byte value as a last-resort domain separator.
                      additionalProperties: false
                      description: Domain separator.
                    message:
                      type: object
                      additionalProperties: {}
                      description: Structured message to sign.
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - types
                    - domain
                    - message
                  additionalProperties: false
                  description: >-
                    Signs a typed structured data as defined in
                    [EIP-712](https://eips.ethereum.org/EIPS/eip-712).
                  title: EIP-712 TypedData
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - Eip7702
                    address:
                      type: string
                      pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                      description: >-
                        The address of the contract the signer's EOA will be
                        delegated to.
                    nonce:
                      type: number
                      description: The current nonce of the signer EOA.
                    chainId:
                      type: number
                      description: Chain ID.
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - address
                    - nonce
                    - chainId
                  additionalProperties: false
                  description: >-
                    Signs an authorization tuple for type 4 set code transaction
                    defined in
                    [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702).
                  title: EIP-7702 Authorization
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - Snip12
                    primaryType:
                      type: string
                      description: The primary type of the message.
                    types:
                      type: object
                      additionalProperties:
                        type: array
                        items:
                          type: object
                          properties:
                            name:
                              type: string
                            type:
                              type: string
                          required:
                            - name
                            - type
                          additionalProperties: false
                      description: Type definitions.
                    domain:
                      type: object
                      properties:
                        name:
                          type: string
                          description: Name of the signing domain.
                        version:
                          type: string
                          description: Current major version of the signing domain.
                        chainId:
                          anyOf:
                            - type: integer
                              exclusiveMinimum: 0
                            - type: string
                          description: Chain ID.
                        revision:
                          anyOf:
                            - type: number
                            - type: string
                          description: Revision of the domain.
                      description: Domain separator.
                    message:
                      type: object
                      additionalProperties: {}
                      description: Structured message to sign.
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - primaryType
                    - types
                    - domain
                    - message
                  additionalProperties: false
                  description: >-
                    Signs a typed structured data as defined in
                    [SNIP-12](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-12.md).
                  title: SNIP-12 TypedData
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - Psbt
                    psbt:
                      type: string
                      pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                      description: The hex encoded PSBT.
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - psbt
                  additionalProperties: false
                  description: Signs a partially signed Bitcoin / Litecoin transaction.
                  title: PSBT
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - Bip322
                    message:
                      type: string
                      pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                      description: The generic message hex encoded.
                    format:
                      type: string
                      enum:
                        - Simple
                        - Full
                      description: >-
                        Defaults to Simple if not present. The formatted
                        signature is returned in the `signedData` field in the
                        response.
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - message
                  additionalProperties: false
                  description: >-
                    Signs a generic message using
                    [BIP-322](https://github.com/bitcoin/bips/blob/master/bip-0322.mediawiki).
                    Note: signing payload construction depends on the targeted
                    blockchain. Therefore it's tied to a specific `network`
                    rather than the blockchain kind.
                  title: BIP-322
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - SignDocDirect
                    signDoc:
                      type: string
                      pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                      description: The hex encoded `SignDoc` Protobuf.
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - signDoc
                  additionalProperties: false
                  description: >-
                    Signs an unsigned transaction using [sign mode
                    direct](https://docs.cosmos.network/main/learn/advanced/transactions#sign_mode_direct-preferred).
                  title: SignDocDirect
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - SignerPayload
                    payload:
                      anyOf:
                        - type: string
                          pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                        - type: object
                          properties: {}
                      description: >
                        The unsigned Signer Payload formatted as JSON, or as a
                        serialized hex-encoded buffer.


                        Please refer to the original Polkadot definition for
                        more details:
                        [SignerPayloadJson](https://github.com/polkadot-js/api/blob/v16.2.2/packages/types/src/types/extrinsic.ts#L32).
                        Note that additional fields will be rejected.


                        | Field                |
                        Description                                                                             
                        | Type - Optional      |

                        | -------------------- |
                        ----------------------------------------------------------------------------------------
                        | -------------------- |

                        | `address`            | ss58-encoded address of the
                        sending
                        account.                                             |
                        String               |

                        | `blockHash`          | The hash of the checkpoint
                        block, hex
                        encoded.                                           |
                        String               |

                        | `blockNumber`        | The checkpoint block number,
                        hex
                        encoded.                                               
                        | String               |

                        | `era`                | The number of blocks after the
                        checkpoint for which a transaction is valid, hex
                        encoded. | String               |

                        | `genesisHash`        | The genesis hash of the chain,
                        hex
                        encoded.                                              |
                        String               |

                        | `metadataHash`       | The metadataHash for the
                        CheckMetadataHash SignedExtension, hex
                        encoded.                 | String *(optional)*  |

                        | `mode`               | flag indicating whether to
                        verify the metadata hash or
                        not.                              | Integer *(optional)*
                        |

                        | `method`             | The encoded method with
                        arguments, hex
                        encoded.                                          |
                        String               |

                        | `nonce`              | The nonce for the transaction,
                        hex
                        encoded.                                              |
                        String               |

                        | `tip`                | The tip to increase transaction
                        priority, hex encoded.                                  
                        | String               |

                        | `version`            | The version of the
                        extrinsic.                                                           
                        | Integer              |

                        | `specVersion`        | The current spec version for
                        the runtime, hex
                        encoded.                                   |
                        String               |

                        | `transactionVersion` | The current transaction version
                        for the runtime, hex encoded.                           
                        | String               |

                        | `signedExtensions`   | The applicable signed
                        extensions for this
                        runtime.                                       |
                        Array<String>       |


                        ```json

                        {
                          "network": "Polymesh",
                          "kind": "SignerPayload",
                          "payload": {
                            "address": "5H5tTnmLUqRgvTZvTwCdBKYjKLBm2gkp7u38Q9UUdJa8m6rX",
                            "blockHash": "0x2ace05e703aa50b48c0ccccfc8b424f7aab9a1e2c424ed12e45d20b1e8ffd0d6",
                            "blockNumber": "0x00000000",
                            "era": "0x00",
                            "genesisHash": "0x2ace05e703aa50b48c0ccccfc8b424f7aab9a1e2c424ed12e45d20b1e8ffd0d6",
                            "method": "0x07141f3da32e72ac6eb6cb40d9e757594363a617b2c3964a2b6ec6895c6648f48d500000",
                            "nonce": "0x00000000",
                            "tip": "0x00000000000000000000000000000000",
                            "version": 4,
                            "specVersion": "0x006adb7a",
                            "transactionVersion": "0x00000007",
                            "signedExtensions": []
                          }
                        }

                        ```
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - payload
                  additionalProperties: false
                  description: >-
                    Signs a [generic Signer
                    Payload](https://github.com/polkadot-js/api/blob/v15.0.1/packages/types/src/extrinsic/SignerPayload.ts#L47-L51).
                    Note: converting the generic signer payload to a signable
                    extrinsic requires fetching metadata from the targeted
                    blockchain. Therefore it's tied to a specific `network`
                    rather than the blockchain kind.
                  title: SignerPayload
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - Cip8
                    payload:
                      type: string
                      pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                      description: The generic message hex encoded.
                    externalAad:
                      type: string
                      pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                      description: >-
                        Allows an application to ask the user to sign some extra
                        data but NOT put it inside the COSE structure (only as
                        part of the data to sign).
                    context:
                      type: string
                      enum:
                        - Signature1
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - context
                  additionalProperties: false
                  description: >-
                    Signs an arbitrary message using
                    [CIP-8](https://cips.cardano.org/cip/CIP-0008). Note:
                    signing address depends on the targeted blockchain.
                    Therefore it's tied to a specific `network` rather than the
                    blockchain kind.
                  title: CIP-8
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - DfnsSmartAccountTransaction
                    structured:
                      type: object
                      properties:
                        address:
                          type: string
                        userOperations:
                          type: array
                          items:
                            type: object
                            properties:
                              to:
                                type: string
                              value:
                                type: string
                              data:
                                type: string
                            required:
                              - to
                        message:
                          type: object
                          properties:
                            kind:
                              type: string
                              enum:
                                - Eip712
                            domain:
                              type: object
                              properties:
                                name:
                                  type: string
                                version:
                                  type: string
                                chainId:
                                  anyOf:
                                    - type: number
                                    - type: string
                                verifyingContract:
                                  type: string
                                salt:
                                  type: string
                            types:
                              type: object
                              additionalProperties:
                                type: array
                                items:
                                  type: object
                                  properties:
                                    name:
                                      type: string
                                    type:
                                      type: string
                                  required:
                                    - name
                                    - type
                            message:
                              type: object
                              additionalProperties: {}
                          required:
                            - kind
                            - domain
                            - types
                            - message
                        authorization:
                          type: object
                          properties:
                            kind:
                              type: string
                              enum:
                                - Eip7702
                            address:
                              type: string
                            nonce:
                              type: number
                            chainId:
                              type: number
                          required:
                            - kind
                            - address
                            - nonce
                            - chainId
                      required:
                        - address
                        - userOperations
                        - message
                    signatures:
                      type: object
                      additionalProperties:
                        type: object
                        properties:
                          r:
                            type: string
                            description: The `r` component of the signature, hex encoded.
                          s:
                            type: string
                            description: The `s` component of the signature, hex encoded.
                          recid:
                            type: number
                            description: >-
                              The recovery id, returned for ECDSA signatures on
                              networks that need it to recover the signing
                              public key.
                          encoded:
                            type: string
                            description: >-
                              The signature already serialized in the format the
                              target network expects, hex encoded and ready to
                              use directly. For EdDSA (Ed25519) networks such as
                              Solana this is the raw 64-byte `r || s`
                              concatenation, where `r` and `s` are each a fixed
                              32 bytes. It is not ASN.1/DER encoded, so no DER
                              parsing or re-padding of the components is needed.
                        required:
                          - r
                          - s
                    transactionReference:
                      type: string
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - structured
                    - signatures
                    - transactionReference
                  additionalProperties: false
                  title: Dfns Smart Account Transaction
                - type: object
                  properties:
                    kind:
                      type: string
                      enum:
                        - StellarFeeBumpTransaction
                    innerTransaction:
                      type: string
                    transactionReference:
                      type: string
                    network:
                      $ref: '#/components/schemas/Network'
                    blockchainKind:
                      $ref: '#/components/schemas/BlockchainKind'
                    externalId:
                      type: string
                      minLength: 1
                      maxLength: 50
                      description: >-
                        A unique ID from your system. It can be leveraged to be
                        used as an idempotency key (read more
                        [here](https://docs.dfns.co/api-reference/idempotency)).
                  required:
                    - kind
                    - innerTransaction
                    - transactionReference
                  additionalProperties: false
                  title: Stellar Fee Bump Transaction
            examples:
              Bip322:
                value:
                  network: BitcoinSignet
                  kind: Bip322
                  message: '0x49206c6f76652044666e73'
              Cip8:
                value:
                  network: CardanoPreprod
                  kind: Cip8
                  payload: '0x49206c6f76652044666e73'
                  externalAad: '0x616464697469706e616c5f64617461'
                  context: Signature1
              Eip191:
                value:
                  blockchainKind: Evm
                  kind: Eip191
                  message: '0x49206c6f76652044666e73'
              Eip712:
                value:
                  blockchainKind: Evm
                  kind: Eip712
                  types:
                    Person:
                      - name: name
                        type: string
                      - name: wallet
                        type: address
                    Mail:
                      - name: from
                        type: Person
                      - name: to
                        type: Person
                      - name: contents
                        type: string
                  domain:
                    name: Ether Mail
                    version: '1'
                    chainId: 1
                    verifyingContract: '0x1b352de7a926ebd1bf52194dab487c2cb0793a9b'
                    salt: >-
                      0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558
                  message:
                    from:
                      name: Chris
                      wallet: '0x00e3495cf6af59008f22ffaf32d4c92ac33dac47'
                    to:
                      name: Bob
                      wallet: '0xcc0ee1a1c5e788b61916c8f1c96c960f9a9d3db7'
                    contents: Hello, Bob!
              Eip7702:
                value:
                  blockchainKind: Evm
                  kind: Eip7702
                  chainId: 1
                  address: '0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e'
                  nonce: 0
              Hash:
                value:
                  kind: Hash
                  hash: >-
                    0xd356339fa071e88335fdfab167cb600430522b71839d8556fa351fe1b4cd7556
              Message:
                value:
                  blockchainKind: Evm
                  kind: Message
                  message: '0x49206c6f76652044666e73'
              Psbt:
                value:
                  blockchainKind: Bitcoin
                  kind: Psbt
                  psbt: >-
                    0x70736274ff0100db02000000019fc89619065ef6b81415397bb9879dfc78cacbaae66072d69eb619bfd79d5cba0200000000fdffffff0350c3000000000000225120cc8f48c274c1ac263046c301cb9e028979c8e89c4060b4b857c414ed6e7b43760000000000000000496a476262743400223d31efd004ca86999dedb0b32445f8ead685b4e99d92ec19ea0e211afd9672a99172cdc13644990aabe785f1595843de7f884249a28cc3170112e7a018b0c6fa00a2171b0000000000225120223d31efd004ca86999dedb0b32445f8ead685b4e99d92ec19ea0e211afd9672dd5d03000001012b9ceb1b0000000000225120223d31efd004ca86999dedb0b32445f8ead685b4e99d92ec19ea0e211afd9672011720223d31efd004ca86999dedb0b32445f8ead685b4e99d92ec19ea0e211afd967200000000
              Hash (Schnorr):
                value:
                  kind: Hash
                  hash: >-
                    0xd356339fa071e88335fdfab167cb600430522b71839d8556fa351fe1b4cd7556
                  taprootMerkleRoot: ''
              Transaction:
                value:
                  blockchainKind: Evm
                  kind: Transaction
                  transaction: >-
                    0xe703847735941a82520894f0965f5eb35ace69f01b77031f2cff22daca622887470de4df82000080
              Transaction (EVM JSON):
                value:
                  blockchainKind: Evm
                  kind: Transaction
                  transaction:
                    to: '0xd964d741998edc275f3800eed113378a391951d9'
                    value: '20000000000000000'
                    nonce: '3'
                    gasLimit: '21000'
                    maxFeePerGas: '2000000000'
                    maxPriorityFeePerGas: '1000000000'
              Transaction (Concordium JSON):
                value:
                  blockchainKind: Concordium
                  kind: Transaction
                  transaction:
                    header:
                      sender: 4FmiTW2L2AccyR36ZBRKNqwQvBJBH8CAXWMLB1dbX5WyZmRo6N
                      nonce: '42'
                      expiry: 1709510400
                      executionEnergyAmount: '501'
                    payload:
                      Transfer:
                        amount: '1000000'
                        toAddress: 3U4sfVSqGG6XK8g6eho2qRYtnHc4MWJBG1dfxdtPGbfHwFxini
              Transaction (Starknet JSON):
                value:
                  blockchainKind: Starknet
                  kind: Transaction
                  transaction:
                    type: INVOKE
                    calldata:
                      - '1'
                      - >-
                        2009894490435840142178314390393166646092438090257831307886760648929397478285
                      - >-
                        232670485425082704932579856502088130646006032362877466777181098476241604910
                      - '3'
                      - >-
                        296727860213112272332383824629975240127004024814636931420022890499591637514
                      - '1'
                      - '0'
                    nonce: '0x51'
                    version: '0x3'
                    resourceBounds:
                      l1Gas:
                        maxAmount: '0x0'
                        maxPricePerUnit: '0x239a01ff6e6c'
                      l2Gas:
                        maxAmount: '0x1694a0'
                        maxPricePerUnit: '0x10c388d00'
                      l1DataGas:
                        maxAmount: '0x120'
                        maxPricePerUnit: '0x98e8'
                    tip: '0x0'
                    paymasterData: []
                    accountDeploymentData: []
                    nonceDataAvailabilityMode: L1
                    feeDataAvailabilityMode: L1
                    chainId: '0x534e5f5345504f4c4941'
                    senderAddress: >-
                      0x0535a9762b984c876abe0b164b0ccedb0d23a78978c9fe87e29deae0ea890c72
              SignerPayload:
                value:
                  network: PolymeshTestnet
                  kind: SignerPayload
                  payload:
                    address: 5ELwJvCPKBxLm3rve77JGDmHv2FNNE2nUW17FXhBs7Tws4Cr
                    blockHash: >-
                      0x2ace05e703aa50b48c0ccccfc8b424f7aab9a1e2c424ed12e45d20b1e8ffd0d6
                    blockNumber: '0x00000000'
                    era: '0x00'
                    genesisHash: >-
                      0x2ace05e703aa50b48c0ccccfc8b424f7aab9a1e2c424ed12e45d20b1e8ffd0d6
                    method: >-
                      0x07141f3da32e72ac6eb6cb40d9e757594363a617b2c3964a2b6ec6895c6648f48d500000
                    mode: 0
                    nonce: '0x00000000'
                    tip: '0x00000000000000000000000000000000'
                    specVersion: '0x006adb7a'
                    transactionVersion: '0x00000007'
                    version: 4
                    signedExtensions: []
              Snip12:
                value:
                  blockchainKind: Starknet
                  kind: Snip12
                  primaryType: Mail
                  types:
                    StarkNetDomain:
                      - name: name
                        type: felt
                      - name: version
                        type: felt
                      - name: chainId
                        type: felt
                      - name: revision
                        type: felt
                    Person:
                      - name: name
                        type: felt
                      - name: wallet
                        type: felt
                    Mail:
                      - name: from
                        type: Person
                      - name: to
                        type: Person
                      - name: contents
                        type: felt
                  domain:
                    name: StarkNet Mail
                    version: '1'
                    chainId: '0x534e5f4d41494e'
                    revision: 1
                  message:
                    from:
                      name: Alice
                      wallet: '0x1234567890123456789012345678901234567890'
                    to:
                      name: Bob
                      wallet: '0x0987654321098765432109876543210987654321'
                    contents: Hello Bob!
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SignatureRequest'
      security:
        - authenticationToken: []
          userActionSignature: []
components:
  schemas:
    Network:
      type: string
      title: Network
      enum:
        - Algorand
        - AlgorandTestnet
        - Aptos
        - AptosTestnet
        - ArbitrumOne
        - ArbitrumSepolia
        - Arc
        - ArcTestnet
        - Areum
        - AvalancheC
        - AvalancheCFuji
        - Base
        - BaseSepolia
        - Berachain
        - BerachainBepolia
        - Bitcoin
        - BitcoinSignet
        - BitcoinTestnet4
        - BitcoinCash
        - Bob
        - BobSepolia
        - Bsc
        - BscTestnet
        - Canton
        - CantonTestnet
        - Cardano
        - CardanoPreprod
        - Concordium
        - ConcordiumTestnet
        - Celo
        - CeloSepolia
        - Codex
        - CodexSepolia
        - CosmosHub4
        - CosmosIcsTestnet
        - Dogecoin
        - DogecoinTestnet
        - Ethereum
        - EthereumClassic
        - EthereumClassicMordor
        - EthereumSepolia
        - EthereumHoodi
        - FlareC
        - FlareCCoston2
        - FlowEvm
        - FlowEvmTestnet
        - Hedera
        - HederaTestnet
        - HyperEvm
        - HyperEvmTestnet
        - Ink
        - InkSepolia
        - InternetComputer
        - Ion
        - IonTestnet
        - Iota
        - IotaTestnet
        - Kusama
        - KusamaAssetHub
        - Litecoin
        - LitecoinTestnet
        - Monad
        - MonadTestnet
        - Movement
        - MovementTestnet
        - Near
        - NearTestnet
        - Optimism
        - OptimismSepolia
        - Origyn
        - Plasma
        - PlasmaTestnet
        - Plume
        - PlumeSepolia
        - Paseo
        - PaseoAssetHub
        - Polkadot
        - PolkadotAssetHub
        - Polygon
        - PolygonAmoy
        - Polymesh
        - PolymeshTestnet
        - Rayls
        - RaylsTestnet
        - Robinhood
        - RobinhoodSepolia
        - SeiAtlantic2
        - SeiPacific1
        - Solana
        - SolanaDevnet
        - Sonic
        - SonicTestnet
        - Starknet
        - StarknetSepolia
        - Stellar
        - StellarTestnet
        - Sui
        - SuiTestnet
        - Tezos
        - TezosShadownet
        - Tempo
        - TempoModerato
        - Tsc
        - TscTestnet1
        - Ton
        - TonTestnet
        - Tron
        - TronNile
        - Westend
        - WestendAssetHub
        - Xdc
        - XdcApothem
        - XLayer
        - XLayerSepolia
        - XrpLedger
        - XrpLedgerTestnet
    BlockchainKind:
      type: string
      enum:
        - Algorand
        - Aptos
        - Bitcoin
        - BitcoinCash
        - Canton
        - Cardano
        - Concordium
        - Cosmos
        - Evm
        - Hedera
        - Icp
        - Iota
        - Kaspa
        - Near
        - Polymesh
        - Solana
        - Starknet
        - Stellar
        - Substrate
        - Sui
        - Tezos
        - Ton
        - Tron
        - Xrpl
    SignatureRequest:
      type: object
      properties:
        id:
          type: string
          minLength: 1
          maxLength: 64
          pattern: ^sig-[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{14,16}$
          description: Signature id.
          example: sig-4sfvl-f4iha-umighfi3hk4t54dr
        keyId:
          type: string
          minLength: 1
          maxLength: 64
          pattern: ^key-[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{14,16}$
          description: Key id.
          example: key-01snl-t56gb-j8tsok0vn802p80i
        requester:
          $ref: '#/components/schemas/Requester'
        requestBody:
          oneOf:
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - Hash
                hash:
                  type: string
                  pattern: ^(0x)?[0-9a-fA-F]{64}$
                  description: 32-byte hash in hex encoded format.
                taprootMerkleRoot:
                  type: string
                  pattern: ^(0x)?([0-9A-Fa-f]{64})?$
                  description: >-
                    Required when signing with a Schnorr key. Specify the merkle
                    root for tweaking the signing key, or the empty string "" to
                    tweak with the default merkle root.
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - hash
              additionalProperties: false
              description: >-
                All cryptographic scheme support hash signing. Different
                blockchains will apply different hash functions to compute the
                hash.
              title: Hash
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - Message
                message:
                  type: string
                  pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                  description: An arbitrary hex encoded message.
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - message
              additionalProperties: false
              description: Signs an arbitrary hex encoded arbitrary message.
              title: Message
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - Transaction
                transaction:
                  anyOf:
                    - type: string
                      pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                    - type: object
                      properties: {}
                      description: >-
                        Network-specific JSON transaction object. The accepted
                        fields depend on the target network. For EVM chains the
                        shape matches the EVM transaction object of [Sign and
                        Broadcast
                        Transaction](https://docs.dfns.co/api-reference/wallets/sign-and-broadcast-transaction)
                        (for example `to`, `value`, `data`, `nonce`, `gasLimit`,
                        `maxFeePerGas`, `maxPriorityFeePerGas`). For other JSON
                        networks (such as Starknet or Concordium), refer to the
                        per-network formats described below.
                      title: JSON transaction object
                  description: >-
                    The unsigned hex-encoded transaction or JSON object for
                    compatible networks
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - transaction
              additionalProperties: false
              description: >-
                Signs an unsigned transaction. The transaction parameter accepts
                hex-encoded transactions or JSON objects for compatible networks
                (Concordium, Starknet, Evm).


                The following blockchains only accept JSON transaction objects
                (not hex strings): Concordium, Starknet.


                For Starknet transactions, you may use invocation request
                objects
                (https://github.com/starkware-libs/starknet-specs/blob/v0.8.1/api/starknet_api_openrpc.json#L2621):


                | Field                         |
                Description                                                                                        
                | Type - Optional                  |

                |-------------------------------|-----------------------------------------------------------------------------------------------------|----------------------------------|

                | type                          | transaction type (always
                INVOKE             
                )                                                      | String
                (required)                |

                | calldata                      | **Array** of encoded function
                call
                parameters                                                      
                | **Array of Strings** (required)  |

                | nonce                         | Transaction nonce in hex
                format                                                                    
                | String (required)                |

                | version                       | Transaction version in hex
                format. Typically "0x3" for current
                transactions                         | String
                (required)                |

                | resourceBounds                | Gas bounds for L1, L2, and L1
                data
                gas                                                             
                | Object (required)                |

                | ↳ resourceBounds.l1Gas        | L1 gas configuration with
                maxAmount and
                maxPricePerUnit                                             |
                Object (required)                |

                | ↳ resourceBounds.l2Gas        | L2 gas configuration with
                maxAmount and
                maxPricePerUnit                                             |
                Object (required)                |

                | ↳ resourceBounds.l1DataGas    | L1 data gas configuration with
                maxAmount and
                maxPricePerUnit                                        | Object
                (required)                |

                | tip                           | Transaction tip in hex format.
                Typically
                "0x0"                                                      |
                String (required)                |

                | paymasterData                 | Paymaster data
                array                                                                               
                | Array of Strings (required)      |

                | accountDeploymentData         | Account deployment data
                array                                                                      
                | Array of Strings (required)      |

                | nonceDataAvailabilityMode     | Data availability mode for
                nonce. Typically "L1" for
                now                                            | String
                (required)                |

                | feeDataAvailabilityMode       | Data availability mode for
                fee. Typically "L1" for
                now                                              | String
                (required)                |

                | chainId                       | The chain identifier in hex
                format                                                                 
                | String (required)                |

                | senderAddress                 | The address of the account
                sending the
                transaction                                                  |
                String (required)                |


                For Concordium transactions, use account transaction objects
                (https://developer.concordium.software/concordium-node-sdk-js/classes/ccd_js_gen.ConcordiumGRPCClient.html):


                | Field                          |
                Description                                                                 
                | Type - Optional              |

                |--------------------------------|------------------------------------------------------------------------------|------------------------------|

                | header.sender                  | Account address
                (base58)                                                     |
                String (required)            |

                | header.nonce                   | Account
                nonce                                                               
                | String (required)            |

                | header.expiry                  | Unix epoch seconds
                expiry                                                    |
                Number (required)            |

                | header.executionEnergyAmount   | Max NRG for
                execution                                                       
                | String (required)            |

                | header.numSignatures           | Number of
                signatures                                                        
                | Number (optional)            |

                | payload                        | Transaction payload
                (type-specific, e.g. Transfer, RegisterData)             |
                Object (required)            |


                ```json

                {
                  "kind": "Transaction",
                  "blockchainKind": "Concordium",
                  "transaction": {
                    "header": {
                      "sender": "4FmiTW2L2AccyR36ZBRKNqwQvBJBH8CAXWMLB1dbX5WyZmRo6N",
                      "nonce": "42",
                      "expiry": 1709510400,
                      "executionEnergyAmount": "501"
                    },
                    "payload": {
                      "Transfer": {
                        "amount": "1000000",
                        "toAddress": "3U4sfVSqGG6XK8g6eho2qRYtnHc4MWJBG1dfxdtPGbfHwFxini"
                      }
                    }
                  }
                }

                ```


                ```json

                {
                  "kind": "Transaction",
                  "transaction": "0xe703847735941a82520894f0965f5eb35ace69f01b77031f2cff22daca622887470de4df82000080"
                }

                ```


                ```json

                {
                  "kind": "Transaction",
                  "transaction": {
                    "type": "INVOKE",
                    "calldata": [
                      "1",
                      "2009894490435840142178314390393166646092438090257831307886760648929397478285",
                      "232670485425082704932579856502088130646006032362877466777181098476241604910",
                      "3",
                      "296727860213112272332383824629975240127004024814636931420022890499591637514",
                      "1",
                      "0"
                    ],
                    "nonce": "0x51",
                    "version": "0x3",
                    "resourceBounds": {
                      "l1Gas": { "maxAmount": "0x0", "maxPricePerUnit": "0x239a01ff6e6c" },
                      "l2Gas": { "maxAmount": "0x1694a0", "maxPricePerUnit": "0x10c388d00" },
                      "l1DataGas": { "maxAmount": "0x120", "maxPricePerUnit": "0x98e8" }
                    },
                    "tip": "0x0",
                    "paymasterData": [],
                    "accountDeploymentData": [],
                    "nonceDataAvailabilityMode": "L1",
                    "feeDataAvailabilityMode": "L1",
                    "chainId": "0x534e5f5345504f4c4941",
                    "senderAddress": "0x0535a9762b984c876abe0b164b0ccedb0d23a78978c9fe87e29deae0ea890c72"
                  }
                }

                ```
              title: Transaction
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - Eip191
                message:
                  type: string
                  pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                  description: Hex-encoded message.
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - message
              additionalProperties: false
              description: >-
                Signs a personal_sign message as defined in
                [EIP-191](https://eips.ethereum.org/EIPS/eip-191).
              title: EIP-191 personal_sign Message
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - Eip712
                types:
                  type: object
                  additionalProperties:
                    type: array
                    items:
                      type: object
                      properties:
                        name:
                          type: string
                        type:
                          type: string
                      required:
                        - name
                        - type
                      additionalProperties: false
                  description: Type definitions.
                domain:
                  type: object
                  properties:
                    name:
                      type: string
                      description: Name of the signing domain.
                    version:
                      type: string
                      description: Current major version of the signing domain.
                    chainId:
                      anyOf:
                        - type: integer
                          exclusiveMinimum: 0
                        - type: string
                      description: Chain ID.
                    verifyingContract:
                      type: string
                      pattern: ^0x[0-9a-fA-F]{40}$
                      description: >-
                        The address of the contract that will verify the
                        signature.
                    salt:
                      type: string
                      pattern: ^0x[0-9a-fA-F]{64}$
                      description: 32-byte value as a last-resort domain separator.
                  additionalProperties: false
                  description: Domain separator.
                message:
                  type: object
                  additionalProperties: {}
                  description: Structured message to sign.
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - types
                - domain
                - message
              additionalProperties: false
              description: >-
                Signs a typed structured data as defined in
                [EIP-712](https://eips.ethereum.org/EIPS/eip-712).
              title: EIP-712 TypedData
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - Eip7702
                address:
                  type: string
                  pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                  description: >-
                    The address of the contract the signer's EOA will be
                    delegated to.
                nonce:
                  type: number
                  description: The current nonce of the signer EOA.
                chainId:
                  type: number
                  description: Chain ID.
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - address
                - nonce
                - chainId
              additionalProperties: false
              description: >-
                Signs an authorization tuple for type 4 set code transaction
                defined in [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702).
              title: EIP-7702 Authorization
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - Snip12
                primaryType:
                  type: string
                  description: The primary type of the message.
                types:
                  type: object
                  additionalProperties:
                    type: array
                    items:
                      type: object
                      properties:
                        name:
                          type: string
                        type:
                          type: string
                      required:
                        - name
                        - type
                      additionalProperties: false
                  description: Type definitions.
                domain:
                  type: object
                  properties:
                    name:
                      type: string
                      description: Name of the signing domain.
                    version:
                      type: string
                      description: Current major version of the signing domain.
                    chainId:
                      anyOf:
                        - type: integer
                          exclusiveMinimum: 0
                        - type: string
                      description: Chain ID.
                    revision:
                      anyOf:
                        - type: number
                        - type: string
                      description: Revision of the domain.
                  description: Domain separator.
                message:
                  type: object
                  additionalProperties: {}
                  description: Structured message to sign.
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - primaryType
                - types
                - domain
                - message
              additionalProperties: false
              description: >-
                Signs a typed structured data as defined in
                [SNIP-12](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-12.md).
              title: SNIP-12 TypedData
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - Psbt
                psbt:
                  type: string
                  pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                  description: The hex encoded PSBT.
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - psbt
              additionalProperties: false
              description: Signs a partially signed Bitcoin / Litecoin transaction.
              title: PSBT
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - Bip322
                message:
                  type: string
                  pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                  description: The generic message hex encoded.
                format:
                  type: string
                  enum:
                    - Simple
                    - Full
                  description: >-
                    Defaults to Simple if not present. The formatted signature
                    is returned in the `signedData` field in the response.
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - message
              additionalProperties: false
              description: >-
                Signs a generic message using
                [BIP-322](https://github.com/bitcoin/bips/blob/master/bip-0322.mediawiki).
                Note: signing payload construction depends on the targeted
                blockchain. Therefore it's tied to a specific `network` rather
                than the blockchain kind.
              title: BIP-322
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - SignDocDirect
                signDoc:
                  type: string
                  pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                  description: The hex encoded `SignDoc` Protobuf.
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - signDoc
              additionalProperties: false
              description: >-
                Signs an unsigned transaction using [sign mode
                direct](https://docs.cosmos.network/main/learn/advanced/transactions#sign_mode_direct-preferred).
              title: SignDocDirect
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - SignerPayload
                payload:
                  anyOf:
                    - type: string
                      pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                    - type: object
                      properties: {}
                  description: >
                    The unsigned Signer Payload formatted as JSON, or as a
                    serialized hex-encoded buffer.


                    Please refer to the original Polkadot definition for more
                    details:
                    [SignerPayloadJson](https://github.com/polkadot-js/api/blob/v16.2.2/packages/types/src/types/extrinsic.ts#L32).
                    Note that additional fields will be rejected.


                    | Field                |
                    Description                                                                             
                    | Type - Optional      |

                    | -------------------- |
                    ----------------------------------------------------------------------------------------
                    | -------------------- |

                    | `address`            | ss58-encoded address of the sending
                    account.                                             |
                    String               |

                    | `blockHash`          | The hash of the checkpoint block,
                    hex encoded.                                           |
                    String               |

                    | `blockNumber`        | The checkpoint block number, hex
                    encoded.                                                |
                    String               |

                    | `era`                | The number of blocks after the
                    checkpoint for which a transaction is valid, hex encoded. |
                    String               |

                    | `genesisHash`        | The genesis hash of the chain, hex
                    encoded.                                              |
                    String               |

                    | `metadataHash`       | The metadataHash for the
                    CheckMetadataHash SignedExtension, hex
                    encoded.                 | String *(optional)*  |

                    | `mode`               | flag indicating whether to verify
                    the metadata hash or not.                              |
                    Integer *(optional)* |

                    | `method`             | The encoded method with arguments,
                    hex encoded.                                          |
                    String               |

                    | `nonce`              | The nonce for the transaction, hex
                    encoded.                                              |
                    String               |

                    | `tip`                | The tip to increase transaction
                    priority, hex encoded.                                   |
                    String               |

                    | `version`            | The version of the
                    extrinsic.                                                           
                    | Integer              |

                    | `specVersion`        | The current spec version for the
                    runtime, hex encoded.                                   |
                    String               |

                    | `transactionVersion` | The current transaction version for
                    the runtime, hex encoded.                            |
                    String               |

                    | `signedExtensions`   | The applicable signed extensions
                    for this runtime.                                       |
                    Array<String>       |


                    ```json

                    {
                      "network": "Polymesh",
                      "kind": "SignerPayload",
                      "payload": {
                        "address": "5H5tTnmLUqRgvTZvTwCdBKYjKLBm2gkp7u38Q9UUdJa8m6rX",
                        "blockHash": "0x2ace05e703aa50b48c0ccccfc8b424f7aab9a1e2c424ed12e45d20b1e8ffd0d6",
                        "blockNumber": "0x00000000",
                        "era": "0x00",
                        "genesisHash": "0x2ace05e703aa50b48c0ccccfc8b424f7aab9a1e2c424ed12e45d20b1e8ffd0d6",
                        "method": "0x07141f3da32e72ac6eb6cb40d9e757594363a617b2c3964a2b6ec6895c6648f48d500000",
                        "nonce": "0x00000000",
                        "tip": "0x00000000000000000000000000000000",
                        "version": 4,
                        "specVersion": "0x006adb7a",
                        "transactionVersion": "0x00000007",
                        "signedExtensions": []
                      }
                    }

                    ```
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - payload
              additionalProperties: false
              description: >-
                Signs a [generic Signer
                Payload](https://github.com/polkadot-js/api/blob/v15.0.1/packages/types/src/extrinsic/SignerPayload.ts#L47-L51).
                Note: converting the generic signer payload to a signable
                extrinsic requires fetching metadata from the targeted
                blockchain. Therefore it's tied to a specific `network` rather
                than the blockchain kind.
              title: SignerPayload
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - Cip8
                payload:
                  type: string
                  pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                  description: The generic message hex encoded.
                externalAad:
                  type: string
                  pattern: ^(0x)?([0-9a-fA-F][0-9a-fA-F])*$
                  description: >-
                    Allows an application to ask the user to sign some extra
                    data but NOT put it inside the COSE structure (only as part
                    of the data to sign).
                context:
                  type: string
                  enum:
                    - Signature1
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - context
              additionalProperties: false
              description: >-
                Signs an arbitrary message using
                [CIP-8](https://cips.cardano.org/cip/CIP-0008). Note: signing
                address depends on the targeted blockchain. Therefore it's tied
                to a specific `network` rather than the blockchain kind.
              title: CIP-8
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - DfnsSmartAccountTransaction
                structured:
                  type: object
                  properties:
                    address:
                      type: string
                    userOperations:
                      type: array
                      items:
                        type: object
                        properties:
                          to:
                            type: string
                          value:
                            type: string
                          data:
                            type: string
                        required:
                          - to
                    message:
                      type: object
                      properties:
                        kind:
                          type: string
                          enum:
                            - Eip712
                        domain:
                          type: object
                          properties:
                            name:
                              type: string
                            version:
                              type: string
                            chainId:
                              anyOf:
                                - type: number
                                - type: string
                            verifyingContract:
                              type: string
                            salt:
                              type: string
                        types:
                          type: object
                          additionalProperties:
                            type: array
                            items:
                              type: object
                              properties:
                                name:
                                  type: string
                                type:
                                  type: string
                              required:
                                - name
                                - type
                        message:
                          type: object
                          additionalProperties: {}
                      required:
                        - kind
                        - domain
                        - types
                        - message
                    authorization:
                      type: object
                      properties:
                        kind:
                          type: string
                          enum:
                            - Eip7702
                        address:
                          type: string
                        nonce:
                          type: number
                        chainId:
                          type: number
                      required:
                        - kind
                        - address
                        - nonce
                        - chainId
                  required:
                    - address
                    - userOperations
                    - message
                signatures:
                  type: object
                  additionalProperties:
                    type: object
                    properties:
                      r:
                        type: string
                        description: The `r` component of the signature, hex encoded.
                      s:
                        type: string
                        description: The `s` component of the signature, hex encoded.
                      recid:
                        type: number
                        description: >-
                          The recovery id, returned for ECDSA signatures on
                          networks that need it to recover the signing public
                          key.
                      encoded:
                        type: string
                        description: >-
                          The signature already serialized in the format the
                          target network expects, hex encoded and ready to use
                          directly. For EdDSA (Ed25519) networks such as Solana
                          this is the raw 64-byte `r || s` concatenation, where
                          `r` and `s` are each a fixed 32 bytes. It is not
                          ASN.1/DER encoded, so no DER parsing or re-padding of
                          the components is needed.
                    required:
                      - r
                      - s
                transactionReference:
                  type: string
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - structured
                - signatures
                - transactionReference
              additionalProperties: false
              title: Dfns Smart Account Transaction
            - type: object
              properties:
                kind:
                  type: string
                  enum:
                    - StellarFeeBumpTransaction
                innerTransaction:
                  type: string
                transactionReference:
                  type: string
                network:
                  $ref: '#/components/schemas/Network'
                blockchainKind:
                  $ref: '#/components/schemas/BlockchainKind'
                externalId:
                  type: string
                  minLength: 1
                  maxLength: 50
                  description: >-
                    A unique ID from your system. It can be leveraged to be used
                    as an idempotency key (read more
                    [here](https://docs.dfns.co/api-reference/idempotency)).
              required:
                - kind
                - innerTransaction
                - transactionReference
              additionalProperties: false
              title: Stellar Fee Bump Transaction
        status:
          type: string
          enum:
            - Pending
            - Executing
            - Signed
            - Confirmed
            - Failed
            - Rejected
        reason:
          type: string
        signature:
          type: object
          properties:
            r:
              type: string
              description: The `r` component of the signature, hex encoded.
            s:
              type: string
              description: The `s` component of the signature, hex encoded.
            recid:
              type: number
              description: >-
                The recovery id, returned for ECDSA signatures on networks that
                need it to recover the signing public key.
            encoded:
              type: string
              description: >-
                The signature already serialized in the format the target
                network expects, hex encoded and ready to use directly. For
                EdDSA (Ed25519) networks such as Solana this is the raw 64-byte
                `r || s` concatenation, where `r` and `s` are each a fixed 32
                bytes. It is not ASN.1/DER encoded, so no DER parsing or
                re-padding of the components is needed.
          required:
            - r
            - s
        signatures:
          type: array
          items:
            type: object
            properties:
              r:
                type: string
                description: The `r` component of the signature, hex encoded.
              s:
                type: string
                description: The `s` component of the signature, hex encoded.
              recid:
                type: number
                description: >-
                  The recovery id, returned for ECDSA signatures on networks
                  that need it to recover the signing public key.
              encoded:
                type: string
                description: >-
                  The signature already serialized in the format the target
                  network expects, hex encoded and ready to use directly. For
                  EdDSA (Ed25519) networks such as Solana this is the raw
                  64-byte `r || s` concatenation, where `r` and `s` are each a
                  fixed 32 bytes. It is not ASN.1/DER encoded, so no DER parsing
                  or re-padding of the components is needed.
            required:
              - r
              - s
        signedData:
          type: string
        network:
          $ref: '#/components/schemas/Network'
        txHash:
          type: string
        fee:
          type: string
        approvalId:
          type: string
          minLength: 1
          maxLength: 64
          pattern: ^ap-[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{14,16}$
          example: ap-2a9in-tt2a1-983lho480p35ejd0
        dateRequested:
          type: string
          format: date-time
          description: >-
            [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date (must be
            UTC). When the signature was requested.
          example: '2023-04-14T20:41:28.715Z'
        datePolicyResolved:
          type: string
          format: date-time
          description: >-
            [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date (must be
            UTC). When policy evaluation resolved for this signature request
            (cleared or blocked).
          example: '2023-04-14T20:41:28.715Z'
        dateSigned:
          type: string
          format: date-time
          description: >-
            [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date (must be
            UTC). When the signature was signed.
          example: '2023-04-14T20:41:28.715Z'
        dateConfirmed:
          type: string
          format: date-time
          description: >-
            [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date (must be
            UTC). When the signature was confirmed on chain.
          example: '2023-04-14T20:41:28.715Z'
        externalId:
          type: string
        details:
          type: object
          additionalProperties: {}
          description: >-
            Structured representation of the data used to construct the
            signature (e.g. nonce, gas parameters). Shape is blockchain
            specific.
      required:
        - id
        - keyId
        - requester
        - requestBody
        - status
        - dateRequested
    Requester:
      type: object
      properties:
        userId:
          type: string
          minLength: 1
          maxLength: 64
          pattern: ^us-[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{14,16}$
          description: User id.
          example: us-6b58p-r53sr-rlrd3l5cj3uc4ome
        tokenId:
          type: string
          minLength: 1
          maxLength: 64
          pattern: ^to-[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{14,16}$
          description: Token id.
          example: to-202a0-cdo33-o65mbt6q758lvvnt
      required:
        - userId
      description: The user who initiated the request.
  securitySchemes:
    authenticationToken:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: >-
        **Bearer Token:** Used to authenticate API requests.

        More details how to generate the token: [Authentication
        flows](https://docs.dfns.co/api-reference/auth/login-flows)
    userActionSignature:
      type: apiKey
      in: header
      name: X-DFNS-USERACTION
      description: >-
        **User Action Signature:** Used to sign the change-inducing API
        requests.

        More details how to generate the token: [User Action Signing
        flows](https://docs.dfns.co/api-reference/auth/signing-flows)

````

This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.