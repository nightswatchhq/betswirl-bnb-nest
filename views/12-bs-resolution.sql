-- Every Roll and BetRefunded, as the arguments _rollBet and _refundBet receive. A resolution only
-- touches a bet that already exists, which bs_applied decides.
CREATE VIEW bs_resolution AS
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CAST(r.rolled AS VARCHAR)) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v1__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CAST(r.rolled AS VARCHAR)) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v2__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CAST(r.rolled AS VARCHAR)) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v3__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CAST(r.rolled AS VARCHAR)) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v4__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CAST(r.rolled AS VARCHAR)) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v4_5__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r.receiver AS r_user, r.token AS r_token, '0' AS amount,
       r."totalBetAmount" AS total, r.payout, string_to_array(replace(replace(replace(trim(r.rolled, '[]'), 'true', '1'), 'false', '0'), '"', ''), ',') AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v5__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CASE WHEN r.rolled = 'true' THEN '1' ELSE '0' END) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v1__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CASE WHEN r.rolled = 'true' THEN '1' ELSE '0' END) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v2__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CASE WHEN r.rolled = 'true' THEN '1' ELSE '0' END) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v3__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CASE WHEN r.rolled = 'true' THEN '1' ELSE '0' END) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v4__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CASE WHEN r.rolled = 'true' THEN '1' ELSE '0' END) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v4_5__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r.receiver AS r_user, r.token AS r_token, '0' AS amount,
       r."totalBetAmount" AS total, r.payout, string_to_array(replace(replace(replace(trim(r.rolled, '[]'), 'true', '1'), 'false', '0'), '"', ''), ',') AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v5__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CAST(r.rolled AS VARCHAR)) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "roulette_v1__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CAST(r.rolled AS VARCHAR)) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "roulette_v2__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CAST(r.rolled AS VARCHAR)) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "roulette_v2_5__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r.receiver AS r_user, r.token AS r_token, '0' AS amount,
       r."totalBetAmount" AS total, r.payout, string_to_array(replace(replace(replace(trim(r.rolled, '[]'), 'true', '1'), 'false', '0'), '"', ''), ',') AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "roulette_v3__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CAST(r.rolled AS VARCHAR)) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "keno_v1__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r."user" AS r_user, r.token AS r_token, r.amount AS amount,
       r.amount AS total, r.payout, make_array(CAST(r.rolled AS VARCHAR)) AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "keno_v1_5__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r.receiver AS r_user, r.token AS r_token, '0' AS amount,
       r."totalBetAmount" AS total, r.payout, string_to_array(replace(replace(replace(trim(r.rolled, '[]'), 'true', '1'), 'false', '0'), '"', ''), ',') AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "keno_v2__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'roll' AS kind, r.receiver AS r_user, r.token AS r_token, '0' AS amount,
       r."totalBetAmount" AS total, r.payout, string_to_array(replace(replace(replace(trim(r.rolled, '[]'), 'true', '1'), 'false', '0'), '"', ''), ',') AS rolled, r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "weighted_game_v1__roll" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       r.amount AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v1__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       r.amount AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v2__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       r.amount AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v3__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       '0' AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v4__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       '0' AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v4_5__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       r.amount AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "dice_v5__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       r.amount AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v1__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       r.amount AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v2__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       r.amount AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v3__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       '0' AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v4__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       '0' AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v4_5__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       r.amount AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "coin_toss_v5__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       r.amount AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "roulette_v1__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       '0' AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "roulette_v2__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       '0' AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "roulette_v2_5__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       r.amount AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "roulette_v3__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       '0' AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "keno_v1__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       '0' AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "keno_v1_5__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       '0' AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "keno_v2__bet_refunded" r
UNION ALL
SELECT CAST(r.id AS VARCHAR) AS id, 'refund' AS kind, CAST(NULL AS VARCHAR) AS r_user, CAST(NULL AS VARCHAR) AS r_token,
       '0' AS amount, r.amount AS total, r.amount AS payout, CAST(NULL AS VARCHAR[]) AS rolled,
       r.tx_hash, CAST(r.block_timestamp AS BIGINT) AS ts, CAST(r.block_number AS BIGINT) * 1000000 + CAST(r.log_index AS BIGINT) AS pos
FROM "weighted_game_v1__bet_refunded" r;
