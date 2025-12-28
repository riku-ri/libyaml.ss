#!/usr/bin/env bash

set -euo pipefail
# woodpecker tag event variables:
CI_COMMIT_TAG="${CI_COMMIT_TAG}" && test -n "${CI_COMMIT_TAG}"
CI_REPO_URL="${CI_REPO_URL}" && test -n "${CI_REPO_URL}"
CI_REPO="${CI_REPO}" && test -n "${CI_REPO}"
CI_REPO_NAME="${CI_REPO_NAME}" && test -n "${CI_REPO_NAME}"
CI_REPO_CLONE_URL="${CI_REPO_CLONE_URL}" && test -n "${CI_REPO_CLONE_URL}"

# other variables:
API_URL="${API_URL}" && test -n "${API_URL}"
	#https://codeberg.org/api/v1
