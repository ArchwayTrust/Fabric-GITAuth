# UPDATE THESE
tennantId = "YOUR TENNANT ID"
clientId = "YOUR CLIENT ID"

import msal
import requests
import json
import base64
import time


REDIRECT_URI = "https://login.microsoftonline.com/common/oauth2/nativeclient"
SCOPES = ["https://api.fabric.microsoft.com/Workspace.GitUpdate.All"]
        
# Initialize the MSAL confidential client
app = msal.PublicClientApplication(
    client_id=clientId,
    authority=f"https://login.microsoftonline.com/{tennantId}"
)

tokenResponse = None
accessToken = None
refreshToken = None

flow = app.initiate_device_flow(scopes=SCOPES)

# Check if the user_code is part of the flow response
if "user_code" not in flow:
    raise ValueError(f"Failed to create device flow. Err: {json.dumps(flow, indent=4)}")

# Set an expiration time for the flow (60 seconds from now)
flow['expires_at'] = int(time.time()) + 60

# Display the authentication message to the user
print(flow["message"])

# Attempt to acquire the token by the device flow
result = app.acquire_token_by_device_flow(flow)

# Check if the authentication was successful
if "access_token" in result:
    print("Successfully authenticated.")
    # Store the refresh token from the result
    refreshToken = result['refresh_token']
    print(refreshToken)
else:
    # Handle authentication failure
    print(f"Authentication failed. Result was: {result}")
    raise Exception(f"Authentication failed. Error: {result}")