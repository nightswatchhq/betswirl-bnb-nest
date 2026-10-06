-- User: every bettor has one (getUser in _createBet). Only id is reproduced.
CREATE VIEW "user" AS SELECT DISTINCT bettor AS id FROM bs_placed;
