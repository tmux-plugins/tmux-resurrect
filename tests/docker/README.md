# Docker integration tests

Run the integration suite with:

```sh
tests/run_tests_in_docker
```

Pass test paths to run a subset:

```sh
tests/run_tests_in_docker tests/test_resurrect_save.sh
```

The image contains the current source snapshot. Runtime containers mount no
host paths, have no network, run as UID 10001, and use a read-only root
filesystem with disposable tmpfs storage.

The host runner labels every container with a unique run ID. Cleanup retains
the exact container ID returned by `docker create`, verifies that its label
still matches the run ID, and removes only that ID. It never lists, stops,
removes, or prunes containers by a broad name or filter.
