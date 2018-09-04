DOCK OAuth Integration Guide
============================

Initial Setup
-------------

Any new Partner application needs to be first set up with DOCK manually before any authentication or data exchange services can be used. Following are the one time set up steps for partners:

- Provide basic info like your application's name, logo and description.
- Provide these URLs: homepage, privacy policy and at least one callback URI. 
The above information, except for the callback URIs, will be shown to the User at the Authorization Page. 

- As a result of registering, you will be given a ``client_id`` and a ``client_secret`` that you will need to use to authenticate your requests to our API.  Please be aware that we do not store your ``client_secret``. You need to save it somewhere safe as soon as you get it since we cannot retrieve it back for you if you lose it. In that event a new secret will have to be created.

Client Integration Steps Overview
=================================
Basically there are two parts to DOCK integration. The first is integrating with DOCK OAuth Server using the steps in this file. In a separate file we explain how you can integrate with DOCK Gateway to get user data by using the contract address we get at the end of this flow. We will also share a separate file that contains the list of attributes you get from DOCK in the data package you get integrating with the DOCK Gateway. 

OAuth Client Integration Flow
=============================

Quick details
-------------
Following is the simplified version of the flow before diving into details: 

- Client request an ``authorization_code`` grant type by redirecting the user to the Dock Authorization Page. 
- The user verifies the information the Client app is requesting access to (the scopes) and also see the app's name, logo and description. 
- After approval, the user is redirected to the given ``return_uri`` with an ``authorization code`` added as a parameter. 
- The client can then do a backend call (not redirection) to exchange it for an ``access token``. 
- Dock will only return an ``access token`` to the right ``authorization code`` coming from the right Client, using the right client credentials. 
- Finally, by using the ``access token`` in the ``Authorization`` header, the client will be able to access the requested user data.

Detailed information
--------------------
To make sense of the above it can be useful to observe the whole flow in a detailed step-by-step explanation. The following steps explain how the flow would look like for a Client getting an Access Token to act on behalf of one of its users:

Step 1 - Authorization grant query
----------------------------------
To initiate the OAuth flow the Client needs to start an authorization grant query by redirecting the user to:
``https://app.dock.io/oauth/authorize`` with the following query params:

- ``client_id``: id of the Client doing the request. This is the id you received when you registered your application.
- ``response_type``: 'code' is always expected, it means that you expect to get an ``authorization_code``
- ``redirect_uri``: URL where you want the user to be redirected to by the Authorization Server if the authorization grant query is successful. This needs to be one of the Redirect URIs you added when registering your application. Remember that **exact match** is used to compare, any minor variations will trigger an error response.
- ``scope``: scope name(s). These define which of the user's resources you're requesting access to. Our API expects comma-separated values if more than one.
- ``state``: (optional but recommended) the value of this parameter will be returned to you unmodified. We recommend that you encode some info and sign it. It is useful for you to verify the authenticity of the next call you receive from us, if the signature doesn't match then you can safely abort the flow.


Step 2 - Authorization page
---------------------------

The User is presented with a page in the Dock application where they need to:

i) Authenticate (if they haven't already done so)
ii) Check the application info (name, description, logo, etc)
iii) Approve the requested access to the given scopes

Additionally, the user is presented the following items:

i) Detailed description of the scope (or which resources the client is requesting access to).
ii) Link to the application's Privacy Policy
iii) Link to register if the user doesn't own an account at Dock

Once the User clicks on "Authorize", we redirect him to the given ``redirect_uri`` with the following two parameters added to the url:

- ``state``: if present in the call from Step 1, it is sent back unmodified to you so you can verify it.
- ``authorization_code``: this is the code that was created when the user approved to grant you access. It expires after a few minutes, so you are expected to use it right away to get an Access Token.



Step 3 - Using an Authorization Code to get an Access Token
-----------------------------------------------------------

