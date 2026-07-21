"""Write local Work IQ notebook and agent settings to the repository root .env file."""

import os
from pathlib import Path

from dotenv import set_key

REPO_ROOT = Path(__file__).parents[1]
ENV_PATH = REPO_ROOT / ".env"


def main() -> None:
    """Copy the azd-provisioned settings the notebooks and agent need into .env."""
    ENV_PATH.touch()
    values = {
        "AZURE_TENANT_ID": os.environ["AZURE_TENANT_ID"],
        "AZURE_SUBSCRIPTION_ID": os.environ.get("AZURE_SUBSCRIPTION_ID", ""),
        "AZURE_RESOURCE_GROUP": os.environ.get("AZURE_RESOURCE_GROUP", ""),
        "FOUNDRY_PROJECT_ENDPOINT": os.environ["FOUNDRY_PROJECT_ENDPOINT"],
        "AZURE_AI_PROJECT_ENDPOINT": os.environ.get(
            "AZURE_AI_PROJECT_ENDPOINT", os.environ["FOUNDRY_PROJECT_ENDPOINT"]
        ),
        "AZURE_AI_PROJECT_ID": os.environ["AZURE_AI_PROJECT_ID"],
        "AZURE_AI_MODEL_DEPLOYMENT_NAME": os.environ["AZURE_AI_MODEL_DEPLOYMENT_NAME"],
        "CUSTOM_FOUNDRY_WORKIQ_TOOLBOX_NAME": os.environ.get(
            "CUSTOM_FOUNDRY_WORKIQ_TOOLBOX_NAME", "work-iq-tools"
        ),
        "WORK_IQ_CONNECTION_NAME": os.environ.get(
            "WORK_IQ_CONNECTION_NAME", "work-iq-connection"
        ),
    }
    for key, value in values.items():
        set_key(ENV_PATH, key, value, quote_mode="never")
    print(f"Wrote {ENV_PATH}")


if __name__ == "__main__":
    main()
