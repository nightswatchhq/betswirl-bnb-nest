// Generate the BetSwirl nest's views. The per-version tables differ only in which event parameter
// feeds which Bet field, so the unions are written from one table of handler shapes rather than by
// hand. Every shape below cites the mapping handler it reproduces (WASM Qma729…, function names
// from its name section).
// usage: node genviews.js <nest-dir>
const fs = require("fs");
const dir = process.argv[2];
const Z = "'0x0000000000000000000000000000000000000000'";
const pos = (t) => `CAST(${t}.block_number AS BIGINT) * 1000000 + CAST(${t}.log_index AS BIGINT)`;

// [table prefix, gameId, PlaceBet shape, Roll shape, Refund shape, SetHouseEdge shape, input column, input kind]
// PlaceBet V1: no amount, betCount 1, no stops, no affiliate (handle*PlaceBetV1)
// PlaceBet V2: amount p3, the rest as V1 (handle*PlaceBetV2, Keno's V1)
// PlaceBet V3: amount, affiliate, betCount, stopGain p8, stopLoss p9, chargedVRFFees p4 (handle*PlaceBetV3)
// Roll V1: amount p3 is both betAmount and totalBetAmount, one rolled value (handle*RollV1)
// Roll V2: totalBetAmount p3, rolled array, betAmount untouched (handle*RollV2)
// Refund A: _refundBet(id, amount, amount); Refund B: _refundBet(id, 0, amount)
// SetHouseEdge V1: houseEdge p1; V2: houseEdge p2 (previousHouseEdge is p1)
const games = [
  ["dice_v1", "Dice", 1, 1, "A", 1, "cap", "int"],
  ["dice_v2", "Dice", 1, 1, "A", 1, "cap", "int"],
  ["dice_v3", "Dice", 1, 1, "A", 1, "cap", "int"],
  ["dice_v4", "Dice", 2, 1, "B", 1, "cap", "int"],
  ["dice_v4_5", "Dice", 2, 1, "B", 1, "cap", "int"],
  ["dice_v5", "Dice", 3, 2, "A", 2, "cap", "int"],
  ["coin_toss_v1", "CoinToss", 1, 1, "A", 1, "face", "bool"],
  ["coin_toss_v2", "CoinToss", 1, 1, "A", 1, "face", "bool"],
  ["coin_toss_v3", "CoinToss", 1, 1, "A", 1, "face", "bool"],
  ["coin_toss_v4", "CoinToss", 2, 1, "B", 1, "face", "bool"],
  ["coin_toss_v4_5", "CoinToss", 2, 1, "B", 1, "face", "bool"],
  ["coin_toss_v5", "CoinToss", 3, 2, "A", 2, "face", "bool"],
  ["roulette_v1", "Roulette", 1, 1, "A", 1, "numbers", "int"],
  ["roulette_v2", "Roulette", 2, 1, "B", 1, "numbers", "int"],
  ["roulette_v2_5", "Roulette", 2, 1, "B", 1, "numbers", "int"],
  ["roulette_v3", "Roulette", 3, 2, "A", 2, "numbers", "int"],
  ["keno_v1", "Keno", 2, 1, "B", 1, "numbers", "int"],
  ["keno_v1_5", "Keno", 2, 1, "B", 1, "numbers", "int"],
  ["keno_v2", "Keno", 3, 2, "B", 2, "numbers", "int"],
  ["weighted_game_v1", null, 3, 2, "B", 2, "configId", "int"],
];
const affiliateEdge = ["dice_v5", "coin_toss_v5", "roulette_v3", "keno_v2", "weighted_game_v1"];
const weightedIds = ["Wheel", "Plinko", "Mines", "Diamonds", "Slide", "Slot", "CUSTOM_WEIGHTED_GAME"];
const userCol = (shape) => (shape === 3 ? "receiver" : "\"user\"");
const input = (col, kind) =>
  kind === "bool" ? `CASE WHEN p."${col}" = 'true' THEN '1' ELSE '0' END` : `CAST(p."${col}" AS VARCHAR)`;

const views = {};

