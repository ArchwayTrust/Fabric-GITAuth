# Fabric GIT Auth
Some helper code for authenticating against Fabric APIs for GIT pipelines. The moment that Fabric supports Service Principals you can disgard this.

## Create App Registration
In the Azure portal you need an App Registration set up for mobile and desktop applications. I used the default redirect URL: https://login.microsoftonline.com/common/oauth2/nativeclient

In the authentication page scroll down to advanced settings and turn on "Allow public client flows".

In API permissions grant what you need for Fabric. For GIT you specifically need:

- Delegated Workspace.GitUpdate.All
- Delegated Workspace.Read.All

Note down the Tennant Id and Client Id. You don't need to create a secret (we're going to authenticate as ourself).

## Generate Refresh Token
Use the code in [ExampleCode/GetRefreshToken.py](ExampleCode/GetRefreshToken.py) to generate a refresh token.

You need to update it with your tennant and client id.

I would do this on a local machine so there is no danger of leaking the refresh token. You need to install the msal module.

It will give you a link to open in a browser and an authentication code to use. When complete it will return a refresh token. THIS MUST BE HELD SECURELY.

## Set up Azure DevOps pipeline.

Place azure-pipelines.yml in the root of your repository.
In pipelines create two secret variables ([MS Learn](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-secret-variables?view=azure-devops&tabs=yaml%2Cbash#secret-variable-in-the-ui)) named:

- TenantId
- RefreshToken

All the yaml file does is tell the pipeline run [ExampleCode/UpdateWorkspace.ps1](ExampleCode/UpdateWorkspace.ps1) and pass in the RefreshToken and TenantId when ever a change is pulled onto the main branch.

## Modify UpdateWorkspace.ps1
The main code is heavily based on https://blog.fabric.microsoft.com/en-CA/blog/automate-your-ci-cd-pipelines-with-microsoft-fabric-git-rest-apis/

However here we use the refresh token to reauthenticate.

At the end of this powershell script modify the workspace names to control what gets updated from Git.

The refresh token currently expires after 90 days. You can though use it to generate a new refesh token however I have yet to work out how to store that back as an updated secret. (Was hoping that within 90 days service principal auth would be available!)


