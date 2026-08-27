#!/usr/bin/env bash
# Convenience wrapper for stage (same pattern as prod/dev).
ENVIRONMENT=stage exec "$(dirname "$0")/eks-port-forward-dev.sh" "$@"
