from camoufox.server import launch_server
import os

def main():
    launch_server(
        headless="virtual",
        humanize=True,
        port=1234,
        ws_path='test',
        geoip=True,
    )

if __name__ == "__main__":
    main()