#!/bin/bash
set -eu

# This script checks if head repo of PR is up to date with ufs-weather-model develop
# Checks for top level (ufs-weather-model) and next level components (submodules)
result() {
  if [[ -n $comment ]]; then
    logID=$1
    comment="@$logID please bring these up to date with respective authoritative repositories\n"$comment
    printf %s "$comment"
    #exit 1
  fi
}

# Declare variables
declare -A base fv3
submodules="fv3"
comment=''
ownerID=$1

# Base branch: this is the top of develop of ufs-weather-model
base[repo]='https://github.com/jkbk2004/gitact'
base[branch]='main'

# Submodules to check
fv3[repo]='https://github.com/NOAA-EMC/fv3atm'
fv3[branch]='develop'
fv3[dir]='FV3'

# Get sha-1's of the top of develop of ufs-weather-model
app="Accept: application/vnd.github.v3+json"
url="https://api.github.com/repos/jkbk2004/gitact/branches/main"
base[sha]=$(curl -sS -H "$app" $url | jq -r '.commit.sha')
for submodule in $submodules; do
  eval url=https://api.github.com/repos/jkbk2004/gitact/contents/'${'$submodule'[dir]}'
  eval $submodule'[sha]=$(curl -sS -H "$app" $url | jq -r '.sha')'
done

# Check if the head branch is up to date with the base branch
cd ${GITHUB_WORKSPACE}
git remote add upstream ${base[repo]}
git fetch -q upstream ${base[branch]}
common=$(git merge-base ${base[sha]} @)
if [[ $common != ${base[sha]} ]]; then
  comment="* ufs-weather-model **NOT** up to date\n"
fi

for submodule in $submodules; do
  eval cd ${GITHUB_WORKSPACE}/'${'$submodule'[dir]}'
  eval git remote add upstream '${'$submodule'[repo]}'
  eval git fetch -q upstream '${'$submodule'[branch]}'
  common=$(eval git merge-base '${'$submodule'[sha]}' @)
  if (eval test $common != '${'$submodule'[sha]}'); then
    comment+="* $submodule **NOT** up to date\n"
  fi
done

result $ownerID
exit 0
