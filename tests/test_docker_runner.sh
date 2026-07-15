#!/usr/bin/env bash

set -eu

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=run_tests_in_docker
source "$current_dir/run_tests_in_docker"

DOCKER_INSPECT_LABEL=""
DOCKER_RM_CALLS=0

docker() {
	case "$1" in
		inspect)
			printf '%s\n' "$DOCKER_INSPECT_LABEL"
			;;
		rm)
			DOCKER_RM_CALLS=$((DOCKER_RM_CALLS + 1))
			;;
		*)
			printf 'Unexpected docker operation in unit test: %s\n' \
				"$1" >&2
			return 1
			;;
	esac
}

assert_equal() {
	local expected="$1"
	local actual="$2"
	local message="$3"
	if [ "$expected" = "$actual" ]; then
		return 0
	fi
	printf 'FAIL: %s: expected [%s], got [%s]\n' \
		"$message" "$expected" "$actual" >&2
	return 1
}

test_foreign_container_is_not_removed() {
	container_id="foreign-container"
	DOCKER_INSPECT_LABEL="another-run"
	DOCKER_RM_CALLS=0
	if remove_container 2>/dev/null; then
		printf 'FAIL: foreign container removal should be rejected\n' >&2
		return 1
	fi
	assert_equal "0" "$DOCKER_RM_CALLS" \
		"foreign container remove calls"
}

test_owned_container_is_removed() {
	container_id="owned-container"
	# Defined by the sourced runner; ShellCheck cannot follow the dynamic path.
	# shellcheck disable=SC2154
	DOCKER_INSPECT_LABEL="$run_id"
	DOCKER_RM_CALLS=0
	remove_container
	assert_equal "1" "$DOCKER_RM_CALLS" \
		"owned container remove calls"
	assert_equal "" "$container_id" \
		"owned container ID cleared"
}

main() {
	test_foreign_container_is_not_removed
	test_owned_container_is_removed
	printf 'Docker runner ownership tests passed\n'
}

main "$@"
