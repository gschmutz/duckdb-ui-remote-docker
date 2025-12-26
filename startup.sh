#!/bin/bash

# Run DuckDB UI in screen
if [[ -n "${DUCKDB_INIT_SCRIPT:-}" ]]; then
  echo "Starting DuckDB UI with init script: $DUCKDB_INIT_SCRIPT"

  screen -L -Logfile ./duckdb_ui.log -dmS duckdb_ui /usr/local/bin/duckdb -init $DUCKDB_INIT_SCRIPT -ui
else
  echo "Starting DuckDB UI without init script"

  screen -L -Logfile ./duckdb_ui.log -dmS duckdb_ui /usr/local/bin/duckdb -ui
fi

# Run HAProxy
screen -L -Logfile ./haproxy.log -dmS haproxy_app haproxy -f /usr/local/etc/haproxy/haproxy.cfg

# Tail both logs
sleep 5
tail -f ./duckdb_ui.log ./haproxy.log
