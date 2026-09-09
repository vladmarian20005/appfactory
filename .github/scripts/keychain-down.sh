#!/usr/bin/env bash
# Destroy the throwaway keychain created by keychain-up.sh. Always run with `if: always()`;
# a runner is discarded anyway, but leaving a default keychain set breaks later steps.
set -uo pipefail
KEYCHAIN="${RUNNER_TEMP:-/tmp}/factory.keychain-db"
security default-keychain -s login.keychain-db 2>/dev/null || true
security delete-keychain "$KEYCHAIN" 2>/dev/null && echo "keychain destroyed" || echo "no keychain to destroy"
rm -f "${RUNNER_TEMP:-/tmp}/dist.p12"
exit 0
