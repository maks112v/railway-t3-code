FROM node:24-bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/data/home
ENV WORKSPACE_DIR=/data/workspaces

RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    curl \
    ca-certificates \
    bash \
    tar \
    tini \
    build-essential \
    python3 \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg \
      -o /usr/share/keyrings/tailscale-archive-keyring.gpg \
    && curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list \
      -o /etc/apt/sources.list.d/tailscale.list \
    && apt-get update \
    && apt-get install -y gh tailscale \
    && rm -rf /var/lib/apt/lists/*

# Install Codex CLI and T3 Code.
RUN npm install --global \
    @openai/codex@latest \
    t3@nightly

# Install CLIProxyAPI without its systemd-oriented Linux installer. Configuration
# and provider credentials belong in the persistent home directory at runtime.
ARG CLIPROXYAPI_VERSION=8.0.2
RUN architecture="$(dpkg --print-architecture)" \
    && case "$architecture" in \
      amd64) release_arch="amd64"; checksum="7478ab50f5b59cb34911547b2b527275bd0bf64f52687588dcce65a386f244ad" ;; \
      arm64) release_arch="aarch64"; checksum="e790af5d63b6bd803c4173ef0d7dc8aaf8e5d66f822d28551c45fd5112918065" ;; \
      *) echo "Unsupported architecture: $architecture" >&2; exit 1 ;; \
    esac \
    && archive="CLIProxyAPI_${CLIPROXYAPI_VERSION}_linux_${release_arch}.tar.gz" \
    && curl -fsSL \
      "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${CLIPROXYAPI_VERSION}/${archive}" \
      -o "/tmp/${archive}" \
    && echo "${checksum}  /tmp/${archive}" | sha256sum --check --status \
    && tar -xzf "/tmp/${archive}" -C /usr/local/bin cli-proxy-api \
    && chmod +x /usr/local/bin/cli-proxy-api \
    && rm "/tmp/${archive}"

COPY start.sh /usr/local/bin/start-t3
RUN chmod +x /usr/local/bin/start-t3

WORKDIR /data/workspaces

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/start-t3"]
