#!/usr/bin/env bash
set -uo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESTORE_SCRIPT="$CURRENT_DIR/../scripts/restore.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() { printf 'PASS %s\n' "$1"; pass=$((pass + 1)); }
no() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail + 1)); }

cleanup_function="$({
	awk '
		/^remove_restored_pane_contents\(\) \{/ { found=1 }
		found { print }
		found && /^}$/ { exit }
	' "$RESTORE_SCRIPT"
})"

if [[ "$cleanup_function" == remove_restored_pane_contents* ]] && grep -q '^}$' <<< "$cleanup_function"; then
	ok 'extract exact remove_restored_pane_contents implementation from restore.sh'
else
	no 'cannot extract remove_restored_pane_contents from restore.sh'
fi

run_cleanup() {
	local pane_dir="$1"
	local suffix="${2:-}"
	PANE_FIXTURE_DIR="$pane_dir" PANE_FIXTURE_SUFFIX="$suffix" CLEANUP_FUNCTION="$cleanup_function" \
		bash -c '
			pane_contents_dir() { printf "%s%s" "$PANE_FIXTURE_DIR" "$PANE_FIXTURE_SUFFIX"; }
			eval "$CLEANUP_FUNCTION"
			remove_restored_pane_contents
		'
}

empty="$TMP/empty"
mkdir -p "$empty"
if run_cleanup "$empty" && [[ -d "$empty" ]] && [[ -z "$(find "$empty" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
	ok 'empty directory cleanup is an idempotent success'
else
	no 'empty directory cleanup failed or created an entry'
fi

populated="$TMP/populated"
mkdir -p "$populated"
printf a > "$populated/pane-alpha"
printf b > "$populated/pane-beta"
if run_cleanup "$populated" && [[ ! -e "$populated/pane-alpha" ]] && [[ ! -e "$populated/pane-beta" ]]; then
	ok 'populated pane-* files are removed'
else
	no 'populated pane-* cleanup did not remove the exact files'
fi

sentinel="$TMP/sentinel"
mkdir -p "$sentinel"
printf keep > "$sentinel/not-a-pane"
printf drop > "$sentinel/pane-drop"
if run_cleanup "$sentinel" && [[ -f "$sentinel/not-a-pane" ]] && [[ ! -e "$sentinel/pane-drop" ]]; then
	ok 'nonmatching sentinel is preserved while pane-* is removed'
else
	no 'cleanup broadened beyond pane-* or failed to remove pane-*'
fi

double_slash="$TMP/double-slash"
mkdir -p "$double_slash"
printf keep > "$double_slash/sentinel"
printf drop > "$double_slash/pane-drop"
if run_cleanup "$double_slash" '//' && [[ -f "$double_slash/sentinel" ]] && [[ ! -e "$double_slash/pane-drop" ]]; then
	ok 'trailing double slash remains bounded and successful'
else
	no 'double-slash path changed cleanup semantics'
fi

bounded="$TMP/bounded"
mkdir -p "$bounded/nested"
printf nested > "$bounded/nested/pane-nested"
printf top > "$bounded/pane-top"
if run_cleanup "$bounded" && [[ -f "$bounded/nested/pane-nested" ]] && [[ ! -e "$bounded/pane-top" ]]; then
	ok 'cleanup is one-directory bounded and nonrecursive'
else
	no 'cleanup recursed or failed to remove the top-level pane file'
fi

# Direct nullglob-state assertion.
#
# The comment inside the function claims it does not change the caller's shell
# options. Every other arm here would stay green if someone replaced the
# subshell with a brace group, so the claim needs an arm of its own: read
# nullglob before and after the call and require the two to be identical, under
# both initial states.
nullglob_state="$TMP/nullglob-state"
mkdir -p "$nullglob_state"
printf drop > "$nullglob_state/pane-drop"
leak_probe() {
	local initial="$1"
	PANE_FIXTURE_DIR="$nullglob_state" CLEANUP_FUNCTION="$cleanup_function" INITIAL="$initial" \
		bash -c '
			shopt "-$INITIAL" nullglob
			before="$(shopt -p nullglob)"
			pane_contents_dir() { printf "%s" "$PANE_FIXTURE_DIR"; }
			eval "$CLEANUP_FUNCTION"
			remove_restored_pane_contents
			after="$(shopt -p nullglob)"
			[[ "$before" == "$after" ]]
		'
}
if leak_probe u && leak_probe s; then
	ok 'nullglob state is identical before and after, from both initial states'
else
	no 'cleanup leaked its nullglob setting into the caller'
fi

mutant_function="$(printf '%s\n' "$cleanup_function" | sed -e 's/shopt -s nullglob/: # nullglob disabled/' -e 's/rm -f --/rm --/')"
mutant="$TMP/mutant-empty"
mkdir -p "$mutant"
if PANE_FIXTURE_DIR="$mutant" PANE_FIXTURE_SUFFIX='' CLEANUP_FUNCTION="$mutant_function" \
	bash -c '
		pane_contents_dir() { printf "%s%s" "$PANE_FIXTURE_DIR" "$PANE_FIXTURE_SUFFIX"; }
		eval "$CLEANUP_FUNCTION"
		remove_restored_pane_contents
	' >/dev/null 2>&1; then
	no 'disablement mutant unexpectedly remained green'
else
	ok 'disablement mutant is RED on an empty directory'
fi

# Behavior mutant: restore the pre-fix semantics (unbounded glob, no nullglob)
# and require the sentinel arm to notice. The disablement mutant above only
# proves the empty-directory path; this one proves the narrowing to pane-* is
# what stops the cleanup from deleting everything in the directory.
behavior_function='remove_restored_pane_contents() {
	local pane_dir="$(pane_contents_dir "restore")"
	rm "${pane_dir%/}"/*
}'
behavior="$TMP/behavior"
mkdir -p "$behavior"
printf keep > "$behavior/not-a-pane"
printf drop > "$behavior/pane-drop"
PANE_FIXTURE_DIR="$behavior" CLEANUP_FUNCTION="$behavior_function" \
	bash -c '
		pane_contents_dir() { printf "%s" "$PANE_FIXTURE_DIR"; }
		eval "$CLEANUP_FUNCTION"
		remove_restored_pane_contents
	' >/dev/null 2>&1
if [[ ! -e "$behavior/not-a-pane" ]]; then
	ok 'behavior mutant deletes the sentinel, so the pane-* narrowing is load-bearing'
else
	no 'behavior mutant left the sentinel, so this suite cannot detect an unbounded glob'
fi

if bash -n "$RESTORE_SCRIPT" && bash -n "$0"; then
	ok 'restore.sh and cleanup PAT pass bash syntax checks'
else
	no 'bash syntax check failed'
fi

printf 'RESULT pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