// Every PlaceBet, as the _createBet arguments it produces. The weighted game's gameId is resolved
// below, from the config as of the bet.
views["10-bs-placement"] = `-- Every PlaceBet, as the arguments the mapping's _createBet receives.
CREATE VIEW bs_placement AS
${games
  .map(([t, g, pb, , , , col, kind]) => {
    const amount = pb === 1 ? "'0'" : "p.amount";
    const aff = pb === 3 ? "p.affiliate" : Z;
    const bc = pb === 3 ? "CAST(p.\"betCount\" AS VARCHAR)" : "'1'";
    const sl = pb === 3 ? "p.\"stopLoss\"" : "'0'";
    const sg = pb === 3 ? "p.\"stopGain\"" : "'0'";
    const vrf = pb === 3 ? "p.\"chargedVRFCost\"" : "'0'";
    const gid = g ? `'${g}'` : "NULL";
    const cfg = g ? "NULL" : "CAST(p.\"configId\" AS BIGINT)";
    return `SELECT CAST(p.id AS VARCHAR) AS id, ${userCol(pb)} AS bettor, p.token, ${aff} AS affiliate,
       ${amount} AS amount, ${bc} AS bet_count, ${sl} AS stop_loss, ${sg} AS stop_gain,
       ${gid} AS game_id, ${cfg} AS config_id, ${input(col, kind)} AS input_value, ${vrf} AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, ${pos("p")} AS pos
FROM "${t}__place_bet" p`;
  })
  .join("\nUNION ALL\n")};
`;

// GameToken.houseEdge writes: SetHouseEdge on any version of a game sets "<gameId>-<token>", and the
// weighted game's sets all seven weighted gameIds (handleWeightedGameSetHouseEdge loops over them).
views["11-bs-house-edge"] = `-- Every write of GameToken.houseEdge, keyed as the mapping keys it: by gameId string, not by contract.
CREATE VIEW bs_house_edge AS
${games
  .filter(([t]) => t !== "weighted_game_v1")
  .map(([t, g, , , , he]) => `SELECT '${g}' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, ${pos("e")} AS pos
FROM "${t}__set_house_edge" e`)
  .join("\nUNION ALL\n")}
UNION ALL
SELECT w.game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, ${pos("e")} AS pos
FROM "weighted_game_v1__set_house_edge" e
CROSS JOIN (VALUES ${weightedIds.map((w) => `('${w}')`).join(", ")}) AS w(game_id);

-- AffiliateGameToken.houseEdge writes. A zero affiliate never gets an AffiliateGameToken.
CREATE VIEW bs_affiliate_house_edge AS
${affiliateEdge
  .filter((t) => t !== "weighted_game_v1")
  .map((t) => {
    const g = games.find((x) => x[0] === t)[1];
    return `SELECT e.affiliate, '${g}' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, ${pos("e")} AS pos
FROM "${t}__set_affiliate_house_edge" e WHERE e.affiliate <> ${Z}`;
  })
  .join("\nUNION ALL\n")}
UNION ALL
SELECT e.affiliate, w.game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, ${pos("e")} AS pos
FROM "weighted_game_v1__set_affiliate_house_edge" e
CROSS JOIN (VALUES ${weightedIds.map((w) => `('${w}')`).join(", ")}) AS w(game_id)
WHERE e.affiliate <> ${Z};
`;
// ---- Rolls and refunds -------------------------------------------------------------------------
const rolledV1 = (t) =>
  /^coin_toss/.test(t)
    ? "make_array(CASE WHEN r.rolled = 'true' THEN '1' ELSE '0' END)"
    : "make_array(CAST(r.rolled AS VARCHAR))";
const rolledV2 =
  "string_to_array(replace(replace(replace(trim(r.rolled, '[]'), 'true', '1'), 'false', '0'), '\"', ''), ',')";
views["12-bs-resolution"] = `-- Every Roll and BetRefunded, as the arguments _rollBet and _refundBet receive. A resolution only
-- touches a bet that already exists, which bs_applied decides.
CREATE VIEW bs_resolution AS
${games
  .map(([t, , , rl]) => {
    const u = rl === 2 ? "r.receiver" : 'r."user"';
    const amount = rl === 2 ? "'0'" : "r.amount";
    const total = rl === 2 ? 'r."totalBetAmount"' : "r.amount";
    const rolled = rl === 2 ? rolledV2 : rolledV1(t);
    return `SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, ${u} AS r_user, r.token AS r_token, ${amount} AS amount,
       ${total} AS total, r.payout, ${rolled} AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, ${pos("r")} AS pos
