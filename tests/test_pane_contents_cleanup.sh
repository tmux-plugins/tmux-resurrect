#!/usr/bin/env bash
set -uo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAVE_SCRIPT="$CURRENT_DIR/../scripts/save.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() { printf 'PASS %s\n' "$1"; pass=$((pass + 1)); }
no() { printf 'FAIL %s\n' "$1" >&2; fail=$((fail + 1)); }

cleanup_function="$({
	awk '
		/^remove_saved_pane_contents\(\) \{/ { found=1 }
		found { print }
		found && /^}$/ { exit }
	' "$SAVE_SCRIPT"
})"

if [[ "$cleanup_function" == remove_saved_pane_contents* ]] && grep -q '^}$' <<< "$cleanup_function"; then
	ok 'extract exact remove_saved_pane_contents implementation from save.sh'
else
	no 'cannot extract remove_saved_pane_contents from save.sh'
fi

run_cleanup() {
	local pane_dir="$1"
	local suffix="${2:-}"
	PANE_FIXTURE_DIR="$pane_dir" PANE_FIXTURE_SUFFIX="$suffix" CLEANUP_FUNCTION="$cleanup_function" \
		bash -c '
			pane_contents_dir() { printf "%s%s" "$PANE_FIXTURE_DIR" "$PANE_FIXTURE_SUFFIX"; }
			eval "$CLEANUP_FUNCTION"
			remove_saved_pane_contents
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

mutant_function="$(printf '%s\n' "$cleanup_function" | sed -e 's/shopt -s nullglob/: # nullglob disabled/' -e 's/rm -f --/rm --/')"
mutant="$TMP/mutant-empty"
mkdir -p "$mutant"
if PANE_FIXTURE_DIR="$mutant" PANE_FIXTURE_SUFFIX='' CLEANUP_FUNCTION="$mutant_function" \
	bash -c '
		pane_contents_dir() { printf "%s%s" "$PANE_FIXTURE_DIR" "$PANE_FIXTURE_SUFFIX"; }
		eval "$CLEANUP_FUNCTION"
		remove_saved_pane_contents
	' >/dev/null 2>&1; then
	no 'disablement mutant unexpectedly remained green'
else
	ok 'disablement mutant is RED on an empty directory'
fi

if bash -n "$SAVE_SCRIPT" && bash -n "$0"; then
	ok 'save.sh and cleanup PAT pass bash syntax checks'
else
	no 'bash syntax check failed'
fi

printf 'RESULT pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
