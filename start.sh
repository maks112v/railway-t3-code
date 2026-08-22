#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/data/home}"
export WORKSPACE_DIR="${WORKSPACE_DIR:-/data/workspaces}"
port="${PORT:-8080}"

mkdir -p \
  "$HOME" \
  "$HOME/.codex" \
  "$HOME/.config" \
  "$HOME/.t3" \
  "$WORKSPACE_DIR"

# Authenticate Codex from the Railway secret on first startup.
if [ -n "${OPENAI_API_KEY:-}" ]; then
  if ! codex login status >/dev/null 2>&1; then
    printf '%s' "$OPENAI_API_KEY" | codex login --with-api-key
  fi
fi

# GH_TOKEN is GitHub CLI's native non-interactive authentication method.
if [ -n "${GH_TOKEN:-}" ]; then
  gh auth setup-git --hostname github.com
fi

# Railway containers cannot create a TUN device, so Tailscale runs as a
# userspace proxy. T3 and its terminals inherit the proxy settings below.
if [ -n "${TS_AUTHKEY:-}" ]; then
  tailscale_state_dir="${TS_STATE_DIR:-$HOME/.local/share/tailscale}"
  tailscale_socket="/tmp/tailscaled.sock"
  mkdir -p "$tailscale_state_dir"

  tailscaled \
    --state="$tailscale_state_dir/tailscaled.state" \
    --socket="$tailscale_socket" \
    --tun=userspace-networking \
    --socks5-server=127.0.0.1:1055 \
    --outbound-http-proxy-listen=127.0.0.1:1055 &

  for _ in $(seq 1 50); do
    [ -S "$tailscale_socket" ] && break
    sleep 0.1
  done

  if [ ! -S "$tailscale_socket" ]; then
    echo "Tailscale failed to start" >&2
    exit 1
  fi

  tailscale_up_args=(--auth-key="$TS_AUTHKEY")
  if [ -n "${TS_HOSTNAME:-}" ]; then
    tailscale_up_args+=(--hostname="$TS_HOSTNAME")
  fi

  tailscale --socket="$tailscale_socket" up "${tailscale_up_args[@]}"
  tailscale --socket="$tailscale_socket" serve \
    --bg \
    --http=80 \
    "http://127.0.0.1:$port"

  export ALL_PROXY="socks5://127.0.0.1:1055"
  export HTTP_PROXY="http://127.0.0.1:1055"
  export HTTPS_PROXY="$HTTP_PROXY"
  export all_proxy="$ALL_PROXY"
  export http_proxy="$HTTP_PROXY"
  export https_proxy="$HTTPS_PROXY"
  export NO_PROXY="localhost,127.0.0.1,::1,.railway.internal${NO_PROXY:+,$NO_PROXY}"
  export no_proxy="$NO_PROXY"

  tailscale_dns_name="$(tailscale --socket="$tailscale_socket" status --self --json | sed -n 's/.*\"DNSName\":[[:space:]]*\"\([^\"]*\)\".*/\1/p')"
  echo "Joined Tailscale as ${tailscale_dns_name%.}"
  unset TS_AUTHKEY
fi

cd "$WORKSPACE_DIR"

echo "Starting T3 Code"
echo "Workspace: $WORKSPACE_DIR"
echo "Railway port: $port"

exec t3 serve \
  --host 0.0.0.0 \
  --port "$port"
