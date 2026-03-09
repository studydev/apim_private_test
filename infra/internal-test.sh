#!/usr/bin/env bash
set -e

APIM_HOST="${APIM_HOST:-<apim-name>.azure-api.net}"

echo "== DNS =="
nslookup "$APIM_HOST"

echo "== test1 =="
cat > /tmp/payload.json <<'EOF'
{"messages":[{"role":"user","content":"hello"}]}
EOF

curl -sS -D /tmp/test1.headers -o /tmp/test1.body -X POST "https://${APIM_HOST}/chat/test1" \
  -H "Content-Type: application/json" \
  -d @/tmp/payload.json
head -n 1 /tmp/test1.headers
cat /tmp/test1.body

echo "== test2 =="
curl -sS -D /tmp/test2.headers -o /tmp/test2.body -X POST "https://${APIM_HOST}/chat/test2" \
  -H "Content-Type: application/json" \
  -d @/tmp/payload.json
head -n 1 /tmp/test2.headers
cat /tmp/test2.body
