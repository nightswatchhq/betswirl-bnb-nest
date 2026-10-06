// An independent reference for the nest's answers: raw eth_getLogs and eth_call from the RPC, decoded
// here, run through a re-statement of the subgraph mapping's handlers (read from the deployed WASM),
// and compared field by field with what the nest's GraphQL endpoint answers. It shares no code with
// nuthatch: not its decoder, not its views.
//
// usage: NEST_RPC=… node tests/reference.js <graphql-url> <from-block> <to-block> [boundary-block]
// Bets placed after <boundary-block> are not compared, so a nest stopped a little past <to-block>
// gives the same verdict as one stopped exactly there.
"use strict";
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const [url, fromArg, toArg, boundaryArg] = process.argv.slice(2);
const RPC = process.env.NEST_RPC;
if (!RPC || !url || !fromArg || !toArg) {
  console.error("usage: NEST_RPC=… node tests/reference.js <graphql-url> <from> <to> [boundary]");
  process.exit(2);
}
const FROM = +fromArg, TO = +toArg, BOUNDARY = boundaryArg ? +boundaryArg : TO;
const NEST = path.join(__dirname, "..");
const ZERO = "0x0000000000000000000000000000000000000000";

// ---- keccak256, for event topics (no dependencies) ---------------------------------------------
function keccak256(bytes) {
  const RC = [0x0000000000000001n, 0x0000000000008082n, 0x800000000000808an, 0x8000000080008000n,
    0x000000000000808bn, 0x0000000080000001n, 0x8000000080008081n, 0x8000000000008009n,
    0x000000000000008an, 0x0000000000000088n, 0x0000000080008009n, 0x000000008000000an,
    0x000000008000808bn, 0x800000000000008bn, 0x8000000000008089n, 0x8000000000008003n,
    0x8000000000008002n, 0x8000000000000080n, 0x000000000000800an, 0x800000008000000an,
    0x8000000080008081n, 0x8000000000008080n, 0x0000000080000001n, 0x8000000080008008n];
  const R = [0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14];
  const M = (1n << 64n) - 1n;
  const rot = (x, n) => (n === 0 ? x : ((x << BigInt(n)) | (x >> BigInt(64 - n))) & M);
  const rate = 136;
  const msg = Buffer.concat([Buffer.from(bytes), Buffer.alloc(rate - (bytes.length % rate))]);
  msg[bytes.length] ^= 0x01;
  msg[msg.length - 1] ^= 0x80;
  const s = new Array(25).fill(0n);
  for (let off = 0; off < msg.length; off += rate) {
    for (let i = 0; i < rate / 8; i++) s[i] ^= msg.readBigUInt64LE(off + i * 8);
    for (let round = 0; round < 24; round++) {
      const C = [0, 1, 2, 3, 4].map((x) => s[x] ^ s[x + 5] ^ s[x + 10] ^ s[x + 15] ^ s[x + 20]);
      for (let x = 0; x < 5; x++) {
        const D = C[(x + 4) % 5] ^ rot(C[(x + 1) % 5], 1);
        for (let y = 0; y < 25; y += 5) s[x + y] ^= D;
      }
      const B = new Array(25);
      for (let x = 0; x < 5; x++) for (let y = 0; y < 5; y++) B[y + 5 * ((2 * x + 3 * y) % 5)] = rot(s[x + 5 * y], R[x + 5 * y]);
      for (let x = 0; x < 5; x++) for (let y = 0; y < 5; y++) s[x + 5 * y] = B[x + 5 * y] ^ (~B[((x + 1) % 5) + 5 * y] & B[((x + 2) % 5) + 5 * y]);
      s[0] ^= RC[round];
    }
  }
  const out = Buffer.alloc(32);
  for (let i = 0; i < 4; i++) out.writeBigUInt64LE(s[i], i * 8);
  return "0x" + out.toString("hex");
}
if (keccak256(Buffer.from("")) !== "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470") throw new Error("keccak");