You now have an ``authorization_code`` that you can use on a call to
``GET https://app.dock.io/api/v1/oauth/access-token`` to get the actual ``access token``. This is the Token that is to be stored for this User in your application. Remember: this call needs to be made from the backend so the traffic is not visible in the User's browser. The following params are expected in the URL for this call:

- ``grant_type``: the string "authorization_code" is expected by default.
- ``code``: the ``authorization_code`` that you received in Step 2.
- ``client_id``: the id you received when you registered your application.
- ``client_secret``: the secret you received when you registered your application.


Our server will validate that the given data is correct and will return the following data in JSON format to you:

- ``access_token``: the token that you can use to sign requests on behalf of the User. This is the key to access this User's data.
- ``token_type``: indicates what type of token you received. You should expect this to be ``bearer``.



Step 4 - Using an Access Token to get contract address
------------------------------------------------------

You finally have an ``access_token`` that you can use on a call to:
``GET https://app.dock.io/api/v1/oauth/user-data`` to get the contract address that can be used to get data about the user from DOCK gateway.The following params are expected in the call:

- ``client_id``: given to you when registering the Client application.

Additionally, the call is expected to contain a header that looks like ``Authorization: Bearer <access_token>`` where you should use the Access Token you got in Step 3.

The response from this call will be a JSON that contains at least the following two items:

-  the ``id`` of this user in Dock, which you should store for this user in your system. When authenticating this allows you to compare this id to the ones stored with you, if you find a match for a user then that is the user that has already logged in using DOCK in your application.
- ETH address of the contract between the Client and the User.

This is the end of the OAuth flow.

PKCE: OAuth for Native Applications
===================================
The OAuth 2.0 spec states that secrets that are statically included as part of a native application should not be treated as confidential secrets, as any user can inspect their copy and learn the shared secret. A malicious attacker could intercept the authorization_code returned by Dock and use these to get an Access Token. The Proof Key for Code Exchange (PKCE) is a technique used to mitigate this authorization code interception attack. In order to access our API from a native application, you need to implement the PKCE OAuth 2.0 grant.

Overview of the flow
--------------------
With PKCE, your native application creates a cryptographically random key called ``code_verifier`` for every authorization request, and derives a ``code_challenge`` from it. The latter is sent to Dock to generate an Authorization Code. When your native application receives the Authorization Code, it needs to use it together with the ``code_verifier`` to get an Access Token.

The amount of calls your native application needs to make in order to get and use an Access Token is the same as in the Authorization Code Grant flow. The only difference is that your client won't be using a ``client_secret``.

PKCE Step 0 - Generate a Code Verifier and Challenge
----------------------------------------------------

Before your native application can begin the OAuth flow from a native app, it needs to generate a ``code_verifier``. The ``code_verifier`` is a cryptographically random string using the characters ``A-Z``, ``a-z``, ``0-9``, and the punctuation characters ``-._~`` (hyphen, period, underscore, and tilde). The ``code_verifier`` needs to be between 43 and 128 characters long (inclusive).

Your application needs to store this ``code_verifier`` and generate what is called a ``code_challenge`` from it. This ``code_challenge`` is a BASE64-URL-encoded string of the SHA256 hash of the code verifier.

It is recommended that your app generates a second cryptographically random string and stores it as the ``state`` variable to use in Step 1.

PKCE Step 1 - Get an Authorization Code
---------------------------------------

To initiate the OAuth flow, your native Client needs to redirect the user to:
``https://app.dock.io/oauth/authorize`` with the following query params:

- ``client_id``: id of the Client doing the request. This is the id you received when you registered your application.
- ``response_type``: 'code' is always expected, it means that you expect to get an ``authorization_code``
- ``redirect_uri``: URL where you want the user to be redirected to by the Authorization Server if the authorization grant query is successful. This needs to be one of the Redirect URIs you added when registering your application. Remember that **exact match** is used to compare, any minor variations will trigger an error response.
- ``scope``: scope name(s). These define which of the user's resources you're requesting access to. Our API expects comma-separated values if more than one.
- ``state``: (optional but recommended) the ``state`` var you generated in Step 0. The value of this parameter will be returned to you unmodified. It is useful for you to verify the authenticity of the next call you receive from us, if the ``state`` doesn't match then you can safely abort the flow.
- ``code_challenge``: the ``code_challenge`` you generated in Step 0.
- ``code_challenge_method``: 'S256' is always expected, it means that your ``code_challenge`` was produced by using a SHA256 hash (which is mandatory).

