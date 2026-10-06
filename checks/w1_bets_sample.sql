-- One bet of each kind in the first window, in full: per game, won, lost, refunded and unresolved.
SELECT id, "gameId", "gameToken", "inputValue", "betAmount", "houseEdge", resolved, refunded, "totalBetAmount",
       payout, "payoutMultiplier", array_to_string(rolled, ',') AS rolled, "betTxnHash", "rollTxnHash"
FROM bet
WHERE id IN (
  SELECT min(id) FROM bet WHERE "betTimestamp" <= 1655236100
  GROUP BY "gameId", resolved, refunded,
           CAST(payout AS DECIMAL(38,0)) > CAST("totalBetAmount" AS DECIMAL(38,0))
)
ORDER BY id
