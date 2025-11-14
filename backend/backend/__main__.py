import sys

sys.path.insert(0, ".")

from backend.cli import cli
from backend.base import CLIError

try:
    cli.run(sys.argv[1:])
except CLIError as err:
    print(err, file=sys.stderr)
    sys.exit(1)
