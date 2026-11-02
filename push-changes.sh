#!/usr/bin/env bash

set -euo pipefail

commit_message="${1:-Update project}"

git add .
git commit -m "$commit_message"
git push
