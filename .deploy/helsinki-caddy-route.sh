#!/usr/bin/env bash
# Run as root on Helsinki (89.167.109.4). Adds a public, no-auth Caddy site for the BetSwirl BNB
# stopgap nest, which runs on the ThinkPad at 100.83.44.63:8310 over the tailnet.
#
# Only the GraphQL paths are exposed; /sql and everything else answer 404. CORS is added here
# because the nest sends none and the SDK runs in browsers.
#
# Any failure after the Caddyfile is touched restores the backup and reloads, so Caddy is never
# left on a config this script wrote unless the public query answered through it.
set -euo pipefail

HOST=${HOST:-betswirl-bnb.89.167.109.4.sslip.io}
UPSTREAM=${UPSTREAM:-100.83.44.63:8310}
DEPLOYMENT=Qmd5oqyojVx5wWSFuWfKz3YVLPHdE3KU5458Qqq3SVeGEB
CADDYFILE=/etc/caddy/Caddyfile
QUERY='{"query":"{ _meta { block { number } } bets(first: 1) { id } }"}'

say() { echo "helsinki-caddy-route: $*" >&2; }

[ "$(id -u)" = 0 ] || { say "run as root"; exit 1; }
command -v caddy >/dev/null || { say "caddy is not on PATH"; exit 1; }
[ -f "$CADDYFILE" ] || { say "no $CADDYFILE"; exit 1; }
if grep -q "^$HOST" "$CADDYFILE"; then
  say "$HOST is already in $CADDYFILE; nothing to do"
  exit 0
fi

say "checking the nest answers from here over the tailnet"
curl -fsS -m 30 -H 'content-type: application/json' -d "$QUERY" "http://$UPSTREAM/subgraphs/id/$DEPLOYMENT" \
  | grep -q '"bets"' || { say "the nest at $UPSTREAM did not answer; Caddy untouched"; exit 1; }

backup="$CADDYFILE.bak-betswirl-$(date -u +%Y%m%dT%H%M%SZ)"
cp -p "$CADDYFILE" "$backup"
say "backed up to $backup"

revert() {
  say "reverting: $*"
  cp -p "$backup" "$CADDYFILE"
  systemctl reload caddy || say "reload after revert failed; check: systemctl status caddy"
  exit 1
}

cat >> "$CADDYFILE" <<EOF

# BetSwirl BNB stopgap nest (nightswatchhq/nuthatch#1941), served from the ThinkPad. Added $(date -u +%F).
$HOST {
	@preflight method OPTIONS
	handle @preflight {
		header Access-Control-Allow-Origin "*"
		header Access-Control-Allow-Methods "POST, OPTIONS"
		header Access-Control-Allow-Headers "content-type"
		header Access-Control-Max-Age "86400"
		respond 204
	}
	@graphql path /graphql /subgraphs/id/$DEPLOYMENT
	handle @graphql {
		header Access-Control-Allow-Origin "*"
		reverse_proxy $UPSTREAM
	}
	handle {
		respond "Not found. GraphQL is at /subgraphs/id/$DEPLOYMENT" 404
	}
}
EOF

caddy validate --config "$CADDYFILE" --adapter caddyfile >/dev/null 2>&1 || revert "caddy validate failed"
systemctl reload caddy || revert "systemctl reload caddy failed"

# The certificate is issued on first use, so give it a minute before deciding.
url="https://$HOST/subgraphs/id/$DEPLOYMENT"
for i in $(seq 1 12); do
  if curl -fsS -m 20 -H 'content-type: application/json' -d "$QUERY" "$url" 2>/dev/null | grep -q '"bets"'; then
    say "live: $url"
    curl -fsS -m 20 -H 'content-type: application/json' -d "$QUERY" "$url"; echo
    exit 0
  fi
  sleep 5
done
revert "the public URL did not answer within a minute"
