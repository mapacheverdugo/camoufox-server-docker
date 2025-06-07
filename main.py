from camoufox.server import launch_server
import os

def main():
    if 'PROXY_SERVER' in os.environ:
        proxy_server = os.environ['PROXY_SERVER']

    if 'PROXY_USERNAME' in os.environ:
        proxy_username = os.environ['PROXY_USERNAME']
    
    if 'PROXY_PASSWORD' in os.environ:
        proxy_password = os.environ['PROXY_PASSWORD']

    if (proxy_server and proxy_username and proxy_password):
        proxy = {
            'server': proxy_server,
            'username': proxy_username,
            'password': proxy_password
        }
    else:
        proxy = None

    launch_server(
        headless="virtual",
        geoip=True,
        humanize=True,
        block_images=True,
        proxy=proxy,
        port=1234,
        ws_path='test'
    )

if __name__ == "__main__":
    main()