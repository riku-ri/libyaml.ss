#!/usr/bin/env bash

set -exuo pipefail

CI_REPO_NAME="${CI_REPO_NAME}" && test -n "${CI_REPO_NAME}"
CI_COMMIT_TAG="${CI_COMMIT_TAG}" && test -n "${CI_COMMIT_TAG}"

git submodule update --init --recursive
git submodule foreach sh -c 'git archive HEAD '"--prefix=$CI_REPO_NAME/$CI_COMMIT_TAG/"'$(realpath --relative-to=$(git rev-parse --show-superproject-working-tree) .)/ | tar x -C $(git rev-parse --show-superproject-working-tree)/.local'
git archive HEAD --prefix="$CI_REPO_NAME/$CI_COMMIT_TAG/" | tar x -C .local
