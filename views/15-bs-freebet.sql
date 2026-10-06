-- handleFreebetPlacedV1: the latest PlaceFreeBet for a bet that exists marks it a freebet.
CREATE VIEW bs_freebet AS
WITH hit AS (
  SELECT CAST(f."betId" AS VARCHAR) AS id, p.pos AS placement_pos, CAST(f."freeBetId" AS VARCHAR) AS freebet_id,
         CAST(f.block_number AS BIGINT) * 1000000 + CAST(f.log_index AS BIGINT) AS pos, row_number() OVER (PARTITION BY CAST(f.block_number AS BIGINT) * 1000000 + CAST(f.log_index AS BIGINT) ORDER BY p.pos DESC) AS rn
  FROM "freebet_v1__place_free_bet" f
  JOIN bs_placed p ON p.id = CAST(f."betId" AS VARCHAR) AND p.pos < CAST(f.block_number AS BIGINT) * 1000000 + CAST(f.log_index AS BIGINT)
)
SELECT id, placement_pos, freebet_id FROM (
  SELECT h.*, row_number() OVER (PARTITION BY h.placement_pos ORDER BY h.pos DESC) AS rn2 FROM hit h WHERE h.rn = 1
) x WHERE rn2 = 1;
