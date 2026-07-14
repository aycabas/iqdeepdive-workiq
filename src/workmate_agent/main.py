# Copyright (c) Microsoft. All rights reserved.

"""Entry point — starts the generic host with :class:`FoundryDigitalWorkerAgent`.

Equivalent of ``Program.cs`` in the original C# sample.
"""

from __future__ import annotations

import sys

from .agent import FoundryDigitalWorkerAgent
from .host_agent_server import create_and_run_host


def main() -> int:
    try:
        print("Starting Workmate (Work IQ digital worker) A365 host...")
        create_and_run_host(FoundryDigitalWorkerAgent)
    except Exception as ex:
        print(f"❌ Failed to start server: {ex}")
        import traceback

        traceback.print_exc()
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
