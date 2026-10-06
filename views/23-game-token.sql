-- GameToken, keyed "<gameId>-<token>" as getGameToken keys it. Counters are refused.
CREATE VIEW game_token AS
WITH k AS (
  SELECT game_id, token FROM bs_placed UNION SELECT game_id, token FROM bs_house_edge
), last AS (
  SELECT game_id, token, house_edge, row_number() OVER (PARTITION BY game_id, token ORDER BY pos DESC) AS rn
  FROM bs_house_edge
)
SELECT k.game_id || '-' || k.token AS id, k.token, k.game_id AS game, CAST(COALESCE(l.house_edge, 0) AS INTEGER) AS "houseEdge"
FROM k LEFT JOIN last l ON l.game_id = k.game_id AND l.token = k.token AND l.rn = 1;
