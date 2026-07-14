# 04 — Publish the hosted agent as an Agent 365 digital worker (tenant scope).
#
# Pass the agent GUID printed by 03-create-agent.ps1.
param([Parameter(Mandatory = $true)][string]$AgentGuid)
. "$PSScriptRoot/_common.ps1"
$c = Get-DeployConfig

$token = Get-AiAzureToken
$workspace = "$($c.AccountName)@$($c.ProjectName)@AML"
$uri = "https://$($c.Location).api.azureml.ms/agent-asset/v2.0/subscriptions/$($c.SubscriptionId)/resourceGroups/$($c.ResourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/$workspace/microsoft365/publish"

$body = @{
    agentGuid              = $AgentGuid
    botId                  = $c.BlueprintClientId
    publishAsDigitalWorker = $true
    appPublishScope        = "Tenant"
    subscriptionId         = $c.SubscriptionId
    agentName              = $c.AgentName
    appVersion             = "1.0.0"
    shortDescription       = "Workmate — a Work IQ digital worker"
    fullDescription        = "A Work IQ Deep Dive digital worker that grounds and acts on the signed-in user's Microsoft 365 work context."
    developerName          = "aycabas"
    developerWebsiteUrl    = "https://azure.microsoft.com"
    privacyUrl             = "https://privacy.microsoft.com"
    termsOfUseUrl          = "https://www.microsoft.com/legal/terms-of-use"
    useAgenticUserTemplate = $true
    agenticUserTemplate    = @{
        Id                       = "digitalWorkerTemplate"
        File                     = "agenticUserTemplateManifest.json"
        SchemaVersion            = "0.1.0-preview"
        AgentIdentityBlueprintId = $c.BlueprintClientId
        CommunicationProtocol    = "activityProtocol"
    }
} | ConvertTo-Json -Depth 10

Write-Host "Publishing digital worker for agent GUID $AgentGuid ..."
try {
    $resp = Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers @{
        "Content-Type" = "application/json"; Accept = "application/json"; Authorization = "Bearer $token"
    }
    $resp | ConvertTo-Json -Depth 10 | Write-Host
    Write-Host "Published." -ForegroundColor Green
}
catch {
    $err = $null
    try { $err = $_.ErrorDetails.Message | ConvertFrom-Json } catch {}
    if ($err.error.code -eq "UserError" -and $err.error.message -like "*version already exists*") {
        Write-Host "Digital worker already published for this version. Skipping."
    }
    else { throw }
}
