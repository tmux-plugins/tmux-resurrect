#!/usr/bin/env bash

# benchmark save and restore on a big, generated tmux environment
#
# run on a separate tmux server with its own socket
# your tmux sessions are not touched
#
# Usage:
#   tests/benchmark.sh [-p plugin_dir] [-s sessions] [-w windows] [-n panes]
#                      [-r runs] [-c]
#
#   -p  plugin directory to benchmark (default: this repository)
#   -s  number of sessions                 (default: 6)
#   -w  number of windows per session      (default: 10)
#   -n  number of panes per window         (default: 4)
#   -r  number of save runs, the median is reported (default: 3)
#   -c  attach a tmux client during restore (default: no client)
#
# Prints one CSV line:
#   panes,windows,save_s,save_contents_s,restore_s,pane_create_s,roundtrip
#
#   save_s           saving, pane contents off
#   save_contents_s  saving, pane contents on
#   restore_s        restoring into an empty server (pane contents off)
#   pane_create_s    time tmux itself needs to create the same panes one by
#                    one, a lower bound for restore_s
#   roundtrip        "ok" if saving after restore gives the same file
#                    (ignoring pane ids), number of differing lines otherwise

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PLUGIN_DIR="$CURRENT_DIR/.."
SESSIONS=6
WINDOWS=10
PANES=4
RUNS=3
ATTACH_CLIENT=""

while getopts "p:s:w:n:r:c" opt; do
	case "$opt" in
		p) PLUGIN_DIR="$OPTARG" ;;
		s) SESSIONS="$OPTARG" ;;
		w) WINDOWS="$OPTARG" ;;
		n) PANES="$OPTARG" ;;
		r) RUNS="$OPTARG" ;;
		c) ATTACH_CLIENT="true" ;;
		*) exit 1 ;;
	esac
done
PLUGIN_DIR="$( cd "$PLUGIN_DIR" && pwd )"

SOCKET="resurrect-bench-$$"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/resurrect-bench.XXXXXX")"
CLIENT_PID=""

t() {
	tmux -L "$SOCKET" -f /dev/null "$@"
}

now() {
	if [ -n "$EPOCHREALTIME" ]; then
		echo "${EPOCHREALTIME/,/.}"
	else
		perl -MTime::HiRes=time -e 'printf "%.6f\n", time'
	fi
}

elapsed() {
	awk -v a="$1" -v b="$2" 'BEGIN { printf "%.2f", b - a }'
}

median() {
	sort -n | awk '{ v[NR] = $1 } END { print v[int((NR + 1) / 2)] }'
}

cleanup() {
	[ -n "$CLIENT_PID" ] && kill "$CLIENT_PID" 2>/dev/null
	t kill-server 2>/dev/null
	rm -rf "$WORK_DIR"
}
trap cleanup EXIT

stop_server() {
	[ -n "$CLIENT_PID" ] && kill "$CLIENT_PID" 2>/dev/null
	CLIENT_PID=""
	t kill-server 2>/dev/null
	while t has-session 2>/dev/null; do sleep 0.2; done
	sleep 0.5
}

set_options() {
	t set -g @resurrect-dir "$WORK_DIR/resurrect"
	t set -g @resurrect-processes '"~sleep->sleep *"'
	t set -g history-limit 2000
	# plain shell, so the startup time and title escapes of the user's shell
	# don't affect the timings or the roundtrip check
	t set -g default-shell /bin/sh
}

# create each window's panes and tiled layout with one tmux command
# every 3rd window runs a process that should be restored
# every pane has some output
create_environment() {
	local s w p
	local -a cmd
	t new-session -d -s "s0" -x 250 -y 80 -c /tmp
	set_options
	for ((s = 0; s < SESSIONS; s++)); do
		[ "$s" -gt 0 ] && t new-session -d -s "s$s" -x 250 -y 80 -c /tmp
		for ((w = 0; w < WINDOWS; w++)); do
			cmd=()
			[ "$w" -gt 0 ] && cmd+=(new-window -d -t "s$s:$w" -c /tmp \;)
			for ((p = 1; p < PANES; p++)); do
				cmd+=(split-window -d -t "s$s:$w" -c /tmp \; select-layout -t "s$s:$w" tiled \;)
			done
			for ((p = 0; p < PANES; p++)); do
				cmd+=(send-keys -t "s$s:$w.$p" "seq 1 $(( (p + 1) * 20 ))" C-m \;)
			done
			if [ $((w % 3)) -eq 0 ]; then
				cmd+=(send-keys -t "s$s:$w.0" "sleep 100$s$w" C-m \;)
			fi
			t "${cmd[@]}"
		done
	done
	sleep 2 # let shells start and print
}

