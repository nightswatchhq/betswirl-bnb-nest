-- Placements with the weighted game's gameId resolved from the config as of the bet
-- (handleWeightedGamePlaceBetV1 falls back to CUSTOM_WEIGHTED_GAME when the config is missing).
CREATE VIEW bs_config AS
SELECT CAST(c."configId" AS BIGINT) AS config_id,
       CASE CAST(c."gameId" AS BIGINT) WHEN 1 THEN 'Wheel' WHEN 2 THEN 'Plinko' WHEN 3 THEN 'Mines' WHEN 4 THEN 'Diamonds' WHEN 5 THEN 'Slide' WHEN 6 THEN 'Slot' ELSE 'CUSTOM_WEIGHTED_GAME' END AS game_id,
       CAST(c."gameId" AS VARCHAR) AS weighted_game_id, c.weights, c.multipliers,
       CAST(c.block_timestamp AS BIGINT) AS ts, CAST(c.block_number AS BIGINT) * 1000000 + CAST(c.log_index AS BIGINT) AS pos
FROM "weighted_game_v1__game_config_added" c;

CREATE VIEW bs_placed AS
WITH cfg AS (
  SELECT p.pos AS bet_pos, c.game_id, row_number() OVER (PARTITION BY p.pos ORDER BY c.pos DESC) AS rn
  FROM bs_placement p JOIN bs_config c ON c.config_id = p.config_id AND c.pos < p.pos
)
SELECT p.id, p.bettor, p.token, p.affiliate, p.amount, p.bet_count, p.stop_loss, p.stop_gain,
       COALESCE(p.game_id, cfg.game_id, 'CUSTOM_WEIGHTED_GAME') AS game_id, p.config_id, p.input_value,
       p.charged_vrf_fees, p.game_address, p.ts, p.tx_hash, p.pos
FROM bs_placement p LEFT JOIN cfg ON cfg.bet_pos = p.pos AND cfg.rn = 1;
