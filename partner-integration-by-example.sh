# Example-based guide
# ===================

# The following guide is an almost shell script-ready code. It helps experiment
# with the Dock API. You will need to change the concrete values of keys,
# access codes etc., as they are returned from the subsequent calls.


# --- Initial, one-time steps ---

# 1: Generate keys for a new ethereum account.
# For convenience we provide a way to do that
# via our Dock Gateway service (the keys are not stored
# anywhere within our system - this is a purely on-the-fly
# operation). You can either use our tool or generate
# your ETH keys in any other way. E.g.:
curl -s -X POST https://gateway.dock.io/v1/account

# At this point, please manually provide the Dock team with the
# following data:
# - your OAuth secret passphrase; this is the value that will be used
#   to authenticate the incoming OAuth calls from your service;
# - the name and description that you would like your users to see
#   as the strings that identify you in the OAuth process;
# - the full URL where your users should be redirected during OAuth
#   (verified for increased security);
# - the generated ETH address and public key (but not the 
#   private key - that is your true encryption secret);

# The Dock team will internally register your account and
# provide you with your Client Id.

# 2: Register your webhook for notifications from Dock Gateway.
# Provide your HTTPS-based URL where you would like to receive the notifications
# and your webhook secret passphrase (different than the OAuth one discussed above), e.g.:
curl -X PUT \
-H "Content-Type: application/json" \
-H "Authorization: PrivateKey dbd31c490ca0f56f267ea9dec7a37995e9bf7c0e69020d4d7004e5e30480f468" \
-d '
    {
      "payload_url": "https://echo.dock.io/testclient-gateway-webhook",
      "secret": "lorem"
    }
' \
https://gateway.dock.io/v1/webhook

# For the sake of testing, we provide all that initial setup with a dummy client account that you can use freely.
# It is registered withthe following data:
#   name: testclient
#   client id: 5b648ea5f09b030007bacb92
#   OAuth client secret: karlo
#   eth private key: dbd31c490ca0f56f267ea9dec7a37995e9bf7c0e69020d4d7004e5e30480f468
#   eth address: 3b1812f39ceb9a6ecb3cb9f0dac86ff677e063a4
#   eth public key: 83af1df4d8bec5ef39b006587d5b9cb1e738766cf09065eaa949a5b0fb8bcd072ba3e6490d03031981fb1ffadf144482fae2a9420ffc3a5b8a69cfa974427ad1
#   home url: https://echo.dock.io/testclient-home
#   accepted oauth redirect URL: https://echo.dock.io/testclient-oauth/
#   Dock Gateway webhook url: https://echo.dock.io/testclient-gateway-webhook,
#   Dock Gateway secret: lorem
#
# We also provide an HTTPS echo server that you can use as a dummy place to monitor the HTTP traffic that our services generate.
# E.g. by viewing: `GET https://echo.dock.io/testclient-oauth/read` you can see recent OAuth redirects for the `testclient`.
# The same goes for Dock Gateway - you can monitor the webhook notifications
# for the `testclient` account at: `GET https://echo.dock.io/testclient-gateway-webhook/read` 


# --- Recurrent steps ---

# Each time a user wants to connect your service with Dock App,
# make sure they have a Dock App account and then redirect them to:
https://app.dock.io/oauth/authorize?client_id=5b648ea5f09b030007bacb92&redirect_uri=https://echo.dock.io/testclient-oauth/&response_type=code&scope=basic,full

# Once the user has authorized the connection, they will be redirected
# to the provided `redirect_uri` and given a one-time authorization code, e.g.:
https://echo.dock.io/testclient-oauth/?code=IjViNmRhZWZiMWY3Yjk5MDAwMTEwZjE3NCI.3yQPzJU6Fxb7KcoeXmVeuUd0pNI

# Use this code to obtain a persistent access token for the user.
# You need to provide the following fields:
#     grant_type: constant string: "authorization_code"
#     code: the authorization code
#     client_id: your registered client id
#     client_secret: your registered client secret
# E.g.:
curl -X GET "https://app.dock.io/api/v1/oauth/access-token?grant_type=authorization_code&code=IjViNmRhZWZiMWY3Yjk5MDAwMTEwZjE3NCI.3yQPzJU6Fxb7KcoeXmVeuUd0pNI&client_id=5b648ea5f09b030007bacb92&client_secret=karlo"

# Dock App will respond with the access token for that user, e.g.:
{"access_token": "IjViNmRhZjIwMjZjMDBkMDAwMWE5NzM5NyI.Zoy4z4LmOFXP_TF050Wo349kDRQ"}

# With the access token, you can finally request the user data, which means that
# you can request the Dock connection to be initiated. E.g.:
curl -X GET \
-H "Authorization: Bearer IjViNmRhZjIwMjZjMDBkMDAwMWE5NzM5NyI.Zoy4z4LmOFXP_TF050Wo349kDRQ" \
"https://app.dock.io/api/v1/oauth/user-data?client_id=5b648ea5f09b030007bacb92&client_secret=karlo"

# Dock App will initiate the Dock connections and will respond with the information
# about the user and the connection, e.g.:
{
    "scopes": ["basic", "full"], 
    "user_data": {"connection_addr": "1993793065ee99004c9af3689283c65d1b7e3b14", 
    "id": "5b683b6c2c224b004aed7254"}
}

# At about the same time you should receive a webhook notification
# that a Dock connection has been requested. You should make sure that
# the incoming `secret` field matches the one that you provided during
# webhook registration. An example notification:
{
    "event_name": "connection-requested",
    "event_data": {"connection_addr": "1993793065ee99004c9af3689283c65d1b7e3b14"},
    "secret": "lorem"
}

# The last required step is to confirm the requested connection.
# This is done via Dock Gateway, e.g.:
curl -X POST \
-H "Content-Type: application/json" \
-H "Authorization: PrivateKey dbd31c490ca0f56f267ea9dec7a37995e9bf7c0e69020d4d7004e5e30480f468" \
https://gateway.dock.io/v1/connection/1993793065ee99004c9af3689283c65d1b7e3b14/confirm

# Shortly after confirming the connection you will receive a Gateway notification
# that a new data package has been created for the user, e.g.:
{
    "event_name": "data-package-created",
    "event_data": {"connection_addr": "1993793065ee99004c9af3689283c65d1b7e3b14",
    "ipfs_addr": "QmFLCZr8qGEBY6csPqFdBEodk6HEQ9hpWbkM6ygr8UWeGA"},
    "secret": "lorem"
}

# From now on everything is ready to go. You can create and receive data packages
# as described in our official docs for Dock Gateway:
# https://github.com/getdock/public-docs/blob/master/gateway.rst

# For testing purposes (e.g. to repeat the process) you may want to close your
# Dock connection. E.g.:
curl -X POST \
-H "Content-Type: application/json" \
-H "Authorization: PrivateKey dbd31c490ca0f56f267ea9dec7a37995e9bf7c0e69020d4d7004e5e30480f468" \
https://gateway.dock.io/v1/connection/1993793065ee99004c9af3689283c65d1b7e3b14/close