Never use an embedded user-agent for this redirection: without the usual address bar and visible certificate validation features that browsers have, it is impossible for the user to know if they are signing in to the legitimate Dock application.

PKCE Step 2 - Authorization page
--------------------------------

The User is presented with a page in the Dock application where they need to:

i) Authenticate (if they haven't already done so)
ii) Check the application info (name, description, logo, etc)
iii) Approve the requested access to the given scopes

Additionally, the user is presented the following items:

i) Detailed description of the scope (or which resources the client is requesting access to).
ii) Link to the application's Privacy Policy
iii) Link to register if the user doesn't own an account at Dock

Once the User clicks on "Authorize", we redirect him to the given ``redirect_uri`` with the following two parameters added to the url:

- ``state``: if present in the call from Step 1, it is sent back unmodified to you so you can verify it.
- ``authorization_code``: this is the code that was created when the user approved to grant you access. It expires after a few minutes, so you are expected to use it right away to get an Access Token.



PKCE Step 3 - Using an Authorization Code to get an Access Token
----------------------------------------------------------------

You now have an ``authorization_code`` that you can use on a call to
``GET https://app.dock.io/api/v1/oauth/access-token`` to get the actual ``access token``. This is the Token that is to be stored for this User in your application. The following params are expected in the URL for this call:

- ``grant_type``: the string "authorization_code" is expected by default.
- ``code``: the ``authorization_code`` that you received in Step 2.
- ``client_id``: the id you received when you registered your application.
- ``code_verifier``: the ``code_verifier`` you generated in Step 0.


Our server will validate that the given data is correct and will return the following data in JSON format to you:

- ``access_token``: the token that you can use to sign requests on behalf of the User. This is the key to access this User's data.
- ``token_type``: indicates what type of token you received. You should expect this to be ``bearer``.



PKCE Step 4 - Using an Access Token to get contract address
-----------------------------------------------------------

You finally have an ``access_token`` that you can use on a call to:
``GET https://app.dock.io/api/v1/oauth/user-data`` to get the contract address that can be used to get data about the user from DOCK gateway.The following param is expected in the call:

- ``client_id``: given to you when registering the Client application.

Additionally, the call is expected to contain a header that looks like ``Authorization: Bearer <access_token>`` where you should use the Access Token you got in Step 3.

The response from this call will be a JSON that contains at least the following two items:

-  the ``id`` of this user in Dock, which you should store for this user in your system. When authenticating this allows you to compare this id to the ones stored with you, if you find a match for a user then that is the user that has already logged in using DOCK in your application.
- ETH address of the contract between the Client and the User.

This is the end of the OAuth flow for native clients.


Appendix: Variable Notes
==========================
Following are the notes about some of the variables mentioned above.

State Variable
--------------
The standard ``state`` url parameter is returned unmodified back to the Client. Clients are encouraged to use it to prevent CSRF attacks. A good state variable could be a self-signed string containing some simple info like:

- Current url to redirect the user to the right page once back
- User id

By signing the ``state`` var properly, you will be able to verify its signature and contents. If a CSRF attack took place, the signature will be broken and you should abort that authentication flow.

Redirect URIs
-------------
Only HTTPS addresses are accepted as Redirect URIs for the regular OAuth flow. **Exact match** is used during the authentication flow, and it is forbidden to provide URLs containing anything after the fragment identifier.
To generate an Authorization Code with a custom-schemed Redirect URIs, PKCE needs to be used.

Scopes
------
A ``scope`` is a way to limit a 3rd party app's access to a user's data. There are many choices, a high level overview of them can be found in `this doc`_.

.. _this doc: dock-schemas.rst
