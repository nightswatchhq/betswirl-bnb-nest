-- graph-node BigDecimal quotients: the twenty commonest payoutMultiplier strings of the first window.
SELECT "payoutMultiplier", count(*) AS bets
FROM bet
WHERE "betTimestamp" <= 1655236100 AND "payoutMultiplier" IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC, 1
LIMIT 20