FROM "${t}__roll" r`;
  })
  .concat(
    games.map(([t, , , , rf]) => `SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       ${rf === "A" ? "r.amount" : "'0'"} AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, ${pos("r")} AS pos
FROM "${t}__bet_refunded" r`)
  )
  .join("\nUNION ALL\n")};
`;

// ---- graph-node BigDecimal: payout / totalBetAmount ------------------------------------------
// The mapping divides BigDecimals. graph-node normalises each operand to 34 significant digits
// (half up), the bigdecimal 0.1.2 crate divides to 100 significant digits and rounds on the 101st,
// and the quotient is normalised to 34 again. Each step is reproduced on decimal strings.
const inc = (h) => `(CASE WHEN rtrim(${h}, '9') = '' THEN '1' || repeat('0', length(${h}))
  ELSE substr(rtrim(${h}, '9'), 1, length(rtrim(${h}, '9')) - 1)
    || chr(ascii(substr(rtrim(${h}, '9'), length(rtrim(${h}, '9')), 1)) + 1)
    || repeat('0', length(${h}) - length(rtrim(${h}, '9'))) END)`;
const round = (s, n) => `(CASE WHEN length(${s}) > ${n} AND substr(${s}, ${n + 1}, 1) >= '5'
  THEN ${inc(`substr(${s}, 1, ${n})`)} ELSE substr(${s}, 1, ${n}) END)`;
const norm34 = (x) => `(CASE WHEN length(${x}) <= 34 THEN ${x} ELSE ${round(x, 34)} || repeat('0', length(${x}) - 34) END)`;
const K = 140;
views["14-bs-payout-multiplier"] = `-- Bet.payoutMultiplier for a roll, as graph-node computes payout.toBigDecimal() / totalBetAmount.toBigDecimal().
CREATE VIEW bs_payout_multiplier AS
WITH n AS (
  SELECT pos, ${norm34("payout")} AS p, ${norm34("total")} AS t FROM bs_applied WHERE kind = 'roll'
), q AS (
  SELECT pos, p, CASE WHEN p = '0' OR t = '0' THEN NULL ELSE nuthatch_mul_div(p, '1' || repeat('0', ${K}), t) END AS q FROM n
), s AS (
  SELECT pos, p, q, ${round("q", 100)} AS s100 FROM q
), m AS (
  SELECT pos, p, q, s100, ${round("s100", 34)} AS m34 FROM s
), e AS (
  SELECT pos, p, rtrim(m34, '0') AS mant,
         CAST(length(q) - ${K} + (length(s100) - least(length(q), 100)) + (length(m34) - least(length(s100), 34)) AS BIGINT) AS ex
  FROM m
)
SELECT pos, CASE
  WHEN p = '0' THEN '0'
  WHEN mant IS NULL THEN NULL
  WHEN ex >= length(mant) THEN mant || repeat('0', CAST(ex - length(mant) AS INT))
  WHEN ex > 0 THEN substr(mant, 1, CAST(ex AS INT)) || '.' || substr(mant, CAST(ex + 1 AS INT))
  ELSE '0.' || repeat('0', CAST(-ex AS INT)) || mant
END AS multiplier
FROM e;
`;

