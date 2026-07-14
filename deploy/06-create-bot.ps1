# 06 — Create the Azure Bot + Microsoft Teams channel (the Teams transport).
#
# Without this, Teams has no registered app to deliver messages to and the
# digital worker never replies. msaAppId = the blueprint clientId; the endpoint
# is the agent's activity-protocol URL; SingleTenant.
. "$PSScriptRoot/_common.ps1"
$c = Get-DeployConfig

if ([string]::IsNullOrWhiteSpace($c.BlueprintClientId)) {
    throw "BlueprintClientId is empty. Run 01-create-blueprint.ps1 and set it in config.ps1."
}

$botName = "$($c.AgentName)-bot"
$endpoint = "$($c.ProjectEndpoint)/agents/$($c.AgentName)/endpoint/protocols/activityprotocol?api-version=2025-11-15-preview"

$botId = "/subscriptions/$($c.SubscriptionId)/resourceGroups/$($c.ResourceGroup)/providers/Microsoft.BotService/botServices/$botName"

$botProps = @{
    location   = "global"
    kind       = "azurebot"
    sku        = @{ name = "F0" }
    properties = @{
        displayName    = "Workmate"
        endpoint       = $endpoint
        msaAppId       = $c.BlueprintClientId
        msaAppTenantId = $c.TenantId
        msaAppType     = "SingleTenant"
    }
} | ConvertTo-Json -Depth 6

$tmp = New-TemporaryFile
Set-Content -Path $tmp -Value $botProps -Encoding utf8
Write-Host "Creating Azure Bot '$botName' -> $endpoint"
az resource create --id $botId --api-version 2022-09-15 --properties "@$tmp" | Out-Null
Remove-Item $tmp -Force

# Enable the Microsoft Teams channel.
$channelId = "$botId/channels/MsTeamsChannel"
$channelProps = @{ location = "global"; properties = @{ channelName = "MsTeamsChannel"; properties = @{} } } | ConvertTo-Json -Depth 6
$tmp2 = New-TemporaryFile
Set-Content -Path $tmp2 -Value $channelProps -Encoding utf8
Write-Host "Enabling Microsoft Teams channel..."
az resource create --id $channelId --api-version 2022-09-15 --properties "@$tmp2" | Out-Null
Remove-Item $tmp2 -Force

Write-Host "Bot '$botName' + Teams channel created." -ForegroundColor Green
Write-Host "In Teams, open the published Workmate digital worker and send a message." -ForegroundColor Yellow
