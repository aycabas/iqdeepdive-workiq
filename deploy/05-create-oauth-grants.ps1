# 05 — Tenant-wide OAuth2 grants on the blueprint service principal.
#
# Grants the blueprint SP the Agent 365 MCP scopes (Mail/Teams/Files/Calendar/...),
# APEX AgentData, and — critically for Work IQ — the IQ OBO delegation
# (user_impersonation on Cognitive Services + Azure ML) so Foundry resolves the
# Work IQ connection on-behalf-of the signed-in user. Requires an admin token.
. "$PSScriptRoot/_common.ps1"
$c = Get-DeployConfig

$blueprintSP = az ad sp show --id $c.BlueprintClientId --query id -o tsv
if ([string]::IsNullOrWhiteSpace($blueprintSP)) { throw "No SP for blueprint $($c.BlueprintClientId)." }

$graphToken = Get-GraphToken

function New-Grant($resourceAppId, $scope) {
    $resourceSP = az ad sp show --id $resourceAppId --query id -o tsv
    if ([string]::IsNullOrWhiteSpace($resourceSP)) { throw "No SP for resource app $resourceAppId." }
    $grant = @{ clientId = $blueprintSP; consentType = "AllPrincipals"; principalId = $null; resourceId = $resourceSP; scope = $scope } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants" -Method Post `
            -Headers @{ "Content-Type" = "application/json"; Accept = "application/json"; Authorization = "Bearer $graphToken" } `
            -Body $grant | Out-Null
        Write-Host "  granted on $resourceAppId" -ForegroundColor Green
    }
    catch {
        $err = $null; try { $err = $_.ErrorDetails.Message | ConvertFrom-Json } catch {}
        if ($err.error.message -like "*Permission entry already exists*") { Write-Host "  already granted on $resourceAppId" }
        else { throw }
    }
}

# Agent 365 Prod MCP app — the full digital-worker tool surface.
$mcpScopes = "McpServers.M365Admin.All McpServers.DASearch.All McpServers.WebSearch.All McpServers.Files.All AgentTools.MOSEvents.All McpServers.Admin365Graph.All McpServers.ERPAnalytics.All McpServers.DataverseCustom.All McpServers.Dataverse.All McpServers.D365Service.All McpServers.D365Sales.All McpServers.Management.All McpServersMetadata.Read.All McpServers.Developer.All McpServers.CopilotMCP.All McpServers.OneDriveSharepoint.All McpServers.Mail.All McpServers.Teams.All McpServers.Me.All McpServers.Calendar.All McpServers.SharepointLists.All McpServers.Knowledge.All McpServers.Excel.All McpServers.Word.All McpServers.PowerPoint.All"
Write-Host "Granting Agent 365 Prod MCP scopes..."
New-Grant "ea9ffc3e-8a23-4a7d-836d-234d7c7565c1" $mcpScopes

Write-Host "Granting APEX AgentData.ReadWrite..."
New-Grant "5a807f24-c9de-44ee-a3a7-329e88a00ffc" "AgentData.ReadWrite"

Write-Host "Granting IQ OBO (user_impersonation) so Work IQ resolves on-behalf-of the user..."
New-Grant "7d312290-28c8-473c-a0ed-8e53749b6d6d" "user_impersonation"   # Microsoft Cognitive Services
New-Grant "18a66f5f-dbdf-4c17-9dd7-1634712a9cbe" "user_impersonation"   # Azure Machine Learning Services

Write-Host "OAuth2 grants complete." -ForegroundColor Green
