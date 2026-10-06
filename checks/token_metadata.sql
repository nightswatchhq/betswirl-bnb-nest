-- Token.name, symbol and decimals as decoded from Bank.getTokens() at each AddToken of the first
-- window. The native token reads "ETH" on BSC because that is what the bank contract returns.
SELECT token, pos, name, symbol, decimals
FROM bs_token_metadata
WHERE pos <= 18690000000000
ORDER BY pos, token
