#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

hypercorn backend.services.$SERVICE_NAME:api