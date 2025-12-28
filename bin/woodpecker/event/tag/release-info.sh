#!/usr/bin/env bash

set -eo pipefail

${0%/*}/ENV.sh

echo '(repo git "'"$CI_REPO_CLONE_URL"'")' | tee $CI_REPO_NAME.release-info
echo '(uri targz "'"$CI_REPO_URL/releases/download/{egg-release}/$CI_REPO_NAME.tar.gz"'")' | tee -a $CI_REPO_NAME.release-info

curl -sSL \
	-X 'GET' \
	-H 'accept: application/json' \
	"$API_URL/repos/$CI_REPO/releases" \
| jq '.[].tag_name' -c | sed 's/^/(release /' | sed 's/$/)/' \
| tee -a $CI_REPO_NAME.release-info

id="$(curl -sSL \
	-X 'GET' \
	-H 'accept: application/json' \
	"$API_URL/repos/$CI_REPO/releases/tags/$CI_COMMIT_TAG" \
	| jq '.id')"

curl -sSL \
	-u :$TOKEN -X 'POST' \
	-H 'accept: application/json' \
	-H 'Content-Type: multipart/form-data' \
	-F "attachment=@$CI_REPO_NAME.release-info" \
	"$API_URL/repos/$CI_REPO/releases/$id/assets?name=$CI_REPO_NAME.release-info"
