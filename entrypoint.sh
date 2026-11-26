#!/bin/bash

set -euo pipefail
shopt -s nullglob dotglob

git config --global --add safe.directory "${GITHUB_WORKSPACE}"

TOKEN="${INPUT_TOKEN:-}"
[ -z "${TOKEN}" ] && { echo "Missing input.token!"; exit 2; }

function setup_credentials_file() {
  echo "Setting up access to RubyGems"
  mkdir -p ~/.gem
  touch ~/.gem/credentials
  chmod 600 ~/.gem/credentials
}

function auth_rubygems() {
  echo "Logging in to RubyGems"
  echo ":rubygems_api_key: ${1}" > ~/.gem/credentials
}

function build_and_push() {
  cd "${1}" || exit 1
  echo "Building gem"

  local gemspecs=(./*.gemspec)
  if [ "${#gemspecs[@]}" -eq 0 ]; then
    echo "No gemspec files found" >&2
    exit 1
  fi

  for gemspec in "${gemspecs[@]}"; do
    gem build "${gemspec}"
  done

  echo "Pushing gem to rubygems.org"

  local gems=(./*.gem)
  if [ "${#gems[@]}" -eq 0 ]; then
    echo "No gem files found" >&2
    exit 1
  fi

  for gem in "${gems[@]}"; do
    gem push --key "${2}" "${gem}"
  done
}

setup_credentials_file
auth_rubygems "${TOKEN}"
build_and_push "${GITHUB_WORKSPACE}" "rubygems"
