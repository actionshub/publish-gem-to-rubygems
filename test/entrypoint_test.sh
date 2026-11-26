#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIRS=()
FAILURES=0

RUN_DIR=""
BIN_DIR=""
HOME_DIR=""
WORKSPACE_DIR=""
STDOUT_FILE=""
STDERR_FILE=""
GEM_LOG=""
EXIT_CODE=0

function cleanup() {
  if [ "${#TEST_DIRS[@]}" -gt 0 ]; then
    rm -rf "${TEST_DIRS[@]}"
  fi
}

trap cleanup EXIT

function prepare_run() {
  local test_name="${1}"

  RUN_DIR="$(mktemp -d)"
  TEST_DIRS+=("${RUN_DIR}")
  BIN_DIR="${RUN_DIR}/bin"
  HOME_DIR="${RUN_DIR}/home"
  WORKSPACE_DIR="${RUN_DIR}/workspace"
  STDOUT_FILE="${RUN_DIR}/stdout"
  STDERR_FILE="${RUN_DIR}/stderr"
  GEM_LOG="${RUN_DIR}/gem.log"

  mkdir -p "${BIN_DIR}" "${HOME_DIR}" "${WORKSPACE_DIR}"

  cat > "${BIN_DIR}/git" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB

  cat > "${BIN_DIR}/gem" <<'STUB'
#!/usr/bin/env bash

echo "$*" >> "${GEM_LOG}"

case "${GEM_STUB_MODE}:${1}" in
  build_failure:build)
    echo "build failed" >&2
    exit 42
    ;;
  no_artifact:build)
    exit 0
    ;;
  push_failure:push)
    echo "Access Denied" >&2
    exit 43
    ;;
  mfa_timeout:push)
    echo "ERROR: execution expired while waiting for WebAuthn" >&2
    exit 1
    ;;
  *:build)
    gem_name="${2%.gemspec}-0.1.0.gem"
    touch "${gem_name}"
    exit 0
    ;;
  *:push)
    exit 0
    ;;
  *)
    echo "unexpected gem command: $*" >&2
    exit 99
    ;;
esac
STUB

  chmod +x "${BIN_DIR}/git" "${BIN_DIR}/gem"
  echo "Running ${test_name}"
}

function run_entrypoint() {
  local test_name="${1}"
  local stub_mode="${2}"
  local token="${3}"
  shift 3

  prepare_run "${test_name}"

  local gemspec
  for gemspec in "$@"; do
    touch "${WORKSPACE_DIR}/${gemspec}"
  done

  HOME="${HOME_DIR}" \
    GITHUB_WORKSPACE="${WORKSPACE_DIR}" \
    INPUT_TOKEN="${token}" \
    GEM_LOG="${GEM_LOG}" \
    GEM_STUB_MODE="${stub_mode}" \
    PATH="${BIN_DIR}:${PATH}" \
    "${ROOT_DIR}/entrypoint.sh" > "${STDOUT_FILE}" 2> "${STDERR_FILE}"

  EXIT_CODE=$?
}

function fail() {
  local message="${1}"

  echo "FAIL: ${message}"
  echo "--- stdout ---"
  cat "${STDOUT_FILE}"
  echo "--- stderr ---"
  cat "${STDERR_FILE}"
  echo "--- gem log ---"
  if [ -f "${GEM_LOG}" ]; then
    cat "${GEM_LOG}"
  fi
  FAILURES=$((FAILURES + 1))
}

function assert_exit_code() {
  local expected="${1}"
  local message="${2}"

  if [ "${EXIT_CODE}" -ne "${expected}" ]; then
    fail "${message}: expected exit ${expected}, got ${EXIT_CODE}"
  fi
}

function assert_file_contains() {
  local file="${1}"
  local expected="${2}"
  local message="${3}"

  if ! grep -Fq "${expected}" "${file}"; then
    fail "${message}: expected ${file} to contain '${expected}'"
  fi
}

run_entrypoint "missing token fails before build" success "" example.gemspec
assert_exit_code 2 "missing token"
assert_file_contains "${STDOUT_FILE}" "Missing input.token!" "missing token message"

run_entrypoint "missing gemspec fails" success "test-token"
assert_exit_code 1 "missing gemspec"
assert_file_contains "${STDERR_FILE}" "No gemspec files found" "missing gemspec message"

run_entrypoint "gem build failure fails the action" build_failure "test-token" example.gemspec
assert_exit_code 42 "gem build failure"
assert_file_contains "${STDERR_FILE}" "build failed" "build failure message"

run_entrypoint "missing built gem fails" no_artifact "test-token" example.gemspec
assert_exit_code 1 "missing built gem"
assert_file_contains "${STDERR_FILE}" "No gem files found" "missing built gem message"

run_entrypoint "gem push failure fails the action" push_failure "test-token" example.gemspec
assert_exit_code 43 "gem push failure"
assert_file_contains "${STDERR_FILE}" "Access Denied" "push failure message"

run_entrypoint "WebAuthn timeout fails the action" mfa_timeout "test-token" example.gemspec
assert_exit_code 1 "WebAuthn timeout"
assert_file_contains "${STDERR_FILE}" "execution expired" "WebAuthn timeout message"

run_entrypoint "successful build pushes every built gem" success "test-token" alpha.gemspec beta.gemspec
assert_exit_code 0 "successful publish"
assert_file_contains "${GEM_LOG}" "build alpha.gemspec" "alpha gem built"
assert_file_contains "${GEM_LOG}" "build beta.gemspec" "beta gem built"
assert_file_contains "${GEM_LOG}" "push --key rubygems alpha-0.1.0.gem" "alpha gem pushed"
assert_file_contains "${GEM_LOG}" "push --key rubygems beta-0.1.0.gem" "beta gem pushed"
assert_file_contains "${HOME_DIR}/.gem/credentials" ":rubygems_api_key: test-token" "rubygems credentials written"

if [ "${FAILURES}" -gt 0 ]; then
  echo "${FAILURES} test failure(s)"
  exit 1
fi

echo "All entrypoint tests passed"
