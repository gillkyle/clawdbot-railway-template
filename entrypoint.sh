#!/usr/bin/env bash
set -e

# Start Tailscale daemon in userspace networking mode (no TUN device needed in containers).
if command -v tailscaled &>/dev/null && [ -n "$TS_AUTHKEY" ]; then
  echo "[entrypoint] Starting tailscaled (userspace networking)..."
  tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state &
  sleep 2

  echo "[entrypoint] Connecting to tailnet..."
  tailscale up --authkey="$TS_AUTHKEY" --hostname="${TS_HOSTNAME:-openclaw-railway}"
  echo "[entrypoint] Tailscale connected: $(tailscale ip -4)"

  # Expose the wrapper's HTTP port over HTTPS via Tailscale Serve.
  echo "[entrypoint] Setting up Tailscale Serve on port ${PORT:-8080}..."
  tailscale serve --bg --yes "${PORT:-8080}" 2>&1 || echo "[entrypoint] Tailscale Serve failed (non-fatal)"
else
  echo "[entrypoint] Tailscale skipped (TS_AUTHKEY not set or tailscale not found)"
fi

# Hand off to the Node.js wrapper.
exec node src/server.js