attach_client() {
	if [ "$(uname)" == "Darwin" ]; then
		sleep 600 2>/dev/null | TERM=xterm script -q /dev/null tmux -L "$SOCKET" attach >/dev/null 2>&1 &
	else
		sleep 600 2>/dev/null | TERM=xterm script -qfc "tmux -L $SOCKET attach" /dev/null >/dev/null 2>&1 &
	fi
	CLIENT_PID=$!
	sleep 1
}

# removes layout checksums and pane ids, they change on every restore
normalize() {
	awk 'BEGIN { FS = OFS = "\t" }
		$1 == "window" {
			sub(/^[0-9a-f]+,/, "", $7)
			out = ""
			while (match($7, /[0-9]+x[0-9]+,[0-9]+,[0-9]+,[0-9]+/)) {
				leaf = substr($7, RSTART, RLENGTH)
				sub(/,[0-9]+$/, "", leaf)
				out = out substr($7, 1, RSTART - 1) leaf
				$7 = substr($7, RSTART + RLENGTH)
			}
			$7 = out $7
		}
		{ print }' "$1"
}

# 'last' is a relative symlink
last_save_file() {
	echo "$WORK_DIR/resurrect/$(readlink "$WORK_DIR/resurrect/last")"
}

save() {
	rm -f "$WORK_DIR/resurrect/last"
	t run-shell "$PLUGIN_DIR/scripts/save.sh quiet"
}

time_saves() {
	local i start end
	for ((i = 0; i < RUNS; i++)); do
		start="$(now)"
		save
		end="$(now)"
		elapsed "$start" "$end"
		echo
	done | median
}

main() {
	local start end
	mkdir -p "$WORK_DIR/resurrect"

	# lower bound: tmux creating the same panes one by one, like restore does
	t new-session -d -s "s0" -x 250 -y 80 -c /tmp
	start="$(now)"
	local s w p
	for ((s = 0; s < SESSIONS; s++)); do
		[ "$s" -gt 0 ] && t new-session -d -s "s$s" -x 250 -y 80 -c /tmp
		for ((w = 0; w < WINDOWS; w++)); do
			[ "$w" -gt 0 ] && t new-window -d -t "s$s:$w" -c /tmp
			for ((p = 1; p < PANES; p++)); do
				t split-window -t "s$s:$w" -c /tmp \; resize-pane -t "s$s:$w" -U 999
			done
		done
	done
	end="$(now)"
	local pane_create="$(elapsed "$start" "$end")"
	stop_server

	create_environment
	local panes="$(t list-panes -a | wc -l | tr -d ' ')"
	local windows="$(t list-windows -a | wc -l | tr -d ' ')"

	t set -g @resurrect-capture-pane-contents on
	local save_contents="$(time_saves)"
	t set -g @resurrect-capture-pane-contents off
	local save_time="$(time_saves)"
	save
	cp "$(last_save_file)" "$WORK_DIR/saved.txt"
	stop_server

	t new-session -d -s 0 -x 250 -y 80
	set_options
	[ -n "$ATTACH_CLIENT" ] && attach_client
	start="$(now)"
	t run-shell "$PLUGIN_DIR/scripts/restore.sh"
	end="$(now)"
	local restore_time="$(elapsed "$start" "$end")"

	sleep 2
	save
	cp "$(last_save_file)" "$WORK_DIR/resaved.txt"
	local diff_lines="$(diff <(normalize "$WORK_DIR/saved.txt") <(normalize "$WORK_DIR/resaved.txt") | grep -c '^[<>]')"
	local roundtrip="ok"
	if [ "$diff_lines" -gt 0 ]; then
		roundtrip="$diff_lines"
		diff <(normalize "$WORK_DIR/saved.txt") <(normalize "$WORK_DIR/resaved.txt") | head -20 >&2
	fi

	echo "${panes},${windows},${save_time},${save_contents},${restore_time},${pane_create},${roundtrip}"
}
main
