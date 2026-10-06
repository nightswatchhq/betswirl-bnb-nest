-- One row per Bet entity: the latest placement of each id, with houseEdge as _createBet read it.
CREATE VIEW bs_bet_edge AS
WITH ge AS (
  SELECT x.pos, x.game_id, x.token,
         max(x.edge_pos) OVER (PARTITION BY x.game_id, x.token ORDER BY x.pos ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS edge_pos,
         x.is_bet
  FROM (SELECT game_id, token, pos, pos AS edge_pos, false AS is_bet FROM bs_house_edge
        UNION ALL SELECT game_id, token, pos, CAST(NULL AS BIGINT), true FROM bs_placed) x
), ae AS (
  SELECT x.pos, x.affiliate, x.game_id, x.token,
         max(x.edge_pos) OVER (PARTITION BY x.affiliate, x.game_id, x.token ORDER BY x.pos ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS edge_pos,
         x.is_bet
  FROM (SELECT affiliate, game_id, token, pos, pos AS edge_pos, false AS is_bet FROM bs_affiliate_house_edge
        UNION ALL SELECT affiliate, game_id, token, pos, CAST(NULL AS BIGINT), true FROM bs_placed) x
)
SELECT p.pos,
       CASE WHEN a.house_edge > 0 THEN a.house_edge WHEN g.house_edge > 0 THEN g.house_edge ELSE 0 END AS house_edge
FROM bs_placed p
LEFT JOIN ge ON ge.is_bet AND ge.pos = p.pos
LEFT JOIN bs_house_edge g ON g.game_id = p.game_id AND g.token = p.token AND g.pos = ge.edge_pos
LEFT JOIN ae ON ae.is_bet AND ae.pos = p.pos AND ae.affiliate = p.affiliate AND ae.game_id = p.game_id AND ae.token = p.token
LEFT JOIN bs_affiliate_house_edge a ON a.affiliate = p.affiliate AND a.game_id = p.game_id AND a.token = p.token AND a.pos = ae.edge_pos;

-- Resolutions that reached a bet: the placement current at the resolution's position.
CREATE VIEW bs_applied AS
WITH m AS (
  SELECT r.pos AS rpos, max(p.pos) AS ppos
  FROM bs_resolution r JOIN bs_placed p ON p.id = r.id AND p.pos < r.pos GROUP BY r.pos
)
SELECT r.*, p.pos AS placement_pos, p.bettor, p.token AS p_token, p.bet_count
FROM m JOIN bs_resolution r ON r.pos = m.rpos JOIN bs_placed p ON p.pos = m.ppos;

CREATE VIEW bs_bet AS
WITH latest AS (
  SELECT * FROM (SELECT p.*, row_number() OVER (PARTITION BY p.id ORDER BY p.pos DESC) AS rn FROM bs_placed p) WHERE rn = 1
), res AS (
  SELECT a.*,
         row_number() OVER (PARTITION BY a.id ORDER BY a.pos DESC) AS rn_last,
         row_number() OVER (PARTITION BY a.id, a.kind ORDER BY a.pos DESC) AS rn_kind,
         row_number() OVER (PARTITION BY a.id, a.amount <> '0' ORDER BY a.pos DESC) AS rn_amount
  FROM bs_applied a JOIN latest l ON l.id = a.id AND a.placement_pos = l.pos
), refunded AS (
  SELECT id FROM res WHERE kind = 'refund' GROUP BY id
)
SELECT l.id, l.game_id AS "gameId", l.game_address AS "gameAddress", l.bettor AS "user",
       l.game_id || '-' || l.token AS "gameToken", l.affiliate, l.input_value AS "inputValue",
       COALESCE(amt.amount, l.amount) AS "betAmount", l.bet_count AS "betCount", l.stop_loss AS "stopLoss",
       l.stop_gain AS "stopGain", CAST(he.house_edge AS INTEGER) AS "houseEdge", l.ts AS "betTimestamp",
       last.id IS NOT NULL AS resolved, rf.id IS NOT NULL AS refunded, l.charged_vrf_fees AS "chargedVRFFees",
       l.tx_hash AS "betTxnHash", fb.id IS NOT NULL AS "isFreebet", fb.freebet_id AS "freebetId",
       last.total AS "totalBetAmount", last.payout,
       CASE WHEN last.kind = 'refund' THEN '1' ELSE pm.multiplier END AS "payoutMultiplier",
       last.tx_hash AS "rollTxnHash", roll.rolled, last.ts AS "rollTimestamp", l.pos AS bs_pos
FROM latest l
JOIN bs_bet_edge he ON he.pos = l.pos
LEFT JOIN res last ON last.id = l.id AND last.rn_last = 1
LEFT JOIN bs_payout_multiplier pm ON pm.pos = last.pos
LEFT JOIN res roll ON roll.id = l.id AND roll.kind = 'roll' AND roll.rn_kind = 1
LEFT JOIN res amt ON amt.id = l.id AND amt.amount <> '0' AND amt.rn_amount = 1
LEFT JOIN refunded rf ON rf.id = l.id
LEFT JOIN bs_freebet fb ON fb.id = l.id AND fb.placement_pos = l.pos;
