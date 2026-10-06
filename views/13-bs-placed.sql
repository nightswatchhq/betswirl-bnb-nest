-- Placements with the weighted game's gameId resolved from the config as of the bet
-- (handleWeightedGamePlaceBetV1 falls back to CUSTOM_WEIGHTED_GAME when the config is missing).
CREATE VIEW bs_config AS
SELECT CAST(c."configId" AS BIGINT) AS config_id,
       CASE CAST(c."gameId" AS BIGINT) WHEN 1 THEN 'Wheel' WHEN 2 THEN 'Plinko' WHEN 3 THEN 'Mines' WHEN 4 THEN 'Diamonds' WHEN 5 THEN 'Slide' WHEN 6 THEN 'Slot' ELSE 'CUSTOM_WEIGHTED_GAME' END AS game_id,
       CAST(c."gameId" AS VARCHAR) AS weighted_game_id, c.weights, c.multipliers,
       CAST(c.block_timestamp AS BIGINT) AS ts, CAST(c.block_number AS BIGINT) * 1000000 + CAST(c.log_index AS BIGINT) AS pos
FROM "weighted_game_v1__game_config_added" c;

-- Burrmill computes a view referenced twice in one statement once only when it holds an aggregate,
-- so this and bs_applied are written as GROUP BYs: every view below reads them without a rescan.
CREATE VIEW bs_placed AS
WITH cfg AS (
  SELECT CAST(w.block_number AS BIGINT) * 1000000 + CAST(w.log_index AS BIGINT) AS bet_pos, max(c.pos) AS cfg_pos
  FROM "weighted_game_v1__place_bet" w JOIN bs_config c ON c.config_id = CAST(w."configId" AS BIGINT) AND c.pos < CAST(w.block_number AS BIGINT) * 1000000 + CAST(w.log_index AS BIGINT)
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
