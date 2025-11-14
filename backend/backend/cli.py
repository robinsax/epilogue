import uvicorn

from backend.base import CLI, CLIError
from backend.config import config

cli = CLI("backend")

@cli.command(short_names={ "s": "service" })
def serve(service: str):
    if service not in ("direct", "matchmaking"):
        raise CLIError("Invalid service")

    target = "backend.services." + service + ":api"
    uvicorn.run(target, host="0.0.0.0", port=config.service_port)
