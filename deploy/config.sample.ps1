# =============================================================================
# Workmate hosted-agent deploy configuration
#
# Copy to `config.ps1` (gitignored) and adjust for your tenant/project, then run
# the numbered scripts in order (see deploy/README.md). Every value here is an
# Azure resource identifier, not a secret.
#
# The design: run the hosted `workmate` agent **inside an existing Foundry
# project** (here `4iq-foundry-project`), reusing that project's Work IQ
# connection + model + an existing ACR. Only two new resources are created — the
# agent-identity **blueprint** and the **Azure Bot** (Teams transport).
# =============================================================================

$Config = @{
    SubscriptionId              = "27b0139a-16b4-42bf-9ec9-c6db3768245e"
    ResourceGroup               = "rg-aycabas-3iqs"
    Location                    = "eastus2"

    # Existing Foundry project that hosts the agent AND owns the Work IQ + model.
    AccountName                 = "4iq-foundry-project-resource"
    ProjectName                 = "4iq-foundry-project"
    ProjectEndpoint             = "https://4iq-foundry-project-resource.services.ai.azure.com/api/projects/4iq-foundry-project"

    # Responses endpoint the agent calls (same project — Work IQ lives here).
    ResponsesEndpoint           = "https://4iq-foundry-project-resource.services.ai.azure.com/api/projects/4iq-foundry-project"

    # Reused, existing Azure Container Registry (Basic is fine).
    ContainerRegistry           = "ca31c6a7351facr"           # name only
    ContainerRegistryEndpoint   = "ca31c6a7351facr.azurecr.io"
    ImageName                   = "workmate-agent:latest"

    # Model deployment already present in the project.
    ModelDeployment             = "gpt-5.4-mini"

    # New dedicated agent + identity blueprint.
    AgentName                   = "workmate"
    MaibName                    = "workmate-maib"

    # Filled in by 01-create-blueprint.ps1 (the blueprint app clientId).
    # Used as the bot msaAppId and the SP that receives the OAuth2 grants.
    BlueprintClientId           = ""

    TenantId                    = "a9d9510e-7131-4355-8b7e-37e7b1e99862"

    # Work IQ project connection name in the project (must already exist).
    WorkIqConnectionId          = "WorkIQ"
}

$Config
