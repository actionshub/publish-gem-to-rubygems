#!/bin/bash

RUBYGEMS_API_KEY=${1}

[ -z "${RUBYGEMS_API_KEY}" ] && { echo "Missing input.rubygems_api_key!"; exit 2; }

echo "Setting up access to RubyGems"
mkdir -p ~/.gem
cat << EOF > ~/.gem/credentials
---
:rubygems_api_key: ${RUBYGEMS_API_KEY}
EOF

echo "Building the gem"
gem build
echo "Pushing the built gem to RubyGems.org"
find . -name '*.gem' -maxdepth 1 -exec gem push {} \;
