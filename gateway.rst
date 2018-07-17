Dock Gateway Integration Guide
++++++++++++++++++++++++++++++

This is the overview of how to interact with Dock Gateway. It is presented with an example of Remote-Dock communication. For that to happen, the following routines should be handled in both Remote and Dock App.

Most of the calls require authorization with a private key. It is achieved by passing a HTTP header like the following one:
``"Authorization: PrivateKey <private-key-value>"``

Ethereum Account creation
=========================

This step is optional since an actor (person or service) may come in with a preexisting Ethereum account. In most cases, however, account creation via the Gateway will probably be the first thing to be done.

``POST /v1/account``

Example (creating two accounts in a row)::

    curl -X POST https://gateway.dock.io/v1/account

    ==> {
      "address": "3d4191255d9cf51c80d43fa2965b96f39522e8fd", 
      "private_key": "c8e092ea4d9c510d4c81c89b051810796f19d0f8b69f2b1ec0191b5d04dec688"
    }

    curl -X POST https://gateway.dock.io/v1/account
    ==> {
      "address": "496e8fccafca90e1445e9229526eb0ba200ab2ba", 
      "private_key": "071dc2ddc9fa4ea67dede870993a66339b8db2eb136d7eca62cb046549a91527"
    }

Webhook registration
====================

This step is optional. An actor may register a webhook in order to facilitate communication with the Gateway. With a webhook, events concerning the actor will be notified to the actor via a HTTP call to the endpoint that the actor provides.

``PUT /v1/webhook``

Example::

    curl -X PUT \
    -H "Content-Type: application/json" \
    -H "Authorization: PrivateKey 071dc2ddc9fa4ea67dede870993a66339b8db2eb136d7eca62cb046549a91527" \
    -d '
        {
          "payload_url": "https://gw.mooxy.com:20000/webhook",
          "secret": "lorem"
        }
    ' \
    https://gateway.dock.io/v1/webhook

    ==> (201)

Given that a webhook has been established, an example notification may look like this::

    POST <the-registered-url>
    {
        "event_name": "data-package-created",
        "event_data": {
            "connection_addr": "ea0d4db7b9bfe970bebc049bd1d00ea9169d19a3",
            "ipfs_addr": "Qm5UuVVdCZkNjWeuTx6tdr275BzdoSLRUZY93YZuu1VHhN"
        },
        "secret": "lorem"
    }

``secret`` ensures that the notification comes from the authentic source.

A webhook can be deregistered with: ``DELETE /v1/webhook'``

Connection creation
===================

In order for data to be exchanged between a pair of actors, first a connection between them must be established. This triggers a webhook notification for the receiving actor.

``POST /v1/connection {"receiver_addr": ...}``

Example::

    curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: PrivateKey c8e092ea4d9c510d4c81c89b051810796f19d0f8b69f2b1ec0191b5d04dec688" \
    -d '
        {"receiver_addr": "496e8fccafca90e1445e9229526eb0ba200ab2ba"}
    ' \
    https://gateway.dock.io/v1/connection

    ==> {
      "confirmed_at": null, 
      "connection_addr": "ea0d4db7b9bfe970bebc049bd1d00ea9169d19a3", 
      "created_at": {
        "$dt": 1526056324
      }, 
      "creator_addr": "3d4191255d9cf51c80d43fa2965b96f39522e8fd", 
      "creator_public_key": "b099815cd20f719a36cf1ee6fa38822e0b252957d919f1ef76eb15ed4069e255f2fe25ef5ad5e8685b385c908bd261af6afb4f51b4489762f1461c43582dc6bf", 
      "package_headers": [], 
      "receiver_addr": "496e8fccafca90e1445e9229526eb0ba200ab2ba", 
      "receiver_public_key": null
    }

Once created, a connection can be viewed like this (no authorization required - this info is public on the blockchain anyway)::

``GET /v1/connection/<connection_address>``

