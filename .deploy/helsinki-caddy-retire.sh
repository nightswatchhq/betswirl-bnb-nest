#!/usr/bin/env bash
# Run as root on Helsinki. Replaces the BetSwirl stopgap site's proxy with a 410 that says it was retired
# and where the handback lives. Restores the backup and reloads if anything fails.
set -euo pipefail

HOST=${HOST:-betswirl-bnb.89.167.109.4.sslip.io}
CADDYFILE=/etc/caddy/Caddyfile
NOTE="Retired 2026-10-07: the BetSwirl BNB stopgap nest had no users. Run it yourself from https://github.com/nightswatchhq/nuthatch/blob/main/docs/stopgap/betswirl-bnb.md"

say() { echo "helsinki-caddy-retire: $*" >&2; }
[ "$(id -u)" = 0 ] || { say "run as root"; exit 1; }
grep -q "^$HOST {" "$CADDYFILE" || { say "$HOST is not in $CADDYFILE; nothing to do"; exit 0; }

backup="$CADDYFILE.bak-betswirl-retire-$(date -u +%Y%m%dT%H%M%SZ)"
cp -p "$CADDYFILE" "$backup"
say "backed up to $backup"
revert() { say "reverting: $*"; cp -p "$backup" "$CADDYFILE"; systemctl reload caddy || true; exit 1; }

# Swap the site block's body for one 410, keeping the block and its comment.
awk -v host="$HOST" -v note="$NOTE" '
  $0 == host " {" { print; print "\trespond \"" note "\" 410"; skip = 1; depth = 1; next }
  skip { n = gsub(/\{/, "{"); m = gsub(/\}/, "}"); depth += n - m; if (depth == 0) { print "}"; skip = 0 } ; next }
  { print }
' "$backup" > "$CADDYFILE"

caddy validate --config "$CADDYFILE" --adapter caddyfile >/dev/null 2>&1 || revert "caddy validate failed"
systemctl reload caddy || revert "reload failed"
code=$(curl -s -o /dev/null -w "%{http_code}" -m 20 "https://$HOST/subgraphs/id/Qmd5oqyojVx5wWSFuWfKz3YVLPHdE3KU5458Qqq3SVeGEB")
[ "$code" = 410 ] || revert "expected 410, got $code"
say "retired: https://$HOST answers 410"
