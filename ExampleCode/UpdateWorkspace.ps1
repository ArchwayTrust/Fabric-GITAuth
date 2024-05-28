param (
    [string]$tenantId,
    [string]$refreshToken
)

$global:baseUrl = "https://api.fabric.microsoft.com/v1"
$global:resourceUrl = "https://api.fabric.microsoft.com"

$refreshUrl = "https://login.microsoftonline.com/" + $tenantId + "/oauth2/token"
$body = "grant_type=refresh_token&refresh_token=" + $refreshToken
$response = Invoke-RestMethod $refreshUrl -Method POST -Body $body
$AccessToken = $response.access_token

$global:fabricHeaders = @{
    'Content-Type'  = "application/json"
    'Authorization' = "Bearer {0}" -f $AccessToken
}

function GetWorkspaceByName($workspaceName) {
    # Get workspaces    
    $getWorkspacesUrl = "{0}/workspaces" -f $global:baseUrl
    $workspaces = (Invoke-RestMethod -Headers $global:fabricHeaders -Uri $getWorkspacesUrl -Method GET).value

    # Try to find the workspace by display name
    $workspace = $workspaces | Where-Object { $_.DisplayName -eq $workspaceName }

    return $workspace
}

function UpdateWorkspaceFromGit {
    param (
        [string]$workspaceName
    )
    try {
        $workspace = GetWorkspaceByName $workspaceName 
        
        # Verify the existence of the requested workspace
        if (!$workspace) {
            #Write-Host "A workspace with the requested name was not found." -ForegroundColor Red
            throw "A workspace with the requested name was not found."
        }
        
        # Get Status
        Write-Host "Calling GET Status REST API to construct the request body for UpdateFromGit REST API."
    
        $gitStatusUrl = "{0}/workspaces/{1}/git/status" -f $global:baseUrl, $workspace.Id
        $gitStatusResponse = Invoke-RestMethod -Headers $global:fabricHeaders -Uri $gitStatusUrl -Method GET
    
        # Update from Git
        Write-Host "Updating the workspace '$workspaceName' from Git."
    
        $updateFromGitUrl = "{0}/workspaces/{1}/git/updateFromGit" -f $global:baseUrl, $workspace.Id
    
        $updateFromGitBody = @{ 
            remoteCommitHash = $gitStatusResponse.RemoteCommitHash
            workspaceHead    = $gitStatusResponse.WorkspaceHead
            options          = @{
                # Allows overwriting existing items if needed
                allowOverrideItems = $TRUE
            }
        } | ConvertTo-Json
    
        $updateFromGitResponse = Invoke-WebRequest -Headers $global:fabricHeaders -Uri $updateFromGitUrl -Method POST -Body $updateFromGitBody
    
        $operationId = $updateFromGitResponse.Headers['x-ms-operation-id']
        $retryAfter = $updateFromGitResponse.Headers['Retry-After']
        Write-Host "Long Running Operation ID: '$operationId' has been scheduled for updating the workspace '$workspaceName' from Git with a retry-after time of '$retryAfter' seconds." -ForegroundColor Green
    
    }
    catch {
        $errorResponse = $_.Exception.Message
        Write-Host "##vso[task.logissue type=error]Failed to update the workspace '$workspaceName' from Git. Error reponse: $errorResponse"
        exit 1
    }
}

# Update Workspace Name 1
Write-Output "Updating Workspace Name 1..."
$response = UpdateWorkspaceFromGit -workspaceName "Workspace Name 1"
Write-Output $response

# Update Workspace Name 2
Write-Output "Updating Workspace Name 2..."
$response = UpdateWorkspaceFromGit -workspaceName "Workspace Name 2"
Write-Output $response

# Update Workspace Name 3
Write-Output "Updating Workspace Name 3..."
$response = UpdateWorkspaceFromGit -workspaceName "Workspace Name 3"
Write-Output $response