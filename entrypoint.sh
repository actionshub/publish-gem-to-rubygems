#!/bin/bash

cd "${GITHUB_WORKSPACE}" || exit 1
git config --global --add safe.directory "${GITHUB_WORKSPACE}"

TOKEN="${1}"
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

function build() {
  echo "Building gem"
  find . -name '*.gemspec' -maxdepth 1 -exec gem build {} \;
  echo "Pushing gem to rubygems.org"
  find . -name '*.gem' -maxdepth 1 -exec gem push --key "${1}" {} \;
}

setup_credentials_file
auth_rubygems "${TOKEN}"
build_and_push "rubygems"
