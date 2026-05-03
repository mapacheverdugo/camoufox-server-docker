import os
import time

from camoufox.server import launch_server

INTERNAL_PORT = 1234


def _env(name: str) -> str | None:
    value = os.environ.get(name)
    if value is None or value.strip() == "":
        return None
    return value


def main() -> None:
    proxy_server = _env("PROXY_SERVER")
    proxy_username = _env("PROXY_USERNAME")
    proxy_password = _env("PROXY_PASSWORD")

    proxy: dict | None
    if proxy_server and proxy_username and proxy_password:
        proxy = {
            "server": proxy_server,
            "username": proxy_username,
            "password": proxy_password,
        }
    elif proxy_server:
        proxy = {"server": proxy_server}
    else:
        proxy = None

    ws_path = _env("WS_PATH") or "/"
    geoip = (_env("GEOIP") or "true").lower() in ("1", "true", "yes")
    humanize = (_env("HUMANIZE") or "true").lower() in ("1", "true", "yes")
    # When the virtual display is disabled there is no X server available,
    # so Camoufox must run headless.
    xvfb_enabled = (_env("ENABLE_XVFB") or "true").lower() in ("1", "true", "yes", "on")
    headless = not xvfb_enabled

    # Build kwargs and only include `proxy` when configured — Camoufox
    # rejects proxy=None ("proxy: expected object, got null").
    kwargs: dict = {
        "headless": headless,
        "geoip": geoip,
        "humanize": humanize,
        "port": INTERNAL_PORT,
        "ws_path": ws_path,
    }
    if proxy is not None:
        kwargs["proxy"] = proxy

    print(
        f"camoufox-server starting on :{INTERNAL_PORT}{ws_path} "
        f"(headless={headless}, proxy={'on' if proxy else 'off'}) at {time.time()}"
    )
    launch_server(**kwargs)


if __name__ == "__main__":
    main()
