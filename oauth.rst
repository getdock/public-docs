DOCK OAuth Integration Guide
============================

Initial Setup
-------------

Any new Partner application needs to be first set up with DOCK manually before any authentication or data exchange services can be used. Following are the one time set up steps for partners:
Provide basic info like your application's name, logo and description.
Provide these URLs: homepage, privacy policy and at least one callback URI. 
The above information, except for the callback URIs, will be shown to the User at the Authorization Page. 
As a result of registering, you will be given a ``client_id`` and a ``client_secret`` that you will need to use to authenticate your requests to our API.  Please be aware that we do not store your ``client_secret``. You need to save it somewhere safe as soon as you get it since we cannot retrieve it back for you if you lose it. In that event a new set of client id/secret will have to be created for you.


Basic Client Integration Flow
=============================

Quick details
-------------
Following is the simplified version of the flow before diving into details: 

- Clients/Partner request an ``authorization_code`` grant type by redirecting the user to the Dock Authorization Page. 
- The user verifies the information the Client app is requesting access to (the scopes) and also see the app's name, logo and description. 
- After approval, the user is redirected to the given ``return_uri`` with an ``authorization code`` added as a parameter. 
- The client can then do a backend call (not redirection) to exchange it for an ``access token``. 
- Dock will only return an ``access token`` to the right ``authorization code`` coming from the right Client, using the right client credentials. 
- Finally, by using the Bearer Token in the ``Authorization`` header, the client will be able to access the requested user data.

Detailed information
--------------------
To make sense of the above it can be useful to observe the whole flow in a detailed step-by-step explanation. The following steps explain how the flow would look like for a Client getting an Access Token to act on behalf of one of its users, and then using it to get user data from Dock:

Step 1 - Authorization grant query
----------------------------------
To initiate the OAuth flow the Client needs to start an authorization grant query by redirecting the user to:
``GET https://app.dock.io/oauth/authorize`` with the following query params:

- ``client_id``: id of the Client doing the request. This is the id you received when you registered your application.
- ``response_type=code``: 'code' is always expected, it means that you expect to get an ``authorization_code``
- ``redirect_uri``: URL where you want the user to be redirected to by the Authorization Server if the authorization grant query is successful. This needs to be one of the Redirect URIs you added when registering your application. Remember that **exact match** is used to compare, any minor variations will trigger an error response.
- ``scope``: scope name(s). These define which of the user's resources you're requesting access to. Our API expects comma-separated values if more than one.
- ``state``: (optional but recommended) the value of this parameter will be returned to you unmodified. We recommend that you encode some info and sign it. It is useful for you to verify the authenticity of the next call you receive from us, if the signature doesn't match then you can safely abort the flow.


Step 2 - Authorization page
---------------------------

The User is presented with a page in the Dock application where they need to:

i) Authenticate (if they haven't already done so)
ii) Check Application info (name, description, logo, etc)
iii) Approve the requested access to the given scopes

Additionally, the user is presented the following items:

i) Detailed description of the scope (or which resources the client is requesting access to).
ii) Link to application's Privacy Policy
iii) Link to register if the user doesn't own an account at Dock

Once the user clicks on "Authorize", we redirect him to the given ``redirect_uri`` with the following two parameters added to the url:

- ``state``: if present in the call from Step 1, it is sent back unmodified to you so you can verify it.
- ``authorization_code``: this is the code that was created when the user approved to grant you access. It expires after a few minutes, so you are expected to use it right away to get an Access Token.



Step 3 - Using an Authorization Code to get an Access Token
-----------------------------------------------------------

You now have an ``authorization_code`` that you can use on a call to
``POST https://app.dock.io/api/v1/oauth/access-token`` to get the actual ``access token``. This is the Token that is to be stored for this User in your application. Remember: this call needs to be made from the BE so the traffic is not visible in the User's browser. The following params are expected in the call:

- ``grant_type``: ``authorization_code`` is expected by default.
- ``code``: the ``authorization_code`` that you received in Step 2.
- ``client_id``: the id you received when you registered your Application.
- ``client_secret``: the secret you received when you registered your Application.


Our server will validate that the given data is correct and will return the following data in JSON format to you:

- ``access_token``: the token that you can use to sign requests on behalf of the User. This is the key to access this User's data.
- ``token_type``: indicates what type of token you received. You should expect this to be ``bearer``.



Step 4 - Using an Access Token to get User Data
-----------------------------------------------

You finally have an ``access_token`` that you can use on a call to:
``GET https://app.dock.io/api/v1/oauth/user-data`` to get the actual data that the User has shared with you. Remember: this call also needs to be made from the BE so the traffic is not visible in the browser. The following params are expected in the call:

- ``client_id``: given to the developer when registering the Client application.
- ``client_secret``: given to the developer when registering the Client application.

Additionally, the call is expected to contain a header that looks like ``Authorization: Bearer <access_token>`` where you should use the Access Token you got in Step 3.

The response from this call is whatever user data the scope gives access to. It will at least contain the ``id`` of this user in Dock, which you should store for this user in your system. When authenticating this allows you to compare this id to the ones stored in your system, if you find a match for a user you can log that user in. This is the end of the OAuth flow.


Appendix 1: Variable Notes
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
Only HTTPS addresses are accepted as Redirect URIs. This means that native apps are not supported for now. **Exact match** is used during the authentication flow, and it is forbidden to provide URLs containing anything after the fragment identifier.

Scopes
------
A ``scope`` is a way to limit a 3rd party app's access to a user's data. There are 2 choices.

Basic Scope (``basic``): This scope will only contain the DOCK user id & ETH address of the contract between the Client and the User. The Client can pass this address and ask the ``dock-gateway`` to fetch and decrypt the user data, and in later versions use this address to go and interact with the contract directly in the Ethereum network.

Full Scope (``full``): This scope will share a lot more details about the user with the partner. The complete list is specified in the next Appendix.

Appendix 2: Complete list of Attributes passed for full scope
=============================================================

Following is the list of attributes passed back to the partner if the user has granted ‘full scope’ to the partner application.

- user.first_name
- user.last_name
- user.email
- user.avatar
- user.headline
- user.industry
- user.home_address
- profile.industry
- profile.interests
- profile.languages
- profile.phone
- profile.phone_country_code
- profile.bio
- profile.reviews
- profile.status
- profile.experience
- profile.skills
- profile.education

Appendix 3: Roles defined by OAuth 2.0 spec 
===========================================

Resource owner: the resource owner is the person who is giving access to some portion of their account. In this case the resource owner is a user in the Dock App. The resources are any piece of data that the user is choosing to share: personal information, contacts, work experience, etc. Any system that wants to act on behalf of the user must first get permission from them.

Resource server: what developers usually refer to as the main API. This is the server that contains the user's information that is being accessed by the third-party application. In our case this is https://app.dock.io

Authorization server: the server that the user interacts with when an application is requesting access to their account.

Client: the 3rd party app that is attempting to act on the user's behalf, or access the user's resources. Before the Client can access the user's account, it needs to obtain permission from the user.
