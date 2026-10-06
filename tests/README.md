# Tests

Two kinds, both run by `tests/run.sh` against whichever smoke windows are being served.

- `reference.js` is the independent check. It fetches raw logs and `eth_call`s from the RPC, decodes
  them itself, re-states the subgraph handlers and compares every field of every bet in the window with
  the nest's GraphQL answer, then exercises the SDK's other calls. It needs `NEST_RPC`.
- `golden.js` replays four SDK Bets queries per window and diffs them with `golden/<window>/`.
  `--update` records them; record only after `reference.js` passes on that window.

## Indexing a window

A window is a copy of this nest with every `start_block` raised to the window's first block, indexed with
`nuthatch dev` until its progress line passes the window's last block, then stopped and served:

```sh
cp -R . /tmp/w2 && cd /tmp/w2 && rm -rf nuthatch.redb segments
awk -v s=43700000 '/^start_block = / { if ($3 < s) $3 = s } { print }' ../betswirl-bnb-nest/nuthatch.toml > nuthatch.toml
nuthatch dev --dir . --rpc "$NEST_RPC" --state-rpc "$NEST_RPC" --window 50000 --listen 127.0.0.1:8302
# stop it once it reports a block past 45,249,999, then:
nuthatch serve --dir . --listen 127.0.0.1:8302
```

| window | first block | index past | port | reference boundary |
| --- | ---: | ---: | ---: | ---: |
| w1 | 16,689,819 (deployment, no edit) | 18,743,237 | 8301 | 18,740,000 |
| w2 | 43,700,000 | 45,249,999 | 8302 | 45,200,000 |
| w3 | 65,500,000 | 66,499,999 | 8303 | 66,400,000 |
| w4 | 48,260,000 | 50,709,999 | 8304 | 50,600,000 |

`tests/run.sh` passes each window's last indexed block to `reference.js` as written above, because token
counters count every resolution the nest holds. A nest that stops later than the table says will differ
on those counters only; the bet comparison stops at the boundary.

`checks/` is the w1 golden for `nuthatch check --dir <w1 copy>`, and holds for a full nest too.
