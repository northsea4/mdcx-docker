#!/bin/bash

GITHUB_ACTIONS_API_URL="https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_CURRENT_REPO/actions"
GITHUB_VARIABLES_API_URL="$GITHUB_ACTIONS_API_URL/variables"

CURL_VERBOSE=${CURL_VERBOSE:--s}

extractVariableValue() {
  local value=$(echo $1 | grep -oi 'value": "[^"]*' | sed 's/value": "//g')
  echo $value
}

buildNameValueJson() {
  local name=$1
  local value=$2
  echo "{\"name\":\"${name}\",\"value\":\"${value}\"}"
}

createVariable() {
  # https://docs.github.com/en/rest/actions/variables?apiVersion=2022-11-28#create-a-repository-variable
  local data=$(buildNameValueJson $1 $2)
  local code=$(curl -L $CURL_VERBOSE -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_API_TOKEN"\
    -H "X-GitHub-Api-Version: 2022-11-28" \
    $GITHUB_VARIABLES_API_URL \
    -d "$data")
  # Status: 201
  echo $code
}

updateVariable() {
  local name=$1
  local value=$2
  local data=$(buildNameValueJson $name $value)
  code=$(curl -L $CURL_VERBOSE  \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_API_TOKEN"\
    -H "X-GitHub-Api-Version: 2022-11-28" \
    $GITHUB_VARIABLES_API_URL/$name \
    -d "$data")
  # Status: 204
  echo $code
}

getVariable() {
  # https://docs.github.com/en/rest/actions/variables?apiVersion=2022-11-28#get-a-repository-variable
  local name=$1
  local res=$(curl -L -s \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_API_TOKEN"\
    -H "X-GitHub-Api-Version: 2022-11-28" \
    $GITHUB_VARIABLES_API_URL/$name)
  # {
  #   "name": "USERNAME",
  #   "value": "octocat",
  #   "created_at": "2021-08-10T14:59:22Z",
  #   "updated_at": "2022-01-10T14:59:22Z"
  # }
  echo $(extractVariableValue "$res")
}