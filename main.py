import os
import time

from camoufox.server import launch_server


def _env(name: str) -> str | None:
    value = os.environ.get(name)
    if value is None or value.strip() == "":
        return None
    return value


def main() -> None:
    proxy_server = _env("PROXY_SERVER")
    proxy_username = _env("PROXY_USERNAME")
    proxy_password = _env("PROXY_PASSWORD")

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

    port = int(_env("PORT") or "1234")
    ws_path = _env("WS_PATH") or "/"
    geoip = (_env("GEOIP") or "true").lower() in ("1", "true", "yes")
    humanize = (_env("HUMANIZE") or "true").lower() in ("1", "true", "yes")

    print(f"camoufox-server starting on :{port}{ws_path} at {time.time()}")
    launch_server(
        geoip=geoip,
        humanize=humanize,
        proxy=proxy,
        port=port,
        ws_path=ws_path,
    )


if __name__ == "__main__":
    main()
