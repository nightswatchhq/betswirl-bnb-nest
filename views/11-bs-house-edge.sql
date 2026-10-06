-- Every write of GameToken.houseEdge, keyed as the mapping keys it: by gameId string, not by contract.
CREATE VIEW bs_house_edge AS
SELECT 'Dice' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "dice_v1__set_house_edge" e
UNION ALL
SELECT 'Dice' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "dice_v2__set_house_edge" e
UNION ALL
SELECT 'Dice' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "dice_v3__set_house_edge" e
UNION ALL
SELECT 'Dice' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "dice_v4__set_house_edge" e
UNION ALL
SELECT 'Dice' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "dice_v4_5__set_house_edge" e
UNION ALL
SELECT 'Dice' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "dice_v5__set_house_edge" e
UNION ALL
SELECT 'CoinToss' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "coin_toss_v1__set_house_edge" e
UNION ALL
SELECT 'CoinToss' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "coin_toss_v2__set_house_edge" e
UNION ALL
SELECT 'CoinToss' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "coin_toss_v3__set_house_edge" e
UNION ALL
SELECT 'CoinToss' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "coin_toss_v4__set_house_edge" e
UNION ALL
SELECT 'CoinToss' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "coin_toss_v4_5__set_house_edge" e
UNION ALL
SELECT 'CoinToss' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "coin_toss_v5__set_house_edge" e
UNION ALL
SELECT 'Roulette' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "roulette_v1__set_house_edge" e
UNION ALL
SELECT 'Roulette' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "roulette_v2__set_house_edge" e
UNION ALL
SELECT 'Roulette' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "roulette_v2_5__set_house_edge" e
UNION ALL
SELECT 'Roulette' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "roulette_v3__set_house_edge" e
UNION ALL
SELECT 'Keno' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "keno_v1__set_house_edge" e
UNION ALL
SELECT 'Keno' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "keno_v1_5__set_house_edge" e
UNION ALL
SELECT 'Keno' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "keno_v2__set_house_edge" e
UNION ALL
SELECT w.game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "weighted_game_v1__set_house_edge" e
CROSS JOIN (VALUES ('Wheel'), ('Plinko'), ('Mines'), ('Diamonds'), ('Slide'), ('Slot'), ('CUSTOM_WEIGHTED_GAME')) AS w(game_id);

-- AffiliateGameToken.houseEdge writes. A zero affiliate never gets an AffiliateGameToken.
CREATE VIEW bs_affiliate_house_edge AS
SELECT e.affiliate, 'Dice' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "dice_v5__set_affiliate_house_edge" e WHERE e.affiliate <> '0x0000000000000000000000000000000000000000'
UNION ALL
SELECT e.affiliate, 'CoinToss' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "coin_toss_v5__set_affiliate_house_edge" e WHERE e.affiliate <> '0x0000000000000000000000000000000000000000'
UNION ALL
SELECT e.affiliate, 'Roulette' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "roulette_v3__set_affiliate_house_edge" e WHERE e.affiliate <> '0x0000000000000000000000000000000000000000'
UNION ALL
SELECT e.affiliate, 'Keno' AS game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "keno_v2__set_affiliate_house_edge" e WHERE e.affiliate <> '0x0000000000000000000000000000000000000000'
UNION ALL
SELECT e.affiliate, w.game_id, e.token, CAST(e."houseEdge" AS INTEGER) AS house_edge, CAST(e.block_number AS BIGINT) * 1000000 + CAST(e.log_index AS BIGINT) AS pos
FROM "weighted_game_v1__set_affiliate_house_edge" e
CROSS JOIN (VALUES ('Wheel'), ('Plinko'), ('Mines'), ('Diamonds'), ('Slide'), ('Slot'), ('CUSTOM_WEIGHTED_GAME')) AS w(game_id)
WHERE e.affiliate <> '0x0000000000000000000000000000000000000000';
