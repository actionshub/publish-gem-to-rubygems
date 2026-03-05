#!/bin/bash
set -e

# Trust the workspace directory
git config --global --add safe.directory "${GITHUB_WORKSPACE}"

function validate_input() {
  if [ -z "${INPUT_TOKEN}" ]; then
    echo "::error::Missing 'token' input"
    exit 1
  fi
}

function setup_credentials() {
  echo "Configuring RubyGems credentials..."
  mkdir -p ~/.gem
  printf "---\n:rubygems_api_key: %s\n" "${INPUT_TOKEN}" > ~/.gem/credentials
  chmod 0600 ~/.gem/credentials
}

function build_gems() {
  echo "Building gems..."
  local count=0
  for spec in *.gemspec; do
    if [ -f "$spec" ]; then
      gem build "$spec"
      ((count++))
    fi
  done

  if [ "$count" -eq 0 ]; then
    echo "::warning::No gemspec files found in ${GITHUB_WORKSPACE}"
  fi
}

function push_gems() {
  echo "Pushing gems to RubyGems.org..."
  local count=0
  for gemfile in *.gem; do
    if [ -f "$gemfile" ]; then
      gem push "$gemfile"
      ((count++))
    fi
  done

  if [ "$count" -eq 0 ]; then
    echo "::warning::No .gem files found to push"
  fi
}

# Main execution
cd "${GITHUB_WORKSPACE}"

validate_input
setup_credentials
build_gems
push_gems