// ---- ABI decoding of the event shapes these contracts use --------------------------------------
const word = (hex, i) => hex.slice(64 * i, 64 * (i + 1));
function decodeStatic(type, w) {
  if (/^u?int/.test(type)) return BigInt("0x" + w).toString();
  if (type === "address") return "0x" + w.slice(24);
  if (type === "bool") return BigInt("0x" + w) !== 0n;
  throw new Error("type " + type);
}
function decodeLog(ev, log) {
  const data = log.data.slice(2);
  const out = {};
  let t = 1, h = 0;
  for (const inp of ev.inputs) {
    if (inp.indexed) { out[inp.name] = decodeStatic(inp.type, log.topics[t++].slice(2)); continue; }
    if (inp.type.endsWith("[]")) {
      const off = Number(BigInt("0x" + word(data, h)) / 32n);
      const n = Number(BigInt("0x" + word(data, off)));
      out[inp.name] = Array.from({ length: n }, (_, i) => decodeStatic(inp.type.slice(0, -2), word(data, off + 1 + i)));
    } else out[inp.name] = decodeStatic(inp.type, word(data, h));
    h++;
  }
  return out;
}

// ---- The contracts, from the nest's own config ---------------------------------------------------
const toml = fs.readFileSync(path.join(NEST, "nuthatch.toml"), "utf8");
const contracts = {};
for (const m of toml.matchAll(/alias = "([^"]+)"\naddress = "([^"]+)"\nstart_block = \d+\nabi = "([^"]+)"\nevents = \[([^\]]*)\]/g)) {
  const abi = JSON.parse(fs.readFileSync(path.join(NEST, m[3])));
  const wanted = [...m[4].matchAll(/"(\w+)"/g)].map((x) => x[1]);
  const byTopic = {};
  for (const ev of abi.filter((x) => x.type === "event" && wanted.includes(x.name))) {
    byTopic[keccak256(Buffer.from(`${ev.name}(${ev.inputs.map((i) => i.type).join(",")})`))] = ev;
  }
  contracts[m[2].toLowerCase()] = { alias: m[1], byTopic };
}

// ---- RPC -----------------------------------------------------------------------------------------
let rpcId = 0;
async function rpc(method, params) {
  for (let attempt = 0; ; attempt++) {
    try {
      const r = await fetch(RPC, { method: "POST", headers: { "content-type": "application/json" },
        signal: AbortSignal.timeout(60000), body: JSON.stringify({ jsonrpc: "2.0", id: ++rpcId, method, params }) });
      const j = await r.json();
      if (j.error) throw new Error(j.error.message);
      return j.result;
    } catch (e) {
      if (attempt > 6) throw new Error(`${method} failed: ${String(e.message).replace(RPC, "<rpc>")}`);
      await new Promise((s) => setTimeout(s, 1000 * (attempt + 1)));
    }
  }
}
async function allLogs() {
  const logs = [];
  for (let a = FROM; a <= TO; a += 10000) {
    const b = Math.min(a + 9999, TO);
    logs.push(...(await rpc("eth_getLogs", [{ address: Object.keys(contracts), fromBlock: "0x" + a.toString(16), toBlock: "0x" + b.toString(16) }])));
  }
  return logs.sort((x, y) => parseInt(x.blockNumber) - parseInt(y.blockNumber) || parseInt(x.logIndex) - parseInt(y.logIndex));
}

// ---- graph-node BigDecimal division (bigdecimal 0.1.2 + normalized()) ---------------------------
function roundHalfUp(digits, n) {
  if (digits.length <= n) return digits;
  let head = BigInt(digits.slice(0, n));
  if (digits[n] >= "5") head += 1n;
  return head.toString();
}
function bdDiv(p, t) {
  if (p === "0") return "0";
  const P = BigInt(norm34(p)), T = BigInt(norm34(t));
  const K = 140n;
  const q = ((P * 10n ** K) / T).toString();
  let ex = q.length - Number(K);
  const s100 = roundHalfUp(q, 100);
  ex += s100.length - Math.min(q.length, 100);
  const m34 = roundHalfUp(s100, 34);
  ex += m34.length - Math.min(s100.length, 34);
  const mant = m34.replace(/0+$/, "");
  if (ex >= mant.length) return mant + "0".repeat(ex - mant.length);
  if (ex > 0) return mant.slice(0, ex) + "." + mant.slice(ex);
  return "0." + "0".repeat(-ex) + mant;
}
function norm34(x) {
  if (x.length <= 34) return x;
  const r = roundHalfUp(x, 34);
  return r + "0".repeat(x.length - 34);
}

