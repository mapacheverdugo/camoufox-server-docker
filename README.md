# camoufox-server-docker

Docker image that runs [Camoufox](https://github.com/daijro/camoufox) as a Playwright-compatible WebSocket server inside a virtual display (Xvfb). Designed to run headless on a homelab (TrueNAS / Portainer / any Docker host) and be reached remotely from Playwright scripts.

The image is built locally from the `Dockerfile` in this repo (it is not pulled from any registry).

---

## Features

- Camoufox + Playwright running as a non-root user.
- Virtual display via `Xvfb` (configurable resolution).
- Playwright WebSocket endpoint at `ws://<host>:<port>/`.
- Optional upstream proxy (with or without authentication).
- Built-in healthcheck.
- Playwright / Camoufox versions are parameterized at build time (defaults to latest).

---

## Quick deploy on Portainer (TrueNAS or similar)

Because the compose file uses `build:` (no pre-built image is pulled), Portainer needs access to the `Dockerfile`. The recommended way is to deploy the stack from the Git repository:

1. In Portainer go to **Stacks → Add stack**.
2. Pick the **Repository** method and point it at this repo (`main` branch).
3. Leave `docker-compose.yml` as the Compose path.
4. Under **Environment variables** add the ones you need from [`.env.example`](./.env.example). The most common to tweak:
   - `EXPOSED_PORT` — host port where the service will be exposed on TrueNAS.
   - `PROXY_SERVER`, `PROXY_USERNAME`, `PROXY_PASSWORD` — optional upstream proxy.
   - `PLAYWRIGHT_VERSION` / `CAMOUFOX_VERSION` — optional, empty = latest.
5. **Deploy the stack**. Portainer will build the image on the host.

Once it is up, the server listens on `ws://<truenas-ip>:<EXPOSED_PORT>/`.

> The "Web editor" method (paste the YAML) **does not work** with `build:` because Portainer has no file context. Use Repository or Upload instead.

### Deploy with `docker compose` directly

```bash
cp .env.example .env
# edit .env if you want to
docker compose up -d --build
```

---

## Environment variables

All variables are optional — defaults are shown in parentheses.

### Server

| Variable        | Default | Description                                                              |
| --------------- | ------- | ------------------------------------------------------------------------ |
| `EXPOSED_PORT`  | `1234`  | Port published on the host. Only consumed by `docker-compose.yml`.       |
| `PORT`          | `1234`  | Internal port Camoufox listens on inside the container.                  |
| `WS_PATH`       | `/`     | Path of the WebSocket endpoint.                                          |
| `GEOIP`         | `true`  | Enable Camoufox's GeoIP database (requires the `[geoip]` extra).         |
| `HUMANIZE`      | `true`  | Enable Camoufox's humanized behavior.                                    |

### Virtual display

| Variable        | Default | Description                                              |
| --------------- | ------- | -------------------------------------------------------- |
| `ENABLE_XVFB`   | `true`  | Start Xvfb inside the container. Set to `false` to skip Xvfb and run Camoufox headless (the other `SCREEN_*` / `DISPLAY` variables are then ignored). |
| `SCREEN_WIDTH`  | `1280`  | Xvfb display width.                                      |
| `SCREEN_HEIGHT` | `720`   | Xvfb display height.                                     |
| `SCREEN_DEPTH`  | `16`    | Color depth (8/16/24).                                   |
| `DISPLAY`       | `:99`   | X display Camoufox attaches to. You usually don't need to change this. |

### Upstream proxy (optional)

| Variable         | Default | Description                                              |
| ---------------- | ------- | -------------------------------------------------------- |
| `PROXY_SERVER`   | _empty_ | Proxy URL (`http://...` or `socks5://...`).              |
| `PROXY_USERNAME` | _empty_ | Proxy username. Only applied if all three are set.       |
| `PROXY_PASSWORD` | _empty_ | Proxy password. Only applied if all three are set.       |

> If only `PROXY_SERVER` is defined, the proxy is used without authentication. If all three are defined, credentials are sent.

### Resources

| Variable          | Default | Description                              |
| ----------------- | ------- | ---------------------------------------- |
| `MEM_LIMIT`       | `2G`    | Hard memory limit for the container.     |
| `MEM_RESERVATION` | `1G`    | Soft memory reservation.                 |

---

## Build args

If you want to _pin_ specific dependency versions you can pass build args. Leaving them empty installs the latest version available on PyPI.

| Build arg            | Default     | Description                                   |
| -------------------- | ----------- | --------------------------------------------- |
| `PLAYWRIGHT_VERSION` | _(latest)_  | Pin the `playwright` version (e.g. `1.52.0`). |
| `CAMOUFOX_VERSION`   | _(latest)_  | Pin the `camoufox` version.                   |

These are wired into `docker-compose.yml`, so you can also set them as environment variables on the stack and they will be passed to the build:

```bash
PLAYWRIGHT_VERSION=1.52.0 CAMOUFOX_VERSION=0.4.11 docker compose build
```

Or with `docker build` directly:

```bash
# Latest (default)
docker build -t camoufox-server .

# Pinned versions
docker build \
  --build-arg PLAYWRIGHT_VERSION=1.52.0 \
  --build-arg CAMOUFOX_VERSION=0.4.11 \
  -t camoufox-server:pinned .
```

---

## How to connect from Playwright

```python
from playwright.sync_api import sync_playwright

WS = "ws://192.168.1.50:1234/"  # TrueNAS IP and EXPOSED_PORT

with sync_playwright() as p:
    browser = p.firefox.connect(WS)
    context = browser.new_context()
    page = context.new_page()
    page.goto("https://example.com")
    print(page.title())
    browser.close()
```

```javascript
import { firefox } from "playwright";

const browser = await firefox.connect("ws://192.168.1.50:1234/");
const page = await browser.newPage();
await page.goto("https://example.com");
console.log(await page.title());
await browser.close();
```

---

## Repo layout

```
.
├── Dockerfile             # AmazonLinux 2023 + Python 3.12 + Camoufox base image
├── docker-compose.yml     # Stack ready for Portainer / TrueNAS
├── entrypoint.sh          # Starts Xvfb and delegates to CMD
├── main.py                # Launches Camoufox in WS server mode
└── .env.example           # Environment variables template
```

---

## Troubleshooting

- **Healthcheck keeps failing** — make sure `PORT` matches between the container and the `docker-compose.yml`.
- **`connect ECONNREFUSED`** — the container is still starting (the first boot downloads the Camoufox binary; usually ~30 s).
- **Memory** — heavy pages may need `MEM_LIMIT` raised to 3-4 GB.
- **Restart loop** — check `docker logs camoufox-server`; it is usually a misconfigured proxy or insufficient RAM.
