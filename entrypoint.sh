#!/bin/bash

git config --global --add safe.directory "${GITHUB_WORKSPACE}"

TOKEN="${INPUT_TOKEN}"
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
  find . -name '*.gemspec' -maxdepth 1 -exec gem build {} \;
  echo "Pushing gem to rubygems.org"
  find . -name '*.gem' -maxdepth 1 -exec gem push --key "${2}" {} \;
}

setup_credentials_file
auth_rubygems "${TOKEN}"
build_and_push "${GITHUB_WORKSPACE}" "rubygems"
