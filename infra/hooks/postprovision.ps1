$ErrorActionPreference = "Stop"

Write-Host "Writing local development settings..."
uv run --locked python infra/setup-env.py

Write-Host "Creating the Work IQ Entra application, RemoteA2A connection, and toolbox..."
uv run --locked python infra/create-workiq-toolbox.py --apply

Write-Host "Postprovision setup complete."