// ---- Bets ----------------------------------------------------------------------------------------
const weighted = games.find(([, g]) => !g)[0];
views["13-bs-placed"] = `-- Placements with the weighted game's gameId resolved from the config as of the bet
-- (handleWeightedGamePlaceBetV1 falls back to CUSTOM_WEIGHTED_GAME when the config is missing).
CREATE VIEW bs_config AS
SELECT CAST(c."configId" AS BIGINT) AS config_id,
       CASE CAST(c."gameId" AS BIGINT) ${weightedIds
         .slice(0, 6)
         .map((g, i) => `WHEN ${i + 1} THEN '${g}'`)
         .join(" ")} ELSE 'CUSTOM_WEIGHTED_GAME' END AS game_id,
       CAST(c."gameId" AS VARCHAR) AS weighted_game_id, c.weights, c.multipliers,
       CAST(c.block_timestamp AS BIGINT) AS ts, ${pos("c")} AS pos
FROM "weighted_game_v1__game_config_added" c;

-- Burrmill computes a view referenced twice in one statement once only when it holds an aggregate,
-- so this and bs_applied are written as GROUP BYs: every view below reads them without a rescan.
CREATE VIEW bs_placed AS
WITH cfg AS (
  SELECT ${pos("w")} AS bet_pos, max(c.pos) AS cfg_pos
  FROM "${weighted}__place_bet" w JOIN bs_config c ON c.config_id = CAST(w."configId" AS BIGINT) AND c.pos < ${pos("w")}
  GROUP BY 1
)
SELECT p.id, p.bettor, p.token, p.affiliate, p.amount, p.bet_count, p.stop_loss, p.stop_gain,
       COALESCE(p.game_id, c.game_id, 'CUSTOM_WEIGHTED_GAME') AS game_id, p.config_id, p.input_value,
       p.charged_vrf_fees, p.game_address, p.ts, p.tx_hash, p.pos
FROM bs_placement p LEFT JOIN cfg ON cfg.bet_pos = p.pos LEFT JOIN bs_config c ON c.pos = cfg.cfg_pos;

-- Resolutions that reached a bet: the placement current at the resolution's position.
CREATE VIEW bs_applied AS
WITH j AS (
  SELECT r.*, p.pos AS placement_pos, p.bettor, p.token AS p_token, p.bet_count
  FROM bs_resolution r JOIN bs_placed p ON p.id = r.id AND p.pos < r.pos
), m AS (
  SELECT pos, max(placement_pos) AS placement_pos FROM j GROUP BY pos
)
SELECT j.* FROM j JOIN m ON m.pos = j.pos AND m.placement_pos = j.placement_pos;
`;

views["15-bs-freebet"] = `-- handleFreebetPlacedV1: the latest PlaceFreeBet for a bet that exists marks it a freebet.
CREATE VIEW bs_freebet AS
WITH hit AS (
  SELECT CAST(f."betId" AS VARCHAR) AS id, p.pos AS placement_pos, CAST(f."freeBetId" AS VARCHAR) AS freebet_id,
         ${pos("f")} AS pos, row_number() OVER (PARTITION BY ${pos("f")} ORDER BY p.pos DESC) AS rn
  FROM "freebet_v1__place_free_bet" f
  JOIN bs_placed p ON p.id = CAST(f."betId" AS VARCHAR) AND p.pos < ${pos("f")}
)
SELECT id, placement_pos, freebet_id FROM (
  SELECT h.*, row_number() OVER (PARTITION BY h.placement_pos ORDER BY h.pos DESC) AS rn2 FROM hit h WHERE h.rn = 1
) x WHERE rn2 = 1;
`;

