-- The Token entity. Counters follow _updateResolveAnalytics (one per roll or refund that reached a
-- bet); the splits follow the bank's AllocateHouseEdgeAmount handlers, which skip a token that does
-- not exist yet. balancesDayDataLength has no column and is refused by name.
CREATE VIEW bs_allocation AS
SELECT a.token, CAST(a.block_number AS BIGINT) * 1000000 + CAST(a.log_index AS BIGINT) AS pos, CAST(a.dividend AS DECIMAL(38,0)) AS "dividendAmount", CAST(0 AS DECIMAL(38,0)) AS "bankAmount", CAST(0 AS DECIMAL(38,0)) AS "partnerAmount", CAST(0 AS DECIMAL(38,0)) AS "affiliateAmount", CAST(a.treasury AS DECIMAL(38,0)) AS "treasuryAmount", CAST(a.team AS DECIMAL(38,0)) AS "teamAmount"
FROM "bank_v1__allocate_house_edge_amount" a
UNION ALL
SELECT a.token, CAST(a.block_number AS BIGINT) * 1000000 + CAST(a.log_index AS BIGINT) AS pos, CAST(a.dividend AS DECIMAL(38,0)) AS "dividendAmount", CAST(0 AS DECIMAL(38,0)) AS "bankAmount", CAST(a.partner AS DECIMAL(38,0)) AS "partnerAmount", CAST(0 AS DECIMAL(38,0)) AS "affiliateAmount", CAST(a.treasury AS DECIMAL(38,0)) AS "treasuryAmount", CAST(a.team AS DECIMAL(38,0)) AS "teamAmount"
FROM "bank_v2__allocate_house_edge_amount" a
UNION ALL
SELECT a.token, CAST(a.block_number AS BIGINT) * 1000000 + CAST(a.log_index AS BIGINT) AS pos, CAST(a.dividend AS DECIMAL(38,0)) AS "dividendAmount", CAST(a.bank AS DECIMAL(38,0)) AS "bankAmount", CAST(a.partner AS DECIMAL(38,0)) AS "partnerAmount", CAST(0 AS DECIMAL(38,0)) AS "affiliateAmount", CAST(a.treasury AS DECIMAL(38,0)) AS "treasuryAmount", CAST(a.team AS DECIMAL(38,0)) AS "teamAmount"
FROM "bank_v3__allocate_house_edge_amount" a
UNION ALL
SELECT a.token, CAST(a.block_number AS BIGINT) * 1000000 + CAST(a.log_index AS BIGINT) AS pos, CAST(a.dividend AS DECIMAL(38,0)) AS "dividendAmount", CAST(a.bank AS DECIMAL(38,0)) AS "bankAmount", CAST(a.partner AS DECIMAL(38,0)) AS "partnerAmount", CAST(0 AS DECIMAL(38,0)) AS "affiliateAmount", CAST(a.treasury AS DECIMAL(38,0)) AS "treasuryAmount", CAST(a.team AS DECIMAL(38,0)) AS "teamAmount"
FROM "bank_v3_5__allocate_house_edge_amount" a
UNION ALL
SELECT a.token, CAST(a.block_number AS BIGINT) * 1000000 + CAST(a.log_index AS BIGINT) AS pos, CAST(a.dividend AS DECIMAL(38,0)) AS "dividendAmount", CAST(a.bank AS DECIMAL(38,0)) AS "bankAmount", CAST(0 AS DECIMAL(38,0)) AS "partnerAmount", CAST(a.affiliate AS DECIMAL(38,0)) AS "affiliateAmount", CAST(a.treasury AS DECIMAL(38,0)) AS "treasuryAmount", CAST(a.team AS DECIMAL(38,0)) AS "teamAmount"
FROM "bank_v4__allocate_house_edge_amount" a;

CREATE VIEW token AS
WITH created AS (
  SELECT token, min(pos) AS pos FROM bs_token_added GROUP BY token
), meta AS (
  SELECT token, name, symbol, decimals FROM (
    SELECT m.*, row_number() OVER (PARTITION BY m.token ORDER BY m.pos DESC) AS rn FROM bs_token_metadata m
  ) WHERE rn = 1
), counters AS (
  SELECT CASE WHEN kind = 'roll' THEN r_token ELSE p_token END AS token,
         count(*) AS bet_txn_count, sum(CAST(bet_count AS DECIMAL(38,0))) AS bet_count,
         sum(CASE WHEN CAST(payout AS DECIMAL(38,0)) > CAST(total AS DECIMAL(38,0)) THEN 1 ELSE 0 END) AS win_txn_count,
         count(DISTINCT CASE WHEN kind = 'roll' THEN r_user ELSE bettor END) AS user_count,
         sum(CAST(total AS DECIMAL(38,0))) AS wagered, sum(CAST(payout AS DECIMAL(38,0))) AS paid
  FROM bs_applied GROUP BY 1
), alloc AS (
  SELECT a.token, sum(a."dividendAmount") AS "dividendAmount", sum(a."bankAmount") AS "bankAmount", sum(a."partnerAmount") AS "partnerAmount", sum(a."affiliateAmount") AS "affiliateAmount", sum(a."treasuryAmount") AS "treasuryAmount", sum(a."teamAmount") AS "teamAmount"
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
       CAST(COALESCE(a."dividendAmount", 0) AS VARCHAR) AS "dividendAmount",
       CAST(COALESCE(a."bankAmount", 0) AS VARCHAR) AS "bankAmount",
       CAST(COALESCE(a."partnerAmount", 0) AS VARCHAR) AS "partnerAmount",
       CAST(COALESCE(a."affiliateAmount", 0) AS VARCHAR) AS "affiliateAmount",
       CAST(COALESCE(a."treasuryAmount", 0) AS VARCHAR) AS "treasuryAmount",
       CAST(COALESCE(a."teamAmount", 0) AS VARCHAR) AS "teamAmount"
FROM created c
LEFT JOIN meta m ON m.token = c.token
LEFT JOIN counters n ON n.token = c.token
LEFT JOIN alloc a ON a.token = c.token;
