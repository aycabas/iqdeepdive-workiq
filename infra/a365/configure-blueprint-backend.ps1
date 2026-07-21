#!/usr/bin/env pwsh
# Configures the blueprint's backend (bot) in the Teams Developer Portal so the approved digital
# worker is wired to the Azure Bot. Bot ID == blueprint (agent identity) client id.
# Needs a token for https://dev.teams.microsoft.com; run after admin approval.
$ErrorActionPreference = "Stop"

$blueprintId = $env:AGENT_IDENTITY_BLUEPRINT_ID
if ([string]::IsNullOrEmpty($blueprintId)) { throw "AGENT_IDENTITY_BLUEPRINT_ID environment variable is not set." }

$token = az account get-access-token --resource https://dev.teams.microsoft.com --query accessToken -o tsv
if ([string]::IsNullOrEmpty($token)) {
    throw "Failed to acquire a https://dev.teams.microsoft.com token. Try: az login --scope https://dev.teams.microsoft.com/.default"
}

$url = "https://dev.teams.microsoft.com/api/v1.0/agentblueprints/$blueprintId/backendConfiguration"
$body = @{ type = "botBased"; botBased = @{ botId = $blueprintId } } | ConvertTo-Json -Depth 5

Write-Host "PUT $url"
Write-Host $body

try {
    $response = Invoke-RestMethod -Uri $url `
        -Method Put `
        -Headers @{ "Content-Type" = "application/json"; "Accept" = "application/json"; "Authorization" = "Bearer $token" } `
        -Body $body
    Write-Host "Response:"; if ($response) { $response | ConvertTo-Json -Depth 5 | Write-Host } else { Write-Host "(empty response)" }
}
catch {
    Write-Host "Failed to configure blueprint backend: $($_.Exception.Message)"
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) { Write-Host "Error details: $($_.ErrorDetails.Message)" }
    throw
}

Write-Host "Blueprint backend configuration completed for blueprint $blueprintId."
