# 03 — Create the hosted agent version in the existing Foundry project.
#
# Registers the image as a `kind: hosted` agent that references the blueprint,
# waits for it to go active, grants the default instance identity Cognitive
# Services User on the account, and switches the endpoint to BotServiceRbac auth.
. "$PSScriptRoot/_common.ps1"
$c = Get-DeployConfig

if ([string]::IsNullOrWhiteSpace($c.BlueprintClientId)) {
    throw "BlueprintClientId is empty. Run 01-create-blueprint.ps1 and set it in config.ps1."
}

$token = Get-AiAzureToken
$headers = @{
    "Content-Type"     = "application/json"
    Accept             = "application/json"
    Authorization      = "Bearer $token"
    "Foundry-Features" = "HostedAgents=V1Preview,AgentEndpoints=V1Preview"
}

$agentUrl = "$($c.ProjectEndpoint)/agents/$($c.AgentName)/versions?api-version=2025-11-15-preview"
$body = @{
    definition = @{
        kind                        = "hosted"
        image                       = "$($c.ContainerRegistryEndpoint)/$($c.ImageName)"
        cpu                         = "2"
        memory                      = "4Gi"
        environment_variables       = @{
            AzureOpenAIEndpoint = $c.ResponsesEndpoint
            ModelDeployment     = $c.ModelDeployment
        }
        container_protocol_versions = @(@{ protocol = "activity_protocol"; version = "v1" })
    }
    metadata            = @{ enableVnextExperience = "true" }
    description         = "Workmate — Work IQ digital worker."
    agent_endpoint      = @{ protocols = @("activity") }
    blueprint_reference = @{ type = "ManagedAgentIdentityBlueprint"; blueprint_id = $c.MaibName }
} | ConvertTo-Json -Depth 6

Write-Host "Creating hosted agent version at $agentUrl"
$resp = Invoke-RestMethod -Uri $agentUrl -Method Post -Headers $headers -Body $body
$resp | ConvertTo-Json -Depth 20 | Write-Host

$version   = $resp.version
$agentGuid = $resp.agent_guid
$instanceClientId = $resp.instance_identity.client_id
Write-Host "Agent GUID: $agentGuid  Version: $version  InstanceClientId: $instanceClientId"

# Poll to active.
$status = $resp.status
$pollUrl = "$($c.ProjectEndpoint)/agents/$($c.AgentName)/versions/$version?api-version=2025-11-15-preview"
for ($i = 0; $i -lt 30 -and $status -ne "active" -and $status -ne "failed"; $i++) {
    Start-Sleep -Seconds 10
    try { $status = (Invoke-RestMethod -Uri $pollUrl -Method Get -Headers $headers).status } catch {}
    Write-Host "  provisioning status: $status"
}
if ($status -ne "active") { throw "Agent version status '$status', expected 'active'." }

# Grant Cognitive Services User to the agent's default instance identity on the account.
$scope = "/subscriptions/$($c.SubscriptionId)/resourceGroups/$($c.ResourceGroup)/providers/Microsoft.CognitiveServices/accounts/$($c.AccountName)"
$out = az role assignment create --assignee $instanceClientId --role "a97b65f3-24c7-4388-baec-2e87135dc908" --scope $scope 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) { Write-Host "Granted Cognitive Services User to instance identity." }
elseif ($out -match "RoleAssignmentExists") { Write-Host "Cognitive Services User already granted." }
else { throw "Role assignment failed: $out" }

# Switch the endpoint to BotServiceRbac so the Azure Bot can call it.
$patchUrl = "$($c.ProjectEndpoint)/agents/$($c.AgentName)?api-version=2025-11-15-preview"
$patchBody = @{ agent_endpoint = @{ protocols = @("activity"); authorization_schemes = @(@{ type = "BotServiceRbac" }) } } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri $patchUrl -Method Patch -Headers $headers -Body $patchBody | ConvertTo-Json -Depth 10 | Write-Host

Write-Host ""
Write-Host "Agent GUID (needed for step 04): $agentGuid" -ForegroundColor Green
