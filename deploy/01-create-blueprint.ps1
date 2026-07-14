# 01 — Create the managed agent identity blueprint (the agent's Entra identity).
#
# This is a single Foundry data-plane PUT; no new project/account is provisioned.
# The returned clientId becomes the bot msaAppId and the SP that receives OAuth2
# grants. Paste it into config.ps1 as BlueprintClientId for the later steps.
. "$PSScriptRoot/_common.ps1"
$c = Get-DeployConfig

$token = Get-AiAzureToken
$url = "$($c.ProjectEndpoint)/managedagentidentityblueprints/$($c.MaibName)?api-version=2025-11-15-preview"

Write-Host "Creating blueprint '$($c.MaibName)' at $url"
$resp = Invoke-RestMethod -Uri $url -Method Put -Headers @{
    Authorization  = "Bearer $token"
    "Content-Type" = "application/json"
    Accept         = "application/json"
}

$resp | ConvertTo-Json -Depth 20 | Write-Host
$clientId = $resp.agentIdentityBlueprint.clientId
Write-Host ""
Write-Host "Blueprint clientId: $clientId" -ForegroundColor Green
Write-Host "-> Set BlueprintClientId = `"$clientId`" in deploy/config.ps1" -ForegroundColor Yellow
