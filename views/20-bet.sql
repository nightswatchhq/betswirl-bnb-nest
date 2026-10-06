-- The Bet entity. Columns are the schema's field names; Bet.consumedNativeVRFFees,
-- consumedLinkVRFFees and kenoBet have no column and are refused by name.
CREATE VIEW bet AS
SELECT id, "gameId", "gameAddress", "user", "gameToken", affiliate, "inputValue", "betAmount", "betCount",
       "stopLoss", "stopGain", "houseEdge", "betTimestamp", resolved, refunded, "chargedVRFFees", "betTxnHash",
       "isFreebet", "freebetId", "totalBetAmount", payout, "payoutMultiplier", "rollTxnHash", rolled, "rollTimestamp"
FROM bs_bet;
