// Golden answers to the SDK's own queries, per smoke window. Each case is a published SDK document
// (queries/*.graphql) with the variables the SDK sends, bounded by a timestamp so a nest stopped a
// little past the window answers the same.
//
// usage: node tests/golden.js <window> <graphql-url> [--update]
//   window: w1 | w2 | w3 | w4, as tests/README.md describes how to index them.
"use strict";
const fs = require("fs");
const path = require("path");
const [win, url, update] = process.argv.slice(2);
const NEST = path.join(__dirname, "..");
// The timestamps of blocks 18,740,000, 45,200,000, 66,400,000 and 50,600,000.
const BOUND = { w1: 1655387404, w2: 1735181078, w3: 1761800892, w4: 1748643835 };
if (!BOUND[win] || !url) {
  console.error("usage: node tests/golden.js <w1|w2|w3|w4> <graphql-url> [--update]");
  process.exit(2);
}
const T = String(BOUND[win]);
const doc = (f) => fs.readFileSync(path.join(NEST, "queries", f), "utf8");
const cases = {
  "bets-newest": [doc("bets.graphql"), { first: 50, skip: 0, where: { betTimestamp_lte: T }, orderBy: "betTimestamp", orderDirection: "desc" }],
  "bets-page-2": [doc("bets.graphql"), { first: 25, skip: 25, where: { betTimestamp_lte: T }, orderBy: "betTimestamp", orderDirection: "desc" }],
  "bets-resolved-by-amount": [doc("bets.graphql"), { first: 20, skip: 0, where: { resolved: true, betTimestamp_lte: T }, orderBy: "betAmount", orderDirection: "desc" }],
  "bets-refunded": [doc("bets.graphql"), { first: 20, skip: 0, where: { refunded: true, betTimestamp_lte: T }, orderBy: "betTimestamp", orderDirection: "desc" }],
};
(async () => {
  const dir = path.join(__dirname, "golden", win);
  fs.mkdirSync(dir, { recursive: true });
  let bad = 0;
  for (const [name, [query, variables]] of Object.entries(cases)) {
    const r = await fetch(url, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ query, variables }) });
    const got = JSON.stringify(await r.json(), null, 1) + "\n";
    const file = path.join(dir, name + ".json");
    if (update) { fs.writeFileSync(file, got); console.log("recorded", win, name); continue; }
    const want = fs.readFileSync(file, "utf8");
    if (want === got) console.log("ok", win, name);
    else { bad++; console.log("DIFF", win, name); }
  }
  process.exit(bad ? 1 : 0);
})();
