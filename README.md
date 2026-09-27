# Host T3 Code on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/Djc2ZX?referralCode=UEjeDc&utm_medium=integration&utm_source=template&utm_campaign=generic)

This template runs the nightly T3 Code server with Codex, GitHub CLI, and CLIProxyAPI installed.

CLIProxyAPI stores provider login tokens in `/data/home/.cli-proxy-api`. This is its default `~/.cli-proxy-api` authentication directory under the persistent home directory, so logins survive redeployments.

## Setup

1. Click the button above to deploy the application to Railway.
2. Add any optional credentials during template setup:
   - `OPENAI_API_KEY` authenticates Codex.
   - `GH_TOKEN` authenticates GitHub CLI and Git over HTTPS.
   - `TS_AUTHKEY` joins the instance to your tailnet. Use an ephemeral, pre-approved auth key when possible.
   - `TS_HOSTNAME` sets the tailnet device name. It only applies when `TS_AUTHKEY` is set.
3. After deployment, copy the connection token from the latest deployment logs. Redeploying in another region creates a new token.
4. Open the Railway domain from the service's Settings page and enter the connection token.
5. If you did not set `OPENAI_API_KEY`, open the terminal with <kbd>Ctrl</kbd>+<kbd>J</kbd> or <kbd>Cmd</kbd>+<kbd>J</kbd>, then run `codex login --device-auth`.

When `TS_AUTHKEY` is set, the deployment logs print the private tailnet hostname. T3 Code is available there over HTTP on port 80. Commands started in T3 use Tailscale's userspace proxy, so they can reach other tailnet devices.

## Connect through T3 Connect

T3 Connect links this deployment to your T3 Code account through its managed relay. After the deployment is running:

1. Open T3 Code through its Railway domain or tailnet hostname.
2. Open the terminal with <kbd>Ctrl</kbd>+<kbd>J</kbd> or <kbd>Cmd</kbd>+<kbd>J</kbd>.
3. Run `t3 connect --headless`.
4. Open the authorization URL printed in the terminal, sign in, then paste the returned code into the terminal.
5. Run `t3 connect status` to confirm the environment is linked.

This cannot run as a template checkbox because authorization needs interactive input. Run it once after deployment instead.
