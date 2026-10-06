#!/bin/bash
# tests/run.sh: the reference comparison and the goldens, for every smoke window that is being served.
# Each window is a copy of this nest whose start blocks are raised to the window's start, indexed past
# its end and served (tests/README.md). Ports default to 8301-8304; NEST_RPC must be set.
set -u
here=$(cd "$(dirname "$0")" && pwd)
fail=0
run() { # window port from to boundary
  if ! curl -sf "127.0.0.1:$2/ready" > /dev/null; then echo "skip $1: nothing served on $2"; return; fi
  echo "== $1"
  node "$here/reference.js" "http://127.0.0.1:$2/graphql" "$3" "$4" "$5" || fail=1
  node "$here/golden.js" "$1" "http://127.0.0.1:$2/graphql" || fail=1
}
run w1 "${W1_PORT:-8301}" 16689819 18743237 18740000
run w2 "${W2_PORT:-8302}" 43700000 45249999 45200000
run w3 "${W3_PORT:-8303}" 65500000 66499999 66400000
run w4 "${W4_PORT:-8304}" 48260000 50709999 50600000
exit $fail
