-- Affiliate: getAffiliate creates one for any non-zero affiliate it sees. Only id is reproduced.
CREATE VIEW affiliate AS
SELECT DISTINCT id FROM (
  SELECT affiliate AS id FROM bs_placed
  UNION ALL SELECT affiliate FROM bs_affiliate_house_edge
) WHERE id <> '0x0000000000000000000000000000000000000000';