// ---- The mapping, re-stated -----------------------------------------------------------------------
const GAME = { dice: "Dice", coin_toss: "CoinToss", roulette: "Roulette", keno: "Keno" };
const WEIGHTED = ["Wheel", "Plinko", "Mines", "Diamonds", "Slide", "Slot", "CUSTOM_WEIGHTED_GAME"];
const placeShape = (alias) =>
  /_v5$|roulette_v3|keno_v2|weighted/.test(alias) ? 3 : /^(dice|coin_toss)_v[123]$|roulette_v1$/.test(alias) ? 1 : 2;
const refundShape = (alias) => (/^(dice|coin_toss)_v(1|2|3|5)$|^roulette_v(1|3)$/.test(alias) ? "A" : "B");
function gameOf(alias) {
  for (const [k, v] of Object.entries(GAME)) if (alias.startsWith(k + "_v")) return v;
  return null;
}

async function main() {
  const logs = await allLogs();
  const gameToken = new Map(); // "<gameId>-<token>" -> houseEdge
  const affGameToken = new Map(); // "<aff>-<gameId>-<token>" -> houseEdge
  const configs = new Map(); // configId -> {gameId, multipliers, weights}
  const bets = new Map();
  const weightedBets = new Map();
  const tokens = new Map();
  const userTokens = new Set();
  const added = new Set();
  const newToken = (id) => ({ id, name: "", symbol: "", decimals: 0, betTxnCount: "0", betCount: "0", winTxnCount: "0",
    userCount: "0", totalWagered: "0", totalPayout: "0", dividendAmount: "0", bankAmount: "0", partnerAmount: "0",
    affiliateAmount: "0", treasuryAmount: "0", teamAmount: "0" });
  const tokenOf = (t) => tokens.get(t);
  const bump = (tok, f, by) => { const T = tokenOf(tok); if (T) T[f] = (BigInt(T[f]) + BigInt(by)).toString(); };

  // _updateResolveAnalytics creates a missing Token rather than skipping it.
  function resolve(bet, user, token, total, payout) {
    if (!tokens.has(token)) tokens.set(token, newToken(token));
    const T = tokenOf(token);
    T.betTxnCount = (BigInt(T.betTxnCount) + 1n).toString();
    T.betCount = (BigInt(T.betCount) + BigInt(bet.betCount)).toString();
    if (!userTokens.has(user + "-" + token)) { userTokens.add(user + "-" + token); T.userCount = (BigInt(T.userCount) + 1n).toString(); }
    T.totalWagered = (BigInt(T.totalWagered) + BigInt(total)).toString();
    T.totalPayout = (BigInt(T.totalPayout) + BigInt(payout)).toString();
    if (BigInt(payout) > BigInt(total)) T.winTxnCount = (BigInt(T.winTxnCount) + 1n).toString();
  }

  for (const log of logs) {
    const c = contracts[log.address.toLowerCase()];
    const ev = c && c.byTopic[log.topics[0]];
    if (!ev) continue;
    const a = decodeLog(ev, log);
    const alias = c.alias;
    const block = parseInt(log.blockNumber);
    const ts = parseInt(log.blockTimestamp || (await blockTs(block)), 16).toString();
    const g = gameOf(alias);

    if (alias.startsWith("bank_")) {
      if (ev.name === "AddToken") {
        if (alias === "bank_v4" && !a.added) continue;
        if (!tokens.has(a.token)) tokens.set(a.token, newToken(a.token));
        added.add(a.token);
        const meta = await getTokens(log.address, block);
        const hit = meta.find((m) => m.token === a.token);
        if (hit) Object.assign(tokens.get(a.token), { name: hit.name, symbol: hit.symbol, decimals: hit.decimals });
      } else if (ev.name === "AllocateHouseEdgeAmount") {
        const add = { dividendAmount: a.dividend, bankAmount: a.bank, partnerAmount: a.partner, affiliateAmount: a.affiliate, treasuryAmount: a.treasury, teamAmount: a.team };
        for (const [f, v] of Object.entries(add)) if (v !== undefined) bump(a.token, f, v);
      }
      continue;
    }
    if (alias === "freebet_v1") {
      const b = bets.get(a.betId);
      if (b) { b.isFreebet = true; b.freebetId = a.freeBetId; }
      continue;
    }
    const gameIds = g ? [g] : WEIGHTED;
    if (ev.name === "SetHouseEdge") {
      for (const gid of gameIds) gameToken.set(`${gid}-${a.token}`, Number(a.houseEdge));
    } else if (ev.name === "SetAffiliateHouseEdge") {
      if (a.affiliate !== ZERO) for (const gid of gameIds) affGameToken.set(`${a.affiliate}-${gid}-${a.token}`, Number(a.houseEdge));
    } else if (ev.name === "GameConfigAdded") {
      configs.set(a.configId, { gameId: WEIGHTED[Number(a.gameId) - 1] && Number(a.gameId) <= 6 ? WEIGHTED[Number(a.gameId) - 1] : "CUSTOM_WEIGHTED_GAME",
        multipliers: a.multipliers, weights: a.weights });
    } else if (ev.name === "PlaceBet") {
      const shape = placeShape(alias);
      let input;
      if (alias.startsWith("coin_toss")) input = a.face ? "1" : "0";
      else input = (a.cap ?? a.numbers ?? a.configId).toString();
      const gameId = g || (configs.get(a.configId)?.gameId ?? "CUSTOM_WEIGHTED_GAME");
      const affiliate = shape === 3 ? a.affiliate : ZERO;
      const gt = `${gameId}-${a.token}`;
      const agt = affGameToken.get(`${affiliate}-${gt}`);
      const he = agt > 0 ? agt : gameToken.get(gt) > 0 ? gameToken.get(gt) : 0;
      if (!gameToken.has(gt)) gameToken.set(gt, 0);
      bets.set(a.id, {
        id: a.id, gameId, gameAddress: log.address.toLowerCase(), user: shape === 3 ? a.receiver : a.user,
        gameToken: gt, token: a.token, affiliate, inputValue: input, betAmount: shape === 1 ? "0" : a.amount,
        betCount: shape === 3 ? a.betCount : "1", stopLoss: shape === 3 ? a.stopLoss : "0", stopGain: shape === 3 ? a.stopGain : "0",
        houseEdge: he, betTimestamp: ts, resolved: false, refunded: false, chargedVRFFees: shape === 3 ? a.chargedVRFCost : "0",
        betTxnHash: log.transactionHash, isFreebet: false, freebetId: null, totalBetAmount: null, payout: null,
        payoutMultiplier: null, rollTxnHash: null, rolled: null, rollTimestamp: null, block,
      });
      if (!g) weightedBets.set(a.id, a.configId);
    } else if (ev.name === "Roll") {
      const b = bets.get(a.id);
      if (!b) continue;
      const v2 = a.totalBetAmount !== undefined;
      const amount = v2 ? "0" : a.amount;
      const total = v2 ? a.totalBetAmount : a.amount;
      if (BigInt(amount) > 0n) b.betAmount = amount;
      b.totalBetAmount = total;
      const rolled = Array.isArray(a.rolled) ? a.rolled : [a.rolled];
      b.rolled = rolled.map((x) => (x === true ? "1" : x === false ? "0" : String(x)));
      b.payout = a.payout; b.rollTimestamp = ts; b.rollTxnHash = log.transactionHash; b.resolved = true;
      b.payoutMultiplier = bdDiv(a.payout, total);
      resolve(b, v2 ? a.receiver : a.user, a.token, total, a.payout);
    } else if (ev.name === "BetRefunded") {
      const b = bets.get(a.id);
      if (!b) continue;
      const amount = refundShape(alias) === "A" ? a.amount : "0";
      b.payout = a.amount;
      if (BigInt(amount) > 0n) b.betAmount = amount;
      b.totalBetAmount = a.amount; b.rollTxnHash = log.transactionHash; b.rollTimestamp = ts;
      b.resolved = true; b.refunded = true; b.payoutMultiplier = "1";
      resolve(b, b.user, b.token, a.amount, a.amount);
    }
  }

  // ---- Compare with the nest ----------------------------------------------------------------------
  const BETS = fs.readFileSync(path.join(NEST, "queries/bets.graphql"), "utf8");
  const TOKENS = fs.readFileSync(path.join(NEST, "queries/tokens.graphql"), "utf8");
  const got = [];
  for (let skip = 0; ; skip += 1000) {
    const r = await gql(BETS, { first: 1000, skip, where: {}, orderBy: "id", orderDirection: "asc" });
    if (r.errors) throw new Error(JSON.stringify(r.errors));
    got.push(...r.data.bets);
    if (r.data.bets.length < 1000) break;
  }
  let compared = 0, bad = 0;
  const report = (what) => { if (bad++ < 20) console.log("DIFF", what); };
  const byId = new Map(got.map((b) => [b.id, b]));
  for (const want of bets.values()) {
    if (want.block > BOUNDARY) continue;
    const have = byId.get(want.id);
    if (!have) { report(`bet ${want.id} missing`); continue; }
    compared++;
    const T = added.has(want.token) ? tokenOf(want.token) : null;
    const expect = {
      id: want.id, gameId: want.gameId, gameAddress: want.gameAddress, user: { address: want.user },
      gameToken: { id: want.gameToken, token: T ? { address: T.id, symbol: T.symbol, name: T.name, decimals: T.decimals } : null },
      affiliate: want.affiliate === ZERO ? null : { address: want.affiliate },
      encodedInput: want.inputValue, betAmount: want.betAmount, betCount: want.betCount, stopLoss: want.stopLoss,
      stopGain: want.stopGain, houseEdge: want.houseEdge, betTimestamp: want.betTimestamp, isResolved: want.resolved,
      isRefunded: want.refunded, chargedVRFFees: want.chargedVRFFees, betTxnHash: want.betTxnHash,
      rollTotalBetAmount: want.totalBetAmount, payout: want.payout, payoutMultiplier: want.payoutMultiplier,
      rollTxnHash: want.rollTxnHash, encodedRolled: want.rolled, rollTimestamp: want.rollTimestamp,
      weightedGameBet: weightedBets.has(want.id) ? { config: configView(configs, weightedBets.get(want.id)) } : null,
    };
    for (const [k, v] of Object.entries(expect)) {
      if (JSON.stringify(v) !== JSON.stringify(have[k])) report(`bet ${want.id} ${k}: want ${JSON.stringify(v)} got ${JSON.stringify(have[k])}`);
    }
  }
  const extra = got.filter((b) => !bets.has(b.id)).length;
  if (extra) report(`${extra} bets answered that the reference does not have`);
  console.log(`bets: ${compared} compared field by field (${bets.size} in the window, ${got.length} answered)`);

  // The SDK's other calls: fetchBet (by id), fetchBetByHash (no orderBy, no skip), and fetchBets with
  // each filter it can send, newest first. Ten bets are sampled deterministically.
  const BET = fs.readFileSync(path.join(NEST, "queries/bet.graphql"), "utf8");
  const maxTs = Math.max(...[...bets.values()].filter((b) => b.block <= BOUNDARY).map((b) => Number(b.betTimestamp)));
  const sample = [...bets.values()].filter((b) => b.block <= BOUNDARY).sort((x, y) => (x.id < y.id ? -1 : 1));
  const picks = Array.from({ length: Math.min(10, sample.length) }, (_, i) => sample[Math.floor((i * sample.length) / 10)]);
  for (const b of picks) {
    const one = await gql(BET, { id: b.id });
    if (one.errors || JSON.stringify(one.data.bet) !== JSON.stringify(byId.get(b.id))) report(`bet(id: ${b.id}) differs from bets`);
    const byHash = await gql(BETS, { first: 1, where: { betTxnHash: b.betTxnHash } });
    if (byHash.errors || byHash.data.bets[0]?.betTxnHash !== b.betTxnHash) report(`fetchBetByHash ${b.betTxnHash}: ${JSON.stringify(byHash.errors || byHash.data)}`);
    const filters = [
      [{ user: b.user }, (x) => x.user === b.user],
      [{ gameId: b.gameId }, (x) => x.gameId === b.gameId],
      [{ gameToken_: { token: b.token } }, (x) => x.token === b.token],
      [{ resolved: b.resolved }, (x) => x.resolved === b.resolved],
      [{ user: b.user, resolved: true, gameToken_: { token: b.token } }, (x) => x.user === b.user && x.resolved && x.token === b.token],
    ];
    if (b.affiliate !== ZERO) filters.push([{ affiliate_in: [b.affiliate] }, (x) => x.affiliate === b.affiliate]);
    for (const [where, pred] of filters) {
      const want = [...bets.values()].filter((x) => x.block <= BOUNDARY && pred(x))
        .sort((x, y) => Number(y.betTimestamp) - Number(x.betTimestamp)).slice(0, 10).map((x) => x.betTimestamp);
      const r = await gql(BETS, { first: 10, skip: 0, where: { ...where, betTimestamp_lte: String(maxTs) }, orderBy: "betTimestamp", orderDirection: "desc" });
      const have = r.errors ? r.errors : r.data.bets.map((x) => x.betTimestamp);
      if (JSON.stringify(have) !== JSON.stringify(want)) report(`fetchBets ${JSON.stringify(where)}: want ${JSON.stringify(want)} got ${JSON.stringify(have)}`);
    }
  }
  console.log(`sdk calls: bet(id), fetchBetByHash and six fetchBets filters on ${picks.length} sampled bets`);

  const tr = await gql(TOKENS, { first: 1000, skip: 0, orderBy: "symbol", orderDirection: "asc" });
  if (tr.errors) throw new Error(JSON.stringify(tr.errors));
  for (const T of [...tokens.values()].filter((t) => added.has(t.id))) {
    const have = tr.data.tokens.find((x) => x.id === T.id);
    if (!have) { report(`token ${T.id} missing`); continue; }
    for (const [k, v] of Object.entries(T)) {
      if (String(v) !== String(have[k])) report(`token ${T.id} ${k}: want ${v} got ${have[k]}`);
    }
  }
  console.log(`tokens: ${added.size} compared (counters only meaningful when the window reaches every resolution)`);
  console.log(bad ? `FAIL: ${bad} difference(s)` : "PASS");
  process.exit(bad ? 1 : 0);
}

