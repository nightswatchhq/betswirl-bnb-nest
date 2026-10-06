-- Every PlaceBet, as the arguments the mapping's _createBet receives.
CREATE VIEW bs_placement AS
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       '0' AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'Dice' AS game_id, NULL AS config_id, CAST(p."cap" AS VARCHAR) AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "dice_v1__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       '0' AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'Dice' AS game_id, NULL AS config_id, CAST(p."cap" AS VARCHAR) AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "dice_v2__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       '0' AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'Dice' AS game_id, NULL AS config_id, CAST(p."cap" AS VARCHAR) AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "dice_v3__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       p.amount AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'Dice' AS game_id, NULL AS config_id, CAST(p."cap" AS VARCHAR) AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "dice_v4__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       p.amount AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'Dice' AS game_id, NULL AS config_id, CAST(p."cap" AS VARCHAR) AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "dice_v4_5__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, receiver AS bettor, p.token, p.affiliate AS affiliate,
       p.amount AS amount, CAST(p."betCount" AS VARCHAR) AS bet_count, p."stopLoss" AS stop_loss, p."stopGain" AS stop_gain,
       'Dice' AS game_id, NULL AS config_id, CAST(p."cap" AS VARCHAR) AS input_value, p."chargedVRFCost" AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "dice_v5__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       '0' AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'CoinToss' AS game_id, NULL AS config_id, CASE WHEN p."face" = 'true' THEN '1' ELSE '0' END AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "coin_toss_v1__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       '0' AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'CoinToss' AS game_id, NULL AS config_id, CASE WHEN p."face" = 'true' THEN '1' ELSE '0' END AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "coin_toss_v2__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       '0' AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'CoinToss' AS game_id, NULL AS config_id, CASE WHEN p."face" = 'true' THEN '1' ELSE '0' END AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "coin_toss_v3__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       p.amount AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'CoinToss' AS game_id, NULL AS config_id, CASE WHEN p."face" = 'true' THEN '1' ELSE '0' END AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "coin_toss_v4__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       p.amount AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'CoinToss' AS game_id, NULL AS config_id, CASE WHEN p."face" = 'true' THEN '1' ELSE '0' END AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "coin_toss_v4_5__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, receiver AS bettor, p.token, p.affiliate AS affiliate,
       p.amount AS amount, CAST(p."betCount" AS VARCHAR) AS bet_count, p."stopLoss" AS stop_loss, p."stopGain" AS stop_gain,
       'CoinToss' AS game_id, NULL AS config_id, CASE WHEN p."face" = 'true' THEN '1' ELSE '0' END AS input_value, p."chargedVRFCost" AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "coin_toss_v5__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       '0' AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'Roulette' AS game_id, NULL AS config_id, CAST(p."numbers" AS VARCHAR) AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "roulette_v1__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       p.amount AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'Roulette' AS game_id, NULL AS config_id, CAST(p."numbers" AS VARCHAR) AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "roulette_v2__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       p.amount AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'Roulette' AS game_id, NULL AS config_id, CAST(p."numbers" AS VARCHAR) AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "roulette_v2_5__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, receiver AS bettor, p.token, p.affiliate AS affiliate,
       p.amount AS amount, CAST(p."betCount" AS VARCHAR) AS bet_count, p."stopLoss" AS stop_loss, p."stopGain" AS stop_gain,
       'Roulette' AS game_id, NULL AS config_id, CAST(p."numbers" AS VARCHAR) AS input_value, p."chargedVRFCost" AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "roulette_v3__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       p.amount AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'Keno' AS game_id, NULL AS config_id, CAST(p."numbers" AS VARCHAR) AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "keno_v1__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, "user" AS bettor, p.token, '0x0000000000000000000000000000000000000000' AS affiliate,
       p.amount AS amount, '1' AS bet_count, '0' AS stop_loss, '0' AS stop_gain,
       'Keno' AS game_id, NULL AS config_id, CAST(p."numbers" AS VARCHAR) AS input_value, '0' AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "keno_v1_5__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, receiver AS bettor, p.token, p.affiliate AS affiliate,
       p.amount AS amount, CAST(p."betCount" AS VARCHAR) AS bet_count, p."stopLoss" AS stop_loss, p."stopGain" AS stop_gain,
       'Keno' AS game_id, NULL AS config_id, CAST(p."numbers" AS VARCHAR) AS input_value, p."chargedVRFCost" AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "keno_v2__place_bet" p
UNION ALL
SELECT CAST(p.id AS VARCHAR) AS id, receiver AS bettor, p.token, p.affiliate AS affiliate,
       p.amount AS amount, CAST(p."betCount" AS VARCHAR) AS bet_count, p."stopLoss" AS stop_loss, p."stopGain" AS stop_gain,
       NULL AS game_id, CAST(p."configId" AS BIGINT) AS config_id, CAST(p."configId" AS VARCHAR) AS input_value, p."chargedVRFCost" AS charged_vrf_fees,
       p.address AS game_address, CAST(p.block_timestamp AS BIGINT) AS ts, p.tx_hash, CAST(p.block_number AS BIGINT) * 1000000 + CAST(p.log_index AS BIGINT) AS pos
FROM "weighted_game_v1__place_bet" p;