views["16-bs-bet"] = `-- One row per Bet entity: the latest placement of each id, with houseEdge as _createBet read it. A
-- resolution reaches that placement exactly when it comes after it, so bs_applied needs no window here.
CREATE VIEW bs_bet AS
WITH lp AS (
  SELECT id, max(pos) AS pos FROM bs_placed GROUP BY id
), l AS (
  SELECT p.* FROM bs_placed p JOIN lp ON lp.pos = p.pos
), ge AS (
  SELECT l.pos, max(e.pos) AS edge_pos
  FROM l JOIN bs_house_edge e ON e.game_id = l.game_id AND e.token = l.token AND e.pos < l.pos GROUP BY l.pos
), ae AS (
  SELECT l.pos, max(e.pos) AS edge_pos
  FROM l JOIN bs_affiliate_house_edge e ON e.affiliate = l.affiliate AND e.game_id = l.game_id AND e.token = l.token AND e.pos < l.pos
  GROUP BY l.pos
), res AS (
  SELECT a.id, max(a.pos) AS last_pos, max(CASE WHEN a.kind = 'roll' THEN a.pos END) AS roll_pos,
         max(CASE WHEN a.amount <> '0' THEN a.pos END) AS amount_pos, bool_or(a.kind = 'refund') AS refunded
  FROM bs_applied a JOIN lp ON lp.id = a.id AND lp.pos = a.placement_pos GROUP BY a.id
)
SELECT l.id, l.game_id AS "gameId", l.game_address AS "gameAddress", l.bettor AS "user",
       l.game_id || '-' || l.token AS "gameToken", l.affiliate, l.input_value AS "inputValue",
       COALESCE(amt.amount, l.amount) AS "betAmount", l.bet_count AS "betCount", l.stop_loss AS "stopLoss",
       l.stop_gain AS "stopGain",
       CAST(CASE WHEN a.house_edge > 0 THEN a.house_edge WHEN g.house_edge > 0 THEN g.house_edge ELSE 0 END AS INTEGER) AS "houseEdge",
       l.ts AS "betTimestamp", res.id IS NOT NULL AS resolved, COALESCE(res.refunded, false) AS refunded,
       l.charged_vrf_fees AS "chargedVRFFees", l.tx_hash AS "betTxnHash", fb.id IS NOT NULL AS "isFreebet",
       fb.freebet_id AS "freebetId", last.total AS "totalBetAmount", last.payout,
       CASE WHEN last.kind = 'refund' THEN '1' ELSE pm.multiplier END AS "payoutMultiplier",
       last.tx_hash AS "rollTxnHash", roll.rolled, last.ts AS "rollTimestamp", l.pos AS bs_pos
FROM l
LEFT JOIN ge ON ge.pos = l.pos
LEFT JOIN bs_house_edge g ON g.game_id = l.game_id AND g.token = l.token AND g.pos = ge.edge_pos
LEFT JOIN ae ON ae.pos = l.pos
LEFT JOIN bs_affiliate_house_edge a ON a.affiliate = l.affiliate AND a.game_id = l.game_id AND a.token = l.token AND a.pos = ae.edge_pos
LEFT JOIN res ON res.id = l.id
LEFT JOIN bs_applied last ON last.pos = res.last_pos
LEFT JOIN bs_payout_multiplier pm ON pm.pos = res.last_pos
LEFT JOIN bs_applied roll ON roll.pos = res.roll_pos
LEFT JOIN bs_applied amt ON amt.pos = res.amount_pos
LEFT JOIN bs_freebet fb ON fb.id = l.id AND fb.placement_pos = l.pos;
`;
// ---- The Graph entities the SDK reads -----------------------------------------------------------
views["20-bet"] = `-- The Bet entity. Columns are the schema's field names; Bet.consumedNativeVRFFees,
-- consumedLinkVRFFees and kenoBet have no column and are refused by name.
CREATE VIEW bet AS
SELECT id, "gameId", "gameAddress", "user", "gameToken", affiliate, "inputValue", "betAmount", "betCount",
       "stopLoss", "stopGain", "houseEdge", "betTimestamp", resolved, refunded, "chargedVRFFees", "betTxnHash",
       "isFreebet", "freebetId", "totalBetAmount", payout, "payoutMultiplier", "rollTxnHash", rolled, "rollTimestamp"
FROM bs_bet;
`;

views["21-user"] = `-- User: every bettor has one (getUser in _createBet). Only id is reproduced.
CREATE VIEW "user" AS SELECT DISTINCT bettor AS id FROM bs_placed;
`;

views["22-affiliate"] = `-- Affiliate: getAffiliate creates one for any non-zero affiliate it sees. Only id is reproduced.
CREATE VIEW affiliate AS
SELECT DISTINCT id FROM (
  SELECT affiliate AS id FROM bs_placed
  UNION ALL SELECT affiliate FROM bs_affiliate_house_edge
) WHERE id <> ${Z};
`;

views["23-game-token"] = `-- GameToken, keyed "<gameId>-<token>" as getGameToken keys it. Counters are refused.
CREATE VIEW game_token AS
WITH k AS (
  SELECT game_id, token FROM bs_placed UNION SELECT game_id, token FROM bs_house_edge
), last AS (
  SELECT game_id, token, house_edge, row_number() OVER (PARTITION BY game_id, token ORDER BY pos DESC) AS rn
  FROM bs_house_edge
)
SELECT k.game_id || '-' || k.token AS id, k.token, k.game_id AS game, CAST(COALESCE(l.house_edge, 0) AS INTEGER) AS "houseEdge"
FROM k LEFT JOIN last l ON l.game_id = k.game_id AND l.token = k.token AND l.rn = 1;
`;

