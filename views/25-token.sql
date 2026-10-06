-- Token creation (getToken in each AddToken handler; V4 only when added) and the metadata the
-- handler copied from Bank.getTokens() at that block.
CREATE VIEW bs_token_added AS
SELECT a.token, CAST(a.block_number AS BIGINT) * 1000000 + CAST(a.log_index AS BIGINT) AS pos, a.block_number, 'bank_v1' AS bank FROM "bank_v1__add_token" a
UNION ALL
SELECT a.token, CAST(a.block_number AS BIGINT) * 1000000 + CAST(a.log_index AS BIGINT) AS pos, a.block_number, 'bank_v2' AS bank FROM "bank_v2__add_token" a
UNION ALL
SELECT a.token, CAST(a.block_number AS BIGINT) * 1000000 + CAST(a.log_index AS BIGINT) AS pos, a.block_number, 'bank_v3' AS bank FROM "bank_v3__add_token" a
UNION ALL
SELECT a.token, CAST(a.block_number AS BIGINT) * 1000000 + CAST(a.log_index AS BIGINT) AS pos, a.block_number, 'bank_v3_5' AS bank FROM "bank_v3_5__add_token" a
UNION ALL
SELECT a.token, CAST(a.block_number AS BIGINT) * 1000000 + CAST(a.log_index AS BIGINT) AS pos, a.block_number, 'bank_v4' AS bank FROM "bank_v4__add_token" a WHERE a.added = 'true';

CREATE VIEW bs_token_metadata AS
WITH calls AS (
  SELECT 'bank_v1' AS bank, block_number, result FROM "bank_v1_get_tokens" WHERE NOT CAST(reverted AS BOOLEAN)
  UNION ALL
  SELECT 'bank_v2' AS bank, block_number, result FROM "bank_v2_get_tokens" WHERE NOT CAST(reverted AS BOOLEAN)
  UNION ALL
  SELECT 'bank_v3' AS bank, block_number, result FROM "bank_v3_get_tokens" WHERE NOT CAST(reverted AS BOOLEAN)
  UNION ALL
  SELECT 'bank_v3_5' AS bank, block_number, result FROM "bank_v3_5_get_tokens" WHERE NOT CAST(reverted AS BOOLEAN)
  UNION ALL
  SELECT 'bank_v4' AS bank, block_number, result FROM "bank_v4_get_tokens" WHERE NOT CAST(reverted AS BOOLEAN)
), arr AS (
  SELECT a.token, a.pos, c.result, TRY_CAST(nuthatch_uint256('0x' || substr(c.result, 67, 64)) AS BIGINT) AS n
  FROM bs_token_added a JOIN calls c ON c.bank = a.bank AND c.block_number = a.block_number
  -- TRY_CAST: the engine may evaluate this before k.i < arr.n removes the row, and past the array
  -- the word is string data ("ETH" read as an offset), which does not fit a BIGINT.
), el AS (
  SELECT arr.token, arr.pos,
         substr(arr.result, 3 + 2 * (64 + TRY_CAST(nuthatch_uint256('0x' || substr(arr.result, 3 + 64 * (2 + k.i), 64)) AS BIGINT))) AS e
  FROM arr CROSS JOIN (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15), (16), (17), (18), (19), (20), (21), (22), (23), (24), (25), (26), (27), (28), (29), (30), (31)) AS k(i) WHERE k.i < arr.n
), dec AS (
  SELECT token, pos, e, '0x' || substr(e, 89, 40) AS addr,
         nuthatch_abi_tuple('uint256,address,string', '0x' || e) AS j3,
         nuthatch_abi_tuple('uint256,address,string,string', '0x' || e) AS j4
  FROM el
), parsed AS (
  SELECT token, pos, j3, j4,
         '["' || CAST(CAST(nuthatch_uint256('0x' || substr(e, 1, 64)) AS INTEGER) AS VARCHAR) || '","' || addr || '","' AS head
  FROM dec WHERE addr = token
), named AS (
  SELECT token, pos, head,
         substr(j3, length(head) + 1, length(j3) - length(head) - 2) AS name_json, j4
  FROM parsed
)
SELECT token, pos,
       CAST(substr(head, 3, strpos(head, '","') - 3) AS INTEGER) AS decimals,
       name_json AS name,
       substr(j4, length(head) + length(name_json) + 4, length(j4) - length(head) - length(name_json) - 5) AS symbol
FROM named;
