#!/usr/bin/env python3
"""Приёмник файлов из браузера: localhost:8765 отдаёт страницу, которая принимает postMessage({name, blob})
со страниц chatgpt.com / gemini.google.com и сохраняет файл в <папку>. Нужен, потому что Chrome владельца
спрашивает «куда сохранить», а fetch на localhost запрещён CSP этих сайтов.

Использование: python3 tools/recv.py <папка>
На странице: w = window.open('http://127.0.0.1:8765/','zrecv'); дождаться message {ready}; w.postMessage({name, blob}, '*').
"""
import http.server
import os
import sys
import urllib.parse

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
PAGE = b"""<!doctype html><title>recv</title><body>recv<script>
const OK=['https://chatgpt.com','https://gemini.google.com'];
addEventListener('message',async e=>{ if(!OK.includes(e.origin)||!e.data||!e.data.blob) return;
 const r=await fetch('/save?name='+encodeURIComponent(e.data.name),{method:'POST',body:e.data.blob});
 document.body.append(' '+e.data.name+':'+r.status); e.source.postMessage({saved:e.data.name,status:r.status},e.origin);});
if(opener) for(const o of OK) try{opener.postMessage({ready:1},o)}catch(_){}
</script>"""


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(PAGE)

    def do_POST(self):
        q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        name = os.path.basename(q.get("name", ["file.bin"])[0])
        data = self.rfile.read(int(self.headers["Content-Length"]))
        with open(os.path.join(OUT, name), "wb") as f:
            f.write(data)
        print("saved", name, len(data), flush=True)
        self.send_response(200)
        self.end_headers()

    def log_message(self, *a):
        pass


http.server.ThreadingHTTPServer(("127.0.0.1", 8765), Handler).serve_forever()
