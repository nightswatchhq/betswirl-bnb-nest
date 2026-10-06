-- Every Bet placed by block 18,690,000 (timestamp 1655236100), summarised per game over every SDK
-- field. Recorded on a copy indexed from deployment to block 18,743,237 (sealed through 18,696,748:
-- `nuthatch check` reads sealed history only, which is why the cut sits below that) and accepted against
-- tests/reference.js, which shares no code with nuthatch. The SQL surface has no hash function, so
-- this is sums and counts rather than a digest.
SELECT "gameId", count(*) AS bets, count(DISTINCT "user") AS users, count(DISTINCT "gameToken") AS game_tokens,
       count(DISTINCT affiliate) AS affiliates, CAST(sum(CAST("inputValue" AS DECIMAL(38,0))) AS VARCHAR) AS inputs,
       CAST(sum(CAST("betAmount" AS DECIMAL(38,0))) AS VARCHAR) AS bet_amount,
       CAST(sum(CAST("betCount" AS DECIMAL(38,0))) AS VARCHAR) AS bet_count, sum("houseEdge") AS house_edge,
       min("betTimestamp") AS first_ts, max("betTimestamp") AS last_ts,
       sum(CASE WHEN resolved THEN 1 ELSE 0 END) AS resolved, sum(CASE WHEN refunded THEN 1 ELSE 0 END) AS refunded,
       CAST(sum(CAST("totalBetAmount" AS DECIMAL(38,0))) AS VARCHAR) AS total_bet_amount,
       CAST(sum(CAST(payout AS DECIMAL(38,0))) AS VARCHAR) AS payout,
       count(DISTINCT "payoutMultiplier") AS multipliers, sum(length("payoutMultiplier")) AS multiplier_chars,
       count(DISTINCT "rollTxnHash") AS roll_txs, sum(array_length(rolled)) AS rolled_values,
       count(DISTINCT array_to_string(rolled, ',')) AS rolled_distinct, max("rollTimestamp") AS last_roll_ts
FROM bet
WHERE "betTimestamp" <= 1655236100
GROUP BY "gameId"
ORDER BY "gameId"
