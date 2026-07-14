# 02 — Build and push the workmate image with ACR Tasks (cloud build).
#
# Reuses an existing registry. The image bakes the M365 Agents SDK connection
# config + Responses endpoint via build args (see foundry-infra/Dockerfile).
. "$PSScriptRoot/_common.ps1"
$c = Get-DeployConfig

# Force UTF-8 so ACR log streaming doesn't crash on Windows cp1252 consoles.
$env:PYTHONUTF8 = "1"; $env:PYTHONIOENCODING = "utf-8"
cmd /c "chcp 65001 >nul"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

if ([string]::IsNullOrWhiteSpace($c.BlueprintClientId)) {
    throw "BlueprintClientId is empty. Run 01-create-blueprint.ps1 and set it in config.ps1."
}

$context = Resolve-Path "$PSScriptRoot/../src/workmate_agent"
Get-ChildItem -Path $context -Filter "__pycache__" -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

$authority = "https://login.microsoftonline.com/$($c.TenantId)"

Write-Host "Building $($c.ImageName) in registry $($c.ContainerRegistry) from $context"
az acr build `
    --registry $c.ContainerRegistry `
    --image $c.ImageName `
    --file "$context/foundry-infra/Dockerfile" `
    --build-arg BLUEPRINT_CLIENT_ID=$($c.BlueprintClientId) `
    --build-arg AUTHORITY_ENDPOINT=$authority `
    --build-arg TENANT_ID=$($c.TenantId) `
    --build-arg AZURE_OPENAI_ENDPOINT=$($c.ResponsesEndpoint) `
    --build-arg MODEL_DEPLOYMENT=$($c.ModelDeployment) `
    $context 2>&1 | ForEach-Object { "$_" }

if ($LASTEXITCODE -ne 0) { throw "ACR build failed ($LASTEXITCODE)." }
Write-Host "Pushed $($c.ContainerRegistryEndpoint)/$($c.ImageName)" -ForegroundColor Green
