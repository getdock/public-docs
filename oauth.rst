Partner Integrations: Public Documentation
=========================================

The OAuth 2.0 spec defines four roles:

- Resource owner
- Resource server
- Authorization server
- Client

The following document will try to explain how Dock approaches its OAuth2 implementation.

The User
--------
The OAuth 2.0 spec refers to the user as the "resource owner". The resource owner is the person who is giving access to some portion of their account. In our case this is a user in the Dock App. The resources in our case is data: personal information, contacts, work experience, etc. Any system that wants to act on behalf of the user must first get permission from them.

The Resource Server
-------------------
What you would typically think of as the main API is called the "resource server". In our case this is the ``dockapi``: the server that contains the user's information that is being accessed by the third-party application.

The Authorization Server
------------------------
The authorization server is what the user interacts with when an application is requesting access to their account. In our case this is the ``dock-auth`` service.

The Client
----------
The Client is the 3rd party app that is attempting to act on the user's behalf, or access the user's resources. Before the Client can access the user's account, it needs to obtain permission from the user.

Client Registration
-------------------
When developers register their applications they need to provide some basic info:

- App name
- App logo
- App description

And also some URLs:

- Homepage url
- Privacy policy url
- Callback URIs (this is a list)

The given information, except for the callback URIs, is shown to the User at the Authorization Page. As for the Callback URIs: An application may have different addresses where they allow their users to login. Some may login from the application's homepage, some others may log in from other pages like their public profiles or something else. Most applications will want to have their users redirected back to the url they came from when they clicked "Login with Dock", we call those the "Callback URIs".

As a result of registering, clients are given a ``client_id`` and a ``client_secret`` that they can use to sign their requests to our api.

State Variable
--------------
Clients are encouraged to use the `state` variable to prevent CSRF attacks. A good state variable could be a self-signed string containing some simple info like:

- Current url to redirect the user to the right page once back
- User_id

The ``state`` var is returned unmodified back to the client by us, the Provider. So if they sign the ``state`` var properly, they can verify that it contains the right user id, and also a valid url to redirect to. If a CSRF attack took place, the signature will be broken and they can abort that authentication flow.

Redirect URIs
-------------
``dock-auth`` only accepts https addresses. That means that native apps are not supported for now. We'll use **exact match** only, to avoid acting as an open redirector, and it is forbidden to provide URLs containing anything after the fragment identifier.

Scopes
------
A ``scope`` is a way to limit a 3rd party app's access to a user's data. In our case we're taking a two-step approach:
1 - First we'll only accept a "basic" scope that allows access to first- and last name, email, avatar and dock user id.
2 - Once the ``dock-gateway`` is fully operational, we'll want to only share user data through the Dock protocol. For that, the "basic" scope will be modified to only contain the ETH address of the contract between the Client and the User. The Client can then use this address to go and interact with the contract directly in the Ethereum network, or ask the ``dock-gateway`` to fetch and decrypt the user data.
Partners that implement their integration during our first step, will need to adjust their implementation once we move to step 2 since these will be breaking changes.
TODO: change step 2 wording once dock-gateway is fully operational.


Basic Client Integration Flow
=============================
Clients request an ``authorization_code`` grant type by redirecting the user to the Dock Authorization Page. The user verifies the information the Client app is requesting (scope) and also see the app's name, logo and description. After approval, the user is redirected to the ``return_uri`` so the Client gets an ``authorization code`` which it can then exchange for an ``access token`` as explained before. It is mandatory that this last call takes place in the Client's backend to avoid MITM attacks. Dock will only return an ``access token`` to the right ``authorization code`` coming from the right Client, using the right client credentials.
``dock-auth`` accepts Bearer Tokens in the ``Authorization`` header. To make sense of this it can be useful to observe how a sample step-by-step flow would look like for a client getting an Access Token to act on behalf of one of its users, and then using it to get user data:

1) Authorization grant query
----------------------------
The client needs to start an authorization grant query by redirecting the user to:
``GET https://app.dock.io/oauth/authorize`` with the following url params:

- ``client_id``: id of the Client or third party app doing the request
- ``response_type=code``: 'code' is always expected. It means that the Client expects an ``authorization_code`` back as response
- ``redirect_uri``: URL where the Client wants the user to be redirected by the Authorization Server if the authorization grant query is successful
- ``scope``: scope name(s). In short it defines which of the user's resources the Client will be getting access to. Our api expects comma-separated values if more than one.
- ``state``: (optional) useful for the client to store encoded info. Will be returned back to the Client unmodified.

2) Authorization page
---------------------
The user is presented with a page where he needs to:

i) Authenticate (if he hasn't already done so)
ii) Check the Application data (client name, description, logo, etc)
iii) Approve the requested access to the given scope

Additionaly, he is presented the following items:

i) Detailed description of the scope (or which resources the client is requesting access to).
ii) Link to the application Privacy Policy
iii) Link to register if the user doesn't own an account at app.dock.io

Once the user clicks on "Authorize", ``dockapi`` redirects the user to the given `redirect_uri` (if registered for the given client) with the following two query params:

- ``state``: is sent back unmodified so the client can use it (if present in the incoming query)
- ``authorization_code``: the one that was just created when the user accepted. It expires after a few minutes, so the client is expected to use it right away.

3) Using an Authorization Code to get an Access Token
-----------------------------------------------------
The Client now has an ``authorization_code`` that it can use on a call to:
``POST https://app.dock.io/api/v1/oauth/access-token`` to get the actual ``access token`` that is to be stored for this user in the Client application. This call needs to be made from the BE so the traffic is not visible in the browser. The following params are expected in the call:

- ``grant_type=authorization_code``: this is by default
- ``code``: contains the ``authorization_code`` returned by the Authorization Server as a result of a successful Authorization Grant query.
- ``client_id``: given to the developer when registering the Client application.
- ``client_secret``: given to the developer when registering the Client application.


The ``dock-auth`` server validates that the given data is correct and sends a response with the following data to ``dockapi``:

- ``access_token``: will be used by the client to sign requests on behalf of the user
- ``token_type=bearer``: this is by default

4) Using an Access Token to get User Data
-----------------------------------------
The Client now has an ``access_token`` that it can use on a call to:
``GET https://app.dock.io/api/v1/oauth/user-data`` to get the actual User Data. This call needs to be made from the BE so the traffic is not visible in the browser. The following params are expected in the call:

- ``client_id``: given to the developer when registering the Client application.
- ``client_secret``: given to the developer when registering the Client application.

Additionally, the call is expected to contain a header like ``Authorization: Bearer <access_token>``

The response from this call is whatever user data the scope gives access to. Right now, with the "basic" scope this data is first- and last name, email, avatar and dock user id. In the future this may change.

