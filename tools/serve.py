"""Local static preview with gzip, like a production static host. No game backend."""
import gzip, io, os
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CACHE={}
class Handler(SimpleHTTPRequestHandler):
    def __init__(self,*a,**kw):super().__init__(*a,directory=str(ROOT.parent),**kw)
    def send_head(self):
        path=self.translate_path(self.path)
        if path.endswith(('.wasm','.pck','.js')) and os.path.isfile(path) and 'gzip' in self.headers.get('Accept-Encoding',''):
            stat=os.stat(path);key=(path,stat.st_mtime)
            if key not in CACHE:CACHE[key]=gzip.compress(Path(path).read_bytes(),compresslevel=6)
            data=CACHE[key];self.send_response(200);self.send_header('Content-Type',self.guess_type(path));self.send_header('Content-Encoding','gzip');self.send_header('Content-Length',str(len(data)));self.send_header('Vary','Accept-Encoding');self.end_headers();return io.BytesIO(data)
        return super().send_head()
print('Open http://127.0.0.1:8766/love-in-bloom/docs/',flush=True)
ThreadingHTTPServer(('127.0.0.1',8766),Handler).serve_forever()
