-- WeightedGameBet (id = bet id) and WeightedGameConfig (id = configId).
CREATE VIEW weighted_game_bet AS
SELECT DISTINCT id, id AS bet, CAST(config_id AS VARCHAR) AS config FROM bs_placement WHERE config_id IS NOT NULL;

CREATE VIEW weighted_game_config AS
SELECT id, multipliers, weights, "weightedGameId", "gameId", "creationTimestamp" FROM (
  SELECT CAST(config_id AS VARCHAR) AS id,
         string_to_array(replace(trim(multipliers, '[]'), '"', ''), ',') AS multipliers,
         string_to_array(replace(trim(weights, '[]'), '"', ''), ',') AS weights,
         weighted_game_id AS "weightedGameId", game_id AS "gameId", ts AS "creationTimestamp",
         row_number() OVER (PARTITION BY config_id ORDER BY pos DESC) AS rn
  FROM bs_config
) WHERE rn = 1;
