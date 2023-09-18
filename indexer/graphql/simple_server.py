from http.server import SimpleHTTPRequestHandler
import http.server
import ssl

handler = SimpleHTTPRequestHandler
httpd = http.server.HTTPServer(("0.0.0.0", 8080), handler)

httpd.socket = ssl.wrap_socket(
    httpd.socket,
    certfile="/etc/letsencrypt/live/survivor-indexer.realms.world/fullchain.pem",
    keyfile="/etc/letsencrypt/live/survivor-indexer.realms.world/privkey.pem",
    server_side=True,
)

httpd.serve_forever()