views["24-weighted"] = `-- WeightedGameBet (id = bet id) and WeightedGameConfig (id = configId).
CREATE VIEW weighted_game_bet AS
SELECT DISTINCT id, id AS bet, CAST(config_id AS VARCHAR) AS config FROM bs_placed WHERE config_id IS NOT NULL;

CREATE VIEW weighted_game_config AS
SELECT id, multipliers, weights, "weightedGameId", "gameId", "creationTimestamp" FROM (
  SELECT CAST(config_id AS VARCHAR) AS id,
         string_to_array(replace(trim(multipliers, '[]'), '"', ''), ',') AS multipliers,
         string_to_array(replace(trim(weights, '[]'), '"', ''), ',') AS weights,
         weighted_game_id AS "weightedGameId", game_id AS "gameId", ts AS "creationTimestamp",
         row_number() OVER (PARTITION BY config_id ORDER BY pos DESC) AS rn
  FROM bs_config
) WHERE rn = 1;
`;

// Token metadata from Bank.getTokens(): an array of tuples whose first four members are
// (uint8 decimals, address token, string name, string symbol) in every bank version.
const banks = ["bank_v1", "bank_v2", "bank_v3", "bank_v3_5", "bank_v4"];
const elems = Array.from({ length: 32 }, (_, i) => `(${i})`).join(", ");
views["25-token"] = `-- Token creation (getToken in each AddToken handler; V4 only when added) and the metadata the
-- handler copied from Bank.getTokens() at that block.
CREATE VIEW bs_token_added AS
${banks
  .map((b) => `SELECT a.token, ${pos("a")} AS pos, a.block_number, '${b}' AS bank FROM "${b}__add_token" a${b === "bank_v4" ? " WHERE a.added = 'true'" : ""}`)
  .join("\nUNION ALL\n")};

CREATE VIEW bs_token_metadata AS
WITH calls AS (
${banks.map((b) => `  SELECT '${b}' AS bank, block_number, result FROM "${b}_get_tokens" WHERE NOT CAST(reverted AS BOOLEAN)`).join("\n  UNION ALL\n")}
), arr AS (
  SELECT a.token, a.pos, c.result, TRY_CAST(nuthatch_uint256('0x' || substr(c.result, 67, 64)) AS BIGINT) AS n
  FROM bs_token_added a JOIN calls c ON c.bank = a.bank AND c.block_number = a.block_number
  -- TRY_CAST: the engine may evaluate this before k.i < arr.n removes the row, and past the array
  -- the word is string data ("ETH" read as an offset), which does not fit a BIGINT.
), el AS (
  SELECT arr.token, arr.pos,
         substr(arr.result, 3 + 2 * (64 + TRY_CAST(nuthatch_uint256('0x' || substr(arr.result, 3 + 64 * (2 + k.i), 64)) AS BIGINT))) AS e
  FROM arr CROSS JOIN (VALUES ${elems}) AS k(i) WHERE k.i < arr.n
), dec AS (
  SELECT token, pos, e, '0x' || substr(e, 89, 40) AS addr,
         nuthatch_abi_tuple('uint256,address,string', '0x' || e) AS j3,
         nuthatch_abi_tuple('uint256,address,string,string', '0x' || e) AS j4
  FROM el
), parsed AS (
  SELECT token, pos, j3, j4,
         '["' || CAST(CAST(nuthatch_uint256('0x' || substr(e, 1, 64)) AS INTEGER) AS VARCHAR) || '","' || addr || '","' AS head
  FROM dec WHERE addr = token
), named AS (
  SELECT token, pos, head,
         substr(j3, length(head) + 1, length(j3) - length(head) - 2) AS name_json, j4
  FROM parsed
)
SELECT token, pos,
       CAST(substr(head, 3, strpos(head, '","') - 3) AS INTEGER) AS decimals,
       name_json AS name,
       substr(j4, length(head) + length(name_json) + 4, length(j4) - length(head) - length(name_json) - 5) AS symbol
FROM named;
`;
// AllocateHouseEdgeAmount: [bank, {field: param}] as each handler adds them, when the Token exists.
const alloc = [
  ["bank_v1", { dividendAmount: "dividend", treasuryAmount: "treasury", teamAmount: "team" }],
  ["bank_v2", { dividendAmount: "dividend", partnerAmount: "partner", treasuryAmount: "treasury", teamAmount: "team" }],
  ["bank_v3", { dividendAmount: "dividend", bankAmount: "bank", partnerAmount: "partner", treasuryAmount: "treasury", teamAmount: "team" }],
  ["bank_v3_5", { dividendAmount: "dividend", bankAmount: "bank", partnerAmount: "partner", treasuryAmount: "treasury", teamAmount: "team" }],
  ["bank_v4", { dividendAmount: "dividend", bankAmount: "bank", affiliateAmount: "affiliate", treasuryAmount: "treasury", teamAmount: "team" }],
];
const splits = ["dividendAmount", "bankAmount", "partnerAmount", "affiliateAmount", "treasuryAmount", "teamAmount"];
const d38 = (x) => `CAST(${x} AS DECIMAL(38,0))`;
views["26-token-entity"] = `-- The Token entity. Counters follow _updateResolveAnalytics (one per roll or refund that reached a
-- bet); the splits follow the bank's AllocateHouseEdgeAmount handlers, which skip a token that does
-- not exist yet. balancesDayDataLength has no column and is refused by name.
CREATE VIEW bs_allocation AS
${alloc
  .map(([b, m]) => `SELECT a.token, ${pos("a")} AS pos, ${splits.map((s) => (m[s] ? `${d38(`a.${m[s]}`)}` : d38("0")) + ` AS "${s}"`).join(", ")}
