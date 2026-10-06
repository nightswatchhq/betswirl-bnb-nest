-- Bet.payoutMultiplier for a roll, as graph-node computes payout.toBigDecimal() / totalBetAmount.toBigDecimal().
CREATE VIEW bs_payout_multiplier AS
WITH n AS (
  SELECT pos, (CASE WHEN length(payout) <= 34 THEN payout ELSE (CASE WHEN length(payout) > 34 AND substr(payout, 35, 1) >= '5'
  THEN (CASE WHEN rtrim(substr(payout, 1, 34), '9') = '' THEN '1' || repeat('0', length(substr(payout, 1, 34)))
  ELSE substr(rtrim(substr(payout, 1, 34), '9'), 1, length(rtrim(substr(payout, 1, 34), '9')) - 1)
    || chr(ascii(substr(rtrim(substr(payout, 1, 34), '9'), length(rtrim(substr(payout, 1, 34), '9')), 1)) + 1)
    || repeat('0', length(substr(payout, 1, 34)) - length(rtrim(substr(payout, 1, 34), '9'))) END) ELSE substr(payout, 1, 34) END) || repeat('0', length(payout) - 34) END) AS p, (CASE WHEN length(total) <= 34 THEN total ELSE (CASE WHEN length(total) > 34 AND substr(total, 35, 1) >= '5'
  THEN (CASE WHEN rtrim(substr(total, 1, 34), '9') = '' THEN '1' || repeat('0', length(substr(total, 1, 34)))
  ELSE substr(rtrim(substr(total, 1, 34), '9'), 1, length(rtrim(substr(total, 1, 34), '9')) - 1)
    || chr(ascii(substr(rtrim(substr(total, 1, 34), '9'), length(rtrim(substr(total, 1, 34), '9')), 1)) + 1)
    || repeat('0', length(substr(total, 1, 34)) - length(rtrim(substr(total, 1, 34), '9'))) END) ELSE substr(total, 1, 34) END) || repeat('0', length(total) - 34) END) AS t FROM bs_resolution WHERE kind = 'roll'
), q AS (
  SELECT pos, p, CASE WHEN p = '0' OR t = '0' THEN NULL ELSE nuthatch_mul_div(p, '1' || repeat('0', 140), t) END AS q FROM n
), s AS (
  SELECT pos, p, q, (CASE WHEN length(q) > 100 AND substr(q, 101, 1) >= '5'
  THEN (CASE WHEN rtrim(substr(q, 1, 100), '9') = '' THEN '1' || repeat('0', length(substr(q, 1, 100)))
  ELSE substr(rtrim(substr(q, 1, 100), '9'), 1, length(rtrim(substr(q, 1, 100), '9')) - 1)
    || chr(ascii(substr(rtrim(substr(q, 1, 100), '9'), length(rtrim(substr(q, 1, 100), '9')), 1)) + 1)
    || repeat('0', length(substr(q, 1, 100)) - length(rtrim(substr(q, 1, 100), '9'))) END) ELSE substr(q, 1, 100) END) AS s100 FROM q
), m AS (
  SELECT pos, p, q, s100, (CASE WHEN length(s100) > 34 AND substr(s100, 35, 1) >= '5'
  THEN (CASE WHEN rtrim(substr(s100, 1, 34), '9') = '' THEN '1' || repeat('0', length(substr(s100, 1, 34)))
  ELSE substr(rtrim(substr(s100, 1, 34), '9'), 1, length(rtrim(substr(s100, 1, 34), '9')) - 1)
    || chr(ascii(substr(rtrim(substr(s100, 1, 34), '9'), length(rtrim(substr(s100, 1, 34), '9')), 1)) + 1)
    || repeat('0', length(substr(s100, 1, 34)) - length(rtrim(substr(s100, 1, 34), '9'))) END) ELSE substr(s100, 1, 34) END) AS m34 FROM s
), e AS (
  SELECT pos, p, rtrim(m34, '0') AS mant,
         CAST(length(q) - 140 + (length(s100) - least(length(q), 100)) + (length(m34) - least(length(s100), 34)) AS BIGINT) AS ex
  FROM m
)
SELECT pos, CASE
  WHEN p = '0' THEN '0'
  WHEN mant IS NULL THEN NULL
  WHEN ex >= length(mant) THEN mant || repeat('0', CAST(ex - length(mant) AS INT))
  WHEN ex > 0 THEN substr(mant, 1, CAST(ex AS INT)) || '.' || substr(mant, CAST(ex + 1 AS INT))
  ELSE '0.' || repeat('0', CAST(-ex AS INT)) || mant
END AS multiplier
FROM e;
