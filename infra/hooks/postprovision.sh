#!/bin/sh
set -e

echo "Writing local development settings..."
uv run --locked python infra/setup-env.py

echo "Creating the Work IQ Entra application, RemoteA2A connection, and toolbox..."
uv run --locked python infra/create-workiq-toolbox.py --apply

echo "Postprovision setup complete."