function configView(configs, id) {
  const c = configs.get(id);
  return c ? { id: String(id), multipliers: c.multipliers, weights: c.weights } : null;
}
const tsCache = new Map();
async function blockTs(n) {
  if (!tsCache.has(n)) tsCache.set(n, (await rpc("eth_getBlockByNumber", ["0x" + n.toString(16), false])).timestamp);
  return tsCache.get(n);
}
async function getTokens(bank, block) {
  const hex = (await rpc("eth_call", [{ to: bank, data: "0xaa6ca808" }, "0x" + block.toString(16)])).slice(2);
  const n = Number(BigInt("0x" + word(hex, 1)));
  const out = [];
  for (let i = 0; i < n; i++) {
    const e = 64 + Number(BigInt("0x" + word(hex, 2 + i)));
    const el = hex.slice(e * 2);
    const str = (k) => {
      const off = Number(BigInt("0x" + word(el, k))) * 2;
      const len = Number(BigInt("0x" + el.slice(off, off + 64)));
      return Buffer.from(el.slice(off + 64, off + 64 + len * 2), "hex").toString("utf8");
    };
    out.push({ decimals: Number(BigInt("0x" + word(el, 0))), token: "0x" + word(el, 1).slice(24), name: str(2), symbol: str(3) });
  }
  return out;
}
async function gql(query, variables) {
  const r = await fetch(url, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ query, variables }) });
  return r.json();
}
main().catch((e) => { console.error(String(e.message || e).replace(RPC, "<rpc>")); process.exit(2); });
