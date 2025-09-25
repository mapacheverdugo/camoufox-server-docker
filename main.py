import time
print(f"MAIN.PY START: {time.time()}")
from camoufox.server import launch_server
import os


def main():
    proxy_server = None
    proxy_username = None
    proxy_password = None

    if 'PROXY_SERVER' in os.environ:
        proxy_server = os.environ.get('PROXY_SERVER')

    if 'PROXY_USERNAME' in os.environ:
        proxy_username = os.environ.get('PROXY_USERNAME')
    
    if 'PROXY_PASSWORD' in os.environ:
        proxy_password = os.environ.get('PROXY_PASSWORD')

    if (proxy_server and proxy_username and proxy_password):
        proxy = {
            'server': proxy_server,
            'username': proxy_username,
            'password': proxy_password
        }
    else:
        proxy = None

    # Get port from environment variable, default to 1234
    port = int(os.environ.get('PORT', 1234))

    print(f"MAIN.PY LAUNCH SERVER: {time.time()}")
    launch_server(
        geoip=True,
        humanize=True,
        proxy=proxy,
        port=port,
        ws_path='/',
    )

if __name__ == "__main__":
    main()