Example::

    curl -X GET https://gateway.dock.io/v1/connection/ea0d4db7b9bfe970bebc049bd1d00ea9169d19a3

    {
      "confirmed_at": null, 
      "connection_addr": "ea0d4db7b9bfe970bebc049bd1d00ea9169d19a3", 
      "created_at": {
        "$dt": 1526056324
      }, 
      "creator_addr": "3d4191255d9cf51c80d43fa2965b96f39522e8fd", 
      "creator_public_key": "b099815cd20f719a36cf1ee6fa38822e0b252957d919f1ef76eb15ed4069e255f2fe25ef5ad5e8685b385c908bd261af6afb4f51b4489762f1461c43582dc6bf", 
      "package_headers": [], 
      "receiver_addr": "496e8fccafca90e1445e9229526eb0ba200ab2ba", 
      "receiver_public_key": null
    }

Other helpers::

    GET /v1/connection/actor/all  # get all connections for the current actor
    GET /v1/connection/actor/<peer_address>/all  # get all connections between the current actor and another peer
    GET /v1/connection/actor/<peer_address>/open  # get the open connection (at most one) between the current actor and another peer

Connection confirmation
=======================

    After a connection is created, the other party must confirm - only then will it be operational. This triggers a webhook notification for the actor that initiated the connection.

    `POST /v1/connection/<connection_addr>/confirm`

    Example:

    curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: PrivateKey 071dc2ddc9fa4ea67dede870993a66339b8db2eb136d7eca62cb046549a91527" \
    https://gateway.dock.io/v1/connection/ea0d4db7b9bfe970bebc049bd1d00ea9169d19a3/confirm

    ==> (the conection JSON)

Data package creation
=====================

With a working connection, one actor can produce a data package so that the other actor can read it. The data will be encrypted for that specific recipient, stored on IPFS (for now mocked) and the header describing it will be placed on the blockchain (for now also mocked). The same header info will be returned by the Gateway upon the data package creation. This triggers a webhook notification for the receiving actor.

``POST /v1/connection/<connection_addr>/packages``

Example::

    curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: PrivateKey c8e092ea4d9c510d4c81c89b051810796f19d0f8b69f2b1ec0191b5d04dec688" \
    -d '
        {
          "json_data": {"dolor": "sit", "amet": [1, 2, 3]},
          "parent_connection_addr": null
        }
    ' \
    https://gateway.dock.io/v1/connection/ea0d4db7b9bfe970bebc049bd1d00ea9169d19a3/packages
    
    ==> {
      "ipfs_addr": "Qmkcknkqd8JGUtLsKqrYfGWkXu6rfmhUBZmvaXVBLDj3M6", 
      "merkle_root": "ffb59de410d6cd1879e9f00ca10b09b410ca4077477da107ed05829d5d3dd1fcbadc1cb70e4c5f09b11705a609226112a8e042df633103d6d8c90035f05767b2"
    }

Data package retrieval
======================

    ``GET /v1/connection/<connection_addr>/packages/<ipfs_addr>'``

Example::

    curl -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: PrivateKey 071dc2ddc9fa4ea67dede870993a66339b8db2eb136d7eca62cb046549a91527" \
    https://gateway.dock.io/v1/connection/ea0d4db7b9bfe970bebc049bd1d00ea9169d19a3/packages/Qm5UuVVdCZkNjWeuTx6tdr275BzdoSLRUZY93YZuu1VHhN

    ==> {
      "json_data": {
        "amet": [
          1, 
          2, 
          3
        ], 
        "dolor": "sit"
      }
    }

Connection closing
==================

When one of the parties of a connection wants to terminate the data exchange, they can close the connection::

    ``POST /v1/connection/<connection_addr>/close``

After closing a connection may never be used again. If the parties want to connect again, they must establish a new connection.

Only one of 2 members of a connection may close it.

There may always be at most one open connection for each pair of actors.

