# Shared helpers for the deploy scripts. Dot-source this at the top of each step.
$ErrorActionPreference = "Stop"

function Get-DeployConfig {
    $dir = $PSScriptRoot
    $configPath = Join-Path $dir "config.ps1"
    if (-not (Test-Path $configPath)) {
        $configPath = Join-Path $dir "config.sample.ps1"
        Write-Host "config.ps1 not found — using config.sample.ps1 defaults." -ForegroundColor Yellow
    }
    return & $configPath
}

function Get-AiAzureToken {
    $t = az account get-access-token --resource https://ai.azure.com --query accessToken -o tsv
    if ([string]::IsNullOrWhiteSpace($t)) { throw "Failed to get ai.azure.com token (run 'az login')." }
    return $t
}

function Get-GraphToken {
    $t = az account get-access-token --resource https://graph.microsoft.com/ --query accessToken -o tsv
    if ([string]::IsNullOrWhiteSpace($t)) { throw "Failed to get Graph token (run 'az login')." }
    return $t
}
