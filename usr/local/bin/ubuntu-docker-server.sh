#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
COMPOSE_URL="https://github.com/docker/compose/releases/download/v2.39.2/docker-compose-linux-x86_64"
COMPOSE_DST="/usr/local/lib/docker/cli-plugins/docker-compose"

# --- CLI arg (optional) ---
NEW_HOSTNAME="${1:-}"

if [[ -n "${NEW_HOSTNAME}" ]]; then
  echo "==> Setting hostname to ${NEW_HOSTNAME}"
  hostnamectl set-hostname "${NEW_HOSTNAME}"
  cp -a /etc/hosts /etc/hosts.bak || true
  SHORT_HOST="${NEW_HOSTNAME%%.*}"
  grep -q "${NEW_HOSTNAME}" /etc/hosts || echo "127.0.1.1 ${NEW_HOSTNAME} ${SHORT_HOST}" >> /etc/hosts
else
  echo "==> Keeping existing hostname: $(hostname -f || hostname)"
fi

echo "==> Remove snap & snap docker if present"
systemctl stop snapd || true
if command -v snap >/dev/null 2>&1; then
  snap list docker >/dev/null 2>&1 && snap remove --purge docker || true
  apt-get purge -y snapd || true
  rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd || true
  systemctl daemon-reload || true
fi

echo "==> Remove any old docker bits"
apt-get remove -y docker docker.io docker-engine docker-ce docker-ce-cli containerd runc || true

echo "==> Install Docker Engine from Docker’s repo"
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> Pin docker compose v2.39.2 to /usr/local"
install -d -m 0755 "$(dirname "${COMPOSE_DST}")"
curl -fsSL "${COMPOSE_URL}" -o "${COMPOSE_DST}"
chmod +x "${COMPOSE_DST}"

echo '==> Configure Docker daemon (journald logging)'
install -d -m 0755 /etc/docker
cat >/etc/docker/daemon.json <<'JSON'
{
  "data-root": "/var/lib/docker",
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5",
    "mode": "non-blocking"
  },
  "storage-driver": "overlay2",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "live-restore": true,
  "userland-proxy": false,
  "iptables": true,
  "ipv6": false,
  "default-address-pools": [
    { "base": "172.20.0.0/16", "size": 24 },
    { "base": "172.21.0.0/16", "size": 24 }
  ],
  "features": { "buildkit": true }
}
JSON

systemctl enable docker
systemctl restart docker

echo "==> Versions"
docker --version
docker compose version
echo "==> Done."