FROM "${b}__allocate_house_edge_amount" a`)
  .join("\nUNION ALL\n")};

CREATE VIEW token AS
WITH created AS (
  SELECT token, min(pos) AS pos FROM bs_token_added GROUP BY token
), meta AS (
  SELECT token, name, symbol, decimals FROM (
    SELECT m.*, row_number() OVER (PARTITION BY m.token ORDER BY m.pos DESC) AS rn FROM bs_token_metadata m
  ) WHERE rn = 1
), counters AS (
  SELECT CASE WHEN kind = 'roll' THEN r_token ELSE p_token END AS token,
         count(*) AS bet_txn_count, sum(${d38("bet_count")}) AS bet_count,
         sum(CASE WHEN ${d38("payout")} > ${d38("total")} THEN 1 ELSE 0 END) AS win_txn_count,
         count(DISTINCT CASE WHEN kind = 'roll' THEN r_user ELSE bettor END) AS user_count,
         sum(${d38("total")}) AS wagered, sum(${d38("payout")}) AS paid
  FROM bs_applied GROUP BY 1
), alloc AS (
  SELECT a.token, ${splits.map((s) => `sum(a."${s}") AS "${s}"`).join(", ")}
  FROM bs_allocation a JOIN created c ON c.token = a.token AND a.pos > c.pos GROUP BY a.token
)
SELECT c.token AS id, COALESCE(m.name, '') AS name, COALESCE(m.symbol, '') AS symbol,
       CAST(COALESCE(m.decimals, 0) AS INTEGER) AS decimals,
       CAST(COALESCE(n.bet_txn_count, 0) AS VARCHAR) AS "betTxnCount",
       CAST(COALESCE(n.bet_count, 0) AS VARCHAR) AS "betCount",
       CAST(COALESCE(n.win_txn_count, 0) AS VARCHAR) AS "winTxnCount",
       CAST(COALESCE(n.user_count, 0) AS VARCHAR) AS "userCount",
       CAST(COALESCE(n.wagered, 0) AS VARCHAR) AS "totalWagered",
       CAST(COALESCE(n.paid, 0) AS VARCHAR) AS "totalPayout",
       ${splits.map((s) => `CAST(COALESCE(a."${s}", 0) AS VARCHAR) AS "${s}"`).join(",\n       ")}
FROM created c
LEFT JOIN meta m ON m.token = c.token
LEFT JOIN counters n ON n.token = c.token
LEFT JOIN alloc a ON a.token = c.token;
`;
fs.mkdirSync(dir + "/views", { recursive: true });
for (const f of fs.readdirSync(`${dir}/views`)) if (f.endsWith(".sql")) fs.unlinkSync(`${dir}/views/${f}`);
for (const [name, sql] of Object.entries(views)) fs.writeFileSync(`${dir}/views/${name}.sql`, sql);
console.log(Object.keys(views).join(" "));
