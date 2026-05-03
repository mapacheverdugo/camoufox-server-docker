# camoufox-server-docker

Imagen Docker que ejecuta [Camoufox](https://github.com/daijro/camoufox) como servidor WebSocket compatible con Playwright, dentro de un display virtual (Xvfb). Pensado para correr de forma headless en un homelab (TrueNAS / Portainer / cualquier host Docker) y conectarse remotamente desde scripts Playwright.

La imagen se publica automáticamente en GitHub Container Registry:

```
ghcr.io/mapacheverdugo/camoufox-server:latest
```

---

## Características

- Camoufox + Playwright corriendo como usuario no-root.
- Display virtual con `Xvfb` (resolución configurable).
- Endpoint WebSocket Playwright en `ws://<host>:<puerto>/`.
- Proxy upstream opcional (con o sin autenticación).
- Healthcheck integrado.
- Versión de Playwright / Camoufox parametrizable en el build (por defecto la última disponible).

---

## Despliegue rápido en Portainer (TrueNAS u otro)

1. En Portainer ve a **Stacks → Add stack**.
2. Pegá el contenido de [`docker-compose.yml`](./docker-compose.yml) (o usá el método "Repository" apuntando a este repo).
3. En la sección **Environment variables** agregá las que necesites del archivo [`.env.example`](./.env.example). Las únicas comunes a tocar:
   - `EXPOSED_PORT` — puerto en el TrueNAS donde querés exponer el servicio.
   - `PROXY_SERVER`, `PROXY_USERNAME`, `PROXY_PASSWORD` — si querés ruta a través de un proxy.
4. **Deploy the stack**.

Una vez levantado, el servidor escucha en `ws://<ip-truenas>:<EXPOSED_PORT>/`.

### Despliegue con `docker compose` directo

```bash
cp .env.example .env
# editá .env si querés
docker compose up -d
```

---

## Variables de entorno

Todas son opcionales — los valores por defecto están entre paréntesis.

### Servidor

| Variable        | Default | Descripción                                                                |
| --------------- | ------- | -------------------------------------------------------------------------- |
| `EXPOSED_PORT`  | `1234`  | Puerto publicado en el host. Solo se usa en el `docker-compose.yml`.       |
| `PORT`          | `1234`  | Puerto interno donde escucha Camoufox dentro del contenedor.               |
| `WS_PATH`       | `/`     | Path del endpoint WebSocket.                                               |
| `GEOIP`         | `true`  | Habilita la base GeoIP de Camoufox (requiere el extra `[geoip]`).          |
| `HUMANIZE`      | `true`  | Habilita el comportamiento "humanizado" de Camoufox.                       |

### Display virtual

| Variable        | Default | Descripción                                  |
| --------------- | ------- | -------------------------------------------- |
| `SCREEN_WIDTH`  | `1280`  | Ancho del display Xvfb.                      |
| `SCREEN_HEIGHT` | `720`   | Alto del display Xvfb.                       |
| `SCREEN_DEPTH`  | `16`    | Profundidad de color (8/16/24).              |
| `DISPLAY`       | `:99`   | Display X que usa Camoufox. Normalmente no hace falta cambiarlo. |

### Proxy upstream (opcional)

| Variable         | Default | Descripción                                         |
| ---------------- | ------- | --------------------------------------------------- |
| `PROXY_SERVER`   | _vacío_ | URL del proxy (`http://...` o `socks5://...`).      |
| `PROXY_USERNAME` | _vacío_ | Usuario del proxy. Solo se aplica si los 3 están.   |
| `PROXY_PASSWORD` | _vacío_ | Password del proxy. Solo se aplica si los 3 están.  |

> Si solo definís `PROXY_SERVER` se usa el proxy sin autenticación. Si definís los tres, se envían las credenciales.

### Recursos

| Variable          | Default | Descripción                              |
| ----------------- | ------- | ---------------------------------------- |
| `MEM_LIMIT`       | `2G`    | Límite duro de memoria del contenedor.   |
| `MEM_RESERVATION` | `1G`    | Reserva de memoria.                      |

---

## Build args (al compilar la imagen)

Si querés _fijar_ versiones específicas de las dependencias, podés pasar build args. Si los dejás vacíos, se instala la última versión disponible en PyPI.

| Build arg            | Default        | Descripción                                  |
| -------------------- | -------------- | -------------------------------------------- |
| `PLAYWRIGHT_VERSION` | _(última)_     | Fija la versión de `playwright` (ej. `1.52.0`). |
| `CAMOUFOX_VERSION`   | _(última)_     | Fija la versión de `camoufox`.               |

### Ejemplos

```bash
# Última versión (default)
docker build -t camoufox-server .

# Fijando versiones
docker build \
  --build-arg PLAYWRIGHT_VERSION=1.52.0 \
  --build-arg CAMOUFOX_VERSION=0.4.11 \
  -t camoufox-server:pinned .
```

Desde GitHub Actions, podés usar **Run workflow** (`workflow_dispatch`) para pasar los inputs `playwright_version` y `camoufox_version`. Si los dejás en blanco, se publica con las últimas.

---

## Cómo conectarse desde Playwright

```python
from playwright.sync_api import sync_playwright

WS = "ws://192.168.1.50:1234/"  # IP del TrueNAS y EXPOSED_PORT

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

## Estructura del repo

```
.
├── Dockerfile             # Imagen base AmazonLinux 2023 + Python 3.12 + Camoufox
├── docker-compose.yml     # Stack listo para Portainer/TrueNAS
├── entrypoint.sh          # Levanta Xvfb y delega al CMD
├── main.py                # Lanza Camoufox en modo servidor WS
├── .env.example           # Plantilla de variables de entorno
└── .github/workflows/     # CI: build y push a GHCR
```

---

## Troubleshooting

- **El healthcheck falla** — verificá que `PORT` coincida en el contenedor y en el `docker-compose.yml`.
- **`connect ECONNREFUSED`** — el contenedor todavía está iniciando (el primer arranque baja el binario Camoufox; suele tardar ~30 s).
- **Memoria** — con páginas pesadas puede hacer falta subir `MEM_LIMIT` a 3-4 GB.
- **Reinicios infinitos** — revisá los logs (`docker logs camoufox-server`); típicamente es un proxy mal configurado o falta de RAM.
