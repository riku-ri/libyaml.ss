#!/usr/bin/env bash

set -eo pipefail

${0%/*}/ENV.sh

set -x
body="$1"
set +x

curl -sSL \
	-u :$TOKEN \
	-X 'POST' \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d '{''"body": '"\"$body\" , "'"name": ''"'"$CI_COMMIT_TAG"'"'' ,"prerelease": true , "draft": false ,  "tag_name": ''"'$CI_COMMIT_TAG'"}' \
	"$API_URL/repos/$CI_REPO/releases"
