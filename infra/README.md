# infra

`azd up` binds to a Foundry project (the `ai-project-workmate-agent-dev` service in
`azure.yaml`), then `hooks/postprovision` provisions everything the Work IQ agent needs:

- **`setup-env.py`** — copies the resolved project settings (`FOUNDRY_PROJECT_ENDPOINT`,
  `AZURE_AI_PROJECT_ID`, `AZURE_AI_MODEL_DEPLOYMENT_NAME`, toolbox/connection names) into a
  local `.env` so the notebooks and a local `main.py` run pick them up.
- **`create-workiq-toolbox.py`** — the one infra script that matters for Work IQ. It:
  1. ensures the tenant's Work IQ service principal exists (app id
     `fdcc1f02-fc51-4226-8753-f668596af7f7`),
  2. creates a **single-tenant Entra app** with the delegated `WorkIQAgent.Ask` scope,
     grants **tenant-wide admin consent** (needs a Global Administrator), and adds a client
     secret + the Foundry OAuth redirect URI,
  3. creates a Foundry **`RemoteA2A` OAuth2 connection** (`work-iq-connection`) targeting the
     Work IQ A2A gateway `https://workiq.svc.cloud.microsoft/a2a/`
     (scopes `WorkIQAgent.Ask` + `offline_access`), and
  4. creates the **`work-iq-tools` toolbox** (`WorkIQPreviewToolboxTool`) that the hosted
     `workmate-agent` mounts as its only tool.

  Run it standalone with `uv run python infra/create-workiq-toolbox.py --apply`
  (`--dry-run` just validates env inputs).

This mirrors [pamelafox/iqdeepdive-foundryiq](https://github.com/pamelafox/iqdeepdive-foundryiq)'s
Work IQ setup. There is no `main.bicep` here because this repo **reuses an existing Foundry
project** (set via `azd env`) rather than provisioning a new account. The Foundry project must
**not** be VNet-restricted — Work IQ does not support VNet-integrated projects.
