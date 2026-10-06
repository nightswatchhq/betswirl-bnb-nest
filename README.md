# BetSwirl BNB Chain nest

A [nuthatch](https://github.com/nightswatchhq/nuthatch) nest that answers the GraphQL queries BetSwirl's
published client sends, for the BNB Chain deployment that no indexer serves any more:
[`Qmd5oqyojVx5wWSFuWfKz3YVLPHdE3KU5458Qqq3SVeGEB`](https://thegraph.com/explorer/deployments/Qmd5oqyojVx5wWSFuWfKz3YVLPHdE3KU5458Qqq3SVeGEB)
(`bsc`, start block 16,689,819). It is the first nest of the subgraph stopgap
([nightswatchhq/nuthatch#1941](https://github.com/nightswatchhq/nuthatch/issues/1941)).

**Every field the SDK's `bet`, `bets`, `token` and `tokens` documents select answers, exactly.** Fields
outside those documents that this nest does not reproduce are refused by name. It is not a drop-in
replacement for the whole subgraph: of its 51 entity types, seven have a view here.

## What it answers

The four documents are in [`queries/`](queries/), copied verbatim from `@betswirl/sdk-core` 0.1.27
(`src/data/subgraphs/protocol/documents/`). There is no public source for the subgraph's mappings, so
every rule below was read out of the deployed WASM (`Qma729hs…` for the games, `QmWHfNFG…` for the
banks), whose name section keeps the handler names.

The views are written by [`tools/genviews.js`](tools/genviews.js) from one table of handler shapes per
contract version; `node tools/genviews.js .` regenerates them.

### `bet` and `bets`: 30 leaf fields, 30 answered

| SDK field | answers from | mapping |
| --- | --- | --- |
| `id` | PlaceBet `id`, as a decimal string | `_createBet` |
| `gameId` | `"Dice"`, `"CoinToss"`, `"Roulette"`, `"Keno"`; for the weighted game the config's name as of the bet, else `"CUSTOM_WEIGHTED_GAME"` | `handle*PlaceBet*` |
| `gameAddress` | the emitting contract | `_createBet` |
| `user { id }` | PlaceBet `user` / `receiver` | `getUser` |
| `gameToken { id }` | `"<gameId>-<token>"` | `getGameToken` |
| `gameToken.token { id symbol name decimals }` | AddToken, and the entry `Bank.getTokens()` returned at that block (`[[calls]]`) | `handleAddTokenV1`-`V4` |
| `affiliate { id }` | PlaceBet `affiliate` (v5 games); `null` for the zero address, which never gets an `Affiliate` | `getAffiliate` |
| `inputValue` | `cap`, `face` (1/0), `numbers` or `configId` | `handle*PlaceBet*` |
| `betAmount` | PlaceBet `amount` (`0` on v1 games), then a Roll or refund `amount` when it is above zero | `_createBet`, `_rollBet`, `_refundBet` |
| `betCount`, `stopLoss`, `stopGain`, `chargedVRFFees` | PlaceBet v3 parameters; `1`, `0`, `0`, `0` before it | `handle*PlaceBetV3` |
| `houseEdge` | the affiliate's house edge for that game and token if above zero, else the game's, else 0, as of the bet | `_createBet` |
| `betTimestamp`, `betTxnHash` | the PlaceBet log | `_createBet` |
| `resolved`, `refunded` | a Roll or BetRefunded reached the bet | `_rollBet`, `_refundBet` |
| `totalBetAmount`, `payout`, `rollTxnHash`, `rollTimestamp` | the latest Roll or BetRefunded | `_rollBet`, `_refundBet` |
| `payoutMultiplier` | `payout / totalBetAmount` in graph-node's `BigDecimal`; `"1"` after a refund | `_rollBet`, `_refundBet` |
| `rolled` | the latest Roll's `rolled`, as an array (booleans as 1/0) | `handle*Roll*` |
| `weightedGameBet { config { id multipliers weights } }` | the weighted PlaceBet's `configId` and GameConfigAdded | `handleWeightedGamePlaceBetV1`, `handleWeightedGameAddConfig` |

### `token` and `tokens`: 17 leaf fields, 17 answered

| SDK field | answers from |
| --- | --- |
| `id` (twice, once as `address`), `symbol`, `name`, `decimals` | AddToken and `Bank.getTokens()` at that block. The native token is `"ETH"`, `"ETH"`, 18 on BSC because that is what the bank returns |
| `betTxnCount`, `betCount`, `winTxnCount`, `userCount`, `totalWagered`, `totalPayout` | every Roll and BetRefunded that reached a bet, as `_updateResolveAnalytics` counts them |
| `dividendAmount`, `bankAmount`, `partnerAmount`, `affiliateAmount`, `treasuryAmount`, `teamAmount` | AllocateHouseEdgeAmount on banks v1-v4, each version's own parameter mapping, once the token exists |

### Refused by name

Selecting any of these is an error naming the field or table (an engine message today, S0 defect 9), never a
substitute value:

- `Bet.consumedNativeVRFFees`, `Bet.consumedLinkVRFFees`: written by `handleChainlinkCallback` from the
  shared VRF coordinator, whose `RandomWordsFulfilled` volume is every VRF user on BSC.
- `Bet.kenoBet`, `Token.balancesDayDataLength`, `Token.balancesDayData`, `Token.usersTokens`,
  `GameToken`'s counters and day data, and every `User` and `Affiliate` field but `id`.
- The other 44 entity types: PvP games, leaderboards, day data and the affiliate analytics. They have no
  view, so they are refused as missing tables.

## How the four at-risk fields were resolved

S0 marked four fields at risk. None needed a guess.

- **`Bet.id`** is `event.params.id.toString()`: the decimal VRF request id, the same across games, which
  is why one bet table holds every game. The SDK parses it with `BigInt(bet.id)`.
- **`GameToken.id`** is `gameId + "-" + token.toHexString()`, keyed by the game's **name**, not its
  contract (`getGameToken`). So `SetHouseEdge` on Dice v1 and on Dice v5 write the same entity, and a
  bet's `houseEdge` is the latest write by any version of that game. The weighted game writes all seven
  of its names at once. The nest reproduces both, including the cross-version sharing.
- **`houseEdge`** is state, not a PlaceBet parameter: `_createBet` reads `AffiliateGameToken.houseEdge`,
  then `GameToken.houseEdge`, each only if above zero. Here it is an as-of join over every
  `SetHouseEdge` and `SetAffiliateHouseEdge` before the bet, by block and log index.
- **`payoutMultiplier`** is `payout.toBigDecimal().div(totalBetAmount.toBigDecimal())`. graph-node
  normalises each operand to 34 significant digits, divides with the `bigdecimal` 0.1.2 crate (100
  digits, rounded on the 101st) and normalises the quotient to 34 again, half up each time.
  `views/14-bs-payout-multiplier.sql` does the same on decimal strings, so a quotient like
  `0.5078775000000000000002014182230472` matches to the last digit.

No public endpoint serves the deployment or its Polygon twin
(`QmUa6b7voVS4kuERGo3bEDvRsW2FdTogSLeztnvtsi5DB2`): the SDK's Studio URLs answer `Not found` and the
gateway needs a key. The formats were therefore confirmed from the WASM and the SDK's own parsing, and
the values against the chain, below.

## Verification

Four windows were indexed on the BNB archive endpoint and checked by
[`tests/reference.js`](tests/reference.js), which shares no code with nuthatch: it pulls raw logs and
`eth_call`s itself, decodes them, runs a re-statement of the handlers above and compares every field of
every bet with the nest's GraphQL answer, plus `bet(id)`, the SDK's fetch-by-hash and six of its
`fetchBets` filters.

| window | blocks | covers | bets compared | result |
| --- | --- | --- | ---: | --- |
| w1 | 16,689,819 - 18,743,237 | deployment; Dice and CoinToss v1-v3, banks v1-v2, three tokens, refunds | 31,399 | pass, tokens too |
| w2 | 43,700,000 - 45,249,999 | v5 deployment and house edges, bank v4, affiliates, Roll v2 arrays | 91 | pass, tokens too |
| w3 | 65,500,000 - 66,499,999 | weighted game, freebets, a config added mid-window | 443 | pass |
| w4 | 48,260,000 - 50,709,999 | weighted game's first configs and house edge across its seven names | 324 | pass |

A window that does not start at deployment has no history before it, so w2-w4 test the logic over the
same inputs on both sides rather than the deployment's true values; w1 is the deployment's own start.

- [`checks/`](checks/): `nuthatch check` goldens for w1, which a full nest also satisfies. `check` reads
  sealed history only, so their cut is block 18,690,000.
- [`tests/golden/`](tests/golden/): the SDK's Bets query answered in each window, four cases each.
- `tests/run.sh` runs both against every served window (see `tests/README.md`).

## Running it

GraphQL needs the `nuthatch-graph` release download, 4.12.0 or later: the default binary has no
`/graphql` route, and releases before 4.11.0 refuse the SDK's Bets query. The step-by-step handback,
tested cold, is [docs/stopgap/betswirl-bnb.md](https://github.com/nightswatchhq/nuthatch/blob/main/docs/stopgap/betswirl-bnb.md)
in nuthatch; it also shows seeding from the public mirror instead of a full backfill.

The BNB public endpoint refuses 10 or more addresses per `eth_getLogs` and anything older than about
75 minutes, so a backfill needs an archive endpoint with a key. Keep it out of the repository:

```sh
RPC=...   # your archive endpoint
nuthatch dev --dir . --rpc "$RPC" --state-rpc "$RPC" --window 100000
```

`--state-rpc` resolves the five `getTokens()` calls. The GraphQL endpoint is
`http://127.0.0.1:8288/graphql`, also at `/subgraphs/id/Qmd5oqyojVx5wWSFuWfKz3YVLPHdE3KU5458Qqq3SVeGEB`.

### Full backfill: what to expect

Measured from a full-history census on 2026-10-06 (tip 126.02M): 109.3M blocks, about 594,000 logs from
these 26 contracts, about 161,000 bets. Activity is front-loaded: blocks 18M-21M hold two thirds of it, and
after 68M there are a few bets per million blocks. An archive endpoint that serves any range under
10,000 logs answered the whole history in 196 `eth_getLogs` calls; nuthatch's capped window
(`--window 100000`) needs at least 1,094 for the empty stretches plus a few hundred more where it
narrows through the dense years, so expect **2,000 to 3,000 requests**, 20 or so `eth_call`s for
`getTokens()`, and no header requests, since the endpoint puts `blockTimestamp` on each log. The four
smoke windows indexed at 1,000 events a second on a MacBook, so **expect 15 to 30 minutes** on the
ThinkPad, most of it the dense range.

### Query cost

Every view is recomputed per query. Over the full 160,802 bets the SDK's Bets query takes about 5.5 s
cold on the ThinkPad at the default two analytics threads (10.4 s before nightswatchhq/nuthatch#1951),
of which about 1.5 s is planning. A repeated statement is answered from the answer cache while nothing
it reads has changed; at BSC's tip that holds only from nightswatchhq/nuthatch#1955, before which every
two-second poll cleared it. The as-of joins and the `payoutMultiplier` arithmetic are not in the subset
RFC-0041 entities accept, so they stay views.

## Assumptions

- Every token gets an `AddToken` before its first bet, as it did on BSC. A resolution against a token
  with no `Token` would have failed the subgraph itself.
- A bet id placed twice keeps its latest placement, and resolutions apply to the placement current at
  the time, as the mapping's `store.get` / overwrite does.
- `Bank.getTokens()` is decoded for the first four members of each entry, which every bank version
  shares; up to 32 entries per call.
