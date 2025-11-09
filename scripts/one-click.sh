#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-deploy}"
ENVIRONMENT="${2:-dev}"

case "$ACTION" in
    "deploy"|"up")
        ./scripts/quick-deploy.sh "$ENVIRONMENT"
        ;;
    "destroy"|"down")
        ./scripts/quick-destroy.sh "$ENVIRONMENT"
        ;;
    *)
        echo "Usage: $0 [deploy|destroy] [dev|staging|prod]"
        echo "Examples:"
        echo "  $0 deploy dev     # Deploy dev environment"
        echo "  $0 destroy prod   # Destroy prod environment"
        exit 1
        ;;
esac# Updated Sun Nov  9 12:50:31 CET 2025
# Updated Sun Nov  9 12:52:07 CET 2025
