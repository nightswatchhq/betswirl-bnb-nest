-- One row per Bet entity: the latest placement of each id, with houseEdge as _createBet read it. A
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
