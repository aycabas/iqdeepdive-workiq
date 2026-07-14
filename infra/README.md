# infra

`azd up` provisions a Foundry project + `gpt-5.4` (`main.bicep`), then `hooks/postprovision`
creates the **Work IQ `RemoteA2A`** connection and writes `WORK_IQ_CONNECTION_ID` to `.env`.

- `main.bicep` / `main.parameters.json` — Foundry account + project + model deployment.
  Adapt from the series template (`pamelafox/iqdeepdive-foundryiq/infra`), dropping Azure AI
  Search / Fabric (not needed for Work IQ) and keeping the account + project + `gpt-5.4`.
  **Do not** enable VNet restriction — Work IQ does not support VNet-integrated projects.
- `setup-workiq-connection.py` — creates the `RemoteA2A` connection targeting
  `https://workiq.svc.cloud.microsoft/a2a/` (`authType=OAuth2`, BYO Entra app, scopes
  `WorkIQAgent.Ask` + `offline_access`) per the
  [Work IQ tool docs](https://learn.microsoft.com/azure/foundry/agents/how-to/tools/work-iq).
- `hooks/` — postprovision scripts (pwsh + sh).
